import AppKit
import SwiftUI

enum AnnotationToolType: String, CaseIterable, Identifiable {
    case arrow
    case rect
    case text
    case mosaic
    case highlight
    case line

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .arrow: return "arrow.up.right"
        case .rect: return "rectangle"
        case .text: return "textformat"
        case .mosaic: return "square.grid.3x3"
        case .highlight: return "highlighter"
        case .line: return "line.diagonal"
        }
    }

    var displayName: String {
        switch self {
        case .arrow: return "Arrow"
        case .rect: return "Rectangle"
        case .text: return "Text"
        case .mosaic: return "Mosaic"
        case .highlight: return "Highlight"
        case .line: return "Line"
        }
    }
}

struct AnnotationStyle {
    var strokeColor: NSColor = .systemRed
    var fillColor: NSColor = .systemRed.withAlphaComponent(0.3)
    var lineWidth: CGFloat = 3.0
    var fontSize: CGFloat = 18.0
    var isFilled: Bool = false
}

protocol AnnotationElement: Identifiable {
    var id: UUID { get }
    var type: AnnotationToolType { get }
    func draw(in context: CGContext)
    func contains(point: CGPoint) -> Bool
}

struct ArrowAnnotation: AnnotationElement {
    let id = UUID()
    let type: AnnotationToolType = .arrow
    var startPoint: CGPoint
    var endPoint: CGPoint
    var style: AnnotationStyle

    func draw(in context: CGContext) {
        context.setStrokeColor(style.strokeColor.cgColor)
        context.setLineWidth(style.lineWidth)
        context.setLineCap(.round)
        context.setLineJoin(.round)

        context.beginPath()
        context.move(to: startPoint)
        context.addLine(to: endPoint)
        context.strokePath()

        let angle = atan2(endPoint.y - startPoint.y, endPoint.x - startPoint.x)
        let arrowLength: CGFloat = 15.0
        let arrowAngle: CGFloat = .pi / 6

        let arrowPoint1 = CGPoint(
            x: endPoint.x - arrowLength * cos(angle - arrowAngle),
            y: endPoint.y - arrowLength * sin(angle - arrowAngle)
        )
        let arrowPoint2 = CGPoint(
            x: endPoint.x - arrowLength * cos(angle + arrowAngle),
            y: endPoint.y - arrowLength * sin(angle + arrowAngle)
        )

        context.beginPath()
        context.move(to: endPoint)
        context.addLine(to: arrowPoint1)
        context.addLine(to: arrowPoint2)
        context.closePath()
        context.fillPath()
    }

    func contains(point: CGPoint) -> Bool {
        let dx = endPoint.x - startPoint.x
        let dy = endPoint.y - startPoint.y
        let length = sqrt(dx * dx + dy * dy)
        guard length > 0 else { return false }

        let dot = ((point.x - startPoint.x) * dx + (point.y - startPoint.y) * dy) / (length * length)
        guard dot >= 0, dot <= 1 else { return false }

        let closestX = startPoint.x + dot * dx
        let closestY = startPoint.y + dot * dy
        let distance = sqrt((point.x - closestX) * (point.x - closestX) + (point.y - closestY) * (point.y - closestY))

        return distance < max(style.lineWidth + 5, 10)
    }
}

struct RectAnnotation: AnnotationElement {
    let id = UUID()
    let type: AnnotationToolType = .rect
    var rect: CGRect
    var style: AnnotationStyle

    func draw(in context: CGContext) {
        if style.isFilled {
            context.setFillColor(style.fillColor.cgColor)
            context.fill(rect)
        }

        context.setStrokeColor(style.strokeColor.cgColor)
        context.setLineWidth(style.lineWidth)
        context.stroke(rect)
    }

    func contains(point: CGPoint) -> Bool {
        rect.insetBy(dx: -5, dy: -5).contains(point)
    }
}

struct TextAnnotation: AnnotationElement {
    let id = UUID()
    let type: AnnotationToolType = .text
    var position: CGPoint
    var text: String
    var style: AnnotationStyle

    func draw(in context: CGContext) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: style.fontSize),
            .foregroundColor: style.strokeColor
        ]

        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let line = CTLineCreateWithAttributedString(attributedString)
        context.textMatrix = .identity
        context.textPosition = position
        CTLineDraw(line, context)
    }

    func contains(point: CGPoint) -> Bool {
        let size = (text as NSString).size(withAttributes: [
            .font: NSFont.systemFont(ofSize: style.fontSize)
        ])
        let textRect = CGRect(origin: position, size: size)
        return textRect.insetBy(dx: -5, dy: -5).contains(point)
    }
}

struct MosaicAnnotation: AnnotationElement {
    let id = UUID()
    let type: AnnotationToolType = .mosaic
    var path: [CGPoint]
    var mosaicSize: CGFloat = 8.0

    func draw(in context: CGContext) {
        guard path.count > 1 else { return }

        for point in path {
            let rect = CGRect(
                x: point.x - mosaicSize / 2,
                y: point.y - mosaicSize / 2,
                width: mosaicSize,
                height: mosaicSize
            )
            let grayValue = ((point.x + point.y).truncatingRemainder(dividingBy: 3)) / 3.0
            let color = NSColor(
                red: grayValue,
                green: grayValue,
                blue: grayValue,
                alpha: 0.5
            )
            context.setFillColor(color.cgColor)
            context.fill(rect)
        }
    }

    func contains(point: CGPoint) -> Bool {
        path.contains { $0.distance(to: point) < mosaicSize }
    }
}

struct HighlightAnnotation: AnnotationElement {
    let id = UUID()
    let type: AnnotationToolType = .highlight
    var rect: CGRect
    var style: AnnotationStyle

    func draw(in context: CGContext) {
        context.setFillColor(NSColor.yellow.withAlphaComponent(0.3).cgColor)
        context.fill(rect)
    }

    func contains(point: CGPoint) -> Bool {
        rect.insetBy(dx: -5, dy: -5).contains(point)
    }
}

struct LineAnnotation: AnnotationElement {
    let id = UUID()
    let type: AnnotationToolType = .line
    var startPoint: CGPoint
    var endPoint: CGPoint
    var style: AnnotationStyle

    func draw(in context: CGContext) {
        context.setStrokeColor(style.strokeColor.cgColor)
        context.setLineWidth(style.lineWidth)
        context.setLineCap(.round)

        context.beginPath()
        context.move(to: startPoint)
        context.addLine(to: endPoint)
        context.strokePath()
    }

    func contains(point: CGPoint) -> Bool {
        let dx = endPoint.x - startPoint.x
        let dy = endPoint.y - startPoint.y
        let length = sqrt(dx * dx + dy * dy)
        guard length > 0 else { return false }

        let dot = ((point.x - startPoint.x) * dx + (point.y - startPoint.y) * dy) / (length * length)
        guard dot >= 0, dot <= 1 else { return false }

        let closestX = startPoint.x + dot * dx
        let closestY = startPoint.y + dot * dy
        let distance = sqrt((point.x - closestX) * (point.x - closestX) + (point.y - closestY) * (point.y - closestY))

        return distance < max(style.lineWidth + 5, 10)
    }
}

final class AnnotationEngine: ObservableObject {
    @Published var elements: [any AnnotationElement] = []
    @Published var selectedTool: AnnotationToolType = .arrow
    @Published var style = AnnotationStyle()
    @Published var selectedElementId: UUID?

    var currentElement: (any AnnotationElement)?
    private var currentPathPoints: [CGPoint] = []

    func beginAnnotation(at point: CGPoint) {
        switch selectedTool {
        case .arrow:
            currentElement = ArrowAnnotation(startPoint: point, endPoint: point, style: style)
        case .rect:
            var rectStyle = style
            rectStyle.isFilled = false
            currentElement = RectAnnotation(rect: CGRect(origin: point, size: .zero), style: rectStyle)
        case .text:
            let text = TextAnnotation(position: point, text: "Text", style: style)
            elements.append(text)
            currentElement = nil
        case .mosaic:
            currentPathPoints = [point]
            currentElement = MosaicAnnotation(path: [point])
        case .highlight:
            currentElement = HighlightAnnotation(rect: CGRect(origin: point, size: .zero), style: style)
        case .line:
            currentElement = LineAnnotation(startPoint: point, endPoint: point, style: style)
        }
    }

    func updateAnnotation(at point: CGPoint) {
        guard let element = currentElement else { return }

        switch element.type {
        case .arrow:
            guard var arrow = element as? ArrowAnnotation else { return }
            arrow.endPoint = point
            currentElement = arrow
        case .rect:
            guard var rectAnnotation = element as? RectAnnotation else { return }
            let origin = rectAnnotation.rect.origin
            let newRect = CGRect(
                x: min(origin.x, point.x),
                y: min(origin.y, point.y),
                width: abs(point.x - origin.x),
                height: abs(point.y - origin.y)
            )
            rectAnnotation.rect = newRect
            currentElement = rectAnnotation
        case .mosaic:
            currentPathPoints.append(point)
            currentElement = MosaicAnnotation(path: currentPathPoints)
        case .highlight:
            guard var highlight = element as? HighlightAnnotation else { return }
            let origin = highlight.rect.origin
            let newRect = CGRect(
                x: min(origin.x, point.x),
                y: min(origin.y, point.y),
                width: abs(point.x - origin.x),
                height: abs(point.y - origin.y)
            )
            highlight.rect = newRect
            currentElement = highlight
        case .line:
            guard var line = element as? LineAnnotation else { return }
            line.endPoint = point
            currentElement = line
        case .text:
            break
        }
    }

    func endAnnotation(at point: CGPoint) {
        if let element = currentElement {
            switch element.type {
            case .arrow:
                guard var arrow = element as? ArrowAnnotation else { break }
                let distance = arrow.startPoint.distance(to: arrow.endPoint)
                if distance > 5 {
                    arrow.endPoint = point
                    elements.append(arrow)
                }
            case .rect:
                guard var rectAnnotation = element as? RectAnnotation else { break }
                if rectAnnotation.rect.width > 5, rectAnnotation.rect.height > 5 {
                    let origin = rectAnnotation.rect.origin
                    let newRect = CGRect(
                        x: min(origin.x, point.x),
                        y: min(origin.y, point.y),
                        width: abs(point.x - origin.x),
                        height: abs(point.y - origin.y)
                    )
                    rectAnnotation.rect = newRect
                    elements.append(rectAnnotation)
                }
            case .mosaic:
                if !currentPathPoints.isEmpty {
                    elements.append(MosaicAnnotation(path: currentPathPoints))
                }
            case .highlight:
                guard var highlight = element as? HighlightAnnotation else { break }
                if highlight.rect.width > 5, highlight.rect.height > 5 {
                    let origin = highlight.rect.origin
                    let newRect = CGRect(
                        x: min(origin.x, point.x),
                        y: min(origin.y, point.y),
                        width: abs(point.x - origin.x),
                        height: abs(point.y - origin.y)
                    )
                    highlight.rect = newRect
                    elements.append(highlight)
                }
            case .line:
                guard var line = element as? LineAnnotation else { break }
                let distance = line.startPoint.distance(to: line.endPoint)
                if distance > 5 {
                    line.endPoint = point
                    elements.append(line)
                }
            case .text:
                break
            }
        }

        currentElement = nil
        currentPathPoints = []
    }

    func removeElement(_ id: UUID) {
        elements.removeAll { $0.id == id }
    }

    func clearAll() {
        elements.removeAll()
        currentElement = nil
        currentPathPoints = []
    }

    func renderToImage(baseImage: NSImage) -> NSImage {
        let size = baseImage.size
        let result = NSImage(size: size)
        result.lockFocus()

        baseImage.draw(at: .zero, from: .zero, operation: .copy, fraction: 1.0)

        guard let context = NSGraphicsContext.current?.cgContext else {
            result.unlockFocus()
            return baseImage
        }

        for element in elements {
            element.draw(in: context)
        }

        if let current = currentElement {
            current.draw(in: context)
        }

        result.unlockFocus()
        return result
    }
}

private extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        let dx = x - point.x
        let dy = y - point.y
        return sqrt(dx * dx + dy * dy)
    }
}
