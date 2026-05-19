import SwiftUI
import UniformTypeIdentifiers

struct ScanPanelView: View {
    @ObservedObject var scanVM: ScanViewModel
    @State private var showFolderPicker = false
    @State private var rotationAngle: Double = 0
    @State private var rotationTimer: Timer?

    var body: some View {
        VStack(spacing: 20) {
            if scanVM.scanState == .idle {
                idleView
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .scale(scale: 0.9).combined(with: .opacity)
                    ))
            } else if scanVM.scanState == .scanning {
                scanningView
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: scanVM.scanState)
        .fileImporter(
            isPresented: $showFolderPicker,
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

    private var idleView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "magnifyingglass.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("查找重复文件")
                .font(.title2)
                .fontWeight(.medium)

            Text("选择一个文件夹开始扫描")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(action: { showFolderPicker = true }) {
                Label("选择文件夹", systemImage: "folder.badge.plus")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            RoundedRectangle(cornerRadius: 12)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                .foregroundStyle(.secondary)
                .frame(height: 120)
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: "arrow.down.doc.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Text("或拖拽文件夹到此处")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                    handleDrop(providers: providers)
                    return true
                }

            Spacer()
        }
        .padding(40)
    }

    private var scanningView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(.blue.opacity(0.15), lineWidth: 4)
                    .frame(width: 72, height: 72)

                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 32))
                    .foregroundStyle(.blue)
                    .rotationEffect(.degrees(rotationAngle))
            }

            Text("正在扫描「\(scanVM.scannedFolderName)」")
                .font(.title3)
                .fontWeight(.medium)

            Text(scanVM.scanPhase.localizedDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if scanVM.progress > 0 {
                ProgressView(value: scanVM.progress)
                    .progressViewStyle(.linear)
                    .frame(maxWidth: 300)
            } else {
                ProgressView()
                    .progressViewStyle(.linear)
                    .frame(maxWidth: 300)
            }

            Text("已扫描 \(scanVM.scannedFileCount) 个文件")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("取消", role: .cancel) {
                scanVM.cancelScan()
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .padding(40)
        .onAppear {
            startRotationAnimation()
        }
        .onDisappear {
            stopRotationAnimation()
        }
    }

    private func startRotationAnimation() {
        rotationAngle = 0
        rotationTimer?.invalidate()
        withAnimation(.linear(duration: 1.5)) {
            rotationAngle = 360
        }
        rotationTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            Task { @MainActor in
                withAnimation(.linear(duration: 1.5)) {
                    rotationAngle += 360
                }
            }
        }
    }

    private func stopRotationAnimation() {
        rotationTimer?.invalidate()
        rotationTimer = nil
    }

    private func handleDrop(providers: [NSItemProvider]) {
        guard let provider = providers.first else { return }
        provider.loadItem(forTypeIdentifier: UTType.folder.identifier, options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir),
                  isDir.boolValue else { return }
            DispatchQueue.main.async {
                scanVM.startScan(folder: url)
            }
        }
    }
}
