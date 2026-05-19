import Cocoa
import Foundation

final class DebugLogger {
    static let shared = DebugLogger()

    private var entries: [String] = []
    private let maxEntries = 5000
    private let queue = DispatchQueue(label: "com.jiaremote.debuglogger", qos: .utility)

    var onNewEntry: ((String) -> Void)?
    var onClear: (() -> Void)?

    private init() {
        redirectStdout()
    }

    var fullLog: String {
        queue.sync { entries.joined(separator: "\n") }
    }

    func log(_ message: String) {
        let timestamp = DateFormatter.logDateFormatter.string(from: Date())
        let entry = "[\(timestamp)] \(message)"
        queue.sync {
            entries.append(entry)
            if entries.count > maxEntries {
                entries.removeFirst(entries.count - maxEntries)
            }
        }
        DispatchQueue.main.async { [weak self] in
            self?.onNewEntry?(entry)
        }
    }

    func clear() {
        queue.sync { entries.removeAll() }
        DispatchQueue.main.async { [weak self] in
            self?.onClear?()
        }
    }

    private func redirectStdout() {
        let pipe = Pipe()
        setvbuf(stdout, nil, _IOLBF, 0)
        dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)

        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if let line = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines), !line.isEmpty {
                self?.log(line)
            }
        }
    }
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
        tv.font = NSFont(name: "Menlo", size: 12)
        tv.textColor = NSColor(white: 0.92, alpha: 1)
        tv.backgroundColor = NSColor(red: 0.06, green: 0.06, blue: 0.07, alpha: 1)
        tv.string = DebugLogger.shared.fullLog
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

        DebugLogger.shared.onNewEntry = { [weak self] entry in
            guard let self else { return }
            let attrStr = NSAttributedString(
                string: entry + "\n",
                attributes: [
                    .font: NSFont(name: "Menlo", size: 12) ?? NSFont.systemFont(ofSize: 12),
                    .foregroundColor: NSColor(white: 0.92, alpha: 1)
                ]
            )
            self.textView.textStorage?.append(attrStr)
            self.textView.scrollToEndOfDocument(nil)
        }

        DebugLogger.shared.onClear = { [weak self] in
            self?.textView.string = ""
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func copyAll() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(DebugLogger.shared.fullLog, forType: .string)
    }

    @objc private func clearLog() {
        DebugLogger.shared.clear()
    }

    func windowDidBecomeKey(_ notification: Notification) {
        DebugLogger.shared.onNewEntry = { [weak self] entry in
            guard let self else { return }
            let attrStr = NSAttributedString(
                string: entry + "\n",
                attributes: [
                    .font: NSFont(name: "Menlo", size: 12) ?? NSFont.systemFont(ofSize: 12),
                    .foregroundColor: NSColor(white: 0.92, alpha: 1)
                ]
            )
            self.textView.textStorage?.append(attrStr)
            self.textView.scrollToEndOfDocument(nil)
        }
    }

    func windowDidResignKey(_ notification: Notification) {
    }
}
