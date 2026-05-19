import SwiftUI

struct CompressionResultView: View {
    let viewModel: CompressionViewModel

    var body: some View {
        if viewModel.compressionComplete {
            resultCard
        }
    }

    private var resultCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 0) {
                    Text(viewModel.formattedOriginalSize)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.green)
                        .padding(.horizontal, 6)
                    Text(viewModel.formattedCompressedSize)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(.green)
                }

                Text(String(format: "\(locStr("节省")) %.1f%% · %d\(locStr("张图片已压缩"))", viewModel.savedPercent, viewModel.results.count))
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.green.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.green.opacity(0.15), lineWidth: 1)
        )
    }
}
