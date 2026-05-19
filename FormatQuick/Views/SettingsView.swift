import SwiftUI

struct SettingsView: View {
    @State var viewModel: FormatQuickViewModel
    @AppStorage("appLanguage") private var appLanguage: String = "system"

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    languagePicker
                } header: {
                    Text(locStr("通用"))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                }

                Section {
                    outputDirectoryPicker
                    openFolderToggle
                } header: {
                    Text(locStr("输出"))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                }

                Section {
                    aboutSection
                } header: {
                    Text(locStr("关于"))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                }
            }
            .formStyle(.grouped)

            Spacer()

            Divider()

            HStack {
                Text("FormatQuick")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                Text(locStr("版本") + " 1.0.0")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .frame(width: 400, height: 480)
        .background(.ultraThinMaterial)
    }

    private var languagePicker: some View {
        HStack {
            Text(locStr("语言 Language 言語"))
                .font(.system(size: 13, weight: .regular, design: .rounded))

            Spacer()

            Picker("", selection: $appLanguage) {
                ForEach(Language.allCases, id: \.rawValue) { lang in
                    Text(lang.displayName).tag(lang.rawValue)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 130)
            .onChange(of: appLanguage) { _, _ in
                if let delegate = NSApp.delegate as? AppDelegate {
                    DispatchQueue.main.async {
                        delegate.rebuildPopoverContent()
                    }
                }
            }
        }
    }

    private var outputDirectoryPicker: some View {
        HStack {
            Text(locStr("输出目录"))
                .font(.system(size: 13, weight: .regular, design: .rounded))

            Spacer()

            Picker("", selection: $viewModel.outputDirectory) {
                ForEach(OutputDirectory.allCases) { dir in
                    Text(locStr(dir.displayKey)).tag(dir)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 130)
            .onChange(of: viewModel.outputDirectory) { _, newValue in
                if newValue == .custom {
                    selectCustomFolder()
                }
                viewModel.saveSettings()
            }
        }
    }

    private var openFolderToggle: some View {
        HStack {
            Text(locStr("转换后打开文件夹"))
                .font(.system(size: 13, weight: .regular, design: .rounded))

            Spacer()

            Toggle("", isOn: $viewModel.openFolderAfterConvert)
                .toggleStyle(.switch)
                .labelsHidden()
                .onChange(of: viewModel.openFolderAfterConvert) { _, _ in
                    viewModel.saveSettings()
                }
        }
    }

    private var aboutSection: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.purple.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)

                Image(systemName: "arrow.triangle.swap")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
            }

            Text("FormatQuick")
                .font(.system(size: 16, weight: .bold, design: .rounded))

            Text(locStr("版本") + " 1.0.0" + " (1)")
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(.secondary)

            Text("macOS 菜单栏批量图片格式转换工具")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func selectCustomFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.prompt = locStr("选择")

        if panel.runModal() == .OK, let url = panel.url {
            UserDefaults.standard.set(url.path, forKey: "customOutputPath")
            viewModel.saveSettings()
        }
    }
}
