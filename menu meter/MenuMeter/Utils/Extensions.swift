import SwiftUI

// MARK: - Adaptive Colors
extension Color {
    static let label = Color(nsColor: .labelColor)
    static let secondaryLabel = Color(nsColor: .secondaryLabelColor)
    static let tertiaryLabel = Color(nsColor: .tertiaryLabelColor)
    static let quaternaryLabel = Color(nsColor: .quaternaryLabelColor)
    static let separator = Color(nsColor: .separatorColor)
    static let windowBackground = Color(nsColor: .windowBackgroundColor)
    static let accent = Color(nsColor: .controlAccentColor)

    static func usageColor(_ v: Double) -> Color {
        v > 95 ? .red : v > 80 ? .orange : accent
    }

    static func batteryColor(_ v: Double) -> Color {
        v < 0.2 ? .red : v < 0.5 ? .orange : accent
    }
}

// MARK: - Thin Progress Bar
struct ThinBar: View {
    let value: Double
    let color: Color
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.separator.opacity(0.15))
                Capsule().fill(color.gradient)
                    .frame(width: geo.size.width * CGFloat(min(max(value, 0), 1)))
            }
        }
        .frame(height: 6)
    }
}

// MARK: - Section Wrapper
struct SectionBox<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 10) { content }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))
            .cornerRadius(8)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
    }
}

// MARK: - Section Header
struct SecLabel: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondaryLabel)
            Text(text)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondaryLabel)
        }
    }
}

// MARK: - Monospaced Value
struct Mono: View {
    let text: String
    var color: Color = .label
    var size: CGFloat = 13
    var weight: Font.Weight = .bold
    var body: some View {
        Text(text)
            .font(.system(size: size, weight: weight, design: .monospaced))
            .foregroundColor(color)
    }
}

// MARK: - Collapsible Details
struct CollapsibleDetails<Content: View>: View {
    let label: String
    @Binding var expanded: Bool
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { expanded.toggle() } }) {
                HStack(spacing: 4) {
                    Image(systemName: expanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.tertiaryLabel)
                    Text(label)
                        .font(.system(size: 9))
                        .foregroundColor(.tertiaryLabel)
                    Spacer()
                }
                .contentShape(Rectangle())
                .padding(.vertical, 2)
            }
            .buttonStyle(.plain)

            if expanded {
                content
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .padding(.top, 6)
            }
        }
    }
}
