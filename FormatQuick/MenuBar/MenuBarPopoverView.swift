import SwiftUI
import UniformTypeIdentifiers

struct MenuBarPopoverView: View {
    @State var viewModel: FormatQuickViewModel

    var body: some View {
        VStack(spacing: 0) {
            headerSection

            Divider()

            VStack(spacing: 12) {
                dropZoneSection

                if !viewModel.imageFiles.isEmpty {
                    fileInfoSection
                }

                formatSection

                optionsSection

                convertButtonSection
            }
            .padding(16)

            if viewModel.isConverting || viewModel.progress > 0 {
                VStack(spacing: 0) {
                    Divider()
                    progressSection
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
            }

            Spacer(minLength: 0)

            Divider()

            quitSection
        }
        .frame(width: 380, height: 500)
    }

    private var headerSection: some View {
        HStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.swap")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 26, height: 26)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.purple.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

                Text("FormatQuick")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            }

            Spacer()

            Button {
                NotificationCenter.default.post(name: .openSettings, object: nil)
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary.opacity(0.5))
                    .frame(width: 26, height: 26)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var dropZoneSection: some View {
        DropZoneView(viewModel: viewModel)
    }

    private var fileInfoSection: some View {
        HStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "photo.on.rectangle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.blue)

                Text("\(viewModel.imageFiles.count) \(locStr("个"))")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
            }

            Spacer()

            Button {
                viewModel.clearImages()
            } label: {
                Text(locStr("清除"))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private var formatSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(locStr("格式").uppercased())
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)

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

    private var optionsSection: some View {
        VStack(spacing: 8) {
            qualityRow
            resizeRow
            exifRow
        }
    }

    private var qualityRow: some View {
        HStack(spacing: 10) {
            Text(locStr("质量"))
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(.primary)
                .frame(width: 56, alignment: .leading)

            Slider(value: $viewModel.quality, in: 0.01...1.0)
                .controlSize(.small)

            Text("\(Int(viewModel.quality * 100))%")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(.blue)
                .frame(width: 36, alignment: .trailing)
        }
    }

    private var resizeRow: some View {
        HStack(spacing: 10) {
            Text(locStr("调整尺寸"))
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(.primary)
                .frame(width: 56, alignment: .leading)

            Spacer()

            Toggle("", isOn: $viewModel.resizeEnabled)
                .toggleStyle(.switch)
                .controlSize(.small)
                .labelsHidden()

            HStack(spacing: 4) {
                TextField("W", value: $viewModel.resizeWidth, format: .number)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .frame(width: 52, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(Color(.controlBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .stroke(Color(.separatorColor).opacity(0.5), lineWidth: 0.8)
                            )
                    )
                    .disabled(!viewModel.resizeEnabled)

                Text("×")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)

                TextField("H", value: $viewModel.resizeHeight, format: .number)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .frame(width: 52, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(Color(.controlBackgroundColor))
                            .overlay(
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .stroke(Color(.separatorColor).opacity(0.5), lineWidth: 0.8)
                            )
                    )
                    .disabled(!viewModel.resizeEnabled)
            }
            .opacity(viewModel.resizeEnabled ? 1 : 0.35)
        }
    }

    private var exifRow: some View {
        HStack(spacing: 10) {
            Text(locStr("保留照片信息"))
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(.primary)
                .frame(width: 56, alignment: .leading)

            Spacer()

            Toggle("", isOn: $viewModel.keepExif)
                .toggleStyle(.switch)
                .controlSize(.small)
                .labelsHidden()
        }
    }

    private var convertButtonSection: some View {
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
                        .font(.system(size: 13, weight: .semibold))
                }

                Text(viewModel.isConverting ? locStr("转换中") : locStr("开始转换"))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))

                if !viewModel.isConverting {
                    Text("· \(viewModel.durationLabel)")
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .opacity(0.6)
                }
            }
            .foregroundColor(viewModel.isConverting ? .blue : .white)
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(viewModel.isConverting ? Color.blue.opacity(0.1) : Color.blue)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(viewModel.isConverting || viewModel.imageFiles.isEmpty)
    }

    private var progressSection: some View {
        VStack(spacing: 6) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color.blue.opacity(0.1))
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color.blue)
                        .frame(width: max(geometry.size.width * viewModel.progress, 4), height: 4)
                }
            }
            .frame(height: 4)

            HStack {
                if !viewModel.currentFileName.isEmpty {
                    Text(viewModel.currentFileName)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Text("\(Int(viewModel.progress * 100))%")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.blue)
            }
        }
    }

    private var quitSection: some View {
        HStack {
            Spacer()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Text(locStr("退出应用"))
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.4))
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .frame(height: 28)
    }
}

struct DropZoneView: View {
    @State var viewModel: FormatQuickViewModel
    @State private var isTargeted = false

    var body: some View {
        Button {
            openFilePicker()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: "photo.badge.plus")
                    .font(.system(size: 22))
                    .foregroundColor(.blue.opacity(0.5))

                Text(locStr("选择图片"))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.blue)

                Text(locStr("或拖拽到此处"))
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(
                        isTargeted ? Color.blue : Color(.separatorColor).opacity(0.15),
                        style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                    )
            )
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isTargeted ? Color.blue.opacity(0.04) : Color(.controlBackgroundColor).opacity(0.3))
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .onDrop(
            of: [.fileURL],
            isTargeted: $isTargeted
        ) { providers in
            handleDrop(providers: providers)
            return true
        }
    }

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
        panel.allowedContentTypes = [.png, .jpeg, .heic, .webP, .gif]
        if let avifType = UTType("public.avif") {
            panel.allowedContentTypes.append(avifType)
        }

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

struct FormatButton: View {
    let format: ImageFormat
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(format.rawValue)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(isSelected ? .white : .secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 26)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isSelected ? Color.blue : Color(.controlBackgroundColor).opacity(0.5))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(
                            isSelected ? Color.clear : Color(.separatorColor).opacity(0.2),
                            lineWidth: 0.8
                        )
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
