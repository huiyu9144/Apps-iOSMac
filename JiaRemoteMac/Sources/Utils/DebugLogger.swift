import Cocoa
import Foundation

func JiaLog(_ message: String) {
    DebugLogger.shared.log(message)
}

final class DebugLogger {
    static let shared = DebugLogger()

    private var entries: [String] = []
    private let maxEntries = 5000
    private let queue = DispatchQueue(label: "com.jiaremote.logger", qos: .utility)
    private let logURL: URL

    private init() {
        logURL = URL(fileURLWithPath: NSHomeDirectory() + "/Desktop/jia_remote_debug.log")
        try? "".write(to: logURL, atomically: false, encoding: .utf8)
    }

    var fullLog: String {
        queue.sync { entries.joined() }
    }

    func log(_ message: String) {
        let timestamp = DateFormatter.logDateFormatter.string(from: Date())
        let line = "[\(timestamp)] \(message)\n"

        queue.sync {
            entries.append(line)
            if entries.count > maxEntries {
                entries.removeFirst(entries.count - maxEntries)
            }
        }

        if let data = line.data(using: .utf8) {
            if let handle = try? FileHandle(forWritingTo: logURL) {
                handle.seekToEndOfFile()
                handle.write(data)
                try? handle.close()
            } else {
                try? data.write(to: logURL, options: .withoutOverwriting)
            }
        }
    }

    func clear() {
        queue.sync { entries.removeAll() }
        try? "".write(to: logURL, atomically: false, encoding: .utf8)
    }

    deinit {}
}

extension DateFormatter {
    static let logDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()
}

final class DebugLogWindowController: NSWindowController, NSWindowDelegate {

    private let textView: NSTextView

    init() {
        let tv = NSTextView()
        tv.isEditable = false
        tv.isSelectable = true
        tv.font = NSFont(name: "Menlo", size: 12) ?? NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        tv.textColor = NSColor(white: 0.92, alpha: 1)
        tv.backgroundColor = NSColor(red: 0.06, green: 0.06, blue: 0.07, alpha: 1)
        self.textView = tv

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.borderType = .noBorder
        scrollView.documentView = tv

        let copyBtn = NSButton(title: "📋 复制全部", target: nil, action: nil)
        copyBtn.bezelStyle = .rounded

        let clearBtn = NSButton(title: "🗑 清空", target: nil, action: nil)
        clearBtn.bezelStyle = .rounded

        let bottomBar = NSStackView(views: [copyBtn, clearBtn])
        bottomBar.orientation = .horizontal
        bottomBar.spacing = 12
        bottomBar.edgeInsets = NSEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)

        let splitView = NSView()
        splitView.addSubview(scrollView)
        splitView.addSubview(bottomBar)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: splitView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: splitView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: splitView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),
            bottomBar.leadingAnchor.constraint(equalTo: splitView.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: splitView.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: splitView.bottomAnchor),
        ])

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "JiaRemote · 调试日志"
        window.contentView = splitView
        window.center()
        window.isReleasedWhenClosed = false

        super.init(window: window)

        window.delegate = self

        copyBtn.target = self
        copyBtn.action = #selector(copyAll)
        clearBtn.target = self
        clearBtn.action = #selector(clearLog)

        refreshLogs()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func refreshLogs() {
        let logText = DebugLogger.shared.fullLog
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.textView.string = logText
            if !logText.isEmpty {
                self.textView.scrollToEndOfDocument(nil)
            }
        }
    }

    @objc private func copyAll() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(DebugLogger.shared.fullLog, forType: .string)
    }

    @objc private func clearLog() {
        DebugLogger.shared.clear()
        textView.string = ""
    }

    func windowDidBecomeKey(_ notification: Notification) {
        refreshLogs()
    }

    func windowDidResignKey(_ notification: Notification) {}
}