import SwiftUI

struct ResultPanelView: View {
    @ObservedObject var scanVM: ScanViewModel
    @StateObject private var resultVM = ResultViewModel()

    private var totalWastedSpace: Int64 {
        resultVM.calculateWastedSpace(for: scanVM.duplicateGroups)
    }

    var body: some View {
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
        .alert("确认删除", isPresented: $resultVM.showConfirmDelete) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                resultVM.confirmDelete { updated in
                    scanVM.duplicateGroups = updated
                }
            }
        } message: {
            Text("确定删除 \(resultVM.selectedFileIDs.count) 个文件，释放 \(resultVM.formattedWastedSpace(for: scanVM.duplicateGroups)) 空间？")
        }
        .alert("删除结果", isPresented: $resultVM.showDeleteAlert) {
            Button("好的", role: .cancel) { }
        } message: {
            Text(resultVM.deleteResultText ?? "")
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

            Text("没有发现重复文件")
                .font(.title3)
                .fontWeight(.medium)

            Text("「\(scanVM.scannedFolderName)」中未找到重复文件")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(action: { scanVM.showFolderPicker = true }) {
                Label("扫描其他位置", systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            Spacer()
        }
    }

    private var headerView: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("扫描完成 — 「\(scanVM.scannedFolderName)」")
                    .font(.headline)
                Spacer()
            }

            HStack {
                Text("找到 \(scanVM.duplicateGroups.count) 组重复文件")
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
            Button(allSelected ? "取消全选" : "全选") {
                if allSelected {
                    resultVM.deselectAll(in: scanVM.duplicateGroups)
                } else {
                    resultVM.selectAll(in: scanVM.duplicateGroups)
                }
            }
            .font(.subheadline)
            .buttonStyle(.borderless)

            Picker("", selection: $resultVM.selectMode) {
                Text("保留一个").tag(ResultViewModel.SelectMode.extras)
                Text("全部选中").tag(ResultViewModel.SelectMode.allFiles)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 200)

            Spacer()

            Button(action: {
                resultVM.requestDelete(from: scanVM.duplicateGroups)
            }, label: {
                Label("删除选中 (\(formatter.string(fromByteCount: totalWastedSpace)))", systemImage: "trash")
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
