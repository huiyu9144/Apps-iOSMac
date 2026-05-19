import SwiftUI

struct CompressionResultView: View {
    let viewModel: CompressionViewModel

    var body: some View {
        if viewModel.compressionComplete {
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(.green.opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.green)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 4) {
                            Text(viewModel.formattedOriginalSize)
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .strikethrough()
                                .foregroundStyle(.secondary)

                            Image(systemName: "arrow.right")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.green)
                                .padding(.horizontal, 2)

                            Text(viewModel.formattedCompressedSize)
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundStyle(.green)
                        }

                        HStack(spacing: 4) {
                            Text("-\(String(format: "%.1f", viewModel.savedPercent))%")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(.green)

                            Text("· \(viewModel.results.count)\(locStr("张图片已压缩"))")
                                .font(.system(size: 11, design: .rounded))
                                .foregroundStyle(.tertiary)
                        }
                    }

                    Spacer()
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.green.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.green.opacity(0.12), lineWidth: 1)
                )
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.compressionComplete)
        }
    }
}
