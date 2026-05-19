import SwiftUI

struct CompressionResultView: View {
    let viewModel: CompressionViewModel

    var body: some View {
        if viewModel.compressionComplete {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(.green.opacity(0.15))
                        .frame(width: 26, height: 26)
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.green)
                }

                HStack(spacing: 3) {
                    Text(viewModel.formattedOriginalSize)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .strikethrough()
                        .foregroundStyle(.secondary)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.green)

                    Text(viewModel.formattedCompressedSize)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(.green)
                }

                Text("-\(String(format: "%.1f", viewModel.savedPercent))%")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(.green.opacity(0.12)))

                Spacer()
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.green.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.green.opacity(0.1), lineWidth: 1)
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.compressionComplete)
        }
    }
}
