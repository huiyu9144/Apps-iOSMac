import SwiftUI

enum ReportPeriod: String, CaseIterable {
    case day = "day"
    case week = "week"
    case month = "month"

    var displayName: String {
        switch self {
        case .day: return locStr("日")
        case .week: return locStr("周")
        case .month: return locStr("月")
        }
    }
}

struct TrafficReportView: View {
    let dailyTotals: [(date: Date, upload: UInt64, download: UInt64)]
    let sessionUpload: UInt64
    let sessionDownload: UInt64
    let processes: [ProcessTrafficInfo]
    let formatBytes: (UInt64) -> String
    let formatSpeed: (Double) -> String

    @State private var selectedPeriod: ReportPeriod = .week

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(locStr("流量报告"))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)

                Spacer()

                Picker("", selection: $selectedPeriod) {
                    ForEach(ReportPeriod.allCases, id: \.self) { period in
                        Text(period.displayName).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 130)
                .scaleEffect(0.8)
            }

            VStack(spacing: 10) {
                todayTotalsHeader
                periodBars
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color(.controlBackgroundColor)))
    }

    private var todayTotalsHeader: some View {
        VStack(spacing: 4) {
            HStack {
                Text(locStr("今日流量"))
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                Spacer()
            }
            HStack(spacing: 16) {
                Label {
                    Text(formatBytes(sessionUpload))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                } icon: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.green)
                }
                Label {
                    Text(formatBytes(sessionDownload))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                } icon: {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.blue)
                }
                Spacer()
            }
        }
    }

    private var periodBars: some View {
        Group {
            switch selectedPeriod {
            case .day:
                processBars
            case .week:
                weekBars
            case .month:
                monthBars
            }
        }
    }

    private var processBars: some View {
        Group {
            if processes.isEmpty {
                emptyState
            } else {
                VStack(spacing: 6) {
                    HStack {
                        Text(locStr("应用占比"))
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                        Spacer()
                    }

                    let totalSpeed = max(processes.reduce(0) { $0 + $1.uploadSpeed + $1.downloadSpeed }, 1)

                    ForEach(processes.prefix(6)) { process in
                        let speed = process.uploadSpeed + process.downloadSpeed
                        let ratio = CGFloat(speed / totalSpeed)

                        HStack(spacing: 6) {
                            ProcessIconView(pid: process.pid)
                                .frame(width: 14, height: 14)

                            Text(process.name)
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .frame(maxWidth: 70, alignment: .leading)

                            GeometryReader { geo in
                                RoundedRectangle(cornerRadius: 3, style: .continuous)
                                    .fill(Color.accentColor.opacity(0.6))
                                    .frame(width: max(2, geo.size.width * ratio))
                            }
                            .frame(height: 8)

                            Text(formatBytes(UInt64(speed)))
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(width: 48, alignment: .trailing)
                        }
                    }

                    if processes.count > 6 {
                        Text("+\(processes.count - 6) \(locStr("更多"))")
                            .font(.system(size: 9, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private var weekBars: some View {
        let data = buildWeekDays().sorted { $0.upload + $0.download > $1.upload + $1.download }
        if data.allSatisfy({ $0.upload == 0 && $0.download == 0 }) {
            return AnyView(emptyState)
        }
        let maxTotal = max(data.map { $0.upload + $0.download }.max() ?? 1, 1)
        return AnyView(barList(data: data, labelWidth: 28, barHeight: 14, valueWidth: 55, maxTotal: maxTotal))
    }

    private var monthBars: some View {
        let data = buildMonthDays().sorted { $0.upload + $0.download > $1.upload + $1.download }
        if data.allSatisfy({ $0.upload == 0 && $0.download == 0 }) {
            return AnyView(emptyState)
        }
        let maxTotal = max(data.map { $0.upload + $0.download }.max() ?? 1, 1)
        return AnyView(barList(data: data, labelWidth: 22, barHeight: 8, valueWidth: 40, maxTotal: maxTotal))
    }

    private func barList(data: [(label: String, date: Date, upload: UInt64, download: UInt64)], labelWidth: CGFloat, barHeight: CGFloat, valueWidth: CGFloat, maxTotal: UInt64) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 3) {
                ForEach(Array(data.enumerated()), id: \.offset) { _, day in
                    let total = day.upload + day.download
                    let barWidth: CGFloat = CGFloat(total) / CGFloat(maxTotal)

                    HStack(spacing: 6) {
                        Text(day.label)
                            .font(.system(size: barHeight > 10 ? 10 : 8, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .frame(width: labelWidth, alignment: .trailing)

                        GeometryReader { geo in
                            HStack(spacing: 1) {
                                RoundedRectangle(cornerRadius: 2, style: .continuous)
                                    .fill(Color.blue.opacity(0.7))
                                    .frame(width: max(0, geo.size.width * barWidth * 0.7))
                                RoundedRectangle(cornerRadius: 2, style: .continuous)
                                    .fill(Color.green.opacity(0.7))
                                    .frame(width: max(0, geo.size.width * barWidth * 0.3))
                            }
                        }
                        .frame(height: barHeight)

                        Text(formatBytes(total))
                            .font(.system(size: barHeight > 10 ? 9 : 7, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .frame(width: valueWidth, alignment: .trailing)
                    }
                }
            }
        }
        .frame(maxHeight: selectedPeriod == .month ? 120 : .infinity)
    }

    private var emptyState: some View {
        Text(locStr("无流量数据"))
            .font(.system(size: 12, design: .rounded))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, minHeight: 50)
    }

    private func buildWeekDays() -> [(label: String, date: Date, upload: UInt64, download: UInt64)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayLabels = [
            locStr("周一"), locStr("周二"), locStr("周三"),
            locStr("周四"), locStr("周五"), locStr("周六"), locStr("周日")
        ]

        return (0..<7).reversed().compactMap { i in
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { return nil }
            let weekday = calendar.component(.weekday, from: date)
            let labelIndex = weekday == 1 ? 6 : weekday - 2
            let label = dayLabels.indices.contains(labelIndex) ? dayLabels[labelIndex] : ""

            if calendar.isDate(date, inSameDayAs: today) {
                return (label: label, date: date, upload: sessionUpload, download: sessionDownload)
            }
            let matched = dailyTotals.first { calendar.isDate($0.date, inSameDayAs: date) }
            return (label: label, date: date, upload: matched?.upload ?? 0, download: matched?.download ?? 0)
        }
    }

    private func buildMonthDays() -> [(label: String, date: Date, upload: UInt64, download: UInt64)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let components = calendar.dateComponents([.year, .month], from: today)
        guard let monthStart = calendar.date(from: components),
              let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) else { return [] }

        let todayDay = calendar.component(.day, from: today)
        let endDay = calendar.component(.day, from: monthEnd)

        return (1...endDay).compactMap { day in
            guard let date = calendar.date(bySetting: .day, value: day, of: today) else { return nil }

            if day == todayDay {
                return (label: "\(day)", date: date, upload: sessionUpload, download: sessionDownload)
            } else if day > todayDay {
                return (label: "\(day)", date: date, upload: 0, download: 0)
            } else {
                let matched = dailyTotals.first { calendar.isDate($0.date, inSameDayAs: date) }
                return (label: "\(day)", date: date, upload: matched?.upload ?? 0, download: matched?.download ?? 0)
            }
        }
    }
}
