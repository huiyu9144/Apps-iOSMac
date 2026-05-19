import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appLanguage") private var appLanguage: String = "system"
    @AppStorage("appearance") private var appearance: String = "system"
    @AppStorage("outputFormat") private var outputFormatSetting: String = "jpeg"
    @AppStorage("preserveEXIF") private var preserveEXIF: Bool = true
    @AppStorage("autoOpenFolder") private var autoOpenFolder: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            Text(locStr("设置"))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .padding(.top, 16)
                .padding(.bottom, 12)

            Divider()
                .padding(.horizontal, 18)

            VStack(spacing: 14) {
                settingRow(label: locStr("输出格式")) {
                    Picker("", selection: $outputFormatSetting) {
                        Text("JPEG").tag("jpeg")
                        Text("WebP").tag("webp")
                        Text("PNG").tag("png")
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 120)
                }

                settingRow(label: locStr("保留 EXIF")) {
                    Toggle("", isOn: $preserveEXIF)
                        .toggleStyle(.switch)
                }

                settingRow(label: locStr("压缩后自动打开文件夹")) {
                    Toggle("", isOn: $autoOpenFolder)
                        .toggleStyle(.switch)
                }

                Divider()
                    .padding(.horizontal, -18)

                settingRow(label: locStr("外观")) {
                    Picker("", selection: $appearance) {
                        Text(locStr("跟随系统")).tag("system")
                        Text(locStr("浅色")).tag("light")
                        Text(locStr("深色")).tag("dark")
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 120)
                }

                settingRow(label: locStr("语言 Language 言語")) {
                    Picker("", selection: $appLanguage) {
                        ForEach(Language.allCases, id: \.rawValue) { lang in
                            Text(lang.displayName).tag(lang.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(width: 120)
                }

                Divider()
                    .padding(.horizontal, -18)

                VStack(spacing: 10) {
                    Text("PicShrink v1.0")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.tertiary)

                    Divider()
                        .padding(.horizontal, -18)

                    Button(locStr("完成")) {
                        dismiss()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color(.controlBackgroundColor)))
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 16)
        }
        .frame(width: 340)
    }

    private func settingRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
            Spacer()
            content()
        }
    }
}

enum AppearanceMode: String, CaseIterable {
    case system
    case light
    case dark
}
