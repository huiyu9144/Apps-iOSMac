import Foundation
import Combine

@MainActor
final class SystemMonitorService: ObservableObject {
    static let shared = SystemMonitorService()

    @Published var cpuStats: CPUStats = CPUStats(usage: 0, temperature: nil, timestamp: Date())
    @Published var memoryStats: MemoryStats = MemoryStats(used: 0, total: 0, timestamp: Date())
    @Published var networkStats: NetworkStats = NetworkStats(downloadSpeed: 0, uploadSpeed: 0, totalDownloadToday: 0, totalUploadToday: 0, timestamp: Date())
    @Published var diskStats: DiskStats = DiskStats(used: 0, total: 0, timestamp: Date())
    @Published var batteryStats: BatteryStats? = nil
    @Published var topProcesses: [MemoryTopProcess] = []

    @Published var cpuHistory: [CPUHistoryEntry] = []
    @Published var memoryHistory: [CPUHistoryEntry] = []

    private let cpuService = CPUService()
    private let memoryService = MemoryService()
    private let networkService = NetworkService()
    private let diskService = DiskService()
    private let batteryService = BatteryService()
    private let temperatureService = TemperatureService()

    private var cpuTimer: Timer?
    private var networkTimer: Timer?
    private var temperatureTimer: Timer?
    private var memoryTimer: Timer?

    private init() {}

    func startMonitoring(refreshInterval: TimeInterval = 2) {
        stopMonitoring()

        cpuTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateCPU()
                self?.updateMemory()
            }
        }

        networkTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateNetwork()
            }
        }

        temperatureTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateTemperature()
            }
        }

        memoryTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateTopProcesses()
                self?.updateDisk()
                self?.updateBattery()
            }
        }

        updateAll()
    }

    func stopMonitoring() {
        cpuTimer?.invalidate()
        cpuTimer = nil
        networkTimer?.invalidate()
        networkTimer = nil
        temperatureTimer?.invalidate()
        temperatureTimer = nil
        memoryTimer?.invalidate()
        memoryTimer = nil
    }

    func updateInterval(_ interval: TimeInterval) {
        stopMonitoring()
        startMonitoring(refreshInterval: interval)
    }

    private func updateAll() {
        updateCPU()
        updateMemory()
        updateNetwork()
        updateTemperature()
        updateTopProcesses()
        updateDisk()
        updateBattery()
    }

    private func updateCPU() {
        let usage = cpuService.readCPUUsage()
        cpuService.recordHistory(usage: usage)
        cpuStats = CPUStats(usage: usage, temperature: cpuStats.temperature, timestamp: Date())
        cpuHistory = Array(cpuService.history)
    }

    private func updateTemperature() {
        let temp = temperatureService.readTemperature()
        cpuStats = CPUStats(usage: cpuStats.usage, temperature: temp, timestamp: Date())
    }

    private func updateMemory() {
        let mem = memoryService.readMemoryStats()
        memoryStats = MemoryStats(used: mem.used, total: mem.total, timestamp: Date())

        let usagePercent = mem.total > 0 ? Double(mem.used) / Double(mem.total) * 100 : 0
        let entry = CPUHistoryEntry(usage: usagePercent, timestamp: Date())
        memoryHistory.append(entry)
        if memoryHistory.count > 180 {
            memoryHistory = Array(memoryHistory.suffix(180))
        }
    }

    private func updateTopProcesses() {
        topProcesses = memoryService.readTopProcesses()
    }

    private func updateNetwork() {
        let net = networkService.readNetworkStats()
        let todayTraffic = networkService.getTodayTraffic()
        networkStats = NetworkStats(
            downloadSpeed: net.downloadSpeed,
            uploadSpeed: net.uploadSpeed,
            totalDownloadToday: todayTraffic.download,
            totalUploadToday: todayTraffic.upload,
            timestamp: Date()
        )
    }

    private func updateDisk() {
        let disk = diskService.readDiskStats()
        diskStats = DiskStats(used: disk.used, total: disk.total, timestamp: Date())
    }

    private func updateBattery() {
        batteryStats = batteryService.readBatteryStats()
    }

    func refreshNow() {
        updateAll()
    }
}
