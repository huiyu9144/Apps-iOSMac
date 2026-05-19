import Foundation
import Network
import Combine
import AppKit
import CoreGraphics
import ScreenCaptureKit

final class ConfigManager: ObservableObject {
    static let shared = ConfigManager()

    private let defaults = UserDefaults.standard

    private enum Key {
        static let prefix = "jiaremote."
        static let listenPort = prefix + "listenPort"
        static let captureMode = prefix + "captureMode"
        static let selectedDisplayID = prefix + "selectedDisplayID"
        static let selectedWindowID = prefix + "selectedWindowID"
        static let colorSpace = prefix + "colorSpace"
        static let pixelFormat = prefix + "pixelFormat"
        static let bonjourEnabled = prefix + "bonjourEnabled"
        static let bonjourServiceName = prefix + "bonjourServiceName"
        static let showOverlay = prefix + "showOverlay"
        static let autoStartService = prefix + "autoStartService"
        static let launchAtLogin = prefix + "launchAtLogin"
    }

    @Published var listenPort: Int = 9527
    @Published var captureMode: String = "fullscreen"
    @Published var selectedDisplayID: UInt32 = 0
    @Published var selectedWindowID: UInt32 = 0
    @Published var colorSpace: String = "Display P3"
    @Published var pixelFormat: String = "BGRA8888"
    @Published var bonjourEnabled: Bool = true
    @Published var bonjourServiceName: String = "JiaRemote-Mac"
    @Published var showOverlay: Bool = false
    @Published var autoStartService: Bool = false
    @Published var launchAtLogin: Bool = false
    @Published var screenRecordingGranted: Bool = false
    @Published var accessibilityGranted: Bool = false

    private init() {}

    func load() {
        if defaults.object(forKey: Key.listenPort) != nil {
            listenPort = defaults.integer(forKey: Key.listenPort)
        }
        if let mode = defaults.string(forKey: Key.captureMode) {
            captureMode = mode
        }
        if defaults.object(forKey: Key.selectedDisplayID) != nil {
            selectedDisplayID = UInt32(defaults.integer(forKey: Key.selectedDisplayID))
        }
        if defaults.object(forKey: Key.selectedWindowID) != nil {
            selectedWindowID = UInt32(defaults.integer(forKey: Key.selectedWindowID))
        }
        if let cs = defaults.string(forKey: Key.colorSpace) {
            colorSpace = cs
        }
        if let pf = defaults.string(forKey: Key.pixelFormat) {
            pixelFormat = pf
        }
        if defaults.object(forKey: Key.bonjourEnabled) != nil {
            bonjourEnabled = defaults.bool(forKey: Key.bonjourEnabled)
        }
        if let name = defaults.string(forKey: Key.bonjourServiceName) {
            bonjourServiceName = name
        }
        if defaults.object(forKey: Key.showOverlay) != nil {
            showOverlay = defaults.bool(forKey: Key.showOverlay)
        }
        if defaults.object(forKey: Key.autoStartService) != nil {
            autoStartService = defaults.bool(forKey: Key.autoStartService)
        }
        if defaults.object(forKey: Key.launchAtLogin) != nil {
            launchAtLogin = defaults.bool(forKey: Key.launchAtLogin)
        }
    }

    func save() {
        defaults.set(listenPort, forKey: Key.listenPort)
        defaults.set(captureMode, forKey: Key.captureMode)
        defaults.set(Int(selectedDisplayID), forKey: Key.selectedDisplayID)
        defaults.set(Int(selectedWindowID), forKey: Key.selectedWindowID)
        defaults.set(colorSpace, forKey: Key.colorSpace)
        defaults.set(pixelFormat, forKey: Key.pixelFormat)
        defaults.set(bonjourEnabled, forKey: Key.bonjourEnabled)
        defaults.set(bonjourServiceName, forKey: Key.bonjourServiceName)
        defaults.set(showOverlay, forKey: Key.showOverlay)
        defaults.set(autoStartService, forKey: Key.autoStartService)
        defaults.set(launchAtLogin, forKey: Key.launchAtLogin)
    }

    func getLocalIPAddress() -> String? {
        var address: String?

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        defer { freeifaddrs(ifaddr) }

        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }

            guard let interface = ptr?.pointee else { continue }

            let ifaName = String(cString: interface.ifa_name)

            guard ifaName.hasPrefix("en") else { continue }

            let addrFamily = interface.ifa_addr.pointee.sa_family
            guard addrFamily == UInt8(AF_INET) else { continue }

            if let saData = interface.ifa_addr {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(saData,
                            socklen_t(interface.ifa_addr.pointee.sa_len),
                            &hostname,
                            socklen_t(hostname.count),
                            nil, 0,
                            NI_NUMERICHOST)
                let ip = String(cString: hostname)
                if ip != "127.0.0.1" {
                    address = ip
                    break
                }
            }
        }

        return address
    }

    func getLocalHostname() -> String? {
        Host.current().localizedName
    }

    func getAllLocalIPs() -> [String] {
        var addresses: [String] = []

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return addresses }
        defer { freeifaddrs(ifaddr) }

        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }

            guard let interface = ptr?.pointee else { continue }

            let addrFamily = interface.ifa_addr.pointee.sa_family
            guard addrFamily == UInt8(AF_INET) else { continue }

            if let saData = interface.ifa_addr {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(saData,
                            socklen_t(interface.ifa_addr.pointee.sa_len),
                            &hostname,
                            socklen_t(hostname.count),
                            nil, 0,
                            NI_NUMERICHOST)
                let ip = String(cString: hostname)
                if ip != "127.0.0.1" {
                    addresses.append(ip)
                }
            }
        }

        return addresses
    }

    func refreshPermissions() {
        screenRecordingGranted = checkScreenRecordingPermission()
        accessibilityGranted = checkAccessibilityPermission()
    }

    func checkScreenRecordingPermission() -> Bool {
        CGPreflightScreenCaptureAccess()
    }

    func checkAccessibilityPermission() -> Bool {
        AXIsProcessTrusted()
    }

    func checkScreenRecordingWithCaptureKit() async -> Bool {
        if CGPreflightScreenCaptureAccess() { return true }
        do {
            _ = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            return true
        } catch {
            return false
        }
    }

    @MainActor
    func requestScreenRecordingPermission() async -> Bool {
        if CGPreflightScreenCaptureAccess() {
            return true
        }

        CGRequestScreenCaptureAccess()
        try? await Task.sleep(nanoseconds: 500_000_000)
        return CGPreflightScreenCaptureAccess()
    }

    func requestAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    func permissionStatusDescription() -> [(name: String, granted: Bool)] {
        [
            (name: NSLocalizedString("Screen Recording", comment: "Screen Recording permission name"),
             granted: checkScreenRecordingPermission()),
            (name: NSLocalizedString("Accessibility", comment: "Accessibility permission name"),
             granted: checkAccessibilityPermission()),
        ]
    }
}
