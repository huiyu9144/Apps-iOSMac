import Foundation

@MainActor
class ScanViewModel: ObservableObject {
    enum ScanState {
        case idle, scanning, completed
    }

    enum ScanPhase: Equatable {
        case enumerating
        case hashing(progress: Double)

        var localizedDescription: String {
            switch self {
            case .enumerating: return loc("正在扫描文件…", "Scanning files…")
            case .hashing(let p): return loc("正在比对哈希… ", "Hashing… ") + "\(Int(p * 100))%"
            }
        }
    }

    @Published var scanState: ScanState = .idle
    @Published var scanPhase: ScanPhase = .enumerating
    @Published var scannedFileCount: Int = 0
    @Published var progress: Double = 0
    @Published var duplicateGroups: [DuplicateGroup] = []
    @Published var scannedFolderName: String = ""
    @Published var showSettings = false
    @Published var showFolderPicker = false

    private let fileScanner = FileScanner()
    private let duplicateFinder = DuplicateFinder()
    private var scannedURL: URL?
    private var isSecurityScoped = false

    nonisolated static let settingsViewModel = SettingsViewModel()

    func startScan(folder url: URL) {
        stopAccessingIfNeeded()

        scannedURL = url
        isSecurityScoped = url.startAccessingSecurityScopedResource()
        scanState = .scanning
        scanPhase = .enumerating
        scannedFileCount = 0
        duplicateGroups = []
        progress = 0
        scannedFolderName = url.lastPathComponent

        Task {
            do {
                let settings = Self.settingsViewModel
                let files = try await fileScanner.scanDirectory(
                    url,
                    minimumSize: settings.minimumFileSize,
                    fileTypeFilter: settings.fileTypeFilter
                ) { count in
                    Task { @MainActor in
                        self.scannedFileCount = count
                    }
                }

                self.scanPhase = .hashing(progress: 0)

                let groups = try await duplicateFinder.findDuplicates(in: files) { progressValue in
                    Task { @MainActor in
                        self.progress = progressValue
                        self.scanPhase = .hashing(progress: progressValue)
                    }
                }

                self.duplicateGroups = groups
                self.progress = 1.0
                self.scanPhase = .hashing(progress: 1.0)
                self.scanState = .completed
                stopAccessingIfNeeded()
            } catch ScannerError.cancelled {
                stopAccessingIfNeeded()
                self.scanState = .idle
            } catch {
                stopAccessingIfNeeded()
                self.scanState = .idle
            }
        }
    }

    func cancelScan() {
        Task {
            await fileScanner.cancel()
        }
    }

    func reset() {
        stopAccessingIfNeeded()
        scanState = .idle
        scanPhase = .enumerating
        scannedFileCount = 0
        duplicateGroups = []
        progress = 0
        scannedFolderName = ""
    }

    private func stopAccessingIfNeeded() {
        if isSecurityScoped, let url = scannedURL {
            url.stopAccessingSecurityScopedResource()
        }
        isSecurityScoped = false
        scannedURL = nil
    }
}
