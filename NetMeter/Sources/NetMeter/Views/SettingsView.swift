import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: NetMeterViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    menuBarSection
                    trafficAlertSection
                    generalSection
                }
                .padding(20)
            }

            Divider()

            doneButton
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
        }
        .frame(width: 360)
        .background(Color(.windowBackgroundColor))
    }

    private var header: some View {
        HStack {
            Text(locStr("设置"))
                .font(.system(size: 16, weight: .bold, design: .rounded))
            Spacer()
        }
    }

    private var menuBarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(locStr("菜单栏显示"))

            HStack(spacing: 8) {
                ForEach(MenuBarDisplayMode.allCases, id: \.rawValue) { mode in
                    let isSelected = viewModel.displayMode == mode
                    Button {
                        viewModel.setDisplayMode(mode)
                    } label: {
                        Text(mode.displayName)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(isSelected ? Color.accentColor : Color(.controlBackgroundColor))
                            )
                            .foregroundColor(isSelected ? .white : .primary)
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack {
                Text(locStr("刷新频率"))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                Spacer()
                Picker("", selection: Binding(
                    get: { viewModel.refreshInterval },
                    set: { viewModel.setRefreshInterval($0) }
                )) {
                    Text("0.5 \(locStr("秒"))").tag(0.5)
                    Text("1 \(locStr("秒"))").tag(1.0)
                    Text("2 \(locStr("秒"))").tag(2.0)
                    Text("5 \(locStr("秒"))").tag(5.0)
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(width: 100)
            }
        }
    }

    private var trafficAlertSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(locStr("流量提醒"))

            HStack {
                Text(locStr("月流量上限"))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                Spacer()
                Toggle("", isOn: Binding(
                    get: { viewModel.monthlyLimitEnabled },
                    set: { viewModel.setMonthlyLimitEnabled($0) }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
            }

            if viewModel.monthlyLimitEnabled {
                HStack {
                    Text("\(Int(viewModel.monthlyLimitGB)) \(locStr("GB"))")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(.secondary)
                    Spacer()
                    Slider(value: Binding(
                        get: { viewModel.monthlyLimitGB },
                        set: { viewModel.setMonthlyLimitGB($0) }
                    ), in: 10...1000, step: 10)
                        .frame(width: 160)
                }

                HStack {
                    Text(locStr("达到 80% 时通知"))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { viewModel.notifyAt80 },
                        set: { viewModel.setNotifyAt80($0) }
                    ))
                    .toggleStyle(.switch)
                    .labelsHidden()
                }
            }
        }
    }

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(locStr("关于"))

            HStack {
                Text(locStr("开机自启"))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                Spacer()
                Toggle("", isOn: Binding(
                    get: { viewModel.launchAtLogin },
                    set: { viewModel.setLaunchAtLogin($0) }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
            }

            HStack {
                Text(locStr("外观"))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                Spacer()
                Picker("", selection: Binding(
                    get: { viewModel.appearance },
                    set: { viewModel.setAppearance($0) }
                )) {
                    ForEach(AppearanceMode.allCases, id: \.rawValue) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(width: 120)
            }

            HStack {
                Text(locStr("语言 Language 言語"))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                Spacer()
                Picker("", selection: Binding(
                    get: { viewModel.appLanguage },
                    set: { viewModel.setLanguage($0) }
                )) {
                    ForEach(Language.allCases, id: \.rawValue) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(width: 120)
            }

            HStack {
                Text(locStr("版本"))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                Spacer()
                Text("1.0.0")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
    }

    private var doneButton: some View {
        HStack {
            Spacer()
            Button {
                dismiss()
            } label: {
                Text(locStr("完成"))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.accentColor)
                    )
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.defaultAction)
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundColor(.secondary)
            .textCase(.uppercase)
    }
}
