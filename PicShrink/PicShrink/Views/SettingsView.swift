import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appLanguage") private var appLanguage: String = "system"
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
            .padding(.bottom, 12)

            Divider()

            ScrollView {
                VStack(spacing: 0) {
                    settingsSection {
                        SettingToggleRow(label: locStr("保留 EXIF"), isOn: $preserveEXIF, icon: "camera.metering.unknown")
                        SettingDivider()
                        SettingToggleRow(label: locStr("压缩后自动打开文件夹"), isOn: $autoOpenFolder, icon: "folder")
                    }

                    sectionSpacer

                    settingsSection {
                        SettingPickerRow(
                            label: locStr("语言"),
                            icon: "globe",
                            selection: $appLanguage,
                            options: Language.allCases.map { ($0.displayName, $0.rawValue) }
                        )
                    }

                    sectionSpacer

                    VStack(spacing: 12) {
                        Text("PicShrink v1.0")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)

                        Button(locStr("完成")) {
                            dismiss()
                        }
                        .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(.tint.opacity(0.1))
                        )
                        .foregroundStyle(.tint)
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .frame(width: 340, height: 310)
    }

    private var sectionSpacer: some View {
        Spacer().frame(height: 12)
    }

    private func settingsSection<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.fill.quinary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(.separator.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
}

private struct SettingDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 44)
    }
}

private struct SettingToggleRow: View {
    let label: String
    @Binding var isOn: Bool
    let icon: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(width: 18)

            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))

            Spacer()

            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
                .controlSize(.small)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

private struct SettingPickerRow: View {
    let label: String
    let icon: String
    @Binding var selection: String
    let options: [(String, String)]

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(width: 18)

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
            .frame(width: 120)
            .font(.system(size: 12, design: .rounded))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}
