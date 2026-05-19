import SwiftUI

struct WeeklyReportView: View {
    let dailyTotals: [(date: Date, upload: UInt64, download: UInt64)]
    let formatBytes: (UInt64) -> String

    private var weekDays: [(label: String, date: Date, upload: UInt64, download: UInt64)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var result: [(label: String, date: Date, upload: UInt64, download: UInt64)] = []

        let dayLabels = [
            locStr("周一"), locStr("周二"), locStr("周三"),
            locStr("周四"), locStr("周五"), locStr("周六"), locStr("周日")
        ]

        for i in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let weekday = calendar.component(.weekday, from: date)
            let labelIndex = weekday == 1 ? 6 : weekday - 2
            let label = dayLabels.indices.contains(labelIndex) ? dayLabels[labelIndex] : ""

            let matched = dailyTotals.first { calendar.isDate($0.date, inSameDayAs: date) }
            let upload = matched?.upload ?? 0
            let download = matched?.download ?? 0

            result.append((label: label, date: date, upload: upload, download: download))
        }

        return result
    }

    private var maxTotal: UInt64 {
        weekDays.map { $0.upload + $0.download }.max() ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(locStr("每周流量报告"))
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)

            if weekDays.allSatisfy({ $0.upload == 0 && $0.download == 0 }) {
                Text(locStr("无流量数据"))
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else {
                VStack(spacing: 6) {
                    ForEach(weekDays, id: \.date) { day in
                        let total = day.upload + day.download
                        let barWidth: CGFloat = maxTotal > 0 ? CGFloat(total) / CGFloat(maxTotal) : 0

                        HStack(spacing: 8) {
                            Text(day.label)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                                .frame(width: 28, alignment: .trailing)

                            GeometryReader { geo in
                                HStack(spacing: 2) {
                                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                                        .fill(Color.blue.opacity(0.7))
                                        .frame(width: max(0, geo.size.width * barWidth * 0.7))

                                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                                        .fill(Color.green.opacity(0.7))
                                        .frame(width: max(0, geo.size.width * barWidth * 0.3))
                                }
                            }
                            .frame(height: 14)

                            Text(formatBytes(total))
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                                .frame(width: 55, alignment: .trailing)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color(.controlBackgroundColor)))
    }
}
