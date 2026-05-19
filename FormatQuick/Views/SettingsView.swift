import SwiftUI

struct SettingsView: View {
    @State var viewModel: FormatQuickViewModel
    @AppStorage("appLanguage") private var appLanguage: String = "system"
    @AppStorage("appearance") private var appearance: String = "system"

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    languagePicker
                    appearancePicker
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
            .padding(.top, 8)

            Spacer()

            Divider()

            HStack {
                Text("FormatQuick")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                Text(locStr("版本") + " 1.0.0")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .frame(width: 400, height: 380)
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

    private var appearancePicker: some View {
        HStack {
            Text(locStr("外观"))
                .font(.system(size: 13, weight: .regular, design: .rounded))

            Spacer()

            Picker("", selection: $appearance) {
                Text(locStr("跟随系统")).tag("system")
                Text(locStr("浅色")).tag("light")
                Text(locStr("深色")).tag("dark")
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
            .onChange(of: appearance) { _, newValue in
                if let delegate = NSApp.delegate as? AppDelegate {
                    delegate.applyAppearance(newValue)
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
            Image(systemName: "arrow.triangle.swap")
                .font(.system(size: 22))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.purple.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text("FormatQuick")
                .font(.system(size: 16, weight: .bold, design: .rounded))

            Text(locStr("版本") + " 1.0.0" + " (1)")
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(.secondary)

            Text("macOS 菜单栏批量图片格式转换工具")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(.secondary)
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
