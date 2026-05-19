import Cocoa
import SwiftUI

protocol ScreenOverlayViewDelegate: AnyObject {
    func overlayDidSelectRect(_ rect: CGRect)
    func overlayDidCancel()
    func overlayDidDoubleClick()
    func overlaySelectionRect() -> CGRect
    func overlayCapturedImage() -> NSImage?
    func overlayAnnotations() -> [Annotation]
    func overlayCurrentAnnotation() -> Annotation?
    func overlayIsEditing() -> Bool
    func overlayDidDragSelection(to rect: CGRect)
    func overlayDidFinishDragSelection(to rect: CGRect)
    func overlaySelectedTool() -> AnnotationTool?
    func overlayMouseDown(at point: NSPoint)
    func overlayMouseUp(at point: NSPoint)
    func overlayMouseDragged(to point: NSPoint)
}

enum ResizeHandle {
    case none
    case topLeft, topRight, bottomLeft, bottomRight
    case topEdge, bottomEdge, leftEdge, rightEdge
    case inside
}

class ScreenOverlayView: NSView {
    weak var delegate: ScreenOverlayViewDelegate?

    private let dimAlpha: CGFloat = 0.45
    private let handleSize: CGFloat = 12
    private var handleHalf: CGFloat { handleSize / 2 }

    private var isDragging = false
    private var dragStartPoint: NSPoint = .zero
    private var dragStartRect: CGRect = .zero
    private var activeHandle: ResizeHandle = .none
    private var isCreatingSelection = false
    private var selectionStartPoint: NSPoint = .zero
    private var selectionEndPoint: NSPoint = .zero

    private var trackingArea: NSTrackingArea?

    override init(frame: CGRect) {
        super.init(frame: frame)
        wantsLayer = true
        setupTracking()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        setupTracking()
    }

    override var acceptsFirstResponder: Bool { true }

    private func setupTracking() {
        let options: NSTrackingArea.Options = [.activeAlways, .mouseMoved, .mouseEnteredAndExited, .cursorUpdate]
        trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(trackingArea!)
    }

    override func cursorUpdate(with event: NSEvent) {
        guard let delegate = delegate else { return }
        if !delegate.overlayIsEditing() {
            NSCursor.crosshair.set()
            return
        }
        let point = convert(event.locationInWindow, from: nil)
        let handle = resizeHandle(at: point)
        switch handle {
        case .topLeft, .topRight, .bottomLeft, .bottomRight:
            NSCursor.crosshair.set()
        case .topEdge, .bottomEdge:
            NSCursor.resizeUpDown.set()
        case .leftEdge, .rightEdge:
            NSCursor.resizeLeftRight.set()
        case .inside:
            if delegate.overlaySelectedTool() != nil {
                NSCursor.crosshair.set()
            } else {
                NSCursor.openHand.set()
            }
        case .none:
            if delegate.overlaySelectedTool() != nil {
                NSCursor.crosshair.set()
            } else {
                NSCursor.arrow.set()
            }
        }
    }

    // MARK: - Mouse Events

    override func mouseDown(with event: NSEvent) {
        guard let delegate = delegate else { return }

        let point = convert(event.locationInWindow, from: nil)

        if event.clickCount == 2 {
            if isCreatingSelection {
                isCreatingSelection = false
                let rect = rectFrom(start: selectionStartPoint, end: selectionEndPoint)
                if rect.width > 5 && rect.height > 5 {
                    delegate.overlayDidSelectRect(rect)
                } else {
                    delegate.overlayDidCancel()
                }
                return
            }
            if delegate.overlayIsEditing() {
                delegate.overlayDidDoubleClick()
                return
            }
        }

        if !delegate.overlayIsEditing() {
            isCreatingSelection = true
            selectionStartPoint = point
            selectionEndPoint = point
            return
        }

        if let _ = delegate.overlaySelectedTool() {
            if delegate.overlaySelectionRect().contains(point) {
                delegate.overlayMouseDown(at: point)
            }
            return
        }

        let handle = resizeHandle(at: point)
        if handle != .none {
            isDragging = true
            activeHandle = handle
            dragStartPoint = point
            dragStartRect = delegate.overlaySelectionRect()
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            delegate?.overlayDidCancel()
        }
    }

    override func mouseDragged(with event: NSEvent) {
        guard let delegate = delegate else { return }
        let point = convert(event.locationInWindow, from: nil)

        if isCreatingSelection {
            selectionEndPoint = point
            needsDisplay = true
            return
        }

        if isDragging {
            delegate.overlayMouseDragged(to: point)
            let dx = point.x - dragStartPoint.x
            let dy = point.y - dragStartPoint.y
            var newRect = dragStartRect

            switch activeHandle {
            case .topLeft:     newRect = CGRect(x: dragStartRect.minX + dx, y: dragStartRect.minY + dy, width: dragStartRect.width - dx, height: dragStartRect.height - dy)
            case .topRight:    newRect = CGRect(x: dragStartRect.minX, y: dragStartRect.minY + dy, width: dragStartRect.width + dx, height: dragStartRect.height - dy)
            case .bottomLeft:  newRect = CGRect(x: dragStartRect.minX + dx, y: dragStartRect.minY, width: dragStartRect.width - dx, height: dragStartRect.height + dy)
            case .bottomRight: newRect = CGRect(x: dragStartRect.minX, y: dragStartRect.minY, width: dragStartRect.width + dx, height: dragStartRect.height + dy)
            case .topEdge:      newRect = CGRect(x: dragStartRect.minX, y: dragStartRect.minY + dy, width: dragStartRect.width, height: dragStartRect.height - dy)
            case .bottomEdge:   newRect = CGRect(x: dragStartRect.minX, y: dragStartRect.minY, width: dragStartRect.width, height: dragStartRect.height + dy)
            case .leftEdge:     newRect = CGRect(x: dragStartRect.minX + dx, y: dragStartRect.minY, width: dragStartRect.width - dx, height: dragStartRect.height)
            case .rightEdge:    newRect = CGRect(x: dragStartRect.minX, y: dragStartRect.minY, width: dragStartRect.width + dx, height: dragStartRect.height)
            case .inside:
                newRect = dragStartRect.offsetBy(dx: dx, dy: dy)
                if let screen = window?.screen {
                    let screenFrame = screen.frame
                    newRect.origin.x = max(screenFrame.minX, min(newRect.minX, screenFrame.maxX - newRect.width))
                    newRect.origin.y = max(screenFrame.minY, min(newRect.minY, screenFrame.maxY - newRect.height))
                }
            case .none: break
            }

            if newRect.width > 20 && newRect.height > 20 {
                delegate.overlayDidDragSelection(to: newRect)
            }
            needsDisplay = true
        }
    }

    override func mouseUp(with event: NSEvent) {
        guard let delegate = delegate else { return }

        if isCreatingSelection {
            isCreatingSelection = false
            let point = convert(event.locationInWindow, from: nil)
            let rect = rectFrom(start: selectionStartPoint, end: point)
            if rect.width > 5 && rect.height > 5 {
                delegate.overlayDidSelectRect(rect)
            } else {
                delegate.overlayDidCancel()
            }
            return
        }

        if delegate.overlayIsEditing() {
            let point = convert(event.locationInWindow, from: nil)
            if delegate.overlaySelectedTool() != nil {
                delegate.overlayMouseUp(at: point)
            }

            if isDragging {
                isDragging = false
                activeHandle = .none
                if dragStartRect != delegate.overlaySelectionRect() {
                    delegate.overlayDidFinishDragSelection(to: delegate.overlaySelectionRect())
                }
            }
        }
        NSCursor.pop()
    }

    override func cancelOperation(_ sender: Any?) {
        delegate?.overlayDidCancel()
    }

    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        guard let delegate = delegate else { return }

        context.setFillColor(NSColor.black.withAlphaComponent(dimAlpha).cgColor)
        context.fill(bounds)

        if delegate.overlayIsEditing() {
            drawActiveSelection(context: context, delegate: delegate)
        } else if isCreatingSelection {
            drawCreatingSelection(context: context)
        }
    }

    private func drawCreatingSelection(context: CGContext) {
        let rect = rectFrom(start: selectionStartPoint, end: selectionEndPoint)
        context.clear(rect)
        context.setStrokeColor(NSColor.keyboardFocusIndicatorColor.cgColor)
        context.setLineWidth(2)
        context.stroke(rect)

        let sizeText = "\(Int(rect.width)) × \(Int(rect.height))"
        drawSizeLabel(text: sizeText, at: CGPoint(x: rect.minX + 6, y: rect.minY + 6), context: context)
    }

    private func drawActiveSelection(context: CGContext, delegate: ScreenOverlayViewDelegate) {
        let rect = delegate.overlaySelectionRect()

        context.clear(rect)

        if let image = delegate.overlayCapturedImage() {
            image.draw(in: rect)
        }

        context.setStrokeColor(NSColor.keyboardFocusIndicatorColor.cgColor)
        context.setLineWidth(2)
        context.stroke(rect)

        drawResizeHandles(context: context, rect: rect)
        drawAnnotations(delegate: delegate)
        drawCurrentAnnotation(delegate: delegate)

        let sizeText = "\(Int(rect.width)) × \(Int(rect.height))"
        drawSizeLabel(text: sizeText, at: CGPoint(x: rect.minX + 6, y: rect.minY + 6), context: context)
    }

    private func drawSizeLabel(text: String, at point: CGPoint, context: CGContext) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
            .foregroundColor: NSColor.white
        ]
        let attrStr = NSAttributedString(string: text, attributes: attrs)
        let textSize = attrStr.size()
        let textRect = CGRect(
            x: point.x,
            y: point.y,
            width: textSize.width + 10,
            height: textSize.height + 6
        )
        NSColor.black.withAlphaComponent(0.6).setFill()
        NSBezierPath(roundedRect: textRect, xRadius: 3, yRadius: 3).fill()
        attrStr.draw(at: CGPoint(x: textRect.minX + 5, y: textRect.minY + 3))
    }

    private func drawResizeHandles(context: CGContext, rect: CGRect) {
        let handles: [(CGRect, ResizeHandle)] = [
            (CGRect(x: rect.minX - handleHalf, y: rect.minY - handleHalf, width: handleSize, height: handleSize), .topLeft),
            (CGRect(x: rect.midX - handleHalf, y: rect.minY - handleHalf, width: handleSize, height: handleSize), .topEdge),
            (CGRect(x: rect.maxX - handleHalf, y: rect.minY - handleHalf, width: handleSize, height: handleSize), .topRight),
            (CGRect(x: rect.minX - handleHalf, y: rect.midY - handleHalf, width: handleSize, height: handleSize), .leftEdge),
            (CGRect(x: rect.maxX - handleHalf, y: rect.midY - handleHalf, width: handleSize, height: handleSize), .rightEdge),
            (CGRect(x: rect.minX - handleHalf, y: rect.maxY - handleHalf, width: handleSize, height: handleSize), .bottomLeft),
            (CGRect(x: rect.midX - handleHalf, y: rect.maxY - handleHalf, width: handleSize, height: handleSize), .bottomEdge),
            (CGRect(x: rect.maxX - handleHalf, y: rect.maxY - handleHalf, width: handleSize, height: handleSize), .bottomRight),
        ]

        context.setFillColor(NSColor.white.cgColor)
        context.setStrokeColor(NSColor.keyboardFocusIndicatorColor.cgColor)
        context.setLineWidth(1.5)

        for (handleRect, _) in handles {
            context.fillEllipse(in: handleRect)
            context.strokeEllipse(in: handleRect)
        }
    }

    private func drawAnnotations(delegate: ScreenOverlayViewDelegate) {
        for annotation in delegate.overlayAnnotations() {
            drawAnnotation(annotation)
        }
    }

    private func drawCurrentAnnotation(delegate: ScreenOverlayViewDelegate) {
        guard let current = delegate.overlayCurrentAnnotation() else { return }
        drawAnnotation(current)
    }

    private func drawAnnotation(_ annotation: Annotation) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        let rect = annotation.rect
        context.setStrokeColor(NSColor.red.cgColor)
        context.setLineWidth(3)

        switch annotation.tool {
        case .redRect:
            context.stroke(rect)
        case .circle:
            context.strokeEllipse(in: rect)
        case .line:
            context.beginPath()
            context.move(to: annotation.startPoint)
            context.addLine(to: annotation.endPoint)
            context.strokePath()
        case .text:
            if let text = annotation.text {
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.boldSystemFont(ofSize: 18),
                    .foregroundColor: NSColor.red
                ]
                (text as NSString).draw(at: annotation.startPoint, withAttributes: attrs)
            }
        }
    }

    // MARK: - Helpers

    private func resizeHandle(at point: NSPoint) -> ResizeHandle {
        guard let delegate = delegate else { return .none }
        let rect = delegate.overlaySelectionRect()
        if delegate.overlaySelectedTool() != nil { return .inside }

        let hitExtra: CGFloat = 4
        let handles: [(CGRect, ResizeHandle)] = [
            (CGRect(x: rect.minX - handleHalf - hitExtra, y: rect.minY - handleHalf - hitExtra, width: handleSize + hitExtra * 2, height: handleSize + hitExtra * 2), .topLeft),
            (CGRect(x: rect.midX - handleHalf - hitExtra, y: rect.minY - handleHalf - hitExtra, width: handleSize + hitExtra * 2, height: handleSize + hitExtra * 2), .topEdge),
            (CGRect(x: rect.maxX - handleHalf - hitExtra, y: rect.minY - handleHalf - hitExtra, width: handleSize + hitExtra * 2, height: handleSize + hitExtra * 2), .topRight),
            (CGRect(x: rect.minX - handleHalf - hitExtra, y: rect.midY - handleHalf - hitExtra, width: handleSize + hitExtra * 2, height: handleSize + hitExtra * 2), .leftEdge),
            (CGRect(x: rect.maxX - handleHalf - hitExtra, y: rect.midY - handleHalf - hitExtra, width: handleSize + hitExtra * 2, height: handleSize + hitExtra * 2), .rightEdge),
            (CGRect(x: rect.minX - handleHalf - hitExtra, y: rect.maxY - handleHalf - hitExtra, width: handleSize + hitExtra * 2, height: handleSize + hitExtra * 2), .bottomLeft),
            (CGRect(x: rect.midX - handleHalf - hitExtra, y: rect.maxY - handleHalf - hitExtra, width: handleSize + hitExtra * 2, height: handleSize + hitExtra * 2), .bottomEdge),
            (CGRect(x: rect.maxX - handleHalf - hitExtra, y: rect.maxY - handleHalf - hitExtra, width: handleSize + hitExtra * 2, height: handleSize + hitExtra * 2), .bottomRight),
        ]

        for (handleRect, handle) in handles {
            if handleRect.contains(point) { return handle }
        }

        if rect.contains(point) { return .inside }
        return .none
    }

    private func rectFrom(start: NSPoint, end: NSPoint) -> CGRect {
        let x = min(start.x, end.x)
        let y = min(start.y, end.y)
        let w = abs(end.x - start.x)
        let h = abs(end.y - start.y)
        return CGRect(x: x, y: y, width: w, height: h)
    }
}
