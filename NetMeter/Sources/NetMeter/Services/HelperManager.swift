import Foundation
import ServiceManagement

@MainActor
class HelperManager {
    static let shared = HelperManager()

    private let outputPath = "/tmp/com.netmeter.traffic.json"
    private let triggerPath = "/tmp/com.netmeter.trigger"
    private let daemonPlist = "com.netmeter.helper"

    private var isHelperInstalled = false

    private init() {}

    func installIfNeeded() async -> Bool {
        if isHelperInstalled { return true }

        let service = SMAppService.daemon(plistName: daemonPlist)
        do {
            try service.register()
            isHelperInstalled = true
            return true
        } catch {
            if let posixError = error as? POSIXError, posixError.code == .EEXIST {
                isHelperInstalled = true
                return true
            }
            print("SMAppService register failed: \(error)")
            return false
        }
    }

    func requestRefresh() async -> [HelperProcessEntry]? {
        if !isHelperInstalled {
            guard await installIfNeeded() else { return nil }
        }

        do {
            try "refresh".write(toFile: triggerPath, atomically: true, encoding: .utf8)
        } catch {
            return nil
        }

        try? await Task.sleep(nanoseconds: 2_500_000_000)

        guard FileManager.default.fileExists(atPath: outputPath) else { return nil }
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: outputPath)) else { return nil }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return nil }

        var entries: [HelperProcessEntry] = []
        for item in json {
            guard let pid = item["pid"] as? Int,
                  let name = item["name"] as? String,
                  let bytesIn = item["bytesIn"] as? Int,
                  let bytesOut = item["bytesOut"] as? Int else { continue }
            entries.append(HelperProcessEntry(
                pid: pid_t(pid),
                name: name,
                bytesIn: UInt64(bytesIn),
                bytesOut: UInt64(bytesOut)
            ))
        }

        return entries
    }
}

struct HelperProcessEntry {
    let pid: pid_t
    let name: String
    let bytesIn: UInt64
    let bytesOut: UInt64
}
