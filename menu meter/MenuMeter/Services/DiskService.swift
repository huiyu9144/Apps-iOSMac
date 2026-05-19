import Foundation

final class DiskService {
    func readDiskStats() -> (used: UInt64, total: UInt64) {
        let fileManager = FileManager.default
        let path = "/"

        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: path)
            let total = (attributes[.systemSize] as? UInt64) ?? 0
            let free = (attributes[.systemFreeSize] as? UInt64) ?? 0
            let used = total - free
            return (used, total)
        } catch {
            return (0, 0)
        }
    }
}
