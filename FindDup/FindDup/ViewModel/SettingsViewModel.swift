import Foundation

class SettingsViewModel: ObservableObject {
    @Published var minimumFileSize: Int64 = 1024
    @Published var fileTypeFilter: FileTypeFilter = .all
    @Published var deleteToTrash: Bool = true

    var minimumFileSizeDisplay: String {
        if minimumFileSize < 1024 {
            return "\(minimumFileSize) B"
        } else if minimumFileSize < 1024 * 1024 {
            return "\(minimumFileSize / 1024) KB"
        } else {
            return "\(minimumFileSize / (1024 * 1024)) MB"
        }
    }
}
