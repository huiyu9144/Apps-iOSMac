import AppKit
import SwiftUI

private func __captureImage(scaledRect: CGRect, option: CGWindowListOption) -> CGImage? {
    CGWindowListCreateImage(scaledRect, option, kCGNullWindowID, .nominalResolution)
}

final class RegionCapturer: NSObject {
    private var captureWindow: NSWindow?
    private var completion: ((NSImage?) -> Void)?

    func capture(completion: @escaping (NSImage?) -> Void) {
        self.completion = completion
        requestScreenRecordingPermission()
        showOverlay()
    }

    private func showOverlay() {
        guard let screen = NSScreen.main else {
            completion?(nil)
            return
        }

        let overlay = RegionOverlayView(frame: screen.frame)
        overlay.captureHandler = { [weak self] rect in
            self?.hideOverlay()
            self?.performCapture(rect: rect)
        }
        overlay.cancelHandler = { [weak self] in
            self?.hideOverlay()
            self?.completion?(nil)
        }

        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.contentView = overlay
        window.level = .screenSaver
        window.acceptsMouseMovedEvents = true
        window.ignoresMouseEvents = false
        window.isOpaque = false
        window.backgroundColor = .clear
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.makeKeyAndOrderFront(nil)

        captureWindow = window

        NSCursor.crosshair.push()
    }

    private func hideOverlay() {
        NSCursor.pop()
        captureWindow?.orderOut(nil)
        captureWindow = nil
    }

    private func performCapture(rect: CGRect) {
        guard let screen = NSScreen.main else {
            completion?(nil)
            return
        }

        let scale = screen.backingScaleFactor
        let scaledRect = CGRect(
            x: rect.origin.x * scale,
            y: (screen.frame.height - rect.origin.y - rect.height) * scale,
            width: rect.width * scale,
            height: rect.height * scale
        )

        guard let imageRef = __captureImage(scaledRect: scaledRect, option: .optionOnScreenOnly) else {
            completion?(nil)
            return
        }

        let image = NSImage(cgImage: imageRef, size: rect.size)
        completion?(image)
    }

    private func requestScreenRecordingPermission() {
        if CGPreflightScreenCaptureAccess() == false {
            CGRequestScreenCaptureAccess()
        }
    }
}

final class RegionOverlayView: NSView {
    var captureHandler: ((CGRect) -> Void)?
    var cancelHandler: (() -> Void)?

    private var startPoint: NSPoint?
    private var currentRect: NSRect?
    private var trackingArea: NSTrackingArea?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
        setupTrackingArea()
    }

    private func setupTrackingArea() {
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseMoved, .mouseEnteredAndExited],
            owner: self,
            userInfo: nil
        )
        if let trackingArea {
            addTrackingArea(trackingArea)
        }
    }

    override func mouseDown(with event: NSEvent) {
        startPoint = convert(event.locationInWindow, from: nil)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = startPoint else { return }
        let current = convert(event.locationInWindow, from: nil)
        currentRect = CGRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(current.x - start.x),
            height: abs(current.y - start.y)
        )
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard let rect = currentRect, rect.width > 10, rect.height > 10 else {
            if currentRect == nil {
                cancelHandler?()
                return
            }
            currentRect = nil
            needsDisplay = true
            return
        }
        captureHandler?(rect)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            cancelHandler?()
        }
    }

    override var acceptsFirstResponder: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        context.setFillColor(NSColor.black.withAlphaComponent(0.3).cgColor)
        context.fill(dirtyRect)

        if let rect = currentRect {
            context.clear(rect)

            context.setStrokeColor(NSColor.white.cgColor)
            context.setLineWidth(2)
            context.stroke(rect)

            context.setStrokeColor(NSColor.black.withAlphaComponent(0.5).cgColor)
            context.setLineWidth(2)
            let dashPattern: [CGFloat] = [6, 4]
            context.setLineDash(phase: 0, lengths: dashPattern)
            context.stroke(rect)
            context.setLineDash(phase: 0, lengths: [])

            let sizeText = "\(Int(rect.width)) × \(Int(rect.height))"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
                .foregroundColor: NSColor.white
            ]
            let textSize = sizeText.size(withAttributes: attrs)
            let textRect = CGRect(
                x: rect.midX - textSize.width / 2,
                y: rect.minY - textSize.height - 8,
                width: textSize.width + 12,
                height: textSize.height + 4
            )

            let bgPath = CGPath(roundedRect: textRect, cornerWidth: 4, cornerHeight: 4, transform: nil)
            context.setFillColor(NSColor.black.withAlphaComponent(0.7).cgColor)
            context.addPath(bgPath)
            context.fillPath()

            sizeText.draw(
                at: CGPoint(x: textRect.midX - textSize.width / 2, y: textRect.minY + 2),
                withAttributes: attrs
            )
        }
    }
}
