import SwiftUI

struct SettingsView: View {
    @ObservedObject var timerManager: TimerManager

    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("notificationEnabled") private var notificationEnabled = true
    @AppStorage("workDuration") private var workDuration = 25
    @AppStorage("breakDuration") private var breakDuration = 5
    @AppStorage("appearance") private var appearance: String = "system"
    @AppStorage("appLanguage") private var appLanguage: String = "system"

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
                .padding(.horizontal, 12)

            ScrollView {
                VStack(spacing: 16) {
                    appearanceSection
                    Divider()
                        .padding(.horizontal, 4)
                    languageSection
                    Divider()
                        .padding(.horizontal, 4)
                    notificationSection
                    Divider()
                        .padding(.horizontal, 4)
                    pomodoroSettingsSection
                    Divider()
                        .padding(.horizontal, 4)
                    aboutSection
                }
                .padding(14)
            }
        }
        .frame(width: 270, height: 370)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(.separatorColor).opacity(0.1), lineWidth: 1)
        )
    }

    private var headerView: some View {
        HStack {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 13))
                .foregroundStyle(.orange.gradient)
            Text(locStr("设置"))
                .font(.system(size: 13, weight: .semibold, design: .rounded))
            Spacer()
            Button(action: { timerManager.showSettings = false }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
                    .opacity(0.7)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(locStr("外观"), icon: "circle.lefthalf.filled")

            HStack(spacing: 8) {
                appearanceButton("system", icon: "gearshape", label: locStr("跟随系统"))
                appearanceButton("light", icon: "sun.max.fill", label: locStr("浅色"))
                appearanceButton("dark", icon: "moon.fill", label: locStr("深色"))
            }
        }
    }

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(locStr("语言"), icon: "globe")

            HStack(spacing: 8) {
                langButton("zh-Hans", label: "中文")
                langButton("en", label: "English")
            }
        }
    }

    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(locStr("通知"), icon: "bell.fill")

            Toggle(isOn: $notificationEnabled) {
                Text(locStr("通知中心提醒"))
                    .font(.system(size: 12, design: .rounded))
            }
            .toggleStyle(.switch)
            .controlSize(.small)

            Toggle(isOn: $soundEnabled) {
                Text(locStr("播放提示音"))
                    .font(.system(size: 12, design: .rounded))
            }
            .toggleStyle(.switch)
            .controlSize(.small)
        }
    }

    private var pomodoroSettingsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(locStr("番茄钟"), icon: "flame.fill")

            HStack {
                Text(locStr("工作时长"))
                    .font(.system(size: 12, design: .rounded))
                Spacer()
                Picker("", selection: $workDuration) {
                    ForEach([15, 20, 25, 30, 45, 60], id: \.self) { min in
                        Text("\(min)\(locStr(" 分钟"))").tag(min)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 110)
            }

            HStack {
                Text(locStr("休息时长"))
                    .font(.system(size: 12, design: .rounded))
                Spacer()
                Picker("", selection: $breakDuration) {
                    ForEach([5, 10, 15, 20, 30], id: \.self) { min in
                        Text("\(min)\(locStr(" 分钟"))").tag(min)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 110)
            }
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionHeader(locStr("关于"), icon: "info.circle.fill")

            HStack {
                Text(locStr("版本"))
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.secondary)
                Spacer()
                Text("1.0.0")
                    .font(.system(size: 12, design: .rounded))
            }

            Text(locStr("MenuTimer — 菜单栏极简倒计时器"))
                .font(.system(size: 11, design: .rounded))
                .foregroundColor(.secondary)
        }
    }

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(.orange.gradient)
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
        }
    }

    private func appearanceButton(_ mode: String, icon: String, label: String) -> some View {
        let isActive = appearance == mode
        return Button(action: { appearance = mode }) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isActive ? .orange : .secondary)
                Text(label)
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(isActive ? .orange : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isActive ? Color.orange.opacity(0.1) : Color(.controlBackgroundColor).opacity(0.35))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(isActive ? Color.orange.opacity(0.3) : Color(.separatorColor).opacity(0.08), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private func langButton(_ lang: String, label: String) -> some View {
        let isSelected = appLanguage == lang || (appLanguage == "system" && lang == "zh-Hans")
        return Button(action: { appLanguage = lang }) {
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(isSelected ? .white : .primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(
                    backgroundForLang(isSelected)
                        .shadow(color: isSelected ? .orange.opacity(0.3) : .clear, radius: 6, y: 2)
                )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func backgroundForLang(_ selected: Bool) -> some View {
        if selected {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.orange)
        } else {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(.controlBackgroundColor).opacity(0.35))
        }
    }
}
