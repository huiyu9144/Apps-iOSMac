import Foundation

let outputPath = "/tmp/com.netmeter.traffic.json"
let triggerPath = "/tmp/com.netmeter.trigger"

func run() -> Int32 {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/script")
    task.arguments = ["-q", "/dev/null", "/usr/bin/nettop", "-P", "-x", "-n", "-s", "1", "-l", "1", "-L", "1"]

    let outPipe = Pipe()
    task.standardOutput = outPipe
    task.standardError = Pipe()
    task.standardInput = FileHandle.nullDevice

    do {
        try task.run()
        task.waitUntilExit()
    } catch {
        return 1
    }

    let data = outPipe.fileHandleForReading.readDataToEndOfFile()
    guard let text = String(data: data, encoding: .utf8) else { return 1 }

    var entries: [[String: Any]] = []
    let lines = text.components(separatedBy: .newlines)

    for line in lines {
        let cleaned = line.replacingOccurrences(of: "\u{0004}", with: "")
                             .replacingOccurrences(of: "\u{0008}", with: "")
        guard cleaned.contains(",") else { continue }

        let cols = cleaned.components(separatedBy: ",")
        guard cols.count >= 6 else { continue }
        if cols[1].hasPrefix("time") || cols[1] == "interface" { continue }

        let namePid = cols[1].trimmingCharacters(in: .whitespaces)
        guard !namePid.isEmpty, namePid.contains(".") else { continue }

        let bytesInStr = cols[4].trimmingCharacters(in: .whitespaces)
        let bytesOutStr = cols[5].trimmingCharacters(in: .whitespaces)
        guard let bytesIn = UInt64(bytesInStr), let bytesOut = UInt64(bytesOutStr) else { continue }

        guard let dotIndex = namePid.lastIndex(of: ".") else { continue }
        let pidStr = namePid[namePid.index(after: dotIndex)...]
        let procName = String(namePid[..<dotIndex]).trimmingCharacters(in: .whitespaces)
        guard let pid = pid_t(pidStr), pid > 0 else { continue }

        entries.append([
            "pid": Int(pid),
            "name": procName,
            "bytesIn": Int(bytesIn),
            "bytesOut": Int(bytesOut)
        ])
    }

    do {
        let jsonData = try JSONSerialization.data(withJSONObject: entries, options: [])
        try jsonData.write(to: URL(fileURLWithPath: outputPath))
        try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: outputPath)
    } catch {
        return 1
    }

    return 0
}

let exitCode = run()
fflush(stdout)
exit(exitCode)
