import AppKit

extension NSImage {
    func cropping(to rect: CGRect) -> NSImage? {
        guard let cgImage = cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }

        let scale = self.size.width / CGFloat(cgImage.width)
        let scaledRect = CGRect(
            x: rect.origin.x / scale,
            y: rect.origin.y / scale,
            width: rect.width / scale,
            height: rect.height / scale
        )

        guard let cropped = cgImage.cropping(to: scaledRect) else { return nil }
        return NSImage(cgImage: cropped, size: rect.size)
    }

    func withShadow(blurRadius: CGFloat = 4, offset: NSSize = NSSize(width: 0, height: -2)) -> NSImage {
        let shadowImage = NSImage(size: NSSize(
            width: size.width + abs(offset.width) + blurRadius * 2,
            height: size.height + abs(offset.height) + blurRadius * 2
        ))

        shadowImage.lockFocus()
        guard let context = NSGraphicsContext.current?.cgContext else {
            shadowImage.unlockFocus()
            return self
        }

        context.setShadow(
            offset: offset,
            blur: blurRadius,
            color: NSColor.black.withAlphaComponent(0.3).cgColor
        )

        let drawPoint = NSPoint(
            x: (shadowImage.size.width - size.width) / 2,
            y: (shadowImage.size.height - size.height) / 2
        )
        draw(at: drawPoint, from: .zero, operation: .copy, fraction: 1.0)

        shadowImage.unlockFocus()
        return shadowImage
    }

    func tinted(with color: NSColor) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()

        let rect = NSRect(origin: .zero, size: size)
        draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)

        color.withAlphaComponent(0.3).setFill()
        rect.fill(using: .sourceAtop)

        image.unlockFocus()
        return image
    }

    func rounded(radius: CGFloat) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()

        let rect = NSRect(origin: .zero, size: size)
        let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
        path.addClip()

        draw(in: rect, from: .zero, operation: .copy, fraction: 1.0)

        image.unlockFocus()
        return image
    }

    func resizedThumbnail(maxWidth: CGFloat = 240) -> NSImage {
        let ratio = size.height / size.width
        let thumbSize = ratio > 1
            ? NSSize(width: maxWidth, height: maxWidth * ratio)
            : NSSize(width: maxWidth, height: maxWidth / ratio)
        let image = NSImage(size: thumbSize)
        image.lockFocus()
        draw(in: NSRect(origin: .zero, size: thumbSize), from: .zero, operation: .copy, fraction: 1.0)
        image.unlockFocus()
        return image
    }
}
