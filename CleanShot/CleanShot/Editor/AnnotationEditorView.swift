import AppKit
import SwiftUI

struct AnnotationEditorView: View {
    @StateObject private var engine = AnnotationEngine()
    @EnvironmentObject private var captureManager: CaptureManager

    var image: NSImage
    var onDismiss: () -> Void

    @State private var imageSize: CGSize = .zero
    @State private var currentTool: AnnotationToolType = .arrow
    @State private var strokeColor: Color = .red
    @State private var lineWidth: CGFloat = 3.0
    @State private var showColorPicker = false

    var body: some View {
        VStack(spacing: 0) {
            toolbarView
            Divider()
            canvasView
            Divider()
            actionBarView
        }
        .onAppear {
            engine.style.strokeColor = NSColor(Color.red)
        }
    }

    private var toolbarView: some View {
        HStack(spacing: 8) {
            ForEach(AnnotationToolType.allCases) { tool in
                ToolButton(
                    icon: tool.icon,
                    title: tool.displayName,
                    isSelected: currentTool == tool
                ) {
                    currentTool = tool
                    engine.selectedTool = tool
                }
            }

            Divider()
                .frame(height: 24)

            colorPickerButton
            lineWidthSlider
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var colorPickerButton: some View {
        Button {
            showColorPicker.toggle()
        } label: {
            Circle()
                .fill(strokeColor)
                .frame(width: 20, height: 20)
                .overlay(Circle().stroke(Color(nsColor: .separatorColor), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showColorPicker) {
            VStack(spacing: 8) {
                ColorPicker("Color", selection: $strokeColor)
                    .labelsHidden()
                    .padding()
            }
            .frame(width: 200)
        }
        .onChange(of: strokeColor) { _, newColor in
            engine.style.strokeColor = NSColor(newColor)
        }
    }

    private var lineWidthSlider: some View {
        HStack(spacing: 4) {
            Image(systemName: "lineweight")
                .font(.caption)
                .foregroundStyle(.secondary)
            Slider(value: $lineWidth, in: 1...8, step: 0.5)
                .frame(width: 80)
        }
        .onChange(of: lineWidth) { _, newValue in
            engine.style.lineWidth = newValue
        }
    }

    private var canvasView: some View {
        GeometryReader { geometry in
            ZStack {
                Color(nsColor: .windowBackgroundColor)
                    .ignoresSafeArea()

                AnnotationCanvas(
                    image: image,
                    engine: engine,
                    imageSize: $imageSize
                )
                .frame(
                    maxWidth: geometry.size.width,
                    maxHeight: geometry.size.height
                )
            }
        }
    }

    private var actionBarView: some View {
        HStack(spacing: 16) {
            Button("Cancel") {
                onDismiss()
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                engine.clearAll()
            } label: {
                Image(systemName: "trash")
                Text("Clear")
            }
            .buttonStyle(.plain)
            .disabled(engine.elements.isEmpty)

            Button {
                let result = engine.renderToImage(baseImage: image)
                captureManager.saveImage(result)
                captureManager.copyToClipboard(result)
                onDismiss()
            } label: {
                Image(systemName: "checkmark.circle.fill")
                Text("Save & Copy")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct ToolButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.caption2)
            }
            .frame(width: 40, height: 36)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct AnnotationCanvas: NSViewRepresentable {
    let image: NSImage
    let engine: AnnotationEngine
    @Binding var imageSize: CGSize

    func makeNSView(context: Context) -> AnnotationNSView {
        let view = AnnotationNSView()
        view.image = image
        view.engine = engine
        view.onSizeChange = { size in
            imageSize = size
        }
        return view
    }

    func updateNSView(_ nsView: AnnotationNSView, context: Context) {
        nsView.image = image
        nsView.engine = engine
        nsView.needsDisplay = true
    }
}

final class AnnotationNSView: NSView {
    var image: NSImage? {
        didSet { cachedBaseImage = nil }
    }
    var engine: AnnotationEngine? {
        didSet { cachedBaseImage = nil }
    }
    var onSizeChange: ((CGSize) -> Void)?

    private var trackingArea: NSTrackingArea?
    private var cachedBaseImage: CGImage?
    private var cachedDrawRect: CGRect = .zero

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        setupTracking()
    }

    override func layout() {
        super.layout()
        cachedBaseImage = nil
        onSizeChange?(bounds.size)
    }

    private func setupTracking() {
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
        let point = convert(event.locationInWindow, from: nil)
        engine?.beginAnnotation(at: point)
    }

    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        engine?.updateAnnotation(at: point)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        engine?.endAnnotation(at: point)
        needsDisplay = true
    }

    private func computeDrawRect() -> CGRect {
        guard let image else { return .zero }

        let imageAspect = image.size.width / image.size.height
        let viewAspect = bounds.width / bounds.height

        if imageAspect > viewAspect {
            let height = bounds.width / imageAspect
            return CGRect(
                x: 0,
                y: (bounds.height - height) / 2,
                width: bounds.width,
                height: height
            )
        } else {
            let width = bounds.height * imageAspect
            return CGRect(
                x: (bounds.width - width) / 2,
                y: 0,
                width: width,
                height: bounds.height
            )
        }
    }

    private func renderBaseImage() {
        guard let image else { return }

        let drawRect = computeDrawRect()
        cachedDrawRect = drawRect

        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }

        let width = Int(drawRect.width)
        let height = Int(drawRect.height)
        guard width > 0, height > 0 else { return }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return }

        ctx.interpolationQuality = .high
        ctx.draw(cgImage, in: CGRect(origin: .zero, size: drawRect.size))

        cachedBaseImage = ctx.makeImage()
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let image, let engine else { return }

        if cachedBaseImage == nil {
            renderBaseImage()
        }

        guard let context = NSGraphicsContext.current?.cgContext else { return }

        if let cached = cachedBaseImage {
            context.draw(cached, in: cachedDrawRect)
        } else {
            image.draw(in: computeDrawRect(), from: .zero, operation: .copy, fraction: 1.0)
        }

        let drawRect = cachedBaseImage != nil ? cachedDrawRect : computeDrawRect()
        let scaleX = drawRect.width / image.size.width
        let scaleY = drawRect.height / image.size.height

        context.saveGState()
        context.translateBy(x: drawRect.origin.x, y: drawRect.origin.y)
        context.scaleBy(x: scaleX, y: scaleY)

        for element in engine.elements {
            element.draw(in: context)
        }

        if let current = engine.currentElement {
            current.draw(in: context)
        }

        context.restoreGState()
    }
}
