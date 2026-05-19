import SwiftUI

struct TrafficChartView: View {
    let history: [TrafficSnapshot]
    let formatSpeed: (Double) -> String

    private var maxSpeed: Double {
        let maxDownload = history.map(\.downloadSpeed).max() ?? 0
        let maxUpload = history.map(\.uploadSpeed).max() ?? 0
        return max(maxDownload, maxUpload, 1024)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(locStr("最近 60 秒"))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 6, height: 6)
                        Text(locStr("下载"))
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text(locStr("上传"))
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
            }

            Canvas { context, size in
                guard history.count > 1 else { return }

                let width = size.width
                let height = size.height
                let stepX = width / CGFloat(history.count - 1)

                var downloadPath = Path()
                var uploadPath = Path()

                for (index, snapshot) in history.enumerated() {
                    let x = CGFloat(index) * stepX
                    let downloadY = height - (CGFloat(snapshot.downloadSpeed) / CGFloat(maxSpeed)) * height
                    let uploadY = height - (CGFloat(snapshot.uploadSpeed) / CGFloat(maxSpeed)) * height

                    if index == 0 {
                        downloadPath.move(to: CGPoint(x: x, y: downloadY))
                        uploadPath.move(to: CGPoint(x: x, y: uploadY))
                    } else {
                        downloadPath.addLine(to: CGPoint(x: x, y: downloadY))
                        uploadPath.addLine(to: CGPoint(x: x, y: uploadY))
                    }
                }

                context.stroke(
                    downloadPath,
                    with: .color(.blue.opacity(0.8)),
                    lineWidth: 1.5
                )

                context.stroke(
                    uploadPath,
                    with: .color(.green.opacity(0.8)),
                    lineWidth: 1.5
                )

                var downloadFillPath = downloadPath
                downloadFillPath.addLine(to: CGPoint(x: width, y: height))
                downloadFillPath.addLine(to: CGPoint(x: 0, y: height))
                downloadFillPath.closeSubpath()
                context.fill(downloadFillPath, with: .color(.blue.opacity(0.08)))

                var uploadFillPath = uploadPath
                uploadFillPath.addLine(to: CGPoint(x: width, y: height))
                uploadFillPath.addLine(to: CGPoint(x: 0, y: height))
                uploadFillPath.closeSubpath()
                context.fill(uploadFillPath, with: .color(.green.opacity(0.08)))
            }
            .frame(height: 80)
            .background(Color(.controlBackgroundColor))

            if let last = history.last {
                HStack {
                    Text("↓ \(formatSpeed(last.downloadSpeed))")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.blue)
                    Spacer()
                    Text("↑ \(formatSpeed(last.uploadSpeed))")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.green)
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color(.controlBackgroundColor)))
    }
}
