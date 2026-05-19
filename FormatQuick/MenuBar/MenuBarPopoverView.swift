import SwiftUI
import UniformTypeIdentifiers

struct MenuBarPopoverView: View {
    @State var viewModel: FormatQuickViewModel
    @State private var isDropTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            Divider()

            VStack(spacing: 14) {
                imageSelectionArea

                formatSection

                optionsSection

                convertButtonSection
            }
            .padding(16)

            if viewModel.isConverting || viewModel.progress > 0 {
                Divider()
                progressSection
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }

            Spacer(minLength: 0)

            Divider()

            bottomBar
        }
        .frame(width: 380)
        .background(.ultraThinMaterial)
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers: providers)
            return true
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.swap")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.purple.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 5))

                Text("FormatQuick")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }

            Spacer()

            Button {
                NotificationCenter.default.post(name: .openSettings, object: nil)
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Unified Image Selection Area

    private var imageSelectionArea: some View {
        Group {
            if viewModel.imageFiles.isEmpty {
                emptySelectionArea
            } else {
                fileInfoCard
            }
        }
    }

    private var emptySelectionArea: some View {
        Button {
            openFilePicker()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: "photo.badge.plus")
                    .font(.system(size: 24))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isDropTargeted ? .blue : .secondary)

                Text(locStr("选择图片"))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(isDropTargeted ? .blue : .secondary)

                Text(locStr("或拖拽到此处"))
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        isDropTargeted ? Color.blue : Color.secondary.opacity(0.25),
                        style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                    )
            )
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isDropTargeted ? Color.blue.opacity(0.06) : .clear)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var fileInfoCard: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 28, height: 28)

                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 13))
                        .foregroundStyle(.blue)
                }

                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 4) {
                        Text("\(viewModel.imageFiles.count)")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.primary)
                            .contentTransition(.numericText())

                        Text(locStr("个"))
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .foregroundStyle(.secondary)
                    }

                    if !viewModel.totalSizeLabel.isEmpty {
                        Text(viewModel.totalSizeLabel)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()

            Button {
                withAnimation(.easeOut(duration: 0.2)) {
                    viewModel.clearImages()
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary.opacity(0.5))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.controlBackgroundColor).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.separator.opacity(0.15), lineWidth: 0.5)
        )
        .onTapGesture { openFilePicker() }
    }

    // MARK: - Format Section

    private var formatSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(locStr("格式").uppercased())
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .tracking(1)
                .foregroundStyle(.tertiary)
                .padding(.leading, 2)

            HStack(spacing: 4) {
                ForEach(ImageFormat.allCases) { format in
                    FormatButton(
                        format: format,
                        isSelected: viewModel.selectedFormat == format,
                        action: { viewModel.selectFormat(format) }
                    )
                }
            }
        }
    }

    // MARK: - Options Section

    private var optionsSection: some View {
        VStack(spacing: 0) {
            sectionHeader(locStr("选项"))
                .padding(.horizontal, 12)
                .padding(.top, 10)
                .padding(.bottom, 4)

            qualityRow
            Divider().padding(.leading, 44)
            resizeRow
            Divider().padding(.leading, 44)
            exifRow
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.controlBackgroundColor).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.separator.opacity(0.15), lineWidth: 0.5)
        )
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .tracking(1)
                .foregroundStyle(.tertiary)
            Spacer()
        }
    }

    private var qualityRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "dial.low.fill")
                .font(.system(size: 12))
                .foregroundStyle(.blue)
                .frame(width: 20, height: 20)

            Text(locStr("质量"))
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(.primary)

            Spacer()

            Slider(value: $viewModel.quality, in: 0.01...1.0)
                .controlSize(.small)
                .tint(.blue)
                .frame(width: 120)

            Text("\(Int(viewModel.quality * 100))%")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(.blue)
                .frame(width: 34, alignment: .trailing)
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var resizeRow: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 12))
                    .foregroundStyle(.blue)
                    .frame(width: 20, height: 20)

                Text(locStr("调整尺寸"))
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(.primary)

                Spacer()

                Toggle("", isOn: $viewModel.resizeEnabled)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .labelsHidden()
                    .tint(.blue)

                HStack(spacing: 3) {
                    TextField("W", value: $viewModel.resizeWidth, format: .number)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .frame(width: 42, height: 22)
                        .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 5))
                        .disabled(!viewModel.resizeEnabled)
                        .monospacedDigit()

                    Text("×")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.tertiary)

                    TextField("H", value: $viewModel.resizeHeight, format: .number)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .frame(width: 42, height: 22)
                        .background(.quaternary.opacity(0.15), in: RoundedRectangle(cornerRadius: 5))
                        .disabled(!viewModel.resizeEnabled)
                        .monospacedDigit()
                }
                .opacity(viewModel.resizeEnabled ? 1 : 0.35)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            if viewModel.resizeEnabled {
                Picker("", selection: $viewModel.resizeMode) {
                    ForEach(ResizeMode.allCases, id: \.self) { mode in
                        Text(locStr(mode.rawValue)).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
            }
        }
    }

    private var exifRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "camera.metering.unknown")
                .font(.system(size: 12))
                .foregroundStyle(.blue)
                .frame(width: 20, height: 20)

            Text(locStr("保留照片信息"))
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(.primary)

            Spacer()

            Toggle("", isOn: $viewModel.keepExif)
                .toggleStyle(.switch)
                .controlSize(.small)
                .labelsHidden()
                .tint(.blue)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Convert Button

    private var convertButtonSection: some View {
        VStack(spacing: 5) {
            if !viewModel.isConverting && !viewModel.imageFiles.isEmpty && !viewModel.totalSizeLabel.isEmpty {
                HStack(spacing: 4) {
                    Spacer()
                    Text(viewModel.totalSizeLabel)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }
            }

            Button {
                Task { await viewModel.startConversion() }
            } label: {
                HStack(spacing: 6) {
                    if viewModel.isConverting {
                        ProgressView()
                            .scaleEffect(0.7)
                            .frame(width: 14, height: 14)
                    } else {
                        Image(systemName: "arrow.triangle.swap")
                            .font(.system(size: 12, weight: .semibold))
                    }

                    Text(viewModel.isConverting ? locStr("转换中") : locStr("开始转换"))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))

                    if !viewModel.isConverting && !viewModel.imageFiles.isEmpty {
                        Text("· \(viewModel.durationLabel)")
                            .font(.system(size: 10, weight: .regular, design: .rounded))
                            .opacity(0.7)
                    }
                }
                .foregroundStyle(viewModel.isConverting || viewModel.imageFiles.isEmpty ? .blue : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(
                            viewModel.isConverting
                                ? Color.blue.opacity(0.08)
                                : viewModel.imageFiles.isEmpty
                                    ? Color.blue.opacity(0.08)
                                    : Color.blue
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(.separator.opacity(viewModel.imageFiles.isEmpty ? 0.3 : 0), lineWidth: 0.5)
                )
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(viewModel.isConverting || viewModel.imageFiles.isEmpty)
        }
        .opacity(viewModel.imageFiles.isEmpty ? 0.6 : 1)
    }

    // MARK: - Progress

    private var progressSection: some View {
        VStack(spacing: 5) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.quaternary.opacity(0.3))
                        .frame(height: 3)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(.blue)
                        .frame(width: max(geometry.size.width * viewModel.progress, 3), height: 3)
                }
            }
            .frame(height: 3)

            HStack {
                if !viewModel.currentFileName.isEmpty {
                    Text(viewModel.currentFileName)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Text("\(Int(viewModel.progress * 100))%")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.blue)
            }
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            Text("FormatQuick")
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(.quaternary)

            Spacer()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Text(locStr("退出应用"))
                    .font(.system(size: 9, weight: .regular, design: .rounded))
                    .foregroundStyle(.quaternary)
            }
            .buttonStyle(.plain)
        }
        .frame(height: 24)
        .padding(.horizontal, 14)
    }

    // MARK: - Helpers

    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                guard let url = url else { return }
                Task { @MainActor in
                    var isDirectory: ObjCBool = false
                    FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
                    if isDirectory.boolValue {
                        viewModel.addFolder(url)
                    } else {
                        viewModel.addImages([url])
                    }
                }
            }
        }
    }

    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowedContentTypes = [
            .jpeg, .png, .heic, .webP, .gif, .tiff, .bmp
        ]
        panel.message = locStr("选择图片")

        if panel.runModal() == .OK {
            for url in panel.urls {
                var isDirectory: ObjCBool = false
                FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
                if isDirectory.boolValue {
                    viewModel.addFolder(url)
                } else {
                    viewModel.addImages([url])
                }
            }
        }
    }
}

// MARK: - FormatButton

struct FormatButton: View {
    let format: ImageFormat
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(format.rawValue)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? .white : .secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isSelected ? Color.blue : Color.secondary.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(.separator.opacity(isSelected ? 0 : 0.15), lineWidth: 0.5)
                )
        }
        .buttonStyle(ScaleButtonStyle())
        .shadow(color: isSelected ? .blue.opacity(0.2) : .clear, radius: 4, y: 2)
    }
}

// MARK: - ScaleButtonStyle

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
