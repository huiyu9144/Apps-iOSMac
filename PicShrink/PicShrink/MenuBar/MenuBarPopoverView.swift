import SwiftUI

struct MenuBarPopoverView: View {
    @Bindable var viewModel: CompressionViewModel
    @AppStorage("outputFormat") private var outputFormatSetting: String = "jpeg"
    @AppStorage("preserveEXIF") private var preserveEXIF: Bool = true
    @AppStorage("autoOpenFolder") private var autoOpenFolder: Bool = true
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            headerRow

            contentArea

            quitButton
        }
        .frame(width: 360)
        .background(Color(.controlBackgroundColor))
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onAppear { syncSettingsToViewModel() }
    }

    private var headerRow: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(.blue.opacity(0.12))
                    .frame(width: 30, height: 30)
                Image(systemName: "arrow.down.to.line.compact")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.blue)
            }

            Text("PicShrink")
                .font(.system(size: 14, weight: .bold, design: .rounded))

            Spacer()

            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(.clear))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    private var contentArea: some View {
        ScrollView {
            VStack(spacing: 16) {
                fileSelectorSection
                qualitySection
                compressButton
                if viewModel.isCompressing { progressSection }
                CompressionResultView(viewModel: viewModel)
                formatSection
            }
            .padding(.horizontal, 18)
            .padding(.top, 4)
            .padding(.bottom, 12)
        }
    }

    private var fileSelectorSection: some View {
        Group {
            if viewModel.selectedURLs.isEmpty {
                emptyFileSelector
            } else {
                activeFileSelector
            }
        }
    }

    private var emptyFileSelector: some View {
        Button(action: { viewModel.selectFilesFromPanel() }) {
            VStack(spacing: 10) {
                Image(systemName: "square.and.arrow.down.on.square")
                    .font(.system(size: 26, weight: .light))
                    .foregroundStyle(.secondary)

                Text(locStr("选择文件/文件夹"))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)

                Text("PNG · JPG · WebP · HEIC")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    .foregroundStyle(.secondary.opacity(0.2))
            )
        }
        .buttonStyle(.plain)
    }

    private var activeFileSelector: some View {
        Button(action: { viewModel.selectFilesFromPanel() }) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(.blue.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: "photo.stack.fill")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.blue)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("\(viewModel.selectedFileCount)\(locStr("张图片"))")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))

                    Text(viewModel.formattedOriginalSize)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(.blue.opacity(0.75))
                }

                Spacer()

                Image(systemName: "pencil.circle")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.blue.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(.blue.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var qualitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(locStr("压缩后质量"))

            HStack(spacing: 0) {
                ForEach(CompressionQuality.allCases, id: \.rawValue) { q in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) { viewModel.quality = q }
                    }) {
                        Text(q.displayName)
                            .font(.system(size: 12, weight: viewModel.quality == q ? .semibold : .medium, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .foregroundStyle(viewModel.quality == q ? .white : .secondary)
                            .background(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(viewModel.quality == q ? .blue : .clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.black.opacity(0.04))
            )
        }
    }

    private var formatSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(locStr("输出格式"))

            HStack(spacing: 0) {
                ForEach(OutputFormat.allCases, id: \.rawValue) { fmt in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            outputFormatSetting = fmt.rawValue
                            viewModel.outputFormat = fmt
                        }
                    }) {
                        Text(fmt.fileExtension.uppercased())
                            .font(.system(size: 12, weight: viewModel.outputFormat == fmt ? .bold : .medium, design: .monospaced))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .foregroundStyle(viewModel.outputFormat == fmt ? .blue : .secondary)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(viewModel.outputFormat == fmt ? .blue.opacity(0.08) : .clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.black.opacity(0.04))
            )
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
            HStack(spacing: 8) {
                Image(systemName: viewModel.isCompressing ? "xmark" : "arrow.down.circle.fill")
                    .font(.system(size: 15, weight: .semibold))

                Text(viewModel.isCompressing ? locStr("取消压缩") : locStr("压缩并导出"))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(viewModel.isCompressing ? Color.red : Color.blue)
            )
            .foregroundStyle(.white)
            .shadow(color: (viewModel.isCompressing ? Color.red : Color.blue).opacity(0.2), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .scaleEffect(viewModel.isCompressing ? 0.98 : 1)
        .animation(.easeInOut(duration: 0.15), value: viewModel.isCompressing)
    }

    private var progressSection: some View {
        VStack(spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 16, height: 16)
                    Text(locStr("正在压缩..."))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                }
                .foregroundStyle(.secondary)

                Spacer()

                Text("\(viewModel.currentFileIndex)/\(viewModel.totalFiles)")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.blue)
                    .contentTransition(.numericText())
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(.secondary.opacity(0.1))
                        .frame(height: 5)

                    Capsule(style: .continuous)
                        .fill(LinearGradient(colors: [.blue, .blue.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(5, geo.size.width * viewModel.progress), height: 5)
                }
            }
            .frame(height: 5)
            .animation(.easeInOut(duration: 0.3), value: viewModel.progress)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.blue.opacity(0.04))
        )
    }

    private var quitButton: some View {
        Button(action: { NSApplication.shared.terminate(nil) }) {
            Text(locStr("退出应用"))
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundStyle(.tertiary)
            .textCase(.uppercase)
            .tracking(0.5)
    }

    private func syncSettingsToViewModel() {
        viewModel.preserveEXIF = preserveEXIF
        viewModel.autoOpenFolder = autoOpenFolder
        viewModel.outputFormat = OutputFormat(rawValue: outputFormatSetting) ?? .jpeg
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
