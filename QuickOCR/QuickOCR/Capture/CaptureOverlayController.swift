import Cocoa
import SwiftUI

class CaptureOverlayController: NSObject {
    static let shared = CaptureOverlayController()

    private var overlayWindow: NSWindow?
    private var overlayView: ScreenOverlayView?

    private var ocrPanelWindow: NSWindow?
    private var toolbarPanelWindow: NSWindow?
    private var textInputWindow: NSWindow?

    private var capturedImage: NSImage?
    private var capturedRect: CGRect = .zero
    var ocrText = ""
    var ocrDone = false
    var annotations: [Annotation] = []
    private var currentAnnotation: Annotation?
    var selectedAnnotationTool: AnnotationTool?
    var selectionRect: CGRect = .zero
    var hasActiveSelection = false
    private var cancelCompletion: (() -> Void)?

    private var resizeDebounceTimer: Timer?
    private let resizeDebounceInterval: TimeInterval = 0.35

    override private init() {}

    func startCapture() {
        cancelCompletion = nil
        guard let screen = NSScreen.main else { return }
        let screenRect = screen.frame

        let window = NSWindow(
            contentRect: screenRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.level = .screenSaver
        window.isOpaque = false
        window.backgroundColor = .clear
        window.acceptsMouseMovedEvents = true
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        let overlay = ScreenOverlayView(frame: screenRect)
        overlay.delegate = self
        overlay.autoresizingMask = [NSView.AutoresizingMask.width, NSView.AutoresizingMask.height]
        window.contentView = overlay

        self.overlayWindow = window
        self.overlayView = overlay
        self.hasActiveSelection = false
        self.selectionRect = .zero

        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
        window.makeFirstResponder(overlay)
    }

    // MARK: - Screen Capture

    private func captureScreen(rect: CGRect) -> CGImage? {
        guard let overlayWindow = overlayWindow else { return nil }
        let wn = overlayWindow.windowNumber
        let option: CGWindowListOption
        let id: CGWindowID
        if wn > 0 {
            option = .optionOnScreenBelowWindow
            id = CGWindowID(wn)
        } else {
            overlayWindow.orderOut(nil)
            option = .optionOnScreenOnly
            id = kCGNullWindowID
        }
        let image = CGWindowListCreateImage(rect, option, id, [])
        if wn <= 0 {
            overlayWindow.orderFront(nil)
        }
        return image
    }

    private func captureAndOCR(at rect: CGRect) {
        guard let screen = NSScreen.main else { return }
        let screenRect = screen.frame
        let captureRect = CGRect(
            x: rect.origin.x,
            y: screenRect.height - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )

        guard let cgImage = captureScreen(rect: captureRect) else { return }
        let nsImage = NSImage(cgImage: cgImage, size: rect.size)

        capturedImage = nsImage
        capturedRect = rect
        selectionRect = rect

        runOCR(image: cgImage)
    }

    private func runOCR(image: CGImage) {
        let nsImage = NSImage(cgImage: image, size: selectionRect.size)
        let langs = AppSettings.shared.recognitionLanguages

        ocrText = ""
        ocrDone = false
        refreshOcrPanel()

        Task {
            let result = await OCRService.shared.recognizeText(in: nsImage, languages: langs)
            await MainActor.run {
                switch result {
                case .success(let text):
                    self.ocrText = text
                case .failure:
                    self.ocrText = ""
                }
                self.ocrDone = true
                self.refreshOcrPanel()
            }
        }
    }

    func cancelCapture() {
        resizeDebounceTimer?.invalidate()
        resizeDebounceTimer = nil
        hideTextInput()
        hidePanelWindows()
        overlayWindow?.orderOut(nil)
        overlayWindow = nil
        overlayView = nil
        capturedImage = nil
        ocrText = ""
        annotations.removeAll()
        hasActiveSelection = false
        selectedAnnotationTool = nil
        cancelCompletion?()
    }

    // MARK: - Selection Lifecycle

    private func activateSelection(at rect: CGRect) {
        hasActiveSelection = true
        selectionRect = rect
        annotations.removeAll()
        selectedAnnotationTool = nil

        captureAndOCR(at: rect)
        showPanelWindows()

        NSCursor.pop()
        NSCursor.arrow.set()
        overlayView?.needsDisplay = true
        overlayWindow?.makeFirstResponder(overlayView)
    }

    private func scheduleRecapture() {
        resizeDebounceTimer?.invalidate()
        resizeDebounceTimer = Timer.scheduledTimer(withTimeInterval: resizeDebounceInterval, repeats: false) { [weak self] _ in
            self?.performRecapture()
        }
    }

    private func performRecapture() {
        guard hasActiveSelection else { return }
        captureAndOCR(at: selectionRect)
        repositionPanelWindows()
        overlayView?.needsDisplay = true
    }

    // MARK: - Panel Windows (independent NSWindow, .screenSaver + 1)

    private func showPanelWindows() {
        guard let screen = NSScreen.main else { return }
        hidePanelWindows()
        showOcrPanel(screen: screen)
        showToolbarPanel(screen: screen)
    }

    private func hidePanelWindows() {
        ocrPanelWindow?.orderOut(nil)
        ocrPanelWindow = nil
        toolbarPanelWindow?.orderOut(nil)
        toolbarPanelWindow = nil
    }

    private func createPanelWindow(frame: NSRect) -> NSWindow {
        let window = NSWindow(
            contentRect: frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .screenSaver + 1
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.isMovableByWindowBackground = false
        window.ignoresMouseEvents = false
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        return window
    }

    private func showOcrPanel(screen: NSScreen) {
        let panelWidth: CGFloat = 240
        let panelHeight: CGFloat = 300
        let margin: CGFloat = 12
        let rect = selectionRect

        var x = rect.maxX + margin
        if x + panelWidth > screen.frame.maxX {
            x = rect.minX - panelWidth - margin
        }
        if x < screen.frame.minX {
            x = rect.minX + margin
        }
        let y = min(rect.maxY - panelHeight, screen.frame.maxY - panelHeight - 40)
        let frame = NSRect(x: max(x, screen.frame.minX + 4), y: max(y, screen.frame.minY + 40), width: panelWidth, height: panelHeight)

        let window = createPanelWindow(frame: frame)
        let hosting = NSHostingView(rootView: OcrPanelView(controller: self))
        hosting.frame = NSRect(origin: .zero, size: frame.size)
        hosting.autoresizingMask = [NSView.AutoresizingMask.width, NSView.AutoresizingMask.height]
        window.contentView = hosting

        ocrPanelWindow = window
        window.orderFront(nil)
    }

    private func showToolbarPanel(screen: NSScreen) {
        let toolbarHeight: CGFloat = 44
        let toolbarWidth: CGFloat = 480
        let margin: CGFloat = 12
        let rect = selectionRect

        var y = rect.minY - toolbarHeight - margin
        if y < screen.frame.minY + 20 {
            y = rect.maxY + margin
        }

        let frame = NSRect(
            x: max(rect.midX - toolbarWidth / 2, screen.frame.minX + 4),
            y: max(y, screen.frame.minY + 20),
            width: min(toolbarWidth, screen.frame.width - 8),
            height: toolbarHeight
        )

        let window = createPanelWindow(frame: frame)
        let hosting = NSHostingView(rootView: ToolbarPanelView(controller: self))
        hosting.frame = NSRect(origin: .zero, size: frame.size)
        hosting.autoresizingMask = [NSView.AutoresizingMask.width, NSView.AutoresizingMask.height]
        window.contentView = hosting

        toolbarPanelWindow = window
        window.orderFront(nil)
    }

    func refreshOcrPanel() {
        guard let window = ocrPanelWindow else { return }
        let frame = window.frame
        let hosting = NSHostingView(rootView: OcrPanelView(controller: self))
        hosting.frame = NSRect(origin: .zero, size: frame.size)
        hosting.autoresizingMask = [NSView.AutoresizingMask.width, NSView.AutoresizingMask.height]
        window.contentView = hosting
    }

    func repositionPanelWindows() {
        guard hasActiveSelection else { return }
        showPanelWindows()
    }

    // MARK: - Actions

    func copyText() {
        ClipboardManager.shared.copy(ocrText)
    }

    func copyAndClose() {
        if !ocrText.isEmpty {
            ClipboardManager.shared.copy(ocrText)
            let result = OCRResult(text: ocrText, language: AppSettings.shared.recognitionLanguages.first ?? "en-US")
            CaptureHistory.shared.add(result)
        }
        cancelCapture()
    }

    func saveToFile() {
        guard let image = capturedImage else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        let dateStr = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        panel.nameFieldStringValue = "Screenshot-\(dateStr).png"
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            let finalImage = self?.renderFinalImage() ?? image
            guard let tiffData = finalImage.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData),
                  let pngData = bitmap.representation(using: .png, properties: [:]) else { return }
            try? pngData.write(to: url)
        }
    }

    private func renderFinalImage() -> NSImage? {
        guard let baseImage = capturedImage else { return nil }
        let size = baseImage.size

        let finalImage = NSImage(size: size)
        finalImage.lockFocusFlipped(false)
        defer { finalImage.unlockFocus() }

        baseImage.draw(in: CGRect(origin: .zero, size: size))

        guard !annotations.isEmpty, let context = NSGraphicsContext.current?.cgContext else { return finalImage }

        context.saveGState()
        context.setStrokeColor(NSColor.red.cgColor)
        context.setLineWidth(3)

        let scaleX = size.width / capturedRect.width
        let scaleY = size.height / capturedRect.height

        for annotation in annotations {
            let sp = CGPoint(
                x: (annotation.startPoint.x - capturedRect.minX) * scaleX,
                y: (capturedRect.height - (annotation.startPoint.y - capturedRect.minY)) * scaleY
            )
            let ep = CGPoint(
                x: (annotation.endPoint.x - capturedRect.minX) * scaleX,
                y: (capturedRect.height - (annotation.endPoint.y - capturedRect.minY)) * scaleY
            )
            let rect = CGRect(x: min(sp.x, ep.x), y: min(sp.y, ep.y), width: abs(ep.x - sp.x), height: abs(ep.y - sp.y))

            switch annotation.tool {
            case .redRect:
                context.stroke(rect)
            case .circle:
                context.strokeEllipse(in: rect)
            case .line:
                context.beginPath()
                context.move(to: sp)
                context.addLine(to: ep)
                context.strokePath()
            case .text:
                if let text = annotation.text {
                    let attrs: [NSAttributedString.Key: Any] = [
                        .font: NSFont.boldSystemFont(ofSize: 18 * scaleX),
                        .foregroundColor: NSColor.red
                    ]
                    (text as NSString).draw(at: sp, withAttributes: attrs)
                }
            }
        }
        context.restoreGState()
        return finalImage
    }

    // MARK: - Annotation

    func selectAnnotationTool(_ tool: AnnotationTool?) {
        selectedAnnotationTool = tool
        if tool != nil {
            NSCursor.crosshair.push()
        } else {
            NSCursor.pop()
            NSCursor.arrow.set()
        }
    }

    func undoAnnotation() {
        if !annotations.isEmpty {
            annotations.removeLast()
            overlayView?.needsDisplay = true
        }
    }

    // MARK: - Inline Text Input (non-modal)

    private func showTextInput(at point: NSPoint, onComplete: @escaping (String) -> Void) {
        hideTextInput()

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 220, height: 24))
        textField.placeholderString = "Type text..."
        textField.bezelStyle = .roundedBezel
        textField.font = NSFont.systemFont(ofSize: 13)
        textField.focusRingType = .none

        let container = NSView(frame: NSRect(x: 0, y: 0, width: 220, height: 36))
        container.wantsLayer = true
        container.layer?.masksToBounds = false
        container.layer?.cornerRadius = 8
        container.layer?.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.95).cgColor
        container.layer?.shadowColor = NSColor.black.cgColor
        container.layer?.shadowOpacity = 0.15
        container.layer?.shadowRadius = 6
        container.layer?.shadowOffset = NSSize(width: 0, height: -2)
        textField.frame = NSRect(x: 8, y: 6, width: 204, height: 24)
        container.addSubview(textField)

        let windowFrame = NSRect(
            x: point.x - 110,
            y: point.y + 10,
            width: 220,
            height: 36
        )

        let window = NSWindow(
            contentRect: windowFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .screenSaver + 2
        window.collectionBehavior = [.canJoinAllSpaces, .stationary]
        window.ignoresMouseEvents = false
        window.contentView = container

        textField.action = #selector(textFieldDidFinish(_:))
        textField.target = self
        textField.window?.makeFirstResponder(textField)

        self.textInputWindow = window
        window.orderFront(nil)

        objc_setAssociatedObject(textField, "textInputComplete", onComplete, .OBJC_ASSOCIATION_COPY_NONATOMIC)
    }

    @objc private func textFieldDidFinish(_ sender: NSTextField) {
        let text = sender.stringValue.trimmingCharacters(in: .whitespaces)
        let callback = objc_getAssociatedObject(sender, "textInputComplete") as? ((String) -> Void)
        hideTextInput()
        if !text.isEmpty {
            callback?(text)
        }
        overlayWindow?.makeFirstResponder(overlayView)
    }

    private func hideTextInput() {
        textInputWindow?.orderOut(nil)
        textInputWindow = nil
    }
}

// MARK: - ScreenOverlayViewDelegate

extension CaptureOverlayController: ScreenOverlayViewDelegate {
    func overlayDidSelectRect(_ rect: CGRect) {
        activateSelection(at: rect)
    }

    func overlayDidCancel() {
        if hasActiveSelection && !annotations.isEmpty {
            let alert = NSAlert()
            alert.messageText = "Discard screenshot?"
            alert.informativeText = "You have unsaved annotations."
            alert.addButton(withTitle: "Discard")
            alert.addButton(withTitle: "Cancel")
            alert.alertStyle = .warning
            alert.beginSheetModal(for: overlayWindow!) { response in
                if response == .alertFirstButtonReturn {
                    self.cancelCapture()
                }
            }
        } else {
            cancelCapture()
        }
    }

    func overlayDidDoubleClick() {
        copyAndClose()
    }

    func overlaySelectionRect() -> CGRect {
        selectionRect
    }

    func overlayCapturedImage() -> NSImage? {
        capturedImage
    }

    func overlayAnnotations() -> [Annotation] {
        annotations
    }

    func overlayCurrentAnnotation() -> Annotation? {
        currentAnnotation
    }

    func overlayIsEditing() -> Bool {
        hasActiveSelection
    }

    func overlayDidDragSelection(to rect: CGRect) {
        selectionRect = rect
        overlayView?.needsDisplay = true
        repositionPanelWindows()
    }

    func overlayDidFinishDragSelection(to rect: CGRect) {
        selectionRect = rect
        scheduleRecapture()
    }

    func overlaySelectedTool() -> AnnotationTool? {
        selectedAnnotationTool
    }

    func overlayMouseDown(at point: NSPoint) {
        hideTextInput()
        guard let tool = selectedAnnotationTool else { return }
        currentAnnotation = Annotation(tool: tool, startPoint: point, endPoint: point, text: nil, color: Color.red)
    }

    func overlayMouseDragged(to point: NSPoint) {
        guard currentAnnotation != nil else { return }
        currentAnnotation?.endPoint = point
        overlayView?.needsDisplay = true
    }

    func overlayMouseUp(at point: NSPoint) {
        guard let current = currentAnnotation, let tool = selectedAnnotationTool else {
            currentAnnotation = nil
            return
        }
        currentAnnotation?.endPoint = point

        let rect = current.rect
        let selectRect = self.selectionRect

        if tool == .text {
            guard selectRect.contains(point) else {
                currentAnnotation = nil
                return
            }
            showTextInput(at: point) { [weak self] text in
                guard let self = self else { return }
                self.annotations.append(Annotation(tool: .text, startPoint: current.startPoint, endPoint: current.startPoint, text: text, color: Color.red))
                self.overlayView?.needsDisplay = true
            }
            currentAnnotation = nil
        } else {
            guard selectRect.contains(point), rect.width > 3 || rect.height > 3 else {
                currentAnnotation = nil
                return
            }
            annotations.append(current)
            overlayView?.needsDisplay = true
        }

        currentAnnotation = nil
    }
}

// MARK: - SwiftUI Panel Views

struct OcrPanelView: View {
    weak var controller: CaptureOverlayController?
    @State private var showCopied = false

    private var ocrDone: Bool { controller?.ocrDone ?? false }
    private var ocrText: String { controller?.ocrText ?? "" }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "text.magnifyingglass")
                Text("OCR Result")
                    .font(.headline)
                Spacer()
                Button(action: { controller?.cancelCapture() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            Divider()

            if !ocrDone {
                VStack(spacing: 8) {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.6)
                    Text("Recognizing...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else if ocrText.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "exclamationmark.circle")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("No text found")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView([.vertical, .horizontal]) {
                    Text(ocrText)
                        .font(.system(size: 11))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button(action: {
                    controller?.copyText()
                    showCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { showCopied = false }
                }) {
                    HStack {
                        Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                        Text(showCopied ? "Copied!" : "Copy Text")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.windowBackgroundColor).opacity(0.95))
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 2)
        )
    }
}

struct ToolbarPanelView: View {
    weak var controller: CaptureOverlayController?

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AnnotationTool.allCases) { tool in
                toolButton(tool)
            }

            Divider().frame(height: 24)

            Button(action: { controller?.undoAnnotation() }) {
                Label("Undo", systemImage: "arrow.uturn.backward")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .disabled((controller?.annotations.count ?? 0) == 0)

            Spacer()

            Button(action: { controller?.copyAndClose() }) {
                Label("Copy & Close", systemImage: "doc.on.doc")
                    .font(.caption)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)

            Button(action: { controller?.saveToFile() }) {
                Label("Save", systemImage: "square.and.arrow.down")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button(action: { controller?.cancelCapture() }) {
                Label("Cancel", systemImage: "xmark")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.windowBackgroundColor).opacity(0.95))
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 2)
        )
    }

    func toolButton(_ tool: AnnotationTool) -> some View {
        Button(action: {
            if controller?.selectedAnnotationTool == tool {
                controller?.selectAnnotationTool(nil)
            } else {
                controller?.selectAnnotationTool(tool)
            }
        }) {
            VStack(spacing: 1) {
                Image(systemName: tool.systemImage)
                    .font(.system(size: 12))
                Text(tool.displayName)
                    .font(.system(size: 8))
            }
            .frame(width: 36, height: 30)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(controller?.selectedAnnotationTool == tool ? Color.accentColor.opacity(0.2) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}
