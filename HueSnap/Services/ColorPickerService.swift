import AppKit
import Foundation
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
    private var isPicking = false
    private var cursorPushed = false
    private var pickerWindow: NSWindow?
    private var magnifyWindow: NSWindow?
    private var eventMonitor: Any?
    private var screenBitmap: NSBitmapImageRep?
    private var currentDisplayID: CGDirectDisplayID = 0
    private var currentScreen: NSScreen?

    var onColorPicked: ((PickedColor) -> Void)?
    var onCancel: (() -> Void)?

    func startPicking() {
        guard !isPicking else { return }

        guard checkScreenCapturePermission() else { return }

        isPicking = true

        captureScreen()
        showMagnifier()
        showPickerOverlay()
    }

    private func checkScreenCapturePermission() -> Bool {
        if CGPreflightScreenCaptureAccess() {
            return true
        }
        return CGRequestScreenCaptureAccess()
    }

    func stopPicking() {
        isPicking = false
        if cursorPushed {
            NSCursor.pop()
            cursorPushed = false
        }
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        magnifyWindow?.orderOut(nil)
        magnifyWindow = nil
        pickerWindow?.orderOut(nil)
        pickerWindow = nil
        screenBitmap = nil
        currentDisplayID = 0
        currentScreen = nil
    }

    private func displayForMouse() -> CGDirectDisplayID? {
        let mouseLoc = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: {
            NSMouseInRect(mouseLoc, $0.frame, false)
        }) else {
            return CGMainDisplayID()
        }
        let did = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
        return did ?? CGMainDisplayID()
    }

    private func screenRecord() {
        guard let did = displayForMouse() else { return }
        currentDisplayID = did

        let mouseLoc = NSEvent.mouseLocation
        currentScreen = NSScreen.screens.first(where: {
            NSMouseInRect(mouseLoc, $0.frame, false)
        })

        guard let image = CGDisplayCreateImage(did) else { return }

        let rep = NSBitmapImageRep(cgImage: image)
        screenBitmap = rep
    }

    private func captureScreen() {
        screenRecord()
    }

    private func showPickerOverlay() {
        guard let screen = NSScreen.main else { return }
        let frame = screen.frame

        let panel = NSPanel(contentRect: frame,
                            styleMask: [.borderless, .nonactivatingPanel],
                            backing: .buffered,
                            defer: false)
        panel.level = .screenSaver
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.ignoresMouseEvents = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.makeKeyAndOrderFront(nil)

        let trackingView = NSView(frame: frame)
        trackingView.wantsLayer = true
        trackingView.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView = trackingView

        NSCursor.crosshair.push()
        cursorPushed = true

        pickerWindow = panel

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .keyDown, .mouseMoved]) { [weak self] event in
            guard let self = self else { return event }

            switch event.type {
            case .leftMouseDown:
                if let color = self.readPixelAtMouse() {
                    self.onColorPicked?(color)
                    self.stopPicking()
                }
                return nil

            case .keyDown:
                if event.keyCode == 53 {
                    self.onCancel?()
                    self.stopPicking()
                    return nil
                }

            case .mouseMoved:
                self.onMouseMoved()

            default:
                break
            }
            return event
        }
    }

    private func onMouseMoved() {
        guard let window = magnifyWindow else { return }

        let mouseLoc = NSEvent.mouseLocation
        if let screen = NSScreen.screens.first(where: {
            NSMouseInRect(mouseLoc, $0.frame, false)
        }) {
            let newID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? 0
            if newID != currentDisplayID {
                screenRecord()
            }
        }

        let ms = window.frame.size
        let x = mouseLoc.x - ms.width / 2
        let y = mouseLoc.y + 20
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func showMagnifier() {
        let half: CGFloat = 5
        let gridPixels = half * 2 + 1
        let cell: CGFloat = 10
        let gridInner = gridPixels * cell
        let pad: CGFloat = 8
        let gridTotal = gridInner + pad * 2
        let mgW = max(gridTotal + 4, 160)
        let mgH = gridTotal + 56
        let mgFrame = NSRect(x: 0, y: 0, width: mgW, height: mgH)

        let panel = NSPanel(contentRect: mgFrame,
                            styleMask: [.borderless, .nonactivatingPanel],
                            backing: .buffered,
                            defer: false)
        panel.level = .screenSaver + 1
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let hostingView = NSHostingView(rootView: MagnifierView(
            capturePixels: { [weak self] in
                self?.captureZoomedRegion()
            }
        ))
        hostingView.frame = CGRect(origin: .zero, size: mgFrame.size)
        panel.contentView = hostingView
        panel.makeKeyAndOrderFront(nil)

        magnifyWindow = panel
        let mouseLoc = NSEvent.mouseLocation
        let x = mouseLoc.x - mgW / 2
        let y = mouseLoc.y + 20
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func convertMouseToPixel(_ point: NSPoint) -> (x: Int, y: Int)? {
        guard let screen = currentScreen else { return nil }
        let f = screen.frame
        let scale = screen.backingScaleFactor
        let px = Int(round((point.x - f.minX) * scale))
        let py = Int(round((f.maxY - point.y) * scale))
        return (px, py)
    }

    private func readPixelAt(x: Int, y: Int) -> PickedColor? {
        guard let rep = screenBitmap else { return nil }
        guard x >= 0, x < rep.pixelsWide, y >= 0, y < rep.pixelsHigh else { return nil }
        guard let ptr = rep.bitmapData else { return nil }

        let bpp = rep.bitsPerPixel / 8
        let bpr = rep.bytesPerRow
        let offset = y * bpr + x * bpp

        let r = Double(ptr[offset + 1]) / 255.0
        let g = Double(ptr[offset + 2]) / 255.0
        let b = Double(ptr[offset + 3]) / 255.0

        return PickedColor(red: r, green: g, blue: b)
    }

    private func captureZoomedRegion() -> (pixels: [[PickedColor]], centerColor: PickedColor)? {
        guard let rep = screenBitmap else { return nil }
        guard let ptr = rep.bitmapData else { return nil }

        let mouseLoc = NSEvent.mouseLocation
        guard let (cx, cy) = convertMouseToPixel(mouseLoc) else { return nil }

        let pw = rep.pixelsWide
        let ph = rep.pixelsHigh

        let half = 5
        let startX = max(0, cx - half)
        let startY = max(0, cy - half)
        let endX = min(pw - 1, cx + half)
        let endY = min(ph - 1, cy + half)
        let captureW = endX - startX + 1
        let captureH = endY - startY + 1

        guard captureW > 0, captureH > 0 else { return nil }

        let bpp = rep.bitsPerPixel / 8
        let bpr = rep.bytesPerRow

        var pixels: [[PickedColor]] = []
        var centerColor: PickedColor?

        for row in 0..<captureH {
            var rowColors: [PickedColor] = []
            for col in 0..<captureW {
                let ax = startX + col
                let ay = startY + row
                let offset = ay * bpr + ax * bpp
                let r = Double(ptr[offset + 1]) / 255.0
                let g = Double(ptr[offset + 2]) / 255.0
                let b = Double(ptr[offset + 3]) / 255.0
                let color = PickedColor(red: r, green: g, blue: b)
                rowColors.append(color)

                if ax == cx && ay == cy {
                    centerColor = color
                }
            }
            pixels.append(rowColors)
        }

        guard let cc = centerColor else { return nil }
        return (pixels, cc)
    }

    private func readPixelAtMouse() -> PickedColor? {
        guard screenBitmap != nil else { return nil }
        let mouseLoc = NSEvent.mouseLocation
        guard let (px, py) = convertMouseToPixel(mouseLoc) else { return nil }
        return readPixelAt(x: px, y: py)
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

struct MagnifierView: View {
    let capturePixels: () -> (pixels: [[PickedColor]], centerColor: PickedColor)?
    @State private var pixels: [[PickedColor]] = []
    @State private var centerColor: PickedColor?
    @State private var refreshTimer: Timer?

    private let cellSize: CGFloat = 10

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                let rows = pixels.count
                let cols = rows > 0 ? pixels[0].count : 0
                let gridW = CGFloat(cols) * cellSize
                let gridH = CGFloat(rows) * cellSize
                let pad: CGFloat = 8

                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.controlBackgroundColor))
                    .frame(width: gridW + pad * 2, height: gridH + pad * 2)
                    .shadow(color: .black.opacity(0.2), radius: 12, y: 5)

                if !pixels.isEmpty {
                    pixelGrid
                }
            }

            if let color = centerColor {
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Color(red: color.red, green: color.green, blue: color.blue))
                        .frame(width: 18, height: 18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .stroke(Color(.separatorColor).opacity(0.3), lineWidth: 1)
                        )

                    Text(color.hex)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text(color.rgbString())
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(Color(.controlBackgroundColor).opacity(0.95))
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            }

            Text(locStr("单击取色"))
                .font(.system(size: 9, weight: .regular, design: .rounded))
                .foregroundColor(.secondary)
        }
        .onAppear {
            refreshTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                if let result = capturePixels() {
                    pixels = result.pixels
                    centerColor = result.centerColor
                }
            }
        }
        .onDisappear {
            refreshTimer?.invalidate()
            refreshTimer = nil
        }
    }

    private var pixelGrid: some View {
        let rows = pixels.count
        let cols = rows > 0 ? pixels[0].count : 0
        let gridW = CGFloat(cols) * cellSize
        let gridH = CGFloat(rows) * cellSize

        return ZStack {
            VStack(spacing: 0) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<cols, id: \.self) { col in
                            let color = pixels[row][col]
                            Rectangle()
                                .fill(Color(red: color.red, green: color.green, blue: color.blue))
                                .frame(width: cellSize, height: cellSize)
                                .overlay(
                                    Rectangle()
                                        .stroke(Color(.separatorColor).opacity(0.08), lineWidth: 0.5)
                                )
                        }
                    }
                }
            }
            CrosshairViewSmall()
        }
        .frame(width: gridW, height: gridH)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct CrosshairViewSmall: View {
    var body: some View {
        GeometryReader { geo in
            let cx = geo.size.width / 2
            let cy = geo.size.height / 2

            Rectangle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 1, height: 14)
                .position(x: cx, y: cy)
            Rectangle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 14, height: 1)
                .position(x: cx, y: cy)
            Circle()
                .stroke(Color.white.opacity(0.9), lineWidth: 1)
                .frame(width: 5, height: 5)
                .position(x: cx, y: cy)
        }
    }
}
