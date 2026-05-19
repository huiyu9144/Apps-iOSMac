import SwiftUI
import AppKit

struct MenuBarPopoverView: View {
    @ObservedObject var viewModel: NetMeterViewModel
    @State private var selectedProcess: ProcessTrafficInfo?
    @State private var hoveredPID: Int?

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)

            Divider()
                .padding(.horizontal, 12)

            ScrollView {
                VStack(spacing: 12) {
                    networkInfoSection
                    trafficOverviewSection

                    if viewModel.showLiveChart {
                        TrafficChartView(
                            history: viewModel.speedHistory,
                            formatSpeed: viewModel.formatSpeed
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    processListSection
                    TrafficReportView(
                        dailyTotals: viewModel.dailyTotals,
                        sessionUpload: viewModel.sessionUpload,
                        sessionDownload: viewModel.sessionDownload,
                        processes: viewModel.processes,
                        formatBytes: viewModel.formatBytes,
                        formatSpeed: viewModel.formatSpeed
                    )
                }
                .padding(12)
            }

            Divider()
                .padding(.horizontal, 12)

            quitButton
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
        }
        .frame(width: 340)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.windowBackgroundColor))
                .shadow(color: .black.opacity(0.12), radius: 24, y: 10)
        )
        .sheet(isPresented: $viewModel.showSettings) {
            SettingsView(viewModel: viewModel)
        }
        .sheet(item: $selectedProcess) { process in
            ProcessDetailSheet(process: process, formatSpeed: viewModel.formatSpeed, formatBytes: viewModel.formatBytes)
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.showLiveChart)
    }

    private var header: some View {
        HStack {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.accentColor)

            Text("NetMeter")
                .font(.system(size: 14, weight: .bold, design: .rounded))

            Spacer()

            Button {
                viewModel.showLiveChart.toggle()
            } label: {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(viewModel.showLiveChart ? .accentColor : .secondary)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(viewModel.showLiveChart ? Color.accentColor.opacity(0.12) : Color.clear)
                    )
            }
            .buttonStyle(.plain)
            .help(locStr("实时图表"))

            Button {
                viewModel.showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .help(locStr("设置…"))
        }
    }

    private var networkInfoSection: some View {
        HStack(spacing: 6) {
            Image(systemName: viewModel.isConnected ? "wifi" : "wifi.slash")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(viewModel.isConnected ? .green : .red)

            Text(viewModel.networkInfoText)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding(.horizontal, 4)
    }

    private var trafficOverviewSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.green)
                Text(locStr("上传"))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                Spacer()
                Text(viewModel.formatSpeed(viewModel.uploadSpeed))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.green)
                Text(locStr("今日") + ": " + viewModel.formatBytes(viewModel.sessionUpload))
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 4) {
                Image(systemName: "arrow.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.blue)
                Text(locStr("下载"))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                Spacer()
                Text(viewModel.formatSpeed(viewModel.downloadSpeed))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)
                Text(locStr("今日") + ": " + viewModel.formatBytes(viewModel.sessionDownload))
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(.controlBackgroundColor))
        )
    }

    private var processListSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(locStr("联网进程"))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)

                Spacer()

                Button {
                    viewModel.refreshProcesses()
                } label: {
                    if viewModel.processIsRefreshing {
                        ProgressView()
                            .scaleEffect(0.5)
                            .frame(width: 12, height: 12)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 9, weight: .medium))
                    }
                }
                .buttonStyle(.plain)
                .disabled(viewModel.processIsRefreshing)
                .help(locStr("刷新进程"))
                .padding(.trailing, 4)

                Menu {
                    ForEach(ProcessSortMode.allCases, id: \.self) { mode in
                        Button {
                            viewModel.setProcessSortMode(mode)
                        } label: {
                            HStack {
                                Text(mode.displayName)
                                if mode == viewModel.processSortMode {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 9, weight: .medium))
                        Text(viewModel.processSortMode.displayName)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(Color.accentColor.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
            }

            if viewModel.sortedProcesses.isEmpty {
                HStack {
                    Spacer()
                    Text(locStr("无结果"))
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.vertical, 8)
            } else {
                VStack(spacing: 3) {
                    ForEach(viewModel.sortedProcesses.prefix(8)) { process in
                        processRow(process)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(.controlBackgroundColor))
        )
    }

    private func processRow(_ process: ProcessTrafficInfo) -> some View {
        let totalSpeed = process.downloadSpeed + process.uploadSpeed
        let barRatio = viewModel.maxProcessSpeed > 0 ? CGFloat(totalSpeed / viewModel.maxProcessSpeed) : 0

        return HStack(spacing: 8) {
            // App icon
            ProcessIconView(pid: process.pid)
                .frame(width: 20, height: 20)

            // Name + bar
            VStack(alignment: .leading, spacing: 3) {
                Text(process.name)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .lineLimit(1)
                    .truncationMode(.tail)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(Color(NSColor.separatorColor).opacity(0.2))
                            .frame(height: 6)

                        HStack(spacing: 1) {
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(Color.green.opacity(0.75))
                                .frame(width: max(2, geo.size.width * barRatio * CGFloat(process.uploadSpeed / totalSpeed)))
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(Color.blue.opacity(0.75))
                                .frame(width: max(2, geo.size.width * barRatio * CGFloat(process.downloadSpeed / totalSpeed)))
                        }
                        .frame(height: 6)
                    }
                }
                .frame(height: 6)
            }

            // Speed text
            VStack(alignment: .trailing, spacing: 1) {
                Text("↑\(viewModel.formatSpeed(process.uploadSpeed))")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(.green)
                Text("↓\(viewModel.formatSpeed(process.downloadSpeed))")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(.blue)
            }
            .frame(width: 60)

            // Close button (on hover)
            if hoveredPID == process.pid {
                Button {
                    killApp(process)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.red.opacity(0.7))
                }
                .buttonStyle(.plain)
                .help(locStr("关闭应用"))
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(hoveredPID == process.pid ? Color.blue.opacity(0.08) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) {
                hoveredPID = hovering ? process.pid : nil
            }
        }
        .onTapGesture {
            selectedProcess = process
        }
    }

    private func killApp(_ process: ProcessTrafficInfo) {
        let pid = pid_t(process.pid)
        kill(pid, SIGTERM)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            if kill(pid, 0) == 0 {
                kill(pid, SIGKILL)
            }
        }
    }

    private var quitButton: some View {
        Button {
            NSApplication.shared.terminate(nil)
        } label: {
            HStack {
                Spacer()
                Text(locStr("退出应用"))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct ProcessIconView: View {
    let pid: Int
    @State private var icon: NSImage?

    var body: some View {
        Group {
            if let icon {
                Image(nsImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(.controlBackgroundColor), Color(.windowBackgroundColor)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .stroke(Color(.separatorColor).opacity(0.3), lineWidth: 0.5)
                    )
                    .overlay(
                        Image(systemName: "app.fill")
                            .font(.system(size: 7, weight: .medium))
                            .foregroundColor(.secondary.opacity(0.5))
                    )
            }
        }
        .onAppear {
            loadIcon()
        }
    }

    private func loadIcon() {
        if let app = NSRunningApplication(processIdentifier: pid_t(pid)),
           let appIcon = app.icon {
            icon = appIcon
        }
    }
}

struct ProcessDetailSheet: View {
    let process: ProcessTrafficInfo
    let formatSpeed: (Double) -> String
    let formatBytes: (UInt64) -> String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                ProcessIconView(pid: process.pid)
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(process.name)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                    Text("PID: \(process.pid)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            Divider()

            VStack(spacing: 12) {
                detailRow(label: locStr("上传速度"), value: formatSpeed(process.uploadSpeed), color: .green)
                detailRow(label: locStr("下载速度"), value: formatSpeed(process.downloadSpeed), color: .blue)
                Divider()
                detailRow(label: locStr("总上传"), value: formatBytes(process.totalBytesOut), color: .secondary)
                detailRow(label: locStr("总下载"), value: formatBytes(process.totalBytesIn), color: .secondary)
            }

            Spacer()

            Button(locStr("完成")) {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(20)
        .frame(width: 280, height: 280)
    }

    private func detailRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
    }
}
