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
            HStack {
                Text(locStr("设置"))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 14)

            Divider()
                .padding(.horizontal, 20)

            ScrollView {
                VStack(spacing: 0) {
                    Group {
                        SettingPickerRow(
                            label: locStr("输出格式"),
                            selection: $outputFormatSetting,
                            options: [
                                ("JPEG", "jpeg"),
                                ("WebP", "webp"),
                                ("PNG", "png"),
                            ]
                        )

                        SettingToggleRow(label: locStr("保留 EXIF"), isOn: $preserveEXIF)

                        SettingToggleRow(label: locStr("压缩后自动打开文件夹"), isOn: $autoOpenFolder)
                    }

                    Divider()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 4)

                    Group {
                        SettingPickerRow(
                            label: locStr("外观"),
                            selection: $appearance,
                            options: [
                                (locStr("跟随系统"), "system"),
                                (locStr("浅色"), "light"),
                                (locStr("深色"), "dark"),
                            ]
                        )

                        SettingPickerRow(
                            label: locStr("语言 Language 言語"),
                            selection: $appLanguage,
                            options: Language.allCases.map { ($0.displayName, $0.rawValue) }
                        )
                    }

                    Divider()
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)

                    VStack(spacing: 8) {
                        Text("PicShrink v1.0")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.bottom, 16)

                    Button(locStr("完成")) {
                        dismiss()
                    }
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .fill(.blue.opacity(0.1))
                    )
                    .foregroundStyle(.blue)
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .frame(width: 340, height: 400)
    }
}

private struct SettingToggleRow: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}

private struct SettingPickerRow: View {
    let label: String
    @Binding var selection: String
    let options: [(String, String)]

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
            Spacer()
            Picker("", selection: $selection) {
                ForEach(options, id: \.1) { name, value in
                    Text(name).tag(value)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(width: 130)
            .font(.system(size: 12, design: .rounded))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
}
