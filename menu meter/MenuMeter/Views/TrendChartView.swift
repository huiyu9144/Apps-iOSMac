import SwiftUI
import Charts

struct TrendChartView: View {
    let entries: [CPUHistoryEntry]
    let color: Color

    var body: some View {
        Chart {
            ForEach(entries.suffix(120)) { entry in
                LineMark(
                    x: .value("", entry.timestamp),
                    y: .value("", entry.usage)
                )
                .foregroundStyle(color.opacity(0.6))
                .lineStyle(StrokeStyle(lineWidth: 1))
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(values: [0, 50, 100]) { _ in
                AxisGridLine().foregroundStyle(Color.separator.opacity(0.3))
            }
        }
        .chartYScale(domain: 0...100)
        .chartXScale(domain: xDomain)
    }

    private var xDomain: ClosedRange<Date> {
        let now = entries.last?.timestamp ?? Date()
        return now.addingTimeInterval(-3600)...now
    }
}
