import SwiftUI

struct ResultPanelView: View {
    @ObservedObject var scanVM: ScanViewModel
    @ObservedObject private var langManager = LocalizationManager.shared
    @StateObject private var resultVM = ResultViewModel()

    private var totalWastedSpace: Int64 {
        resultVM.calculateWastedSpace(for: scanVM.duplicateGroups)
    }

    var body: some View {
        let _ = langManager
        VStack(spacing: 0) {
            if scanVM.duplicateGroups.isEmpty {
                emptyView
            } else {
                headerView

                Divider()

                toolbarView

                Divider()

                groupListView
            }
        }
        .alert(loc("确认删除", "Confirm Delete"), isPresented: $resultVM.showConfirmDelete) {
            Button(loc("取消", "Cancel"), role: .cancel) { }
            Button(loc("删除", "Delete"), role: .destructive) {
                resultVM.confirmDelete { updated in
                    scanVM.duplicateGroups = updated
                }
            }
        } message: {
            Text(verbatim: loc("确定删除 ", "Delete ") + "\(resultVM.selectedFileIDs.count) " + loc("个文件，释放 ", " files, free up ") + "\(resultVM.formattedWastedSpace(for: scanVM.duplicateGroups))" + loc(" 空间？", "?"))
        }
        .alert(loc("删除结果", "Delete Result"), isPresented: $resultVM.showDeleteAlert) {
            Button(loc("好的", "OK"), role: .cancel) { }
        } message: {
            Text(verbatim: resultVM.deleteResultText ?? "")
        }
        .onAppear {
            resultVM.defaultSelection(in: scanVM.duplicateGroups)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundStyle(.green)

            Text(verbatim: loc("没有发现重复文件", "No Duplicates Found"))
                .font(.title3)
                .fontWeight(.medium)

            Text(verbatim: "「\(scanVM.scannedFolderName)」" + loc("中未找到重复文件", ": No duplicate files found"))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(action: { scanVM.showFolderPicker = true }) {
                Label(loc("扫描其他位置", "Scan Another Location"), systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var headerView: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text(verbatim: loc("扫描完成 — 「", "Scan Complete — 「") + scanVM.scannedFolderName + "」")
                    .font(.headline)
                Spacer()
            }

            HStack {
                Text(verbatim: loc("找到 ", "Found ") + "\(scanVM.duplicateGroups.count) " + loc("组重复文件", " duplicate groups"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var toolbarView: some View {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return HStack {
            let allSelected = resultVM.areAllSelected(in: scanVM.duplicateGroups)
            Button(allSelected ? loc("取消全选", "Deselect All") : loc("全选", "Select All")) {
                if allSelected {
                    resultVM.deselectAll(in: scanVM.duplicateGroups)
                } else {
                    resultVM.selectAll(in: scanVM.duplicateGroups)
                }
            }
            .font(.subheadline)
            .buttonStyle(.borderless)

            Picker("", selection: $resultVM.selectMode) {
                Text(verbatim: loc("保留一个", "Keep One")).tag(ResultViewModel.SelectMode.extras)
                Text(verbatim: loc("全部选中", "Select All")).tag(ResultViewModel.SelectMode.allFiles)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 200)

            Spacer()

            Button(action: {
                resultVM.requestDelete(from: scanVM.duplicateGroups)
            }, label: {
                Label(loc("删除选中 (", "Delete Selected (") + formatter.string(fromByteCount: totalWastedSpace) + ")", systemImage: "trash")
                    .font(.subheadline)
            })
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(resultVM.selectedFileIDs.isEmpty)

            Button(action: { scanVM.showSettings = true }, label: {
                Image(systemName: "gearshape")
                    .font(.subheadline)
            })
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var groupListView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(scanVM.duplicateGroups) { group in
                    DuplicateGroupRow(
                        group: group,
                        isExpanded: resultVM.expandedGroupID == group.id,
                        isGroupSelected: resultVM.isGroupSelected(group),
                        isGroupPartiallySelected: resultVM.isGroupPartiallySelected(group),
                        selectedFileIDs: resultVM.selectedFileIDs,
                        selectMode: resultVM.selectMode,
                        onToggle: { resultVM.toggleGroupExpansion(group.id) },
                        onToggleGroup: { resultVM.toggleGroupSelection(group) },
                        onToggleFile: { fileID in resultVM.toggleSelection(for: fileID) }
                    )
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 12)
        }
    }
}
