import Foundation

actor DuplicateFinder {
    private let hashCalculator = HashCalculator()

    func findDuplicates(
        in files: [FileInfo],
        progressHandler: @escaping (Double) -> Void
    ) async throws -> [DuplicateGroup] {
        let sizeGroups = Dictionary(grouping: files) { $0.size }
            .filter { $0.value.count > 1 }

        let totalGroups = sizeGroups.count
        var processedGroups = 0
        var allDuplicates: [DuplicateGroup] = []

        for (_, candidates) in sizeGroups {
            processedGroups += 1
            progressHandler(Double(processedGroups) / Double(totalGroups))

            var sha256Groups: [String: [FileInfo]] = [:]

            for var file in candidates {
                if let sha256 = try await hashCalculator.calculateSHA256(for: file.url) {
                    file.sha256Hash = sha256
                    sha256Groups[sha256, default: []].append(file)
                }
            }

            for (_, duplicateFiles) in sha256Groups where duplicateFiles.count > 1 {
                let totalSize = duplicateFiles.reduce(0) { $0 + $1.size }
                let wastedSize = totalSize - duplicateFiles[0].size
                allDuplicates.append(DuplicateGroup(
                    files: duplicateFiles,
                    totalSize: totalSize,
                    wastedSize: wastedSize
                ))
            }
        }

        return allDuplicates.sorted { $0.wastedSize > $1.wastedSize }
    }
}
