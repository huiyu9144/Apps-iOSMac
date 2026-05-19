import SwiftUI

struct FileSelectorView: View {
    let viewModel: CompressionViewModel

    var body: some View {
        Group {
            if viewModel.selectedURLs.isEmpty {
                emptyState
            } else {
                selectedState
            }
        }
    }

    private var emptyState: some View {
        Button(action: { viewModel.selectFilesFromPanel() }) {
            VStack(spacing: 10) {
                Image(systemName: "plus.viewfinder")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(.tertiary)

                VStack(spacing: 3) {
                    Text(locStr("选择文件/文件夹"))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text("PNG · JPG · WebP")
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                    )
                    .foregroundStyle(.quaternary)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var selectedState: some View {
        Button(action: { viewModel.selectFilesFromPanel() }) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(.tint.opacity(0.1))
                        .frame(width: 34, height: 34)
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.tint)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(locStr("已选择")) \(viewModel.selectedFileCount)\(locStr("张图片"))")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                    Text(viewModel.formattedOriginalSize)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.tint.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(.tint.opacity(0.1), lineWidth: 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
