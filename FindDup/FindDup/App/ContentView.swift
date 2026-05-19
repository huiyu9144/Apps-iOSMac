import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var scanVM = ScanViewModel()
    @ObservedObject private var langManager = LocalizationManager.shared

    var body: some View {
        HSplitView {
            if shouldShowSidebar {
                sidebarView
                    .frame(minWidth: 180, idealWidth: 200, maxWidth: 250)
            }

            mainContentView
        }
        .frame(minWidth: 800, minHeight: 500)
        .fileImporter(
            isPresented: $scanVM.showFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    scanVM.startScan(folder: url)
                }
            case .failure:
                break
            }
        }
    }

    private var shouldShowSidebar: Bool {
        true
    }

    private var sidebarView: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "doc.on.doc.fill")
                    .foregroundStyle(.blue)
                Text("FindDup")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider()

            if scanVM.scanState == .completed {
                completedSidebarContent
            } else {
                idleSidebarContent
            }

            Spacer()

            VStack(spacing: 4) {
                Divider()
                Button(action: { scanVM.showSettings = true }) {
                    Label(loc("设置", "Settings"), systemImage: "gearshape")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.borderless)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
        .background(.background)
    }

    private var idleSidebarContent: some View {
        VStack(spacing: 4) {
            Button(action: { scanVM.showFolderPicker = true }) {
                Label(loc("选择文件夹", "Select Folder"), systemImage: "folder.badge.plus")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.borderless)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    private var completedSidebarContent: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "folder")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(width: 16)
                VStack(alignment: .leading, spacing: 1) {
                    Text(scanVM.scannedFolderName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    Text(verbatim: "\(scanVM.duplicateGroups.count) " + loc("组重复", "groups"))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Button(action: { scanVM.reset() }) {
                Label(loc("新建扫描", "New Scan"), systemImage: "arrow.counterclockwise")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.borderless)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private var mainContentView: some View {
        Group {
            switch scanVM.scanState {
            case .idle:
                ScanPanelView(scanVM: scanVM)
            case .scanning:
                ScanPanelView(scanVM: scanVM)
            case .completed:
                ResultPanelView(scanVM: scanVM)
            }
        }
        .sheet(isPresented: $scanVM.showSettings) {
            SettingsView(viewModel: ScanViewModel.settingsViewModel)
        }
    }
}
