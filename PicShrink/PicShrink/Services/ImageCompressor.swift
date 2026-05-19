import AppKit
import CoreImage
import UniformTypeIdentifiers
import ImageIO

enum CompressionQuality: String, CaseIterable {
    case lossless
    case high
    case medium
    case low

    var jpegValue: CGFloat {
        switch self {
        case .lossless: return 0.92
        case .high: return 0.75
        case .medium: return 0.55
        case .low: return 0.25
        }
    }

    var webpValue: CGFloat {
        switch self {
        case .lossless: return 100
        case .high: return 85
        case .medium: return 60
        case .low: return 30
        }
    }

    var maxPixelDimension: Int {
        switch self {
        case .lossless: return 8192
        case .high: return 2560
        case .medium: return 1920
        case .low: return 1024
        }
    }
}

enum OutputFormat: String, CaseIterable {
    case jpeg
    case webp
    case png

    var fileExtension: String {
        switch self {
        case .jpeg: return "jpg"
        case .webp: return "webp"
        case .png: return "png"
        }
    }

    var utType: UTType {
        switch self {
        case .png: return .png
        case .jpeg: return .jpeg
        case .webp: return .webP
        }
    }
}

struct CompressionResult: Sendable {
    let originalURL: URL
    let outputURL: URL
    let originalSize: Int64
    let compressedSize: Int64

    var savedBytes: Int64 { originalSize - compressedSize }
    var savedPercent: Double {
        guard originalSize > 0 else { return 0 }
        return Double(savedBytes) / Double(originalSize) * 100.0
    }
}

enum ImageCompressor {

    static func uniqueOutputURL(baseName: String, ext: String, in directory: URL) -> URL {
        let candidate = directory.appendingPathComponent("\(baseName).\(ext)")
        guard FileManager.default.fileExists(atPath: candidate.path) else { return candidate }

        var counter = 1
        while true {
            let next = directory.appendingPathComponent("\(baseName)-\(counter).\(ext)")
            if !FileManager.default.fileExists(atPath: next.path) { return next }
            counter += 1
        }
    }

    static func compress(
        imageAt url: URL,
        quality: CompressionQuality,
        outputFormat: OutputFormat,
        preserveEXIF: Bool,
        outputDirectory: URL
    ) async throws -> CompressionResult {
        let originalSize = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize.map(Int64.init) ?? 0

        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            throw CompressionError.cannotReadFile
        }

        guard let originalCGImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw CompressionError.cannotDecodeImage
        }

        let baseName = url.deletingPathExtension().lastPathComponent
        let outFile = uniqueOutputURL(baseName: baseName, ext: outputFormat.fileExtension, in: outputDirectory)

        let sourceProperties = preserveEXIF
            ? CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any]
            : nil

        let imageToWrite: CGImage
        let maxDim = quality.maxPixelDimension

        if originalCGImage.width > maxDim || originalCGImage.height > maxDim {
            imageToWrite = resizeImage(originalCGImage, maxDimension: maxDim)
        } else {
            imageToWrite = originalCGImage
        }

        switch outputFormat {
        case .png:
            try writePNG(image: imageToWrite, to: outFile, quality: quality)
        case .webp:
            try writeWebP(image: imageToWrite, to: outFile, quality: quality, sourceProperties: sourceProperties)
        case .jpeg:
            try writeJPEG(image: imageToWrite, to: outFile, quality: quality, sourceProperties: sourceProperties)
        }

        let compressedSize = try outFile.resourceValues(forKeys: [.fileSizeKey]).fileSize.map(Int64.init) ?? 0

        if compressedSize >= originalSize {
            let fallbackQuality: CompressionQuality = switch quality {
            case .lossless: .high
            case .high: .medium
            case .medium: .low
            case .low: .low
            }
            let smallerImage = resizeImage(imageToWrite, maxDimension: fallbackQuality.maxPixelDimension)
            try? FileManager.default.removeItem(at: outFile)
            let fallbackFile = uniqueOutputURL(baseName: baseName, ext: "jpg", in: outputDirectory)
            try writeJPEG(image: smallerImage, to: fallbackFile, quality: fallbackQuality, sourceProperties: nil)
            let smallerSize = try fallbackFile.resourceValues(forKeys: [.fileSizeKey]).fileSize.map(Int64.init) ?? 0
            return CompressionResult(
                originalURL: url,
                outputURL: fallbackFile,
                originalSize: originalSize,
                compressedSize: smallerSize
            )
        }

        return CompressionResult(
            originalURL: url,
            outputURL: outFile,
            originalSize: originalSize,
            compressedSize: compressedSize
        )
    }

    private static func resizeImage(_ image: CGImage, maxDimension: Int) -> CGImage {
        let width = image.width
        let height = image.height

        guard width > maxDimension || height > maxDimension else { return image }

        let ratio = CGFloat(maxDimension) / CGFloat(max(width, height))
        let newWidth = Int(CGFloat(width) * ratio)
        let newHeight = Int(CGFloat(height) * ratio)

        guard let colorSpace = image.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: nil,
                width: newWidth,
                height: newHeight,
                bitsPerComponent: image.bitsPerComponent,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: image.bitmapInfo.rawValue
              )
        else { return image }

        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))

        return context.makeImage() ?? image
    }

    private static func writePNG(image: CGImage, to url: URL, quality: CompressionQuality) throws {
        let rep = NSBitmapImageRep(cgImage: image)
        rep.size = NSSize(width: image.width, height: image.height)

        var props: [NSBitmapImageRep.PropertyKey: Any] = [:]

        switch quality {
        case .lossless:
            props[.compressionFactor] = 1.0
            props[.interlaced] = false
        case .high:
            props[.compressionFactor] = 0.65
            props[.interlaced] = false
        case .medium:
            props[.compressionFactor] = 0.4
            props[.interlaced] = false
        case .low:
            props[.compressionFactor] = 0.2
            props[.interlaced] = false
        }

        guard let data = rep.representation(using: .png, properties: props) else {
            throw CompressionError.encodingFailed
        }
        try data.write(to: url)
    }

    private static func writeJPEG(
        image: CGImage,
        to url: URL,
        quality: CompressionQuality,
        sourceProperties: [CFString: Any]?
    ) throws {
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw CompressionError.encodingFailed
        }

        var properties: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality.jpegValue,
            kCGImagePropertyDPIWidth: 72,
            kCGImagePropertyDPIHeight: 72,
        ]

        if let exif = sourceProperties?[kCGImagePropertyExifDictionary] {
            properties[kCGImagePropertyExifDictionary] = exif
        }
        if let tiff = sourceProperties?[kCGImagePropertyTIFFDictionary] {
            properties[kCGImagePropertyTIFFDictionary] = tiff
        }
        if let gps = sourceProperties?[kCGImagePropertyGPSDictionary] {
            properties[kCGImagePropertyGPSDictionary] = gps
        }

        CGImageDestinationAddImage(destination, image, properties as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw CompressionError.encodingFailed
        }
    }

    private static func writeWebP(
        image: CGImage,
        to url: URL,
        quality: CompressionQuality,
        sourceProperties: [CFString: Any]?
    ) throws {
        let mutableData = NSMutableData()

        guard let destination = CGImageDestinationCreateWithData(
            mutableData as CFMutableData,
            UTType.webP.identifier as CFString,
            1,
            nil
        ) else {
            throw CompressionError.webpNotSupported
        }

        var properties: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality.webpValue / 100.0,
        ]

        CGImageDestinationAddImage(destination, image, properties as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw CompressionError.webpNotSupported
        }

        try mutableData.write(to: url)
    }

    static func isImageFile(_ url: URL) -> Bool {
        guard let utType = UTType(filenameExtension: url.pathExtension) else { return false }
        let imageTypes: [UTType] = [.png, .jpeg, .webP, .heic, .heif, .tiff, .bmp, .gif, .rawImage]
        return imageTypes.contains { utType.conforms(to: $0) }
    }

    static func formatByteSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

enum CompressionError: LocalizedError {
    case cannotReadFile
    case cannotDecodeImage
    case encodingFailed
    case webpNotSupported

    var errorDescription: String? {
        switch self {
        case .cannotReadFile: return "Cannot read file"
        case .cannotDecodeImage: return "Cannot decode image"
        case .encodingFailed: return "Encoding failed"
        case .webpNotSupported: return "WebP encoding not available on this macOS"
        }
    }
}
