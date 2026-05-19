import SwiftUI
import AppKit

struct MenuBarPopoverView: View {
    @ObservedObject var viewModel: NetMeterViewModel
    @State private var copiedPID: String?

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
                    WeeklyReportView(
                        dailyTotals: viewModel.dailyTotals,
                        formatBytes: viewModel.formatBytes
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
        .overlay(
            Group {
                if let pid = copiedPID {
                    Text(pid)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.black.opacity(0.75))
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    copiedPID = nil
                                }
                            }
                        }
                }
            },
            alignment: .top
        )
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
        VStack(alignment: .leading, spacing: 8) {
            Text(locStr("联网进程"))
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)

            if viewModel.processes.isEmpty {
                HStack {
                    Spacer()
                    Text(locStr("无结果"))
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.vertical, 8)
            } else {
                VStack(spacing: 2) {
                    ForEach(viewModel.processes.prefix(8)) { process in
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
        HStack(spacing: 8) {
            Text(process.name)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: 100, alignment: .leading)

            Spacer()

            Text("↑\(viewModel.formatSpeed(process.uploadSpeed))")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.green)
                .frame(width: 70, alignment: .trailing)

            Text("↓\(viewModel.formatSpeed(process.downloadSpeed))")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.blue)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(.controlBackgroundColor).opacity(0.5))
        )
        .contextMenu {
            Button(locStr("复制 PID")) {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString("\(process.pid)", forType: .string)
                withAnimation(.easeOut(duration: 0.15)) {
                    copiedPID = locStr("已复制") + ": \(process.pid)"
                }
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
