import SwiftUI

struct HistoryListView: View {
    @StateObject private var history = CaptureHistory.shared

    var body: some View {
        VStack(spacing: 0) {
            if history.entries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                    Text("No History")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Press ⌘+⇧+O to start capturing text from your screen")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(history.entries) { entry in
                        HistoryRow(result: entry)
                            .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
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

struct HistoryRow: View {
    let result: OCRResult
    @State private var isCopied = false

    var body: some View {
        Button(action: {
            ClipboardManager.shared.copy(result.text)
            isCopied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isCopied = false
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.previewText)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    HStack(spacing: 8) {
                        Text(result.formattedTime)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        if result.language != "en-US" {
                            Text(LanguageManager.shared.displayName(for: result.language))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                Spacer()
                if isCopied {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                } else {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
