import AppKit
import SwiftUI

struct PickedColor: Identifiable, Codable, Equatable {
    var id: UUID
    var hex: String
    var red: Double
    var green: Double
    var blue: Double

    init(red: Double, green: Double, blue: Double) {
        self.id = UUID()
        self.red = red
        self.green = green
        self.blue = blue
        self.hex = Self.rgbToHex(r: red, g: green, b: blue)
    }

    init(nsColor: NSColor) {
        let srgb = nsColor.usingColorSpace(.sRGB) ?? nsColor
        self.init(red: srgb.redComponent, green: srgb.greenComponent, blue: srgb.blueComponent)
    }

    static func rgbToHex(r: Double, g: Double, b: Double) -> String {
        let ri = Int(max(0, min(255, r * 255)))
        let gi = Int(max(0, min(255, g * 255)))
        let bi = Int(max(0, min(255, b * 255)))
        return String(format: "#%02X%02X%02X", ri, gi, bi)
    }

    func rgbString() -> String {
        let ri = Int(red * 255)
        let gi = Int(green * 255)
        let bi = Int(blue * 255)
        return "rgb(\(ri), \(gi), \(bi))"
    }

    func hslString() -> String {
        let r = red
        let g = green
        let b = blue
        let maxC = max(r, g, b)
        let minC = min(r, g, b)
        let delta = maxC - minC

        var h: Double = 0
        var s: Double = 0
        let l = (maxC + minC) / 2.0

        if delta != 0 {
            s = l > 0.5 ? delta / (2.0 - maxC - minC) : delta / (maxC + minC)
            if maxC == r {
                h = ((g - b) / delta).truncatingRemainder(dividingBy: 6)
            } else if maxC == g {
                h = (b - r) / delta + 2.0
            } else {
                h = (r - g) / delta + 4.0
            }
            h *= 60
            if h < 0 { h += 360 }
        }

        let hi = Int(round(h))
        let si = Int(round(s * 100))
        let li = Int(round(l * 100))
        return "hsl(\(hi), \(si)%, \(li)%)"
    }
}

@MainActor
class ColorPickerService {
    var onColorPicked: ((PickedColor) -> Void)?
    var onCancel: (() -> Void)?

    func startPicking() {
        let sampler = NSColorSampler()
        let pickedHandler = onColorPicked
        let cancelHandler = onCancel
        sampler.show { nsColor in
            if let nsColor = nsColor {
                let picked = PickedColor(nsColor: nsColor)
                pickedHandler?(picked)
            } else {
                cancelHandler?()
            }
        }
    }

    static func showFloatingToast(message: String) {
        let screenFrame = NSScreen.main?.frame ?? .zero
        let toastWidth: CGFloat = 280
        let toastHeight: CGFloat = 48
        let x = screenFrame.midX - toastWidth / 2
        let y: CGFloat = 80

        let panel = NSPanel(contentRect: NSRect(x: x, y: y, width: toastWidth, height: toastHeight),
                            styleMask: [.borderless, .nonactivatingPanel],
                            backing: .buffered,
                            defer: false)
        panel.level = .screenSaver + 2
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let hostingView = NSHostingView(rootView: ToastView(message: message))
        hostingView.frame = CGRect(origin: .zero, size: CGSize(width: toastWidth, height: toastHeight))
        panel.contentView = hostingView

        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.25
            panel.animator().alphaValue = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.25
                panel.animator().alphaValue = 0
            } completionHandler: {
                panel.orderOut(nil)
            }
        }
    }
}

struct ToastView: View {
    let message: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.green)
            Text(message)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.85))
                .shadow(color: .black.opacity(0.25), radius: 12, y: 4)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
