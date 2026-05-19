import Foundation

@MainActor
class ResultViewModel: ObservableObject {
    enum SelectMode: String, CaseIterable {
        case extras = "KeepOne"
        case allFiles = "SelectAll"
    }

    @Published var selectedFileIDs: Set<UUID> = []
    @Published var expandedGroupID: UUID?
    @Published var selectMode: SelectMode = .extras
    @Published var isDeleting = false
    @Published var showDeleteAlert = false
    @Published var deleteResultText: String?
    @Published var showConfirmDelete = false

    private let fileDeleter = FileDeleter()
    private var pendingDeleteGroups: [DuplicateGroup] = []

    func toggleSelection(for fileID: UUID) {
        if selectedFileIDs.contains(fileID) {
            selectedFileIDs.remove(fileID)
        } else {
            selectedFileIDs.insert(fileID)
        }
    }

    func toggleGroupSelection(_ group: DuplicateGroup) {
        let isGroupDone: Bool
        switch selectMode {
        case .extras:
            isGroupDone = group.files.dropFirst().allSatisfy { selectedFileIDs.contains($0.id) }
        case .allFiles:
            isGroupDone = group.files.allSatisfy { selectedFileIDs.contains($0.id) }
        }

        if isGroupDone {
            for file in group.files {
                selectedFileIDs.remove(file.id)
            }
        } else {
            switch selectMode {
            case .extras:
                for file in group.files.dropFirst() {
                    selectedFileIDs.insert(file.id)
                }
            case .allFiles:
                for file in group.files {
                    selectedFileIDs.insert(file.id)
                }
            }
        }
    }

    func isGroupSelected(_ group: DuplicateGroup) -> Bool {
        switch selectMode {
        case .extras:
            let extras = group.files.dropFirst()
            return extras.allSatisfy { selectedFileIDs.contains($0.id) }
        case .allFiles:
            return group.files.allSatisfy { selectedFileIDs.contains($0.id) }
        }
    }

    func isGroupPartiallySelected(_ group: DuplicateGroup) -> Bool {
        let anySelected = group.files.contains { selectedFileIDs.contains($0.id) }
        let allSelected = group.files.allSatisfy { selectedFileIDs.contains($0.id) }
        return anySelected && !allSelected
    }

    func selectAll(in groups: [DuplicateGroup]) {
        for group in groups {
            switch selectMode {
            case .extras:
                for file in group.files.dropFirst() {
                    selectedFileIDs.insert(file.id)
                }
            case .allFiles:
                for file in group.files {
                    selectedFileIDs.insert(file.id)
                }
            }
        }
    }

    func deselectAll(in groups: [DuplicateGroup]) {
        for group in groups {
            for file in group.files {
                selectedFileIDs.remove(file.id)
            }
        }
    }

    func areAllSelected(in groups: [DuplicateGroup]) -> Bool {
        for group in groups {
            switch selectMode {
            case .extras:
                guard group.files.dropFirst().allSatisfy({ selectedFileIDs.contains($0.id) }) else { return false }
            case .allFiles:
                guard group.files.allSatisfy({ selectedFileIDs.contains($0.id) }) else { return false }
            }
        }
        return !groups.isEmpty
    }

    func defaultSelection(in groups: [DuplicateGroup]) {
        selectedFileIDs.removeAll()
        for group in groups {
            for file in group.files.dropFirst() {
                selectedFileIDs.insert(file.id)
            }
        }
    }

    func calculateWastedSpace(for groups: [DuplicateGroup]) -> Int64 {
        groups.reduce(0) { total, group in
            let selectedInGroup = group.files.filter { selectedFileIDs.contains($0.id) }
            return total + selectedInGroup.reduce(0) { $0 + $1.size }
        }
    }

    func formattedWastedSpace(for groups: [DuplicateGroup]) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: calculateWastedSpace(for: groups))
    }

    func getFilesToDelete(from groups: [DuplicateGroup]) -> [FileInfo] {
        groups.flatMap { group in
            group.files.filter { selectedFileIDs.contains($0.id) }
        }
    }

    func requestDelete(from groups: [DuplicateGroup]) {
        let files = getFilesToDelete(from: groups)
        guard !files.isEmpty else { return }
        pendingDeleteGroups = groups
        showConfirmDelete = true
    }

    func confirmDelete(onCompletion: @escaping ([DuplicateGroup]) -> Void) {
        let filesToDelete = getFilesToDelete(from: pendingDeleteGroups)
        guard !filesToDelete.isEmpty else { return }

        isDeleting = true
        Task {
            let result = await fileDeleter.moveToTrash(files: filesToDelete)

            let deletedIDs = Set(filesToDelete.map(\.id))
            selectedFileIDs.subtract(deletedIDs)

            let updated = pendingDeleteGroups.compactMap { group -> DuplicateGroup? in
                let remaining = group.files.filter { !deletedIDs.contains($0.id) }
                if remaining.count >= 2 {
                    let totalSize = remaining.reduce(0) { $0 + $1.size }
                    let wastedSize = totalSize - remaining[0].size
                    return DuplicateGroup(files: remaining, totalSize: totalSize, wastedSize: wastedSize)
                }
                return nil
            }

            let formatter = ByteCountFormatter()
            formatter.countStyle = .file

            if result.failureCount > 0 {
                deleteResultText = loc("已释放 ", "Freed ") + "\(formatter.string(fromByteCount: result.freedSpace))，" + "\(result.failureCount) " + loc("个文件删除失败", "files failed to delete")
            } else {
                deleteResultText = loc("已释放 ", "Freed ") + formatter.string(fromByteCount: result.freedSpace)
            }

            isDeleting = false
            showDeleteAlert = true
            onCompletion(updated)
        }
    }

    func toggleGroupExpansion(_ groupID: UUID) {
        if expandedGroupID == groupID {
            expandedGroupID = nil
        } else {
            expandedGroupID = groupID
        }
    }
}
