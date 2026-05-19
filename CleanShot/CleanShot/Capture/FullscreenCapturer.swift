import AppKit

final class FullscreenCapturer {
    func capture(completion: @escaping (NSImage?) -> Void) {
        requestScreenRecordingPermission()

        if NSScreen.screens.count > 1 {
            captureAllScreens(completion: completion)
        } else {
            guard let mainDisplay = CGMainDisplayID() else {
                completion(nil)
                return
            }

            guard let imageRef = CGDisplayCreateImage(mainDisplay) else {
                completion(nil)
                return
            }

            let width = CGFloat(imageRef.width)
            let height = CGFloat(imageRef.height)
            let image = NSImage(cgImage: imageRef, size: NSSize(width: width, height: height))
            completion(image)
        }
    }

    private func captureAllScreens(completion: @escaping (NSImage?) -> Void) {
        var allImages: [NSImage] = []

        for screen in NSScreen.screens {
            let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? 0
            if let imageRef = CGDisplayCreateImage(displayID) {
                let width = CGFloat(imageRef.width)
                let height = CGFloat(imageRef.height)
                let image = NSImage(cgImage: imageRef, size: NSSize(width: width, height: height))
                allImages.append(image)
            }
        }

        if allImages.count > 1, let combined = combineImagesHorizontally(allImages) {
            completion(combined)
        } else if let single = allImages.first {
            completion(single)
        } else {
            completion(nil)
        }
    }

    private func combineImagesHorizontally(_ images: [NSImage]) -> NSImage? {
        guard !images.isEmpty else { return nil }

        let totalWidth = images.reduce(0) { $0 + $1.size.width }
        let maxHeight = images.map(\.size.height).max() ?? 0

        let combined = NSImage(size: NSSize(width: totalWidth, height: maxHeight))
        combined.lockFocus()

        var xOffset: CGFloat = 0
        for image in images {
            image.draw(
                at: NSPoint(x: xOffset, y: 0),
                from: .zero,
                operation: .copy,
                fraction: 1.0
            )
            xOffset += image.size.width
        }

        combined.unlockFocus()
        return combined
    }

    private func requestScreenRecordingPermission() {
        if CGPreflightScreenCaptureAccess() == false {
            CGRequestScreenCaptureAccess()
        }
    }
}

func CGMainDisplayID() -> CGDirectDisplayID? {
    let screens = NSScreen.screens
    guard let main = screens.first else { return nil }
    return main.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
}
