import Foundation
import UserNotifications
import AppKit

enum TimerState: Equatable {
    case idle
    case running
    case paused
    case finished
}

enum PomodoroPhase: Equatable {
    case work
    case break_
}

@MainActor
class TimerManager: ObservableObject {
    @Published var state: TimerState = .idle
    @Published var remainingSeconds: Int = 0
    @Published var totalSeconds: Int = 0
    @Published var isPomodoroMode: Bool = false
    @Published var pomodoroCount: Int = 0
    @Published var pomodoroPhase: PomodoroPhase = .work
    @Published var isBlinking: Bool = false
    @Published var showSettings: Bool = false

    private var timer: Timer?
    private var blinkTimer: Timer?
    private var blinkCount: Int = 0

    private var soundEnabled: Bool {
        UserDefaults.standard.bool(forKey: "soundEnabled")
    }

    private var notificationEnabled: Bool {
        UserDefaults.standard.bool(forKey: "notificationEnabled")
    }

    private var workDurationSetting: Int {
        let saved = UserDefaults.standard.integer(forKey: "workDuration")
        return saved > 0 ? saved * 60 : 25 * 60
    }

    private var breakDurationSetting: Int {
        let saved = UserDefaults.standard.integer(forKey: "breakDuration")
        return saved > 0 ? saved * 60 : 5 * 60
    }

    var timeString: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var menuBarTitle: String {
        switch state {
        case .idle:
            return ""
        case .running, .paused:
            if isPomodoroMode {
                let icon = pomodoroPhase == .work ? "" : "☕️"
                return "\(icon) \(timeString)"
            }
            return timeString
        case .finished:
            return isBlinking ? "" : "00:00"
        }
    }

    func startTimer(duration seconds: Int) {
        stopTimer()
        state = .running
        totalSeconds = seconds
        remainingSeconds = seconds
        startTimerInternal()
    }

    func togglePause() {
        switch state {
        case .running:
            timer?.invalidate()
            timer = nil
            state = .paused
        case .paused:
            state = .running
            startTimerInternal()
        default:
            break
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
        blinkTimer?.invalidate()
        blinkTimer = nil
        state = .idle
        remainingSeconds = 0
        totalSeconds = 0
        isBlinking = false
    }

    func startPomodoro() {
        isPomodoroMode = true
        pomodoroPhase = .work
        pomodoroCount = 0
        startTimer(duration: workDurationSetting)
    }

    func exitPomodoro() {
        isPomodoroMode = false
        stopTimer()
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func startTimerInternal() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(
            timeInterval: 1.0,
            target: self,
            selector: #selector(tick),
            userInfo: nil,
            repeats: true
        )
    }

    @objc private func tick() {
        remainingSeconds -= 1
        if remainingSeconds <= 0 {
            remainingSeconds = 0
            timer?.invalidate()
            timer = nil
            state = .finished
            startBlinking()
            notifyTimerComplete()
            if isPomodoroMode {
                handlePomodoroComplete()
            }
        }
    }

    private func startBlinking() {
        isBlinking = true
        blinkCount = 0
        blinkTimer?.invalidate()
        blinkTimer = Timer.scheduledTimer(
            timeInterval: 0.5,
            target: self,
            selector: #selector(blinkTick),
            userInfo: nil,
            repeats: true
        )
    }

    @objc private func blinkTick() {
        isBlinking.toggle()
        blinkCount += 1
        if blinkCount > 20 {
            blinkTimer?.invalidate()
            blinkTimer = nil
            isBlinking = false
        }
    }

    private func handlePomodoroComplete() {
        pomodoroCount += 1
        if pomodoroPhase == .work {
            pomodoroPhase = .break_
            startTimer(duration: breakDurationSetting)
        } else {
            pomodoroPhase = .work
            startTimer(duration: workDurationSetting)
        }
    }

    private func notifyTimerComplete() {
        let hasNotification = notificationEnabled
        let hasSound = soundEnabled

        if hasNotification {
            let body: String
            if isPomodoroMode {
                body = pomodoroPhase == .break_
                    ? locStr("work_complete")
                    : locStr("break_over")
            } else {
                body = locStr("timer_up")
            }

            let content = UNMutableNotificationContent()
            content.title = "MenuTimer"
            content.body = body
            content.sound = hasSound ? .default : nil
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )
            UNUserNotificationCenter.current().add(request)
        }
        if hasSound && !hasNotification {
            NSSound.beep()
        }
    }
}
