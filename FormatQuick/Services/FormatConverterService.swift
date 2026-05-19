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
        resizeMode: ResizeMode,
        keepExif: Bool,
        outputDirectory: URL,
        onProgress: @escaping (Int, String) -> Void
    ) async {
        try? FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

        let stream = AsyncStream<(Int, String)> { continuation in
            let taskFiles = files
            Task.detached { [weak self] in
                guard let self else { return }
                await withTaskGroup(of: Void.self) { group in
                    for file in taskFiles {
                        group.addTask {
                            await self.convertSingle(
                                sourceURL: file,
                                format: format,
                                quality: quality,
                                resize: resize,
                                targetWidth: targetWidth,
                                targetHeight: targetHeight,
                                resizeMode: resizeMode,
                                keepExif: keepExif,
                                outputDirectory: outputDirectory
                            )
                        }
                    }
                    for await _ in group {}
                    continuation.yield((taskFiles.count, ""))
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

    nonisolated private let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!

    private nonisolated func convertSingle(
        sourceURL: URL,
        format: ImageFormat,
        quality: Double,
        resize: Bool,
        targetWidth: Int,
        targetHeight: Int,
        resizeMode: ResizeMode,
        keepExif: Bool,
        outputDirectory: URL
    ) async {
        guard let imageData = try? Data(contentsOf: sourceURL) else { return }
        guard let cgImageSource = CGImageSourceCreateWithData(imageData as CFData, nil) else { return }

        let outputFileName = sourceURL
            .deletingPathExtension()
            .lastPathComponent + "." + format.fileExtension

        let rawOutputURL = outputDirectory.appendingPathComponent(outputFileName)
        let outputURL = await Self.uniqueURL(base: rawOutputURL)

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
                convertGIF(source: cgImageSource, destination: outputURL, targetWidth: targetWidth, targetHeight: targetHeight, resizeMode: resizeMode)
            }
            return
        }

        guard CGImageSourceGetCount(cgImageSource) > 0 else { return }

        var outputImage = CGImageSourceCreateImageAtIndex(cgImageSource, 0, nil)

        if needsResize, let sourceImage = outputImage {
            outputImage = applyResize(sourceImage, targetWidth: targetWidth, targetHeight: targetHeight, mode: resizeMode)
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
        case .heic:
            options[kCGImageDestinationLossyCompressionQuality] = quality
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

    private nonisolated func applyResize(_ image: CGImage, targetWidth: Int, targetHeight: Int, mode: ResizeMode) -> CGImage? {
        switch mode {
        case .stretch:
            return resizeCGImage(image, width: targetWidth, height: targetHeight)

        case .fill:
            let tw = CGFloat(targetWidth)
            let th = CGFloat(targetHeight)
            let scale = max(tw / CGFloat(image.width), th / CGFloat(image.height))
            let scaledW = Int(CGFloat(image.width) * scale)
            let scaledH = Int(CGFloat(image.height) * scale)

            guard let scaled = resizeCGImage(image, width: scaledW, height: scaledH) else { return nil }

            let cropX = max(0, (scaledW - targetWidth) / 2)
            let cropY = max(0, (scaledH - targetHeight) / 2)
            let cropped = scaled.cropping(to: CGRect(x: cropX, y: cropY, width: targetWidth, height: targetHeight))
            return cropped ?? scaled

        case .fit:
            let tw = CGFloat(targetWidth)
            let th = CGFloat(targetHeight)
            let scale = min(tw / CGFloat(image.width), th / CGFloat(image.height))
            let drawW = max(1, Int(CGFloat(image.width) * scale))
            let drawH = max(1, Int(CGFloat(image.height) * scale))
            return drawInCenter(image, canvasWidth: targetWidth, canvasHeight: targetHeight, drawWidth: drawW, drawHeight: drawH)
        }
    }

    private nonisolated func drawInCenter(_ image: CGImage, canvasWidth: Int, canvasHeight: Int, drawWidth: Int, drawHeight: Int) -> CGImage? {
        guard let context = CGContext(
            data: nil,
            width: canvasWidth,
            height: canvasHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: sRGB,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else { return nil }

        context.setFillColor(.black)
        context.fill(CGRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight))
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(
            x: (canvasWidth - drawWidth) / 2,
            y: (canvasHeight - drawHeight) / 2,
            width: drawWidth,
            height: drawHeight
        ))
        return context.makeImage()
    }

    private nonisolated func resizeCGImage(_ image: CGImage, width: Int, height: Int) -> CGImage? {
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: sRGB,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else { return nil }

        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()
    }

    private nonisolated func convertGIF(
        source: CGImageSource,
        destination outputURL: URL,
        targetWidth: Int,
        targetHeight: Int,
        resizeMode: ResizeMode
    ) {
        let frameCount = CGImageSourceGetCount(source)
        guard let dest = CGImageDestinationCreateWithURL(
            outputURL as CFURL,
            "com.compuserve.gif" as CFString,
            frameCount,
            nil
        ) else { return }

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

            if let resized = applyResize(frameImage, targetWidth: targetWidth, targetHeight: targetHeight, mode: resizeMode) {
                CGImageDestinationAddImage(dest, resized, frameOptions as CFDictionary)
            } else {
                CGImageDestinationAddImage(dest, frameImage, frameOptions as CFDictionary)
            }
        }
        CGImageDestinationFinalize(dest)
    }
}
