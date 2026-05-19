import AppKit
import Foundation

@MainActor
class FormatConverterService {

    func convertBatch(
        files: [URL],
        format: ImageFormat,
        quality: Double,
        resize: Bool,
        targetWidth: Int,
        targetHeight: Int,
        keepExif: Bool,
        outputDirectory: URL,
        onProgress: @escaping (Int, String) -> Void
    ) async {
        try? FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

        let stream = AsyncStream<(Int, String)> { continuation in
            Task.detached {
                await withTaskGroup(of: Void.self) { group in
                    for file in files {
                        group.addTask {
                            await self.convertSingle(
                                sourceURL: file,
                                format: format,
                                quality: quality,
                                resize: resize,
                                targetWidth: targetWidth,
                                targetHeight: targetHeight,
                                keepExif: keepExif,
                                outputDirectory: outputDirectory
                            )
                        }
                    }
                    for await _ in group {}
                    continuation.yield((files.count, ""))
                }
                continuation.finish()
            }
        }

        for await (completed, _) in stream {
            onProgress(completed, "")
        }
    }

    private static func uniqueURL(base: URL) -> URL {
        let dir = base.deletingLastPathComponent()
        let stem = base.deletingPathExtension().lastPathComponent
        let ext = base.pathExtension
        var candidate = base
        var counter = 1
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = dir.appendingPathComponent("\(stem)_\(counter).\(ext)")
            counter += 1
        }
        return candidate
    }

    private nonisolated func convertSingle(
        sourceURL: URL,
        format: ImageFormat,
        quality: Double,
        resize: Bool,
        targetWidth: Int,
        targetHeight: Int,
        keepExif: Bool,
        outputDirectory: URL
    ) async {
        guard let imageData = try? Data(contentsOf: sourceURL) else { return }
        guard let cgImageSource = CGImageSourceCreateWithData(imageData as CFData, nil) else { return }

        let outputFileName = sourceURL
            .deletingPathExtension()
            .lastPathComponent + "." + format.fileExtension

        let rawOutputURL = outputDirectory.appendingPathComponent(outputFileName)
        let outputURL = Self.uniqueURL(base: rawOutputURL)

        let sourceType = CGImageSourceGetType(cgImageSource)

        let needsResize = resize && (targetWidth > 0 && targetHeight > 0)

        let isSameFormat = sourceType != nil
            && (sourceType! as String) == format.utType

        if isSameFormat && !needsResize {
            try? imageData.write(to: outputURL)
            return
        }

        if format == .gif && sourceType == "com.compuserve.gif" as CFString {
            if !needsResize {
                try? imageData.write(to: outputURL)
            } else {
                convertGIF(source: cgImageSource, destination: outputURL, targetWidth: targetWidth, targetHeight: targetHeight)
            }
            return
        }

        guard CGImageSourceGetCount(cgImageSource) > 0 else { return }

        var outputImage = CGImageSourceCreateImageAtIndex(cgImageSource, 0, nil)

        if needsResize, let sourceImage = outputImage {
            let srcW = CGFloat(sourceImage.width)
            let srcH = CGFloat(sourceImage.height)
            let tw = CGFloat(targetWidth)
            let th = CGFloat(targetHeight)

            let scale = min(tw / srcW, th / srcH, 1.0)
            if scale < 1.0 {
                let newW = Int(srcW * scale)
                let newH = Int(srcH * scale)
                outputImage = resizeCGImage(sourceImage, width: newW, height: newH)
            }
        }

        guard let finalImage = outputImage else { return }

        guard let destination = CGImageDestinationCreateWithURL(
            outputURL as CFURL,
            format.utType as CFString,
            1,
            nil
        ) else { return }

        var options: [CFString: Any] = [:]

        switch format {
        case .jpg:
            options[kCGImageDestinationLossyCompressionQuality] = quality
            options[kCGImageDestinationOptimizeColorForSharing] = true
        case .webp, .heic, .avif:
            options[kCGImageDestinationLossyCompressionQuality] = quality
        case .png:
            break
        case .gif:
            break
        }

        if keepExif {
            if let props = CGImageSourceCopyPropertiesAtIndex(cgImageSource, 0, nil) as? [CFString: Any] {
                if let exif = props[kCGImagePropertyExifDictionary] {
                    options[kCGImagePropertyExifDictionary] = exif
                }
                if let tiff = props[kCGImagePropertyTIFFDictionary] {
                    options[kCGImagePropertyTIFFDictionary] = tiff
                }
                if let iptc = props[kCGImagePropertyIPTCDictionary] {
                    options[kCGImagePropertyIPTCDictionary] = iptc
                }
                if let gps = props[kCGImagePropertyGPSDictionary] {
                    options[kCGImagePropertyGPSDictionary] = gps
                }
            }
        }

        CGImageDestinationAddImage(destination, finalImage, options as CFDictionary)
        CGImageDestinationFinalize(destination)

        let originalSize = imageData.count
        let resultSize = (try? Data(contentsOf: outputURL))?.count ?? 0

        if resultSize >= originalSize && !needsResize && !isSameFormat {
            try? imageData.write(to: outputURL)
        }
    }

    private nonisolated func resizeCGImage(_ image: CGImage, width: Int, height: Int) -> CGImage? {
        let colorSpace = image.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB)!
        let bitmapInfo = image.bitmapInfo

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else { return nil }

        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()
    }

    private nonisolated func convertGIF(
        source: CGImageSource,
        destination outputURL: URL,
        targetWidth: Int,
        targetHeight: Int
    ) {
        let frameCount = CGImageSourceGetCount(source)
        guard let dest = CGImageDestinationCreateWithURL(
            outputURL as CFURL,
            "com.compuserve.gif" as CFString,
            frameCount,
            nil
        ) else { return }

        let tw = CGFloat(targetWidth)
        let th = CGFloat(targetHeight)

        for i in 0..<frameCount {
            var frameOptions: [CFString: Any] = [:]
            if let props = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [CFString: Any],
               let gifProps = props[kCGImagePropertyGIFDictionary] as? [CFString: Any] {
                frameOptions[kCGImagePropertyGIFDictionary] = gifProps
            }

            guard let frameImage = CGImageSourceCreateImageAtIndex(source, i, nil) else {
                CGImageDestinationAddImageFromSource(dest, source, i, frameOptions as CFDictionary)
                continue
            }

            let srcW = CGFloat(frameImage.width)
            let srcH = CGFloat(frameImage.height)
            let scale = min(tw / srcW, th / srcH, 1.0)

            if scale < 1.0 {
                let newW = Int(srcW * scale)
                let newH = Int(srcH * scale)
                if let resized = resizeCGImage(frameImage, width: newW, height: newH) {
                    CGImageDestinationAddImage(dest, resized, frameOptions as CFDictionary)
                    continue
                }
            }

            CGImageDestinationAddImage(dest, frameImage, frameOptions as CFDictionary)
        }
        CGImageDestinationFinalize(dest)
    }
}
