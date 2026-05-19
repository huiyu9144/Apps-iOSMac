import Foundation
import SwiftUI

enum AnnotationTool: String, CaseIterable, Identifiable {
    case redRect
    case circle
    case line
    case text

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .redRect: return "Rect"
        case .circle: return "Circle"
        case .line: return "Line"
        case .text: return "Text"
        }
    }

    var systemImage: String {
        switch self {
        case .redRect: return "rectangle"
        case .circle: return "circle"
        case .line: return "line.diagonal"
        case .text: return "character.cursor.ibeam"
        }
    }
}

struct Annotation: Identifiable {
    let id = UUID()
    let tool: AnnotationTool
    var startPoint: CGPoint
    var endPoint: CGPoint
    var text: String?
    let color: Color

    var rect: CGRect {
        CGRect(x: min(startPoint.x, endPoint.x),
               y: min(startPoint.y, endPoint.y),
               width: abs(endPoint.x - startPoint.x),
               height: abs(endPoint.y - startPoint.y))
    }
}
