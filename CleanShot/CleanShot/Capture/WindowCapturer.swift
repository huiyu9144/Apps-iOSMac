import AppKit

private final class WindowSelectionOverlay: NSView {
    var windowSelectedHandler: ((CGWindowID) -> Void)?
    var cancelHandler: (() -> Void)?

    private var hoveredWindowID: CGWindowID = 0
    private var hoveredRect: CGRect = .zero
    private var isHovering = false

    private var cachedWindows: [WindowInfo] = []
    private var globalTrackingArea: NSTrackingArea?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        wantsLayer = true
        window?.acceptsMouseMovedEvents = true
        refreshWindowCache()
        setupGlobalTracking()
    }

    override func viewDidEndLiveResize() {
        super.viewDidEndLiveResize()
        setupGlobalTracking()
    }

    private func setupGlobalTracking() {
        if let existing = globalTrackingArea {
            removeTrackingArea(existing)
        }
        globalTrackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseMoved, .mouseEnteredAndExited],
            owner: self,
            userInfo: nil
        )
        if let area = globalTrackingArea {
            addTrackingArea(area)
        }
    }

    private func refreshWindowCache() {
        guard let list = getOnScreenWindows() else { return }
        cachedWindows = list
    }

    override func mouseMoved(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        updateHover(at: point)
    }

    override func mouseDown(with event: NSEvent) {
        if isHovering, hoveredWindowID != 0 {
            windowSelectedHandler?(hoveredWindowID)
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            cancelHandler?()
        }
    }

    override var acceptsFirstResponder: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        guard isHovering, let context = NSGraphicsContext.current?.cgContext else { return }

        context.setFillColor(NSColor.selectedContentBackgroundColor.withAlphaComponent(0.15).cgColor)
        context.fill(hoveredRect)

        context.setStrokeColor(NSColor.selectedContentBackgroundColor.cgColor)
        context.setLineWidth(3)
        context.stroke(hoveredRect)
    }

    private func updateHover(at point: NSPoint) {
        for info in cachedWindows {
            let screenRect = convertWindowRectToScreen(info.kRect)
            if screenRect.contains(point) {
                if info.id != hoveredWindowID {
                    isHovering = true
                    hoveredWindowID = info.id
                    hoveredRect = screenRect
                    needsDisplay = true
                }
                return
            }
        }

        if isHovering {
            isHovering = false
            needsDisplay = true
        }
    }

    private func getOnScreenWindows() -> [WindowInfo]? {
        guard let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }

        var windows: [WindowInfo] = []
        for info in windowList {
            guard let bounds = info[kCGWindowBounds as String] as? [String: CGFloat],
                  let x = bounds["X"],
                  let y = bounds["Y"],
                  let width = bounds["Width"],
                  let height = bounds["Height"],
                  width > 0, height > 0 else { continue }

            guard let layer = info[kCGWindowLayer as String] as? Int, layer == 0 else { continue }
            guard let name = info[kCGWindowName as String] as? String, !name.isEmpty else { continue }
            guard let windowID = info[kCGWindowNumber as String] as? CGWindowID else { continue }
            guard let ownerName = info[kCGWindowOwnerName as String] as? String else { continue }

            if ownerName == "Window Server" { continue }

            windows.append(WindowInfo(
                id: windowID,
                name: name,
                ownerName: ownerName,
                kRect: CGRect(x: x, y: y, width: width, height: height)
            ))
        }

        return windows.sorted { $0.kRect.area < $1.kRect.area }
    }

    private func convertWindowRectToScreen(_ cgRect: CGRect) -> CGRect {
        guard let screen = NSScreen.main else { return .zero }
        let screenHeight = screen.frame.height
        return CGRect(
            x: cgRect.origin.x,
            y: screenHeight - cgRect.origin.y - cgRect.height,
            width: cgRect.width,
            height: cgRect.height
        )
    }
}

final class WindowCapturer: NSObject {
    private var completion: ((NSImage?) -> Void)?
    private var selectionWindow: NSWindow?

    func capture(completion: @escaping (NSImage?) -> Void) {
        self.completion = completion
        requestScreenRecordingPermission()
        showWindowSelection()
    }

    private func showWindowSelection() {
        guard let mainScreen = NSScreen.main else {
            completion?(nil)
            return
        }

        let selectionView = WindowSelectionOverlay(frame: mainScreen.frame)
        selectionView.windowSelectedHandler = { [weak self] windowID in
            self?.selectionWindow?.orderOut(nil)
            self?.selectionWindow = nil
            self?.captureWindow(withID: windowID)
        }
        selectionView.cancelHandler = { [weak self] in
            self?.selectionWindow?.orderOut(nil)
            self?.selectionWindow = nil
            self?.completion?(nil)
        }

        let window = NSWindow(
            contentRect: mainScreen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.contentView = selectionView
        window.level = .screenSaver
        window.isOpaque = false
        window.backgroundColor = NSColor.black.withAlphaComponent(0.2)
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.acceptsMouseMovedEvents = true
        window.makeKeyAndOrderFront(nil)

        selectionWindow = window
    }

    private func captureWindow(withID windowID: CGWindowID) {
        guard let windowInfo = getWindowInfo(windowID: windowID) else {
            completion?(nil)
            return
        }

        let windowRect = windowInfo.kRect

        guard let imageRef = captureWindowImage(windowRect: windowRect, windowID: windowID) else {
            completion?(nil)
            return
        }

        let image = NSImage(cgImage: imageRef, size: windowRect.size)
        completion?(image)
    }

    private func captureWindowImage(windowRect: CGRect, windowID: CGWindowID) -> CGImage? {
        let scale = NSScreen.main?.backingScaleFactor ?? 2.0
        let scaledRect = CGRect(
            x: windowRect.origin.x * scale,
            y: windowRect.origin.y * scale,
            width: windowRect.width * scale,
            height: windowRect.height * scale
        )
        return CGWindowListCreateImage(
            scaledRect,
            .optionIncludingWindow,
            windowID,
            .nominalResolution
        )
    }

    private func getWindowInfo(windowID: CGWindowID) -> WindowInfo? {
        guard let windowList = CGWindowListCopyWindowInfo(.optionIncludingWindow, windowID) as? [[String: Any]],
              let info = windowList.first else {
            return nil
        }

        guard let bounds = info[kCGWindowBounds as String] as? [String: CGFloat],
              let x = bounds["X"],
              let y = bounds["Y"],
              let width = bounds["Width"],
              let height = bounds["Height"] else {
            return nil
        }

        if let layer = info[kCGWindowLayer as String] as? Int, layer != 0 {
            return nil
        }

        guard let name = info[kCGWindowName as String] as? String, !name.isEmpty,
               let ownerName = info[kCGWindowOwnerName as String] as? String else {
            return nil
        }

        return WindowInfo(
            id: windowID,
            name: name,
            ownerName: ownerName,
            kRect: CGRect(x: x, y: y, width: width, height: height)
        )
    }

    private func requestScreenRecordingPermission() {
        if CGPreflightScreenCaptureAccess() == false {
            CGRequestScreenCaptureAccess()
        }
    }
}

struct WindowInfo {
    let id: CGWindowID
    let name: String
    let ownerName: String
    let kRect: CGRect
}

private extension CGRect {
    var area: CGFloat {
        width * height
    }
}
