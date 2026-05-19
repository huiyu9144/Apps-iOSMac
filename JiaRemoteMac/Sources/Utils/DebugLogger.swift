import Cocoa
import Foundation

func JiaLog(_ message: String) {
    let timestamp = DateFormatter.logDateFormatter.string(from: Date())
    let line = "[\(timestamp)] \(message)\n"
    
    // 写入内存数组
    DebugLogger.shared.entries.append(line)
    
    // 同时写入文件（100%可靠）
    let logPath = NSHomeDirectory() + "/Desktop/jia_remote_debug.log"
    if let handle = FileHandle(forWritingAtPath: logPath) {
        handle.seekToEndOfFile()
        handle.write(Data(line.utf8))
        handle.closeFile()
    } else {
        FileManager.default.createFile(atPath: logPath, contents: Data(line.utf8), attributes: nil)
    }
}

final class DebugLogger {
    static let shared = DebugLogger()
    var entries: [String] = []
    let maxEntries = 5000
    
    private init() {}

    var fullLog: String {
        String(entries.prefix(maxEntries).joined())
    }

    func clear() {
        entries.removeAll()
        let logPath = NSHomeDirectory() + "/Desktop/jia_remote_debug.log"
        try? "".write(toFile: logPath, atomically: true, encoding: .utf8)
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
        if !logText.isEmpty {
            textView.string = logText
            textView.scrollToEndOfDocument(nil)
        }
        
        let filePath = NSHomeDirectory() + "/Desktop/jia_remote_debug.log"
        if let fileContent = try? String(contentsOfFile: filePath, encoding: .utf8), !fileContent.isEmpty {
            if textView.string.isEmpty || fileContent.count > textView.string.count {
                textView.string = fileContent
                textView.scrollToEndOfDocument(nil)
            }
        }
    }

    @objc private func copyAll() {
        NSPasteboard.general.clearContents()
        let content = DebugLogger.shared.fullLog
        let filePath = NSHomeDirectory() + "/Desktop/jia_remote_debug.log"
        let fileContent = (try? String(contentsOfFile: filePath, encoding: .utf8)) ?? ""
        NSPasteboard.general.setString(content.isEmpty ? fileContent : content, forType: .string)
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