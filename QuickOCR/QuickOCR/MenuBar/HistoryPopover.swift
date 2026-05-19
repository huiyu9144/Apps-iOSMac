import SwiftUI

struct HistoryPopover: View {
    @StateObject private var history = CaptureHistory.shared

    var body: some View {
        VStack(spacing: 0) {
            if history.entries.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No history yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Press ⌘+⇧+O to capture text")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List {
                    ForEach(history.entries) { entry in
                        Button(action: {
                            ClipboardManager.shared.copy(entry.text)
                        }) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.previewText)
                                    .font(.subheadline)
                                    .lineLimit(3)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Text(entry.formattedTime)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            history.remove(at: index)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
}
