import SwiftUI

struct SearchBarView: View {
    @Binding var searchQuery: String
    @Binding var isFocused: Bool

    init(searchQuery: Binding<String>, isFocused: Binding<Bool> = .constant(false)) {
        self._searchQuery = searchQuery
        self._isFocused = isFocused
    }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)

            TextField("Search history", text: $searchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 13))

            if !searchQuery.isEmpty {
                Button(action: {
                    searchQuery = ""
                    isFocused = true
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(.textBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isFocused ? Color.accentColor.opacity(0.4) : Color.clear, lineWidth: 1)
        )
    }
}
