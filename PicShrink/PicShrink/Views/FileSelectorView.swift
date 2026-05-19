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
            HStack(spacing: 10) {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 36, height: 36)
                    .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(.blue.opacity(0.12)))
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text(locStr("选择文件/文件夹"))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))

                    Text(locStr("PNG / JPG / WebP"))
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .fill(.secondary.opacity(0.25))
            )
        }
        .buttonStyle(.plain)
    }

    private var selectedState: some View {
        Button(action: { viewModel.selectFilesFromPanel() }) {
            HStack(spacing: 10) {
                Image(systemName: "photo.stack.fill")
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 36, height: 36)
                    .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(.blue.opacity(0.12)))
                    .foregroundStyle(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(locStr("已选择")) \(viewModel.selectedFileCount)\(locStr("张图片"))")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))

                    Text(viewModel.formattedOriginalSize)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .fill(.blue.opacity(0.3))
            )
        }
        .buttonStyle(.plain)
    }
}
