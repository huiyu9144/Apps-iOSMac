import AppKit
import CoreGraphics

let orangeR: CGFloat = 0.95
let orangeG: CGFloat = 0.55
let orangeB: CGFloat = 0.05

let darkOrangeR: CGFloat = 0.85
let darkOrangeG: CGFloat = 0.40
let darkOrangeB: CGFloat = 0.00

let sizes: [(name: String, size: Int)] = [
    ("icon_16", 16), ("icon_32", 32), ("icon_64", 64),
    ("icon_128", 128), ("icon_256", 256), ("icon_512", 512), ("icon_1024", 1024)
]

let outputDir = "MenuTimer/Assets.xcassets/AppIcon.appiconset"

func drawIcon(size: Int) -> Data {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue
    let ctx = CGContext(
        data: nil,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: bitmapInfo
    )!

    let rect = CGRect(x: 0, y: 0, width: size, height: size)

    ctx.setAllowsAntialiasing(true)
    ctx.setShouldAntialias(true)

    let cornerRadius = CGFloat(size) * 0.22
    let bgPath = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    ctx.addPath(bgPath)
    ctx.clip()

    let gradient = CGGradient(
        colorsSpace: colorSpace,
        colors: [
            CGColor(red: orangeR, green: orangeG, blue: orangeB, alpha: 1) as CFTypeRef,
            CGColor(red: darkOrangeR, green: darkOrangeG, blue: darkOrangeB, alpha: 1) as CFTypeRef,
        ] as CFArray,
        locations: [0, 1]
    )!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size), end: CGPoint(x: size, y: 0), options: [])

    let s = CGFloat(size) / 1024.0
    ctx.translateBy(x: rect.midX, y: rect.midY)
    ctx.scaleBy(x: s, y: s)

    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)

    let r: CGFloat = 280
    let thick: CGFloat = 40

    ctx.setStrokeColor(red: 1, green: 1, blue: 1, alpha: 0.92)
    ctx.setLineWidth(thick)
    ctx.addArc(center: .zero, radius: r, startAngle: 0, endAngle: .pi * 2, clockwise: false)
    ctx.strokePath()

    ctx.move(to: CGPoint(x: 0, y: r))
    ctx.addLine(to: CGPoint(x: 0, y: r - 90))
    ctx.strokePath()

    ctx.move(to: CGPoint(x: r, y: 0))
    ctx.addLine(to: CGPoint(x: r - 90, y: 0))
    ctx.strokePath()

    ctx.setFillColor(red: 1, green: 1, blue: 1, alpha: 0.92)
    let tri = CGMutablePath()
    tri.move(to: CGPoint(x: r * 0.28, y: -60))
    tri.addLine(to: CGPoint(x: r * 0.28, y: 60))
    tri.addLine(to: CGPoint(x: r * 0.28 + 85, y: 0))
    tri.closeSubpath()
    ctx.addPath(tri)
    ctx.fillPath()

    let cgImage = ctx.makeImage()!
    let bitmap = NSBitmapImageRep(cgImage: cgImage)
    return bitmap.representation(using: .png, properties: [:])!
}

print("🎨 Generating MenuTimer App Icons\n")

for (name, size) in sizes {
    let data = drawIcon(size: size)
    let fileURL = URL(fileURLWithPath: "\(outputDir)/\(name).png")
    try? FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(),
                                            withIntermediateDirectories: true)
    try? data.write(to: fileURL)
    print("  ✓ \(name).png  \(size)x\(size)")
}

print("\n✅ Done! All icons saved to \(outputDir)/")
