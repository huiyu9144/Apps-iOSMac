import SwiftUI

struct MenuBarPopoverView: View {
    @Bindable var viewModel: CompressionViewModel
    @AppStorage("preserveEXIF") private var preserveEXIF: Bool = true
    @AppStorage("autoOpenFolder") private var autoOpenFolder: Bool = true
    @State private var showSettings = false
    @State private var isHoveringSettings = false

    var body: some View {
        VStack(spacing: 0) {
            headerRow
            contentArea
            bottomBar
        }
        .frame(width: 360)
        .background(Color.white)
        .clipShape(.rect(cornerRadius: 14))
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onAppear { syncSettingsToViewModel() }
    }

    private var headerRow: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "photo.badge.arrow.down")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.blue)

                Text("PicShrink")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }

            Spacer()

            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isHoveringSettings ? .primary : .secondary)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(isHoveringSettings ? Color(.separatorColor).opacity(0.12) : .clear)
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onHover { isHoveringSettings = $0 }
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    private var contentArea: some View {
        VStack(spacing: 12) {
            fileSelectorSection
            qualitySection
            compressButton
            if viewModel.isCompressing { progressSection }
            CompressionResultView(viewModel: viewModel)
        }
        .padding(.horizontal, 16)
        .padding(.top, 2)
        .padding(.bottom, 10)
    }

    private var fileSelectorSection: some View {
        Button(action: { viewModel.selectFilesFromPanel() }) {
            Group {
                if viewModel.selectedURLs.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "plus.viewfinder")
                            .font(.system(size: 22, weight: .light))
                            .foregroundStyle(.tertiary)
                        Text(locStr("选择文件/文件夹"))
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 26)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(
                                style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                            )
                            .foregroundStyle(.quaternary)
                    )
                } else {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(.tint.opacity(0.1))
                                .frame(width: 32, height: 32)
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.tint)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(viewModel.selectedFileCount)\(locStr("张图片"))")
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
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(.tint.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(.tint.opacity(0.1), lineWidth: 1)
                    )
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var qualitySection: some View {
        HStack(spacing: 0) {
            ForEach(CompressionQuality.allCases, id: \.rawValue) { q in
                qualityButton(for: q)
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(.fill.quaternary.opacity(0.35))
        )
    }

    private func qualityButton(for q: CompressionQuality) -> some View {
        Button(action: {
            withAnimation(.interactiveSpring(response: 0.25, dampingFraction: 0.8)) {
                viewModel.quality = q
            }
        }) {
            Text(q.displayName)
                .font(.system(size: 11.5,
                              weight: viewModel.quality == q ? .semibold : .regular,
                              design: .rounded))
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .foregroundStyle(viewModel.quality == q ? .white : .secondary)
                .background(qualityBackground(for: q))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func qualityBackground(for q: CompressionQuality) -> some View {
        if viewModel.quality == q {
            Capsule()
                .fill(.tint)
                .shadow(color: Color(.controlAccentColor).opacity(0.25), radius: 4, y: 1)
        } else {
            EmptyView()
        }
    }

    private var compressButton: some View {
        Button(action: {
            if viewModel.isCompressing {
                viewModel.cancelCompression()
            } else {
                syncSettingsToViewModel()
                viewModel.startCompression()
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: viewModel.isCompressing ? "xmark" : "arrow.down")
                    .font(.system(size: 12, weight: .semibold))
                Text(viewModel.isCompressing ? locStr("取消压缩") : locStr("压缩并导出"))
                    .font(.system(size: 12.5, weight: .semibold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(viewModel.isCompressing ? Color.red : Color.blue)
                    .shadow(color: (viewModel.isCompressing ? Color.red : Color.blue).opacity(0.25),
                            radius: 6, y: 2)
            )
            .foregroundStyle(.white)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .scaleEffect(viewModel.isCompressing ? 0.97 : 1)
        .animation(.interactiveSpring(response: 0.2, dampingFraction: 0.8), value: viewModel.isCompressing)
    }

    private var progressSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    DotPulsingView()
                    Text(locStr("正在压缩..."))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                }
                .foregroundStyle(.secondary)

                Spacer()

                Text("\(viewModel.currentFileIndex)/\(viewModel.totalFiles)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.tint)
                    .contentTransition(.numericText())
            }

            ProgressView(value: viewModel.progress)
                .tint(.blue)

            if !viewModel.currentFileName.isEmpty {
                Text(viewModel.currentFileName)
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.blue.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.blue.opacity(0.08), lineWidth: 1)
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var bottomBar: some View {
        HStack {
            Button(action: { NSApplication.shared.terminate(nil) }) {
                Text(locStr("退出应用"))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    private func syncSettingsToViewModel() {
        viewModel.preserveEXIF = preserveEXIF
        viewModel.autoOpenFolder = autoOpenFolder
    }
}

extension CompressionQuality {
    var displayName: String {
        switch self {
        case .lossless: return locStr("最佳画质")
        case .high: return locStr("高质量")
        case .medium: return locStr("中等质量")
        case .low: return locStr("最小体积")
        }
    }
}

struct DotPulsingView: View {
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 1.0

    var body: some View {
        Circle()
            .fill(.blue)
            .frame(width: 7, height: 7)
            .opacity(opacity)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 0.6).repeatForever(autoreverses: true)
                ) {
                    opacity = 0.4
                    scale = 0.6
                }
            }
    }
}
