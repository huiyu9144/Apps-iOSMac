import SwiftUI

struct iOSFilledButton: ButtonStyle {
    var color: Color = .orange
    var isActive: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .frame(minWidth: 72)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color)
                    .opacity(configuration.isPressed ? 0.7 : 1)
            )
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.interactiveSpring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct iOSTintedButton: ButtonStyle {
    var color: Color = .gray
    var isActive: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundColor(isActive ? color : .secondary.opacity(0.4))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .frame(minWidth: 72)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color.opacity(configuration.isPressed ? 0.25 : 0.12))
            )
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.interactiveSpring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct LiquidPresetButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(.controlBackgroundColor).opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color(.separatorColor).opacity(0.12), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.93 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct LiquidPomodoroButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(configuration.isPressed ? Color.orange.opacity(0.2) : Color(.controlBackgroundColor).opacity(0.25))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(configuration.isPressed ? Color.orange.opacity(0.4) : Color.orange.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(color: configuration.isPressed ? .orange.opacity(0.1) : .clear, radius: 4, y: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

struct MenuBarPopoverView: View {
    @ObservedObject var timerManager: TimerManager
    @State private var customMinutes: String = ""
    @State private var showCustomInput: Bool = false
    @AppStorage("appearance") private var appearance: String = "system"
    @AppStorage("appLanguage") private var appLanguage: String = "system"

    private let presets: [(label: String, seconds: Int)] = [
        ("1m", 60), ("3m", 180), ("5m", 300),
        ("10m", 600), ("15m", 900), ("25m", 1500),
        ("30m", 1800), ("60m", 3600)
    ]

    var body: some View {
        VStack(spacing: 0) {
            headerView

            Divider()
                .padding(.horizontal, 16)

            contentSection

            Divider()
                .padding(.horizontal, 16)

            footerView
        }
        .frame(width: 236)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.separatorColor).opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(appearance == "dark" ? 0.35 : 0.1), radius: 24, y: 10)
        .preferredColorScheme(colorScheme)
        .sheet(isPresented: $timerManager.showSettings) {
            SettingsView(timerManager: timerManager)
        }
        .id(appLanguage)
    }

    private var colorScheme: ColorScheme? {
        switch appearance {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    private var headerView: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "timer")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.orange.gradient)
                Text("DashTimer")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            Spacer()
            Button(action: { timerManager.showSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .frame(width: 26, height: 26)
                    .background(Color(.controlBackgroundColor).opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    @ViewBuilder
    private var contentSection: some View {
        if timerManager.state == .idle || timerManager.state == .finished {
            idleContent
        } else {
            activeContent
        }
    }

    private var footerView: some View {
        HStack(spacing: 0) {
            if timerManager.isPomodoroMode {
                Button(action: { timerManager.exitPomodoro() }) {
                    HStack(spacing: 3) {
                        Image(systemName: "xmark")
                            .font(.system(size: 7))
                        Text(locStr("退出番茄模式"))
                    }
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.4))
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 16)

                Divider()
                    .frame(height: 16)
            }

            Button(action: { NSApplication.shared.terminate(nil) }) {
                HStack(spacing: 3) {
                    Image(systemName: "power")
                        .font(.system(size: 8))
                    Text(locStr("退出应用"))
                }
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(.secondary.opacity(0.4))
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: timerManager.isPomodoroMode ? .trailing : .center)
            .padding(.trailing, timerManager.isPomodoroMode ? 16 : 0)
        }
        .contentShape(Rectangle())
    }

    private var idleContent: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Button(action: { showCustomInput.toggle() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                        Text(locStr("自定义"))
                            .font(.system(size: 12, design: .rounded))
                        Spacer()
                        Image(systemName: showCustomInput ? "chevron.up" : "chevron.down")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.controlBackgroundColor).opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.top, 8)

                if showCustomInput {
                    HStack(spacing: 6) {
                        HStack(spacing: 6) {
                            TextField(locStr("输入分钟..."), text: $customMinutes)
                                .textFieldStyle(.plain)
                                .font(.system(size: 13, design: .rounded))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(Color(.textBackgroundColor).opacity(0.4))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(Color(.separatorColor).opacity(0.15), lineWidth: 1)
                                )

                            Button(action: {
                                if let minutes = Int(customMinutes), minutes > 0 {
                                    timerManager.startTimer(duration: minutes * 60)
                                    customMinutes = ""
                                    showCustomInput = false
                                }
                            }) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.orange.gradient)
                            }
                            .buttonStyle(.plain)
                            .disabled(Int(customMinutes) == nil || Int(customMinutes)! <= 0)
                            .opacity(Int(customMinutes) != nil && Int(customMinutes)! > 0 ? 1 : 0.35)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.bottom, 8)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 6) {
                ForEach(presets, id: \.seconds) { preset in
                    Button(action: {
                        timerManager.startTimer(duration: preset.seconds)
                    }) {
                        Text(preset.label)
                    }
                    .buttonStyle(LiquidPresetButton())
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)

            Button(action: { timerManager.startPomodoro() }) {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.orange.gradient)
                    Text(locStr("番茄钟模式"))
                        .font(.system(size: 12, design: .rounded))
                    Spacer()
                    Text(locStr("25/5 min"))
                        .font(.system(size: 10, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color(.controlBackgroundColor).opacity(0.4))
                        .clipShape(Capsule())
                }
            }
            .buttonStyle(LiquidPomodoroButton())
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
    }

    private var activeContent: some View {
        VStack(spacing: 14) {
            VStack(spacing: 4) {
                HStack {
                    Spacer()
                    Text(timerManager.timeString)
                        .font(.system(size: 44, weight: .regular, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(timerManager.state == .paused ? .secondary : .primary)
                        .contentTransition(.numericText())
                    if timerManager.state == .paused {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .offset(x: -6, y: -10)
                    }
                    Spacer()
                }

                if timerManager.isPomodoroMode {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.orange.gradient)
                        Text("\(locStr("番茄钟 "))\(timerManager.pomodoroCount)")
                            .font(.system(size: 11, design: .rounded))
                            .foregroundColor(.secondary)
                        Text("·")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        Text(timerManager.pomodoroPhase == .work ? locStr("工作中") : locStr("休息中"))
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(timerManager.pomodoroPhase == .work ? .orange : .green)
                    }
                    .padding(.top, 2)
                }
            }
            .padding(.top, 12)

            progressBar
                .padding(.horizontal, 20)

            HStack(spacing: 14) {
                Button(action: { timerManager.stopTimer() }) {
                    Label(locStr("停止"), systemImage: "stop.fill")
                }
                .buttonStyle(iOSTintedButton(color: .gray, isActive: timerManager.state != .idle))

                Button(action: { timerManager.togglePause() }) {
                    Label(
                        timerManager.state == .paused ? locStr("继续") : locStr("暂停"),
                        systemImage: timerManager.state == .paused ? "play.fill" : "pause.fill"
                    )
                }
                .buttonStyle(iOSFilledButton(color: .orange))
            }
        }
        .padding(.bottom, 12)
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.separatorColor).opacity(0.1))
                    .frame(height: 4)
                Capsule()
                    .fill(.orange.gradient)
                    .frame(
                        width: max(4, geo.size.width * CGFloat(timerManager.remainingSeconds) / CGFloat(max(timerManager.totalSeconds, 1))),
                        height: 4
                    )
                    .shadow(color: .orange.opacity(0.3), radius: 3, x: 0, y: 0)
                    .animation(.linear(duration: 0.3), value: timerManager.remainingSeconds)
            }
        }
        .frame(height: 4)
    }
}
