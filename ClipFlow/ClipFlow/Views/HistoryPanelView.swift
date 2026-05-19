import SwiftUI

struct HistoryPanelView: View {
    @ObservedObject var clipboardMonitor: ClipboardMonitor
    private let searchService = SearchService()
    @State private var searchQuery = ""
    @State private var showClearConfirmation = false
    @State private var showCopiedToast = false
    @State private var selectedIndex: Int?
    @State private var searchFocused = false
    @State private var keyboardMonitor: Any?

    init(clipboardMonitor: ClipboardMonitor) {
        self.clipboardMonitor = clipboardMonitor
    }

    var body: some View {
        VStack(spacing: 0) {
            headerArea

            ZStack {
                if filteredItems.isEmpty {
                    emptyState
                } else {
                    itemsList
                }
            }

            footerView
        }
        .background(Color(.windowBackgroundColor))
        .overlay(alignment: .bottom) {
            if showCopiedToast {
                copiedToast
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 44)
            }
        }
        .alert("Clear all history?", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                clipboardMonitor.clearAll()
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .onAppear {
            let monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "f" {
                    searchFocused = true
                    return nil
                }
                if event.charactersIgnoringModifiers == "\u{001B}" {
                    if !searchQuery.isEmpty {
                        searchQuery = ""
                    } else {
                        NSApp.keyWindow?.performClose(nil)
                    }
                    return nil
                }
                if event.keyCode == 125 || event.keyCode == 126 {
                    if !searchFocused, !filteredItems.isEmpty {
                        if let idx = selectedIndex {
                            selectedIndex = event.keyCode == 125
                                ? min(idx + 1, filteredItems.count - 1)
                                : max(idx - 1, 0)
                        } else {
                            selectedIndex = 0
                        }
                        return nil
                    }
                    return event
                }
                if event.keyCode == 36, let idx = selectedIndex, idx < filteredItems.count {
                    clipboardMonitor.copyToClipboard(filteredItems[idx])
                    showCopyFeedback()
                    return nil
                }
                return event
            }
            keyboardMonitor = monitor
        }
        .onDisappear {
            if let monitor = keyboardMonitor as? AnyObject {
                NSEvent.removeMonitor(monitor)
            }
            keyboardMonitor = nil
        }
    }

    private var copiedToast: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(.green)
            Text("Copied")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }

    private var headerArea: some View {
        VStack(spacing: 0) {
            SearchBarView(searchQuery: $searchQuery, isFocused: $searchFocused)
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 10)

            Divider()
                .opacity(0.5)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.4))
            Text(searchQuery.isEmpty ? "No clipboard history yet" : "No results found")
                .font(.system(size: 13))
                .foregroundColor(.secondary.opacity(0.6))
            if !searchQuery.isEmpty {
                Text("Try a different search term")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.4))
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var itemsList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    let favorites = filteredItems.enumerated().filter { $0.element.isFavorite }
                    let nonFavorites = filteredItems.enumerated().filter { !$0.element.isFavorite }

                    if !favorites.isEmpty {
                        VStack(spacing: 2) {
                            ForEach(Array(favorites), id: \.element.id) { offset, item in
                                HistoryItemRow(
                                    item: item,
                                    onCopy: {
                                        clipboardMonitor.copyToClipboard(item)
                                        showCopyFeedback()
                                    },
                                    onToggleFavorite: { clipboardMonitor.toggleFavorite(item) },
                                    onDelete: { clipboardMonitor.removeItem(item) },
                                    isSelected: selectedIndex == offset
                                )
                                .id(item.id)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, 6)

                        if !nonFavorites.isEmpty {
                            sectionDivider
                        }
                    }

                    if !nonFavorites.isEmpty {
                        VStack(spacing: 2) {
                            ForEach(Array(nonFavorites), id: \.element.id) { offset, item in
                                HistoryItemRow(
                                    item: item,
                                    onCopy: {
                                        clipboardMonitor.copyToClipboard(item)
                                        showCopyFeedback()
                                    },
                                    onToggleFavorite: { clipboardMonitor.toggleFavorite(item) },
                                    onDelete: { clipboardMonitor.removeItem(item) },
                                    isSelected: selectedIndex == (favorites.count + offset)
                                )
                                .id(item.id)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, favorites.isEmpty ? 6 : 2)
                    }
                }
                .padding(.bottom, 6)
            }
            .onChange(of: selectedIndex) { _, newValue in
                if let idx = newValue, idx < filteredItems.count {
                    withAnimation {
                        proxy.scrollTo(filteredItems[idx].id, anchor: .center)
                    }
                }
            }
        }
    }

    private func showCopyFeedback() {
        withAnimation { showCopiedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation { showCopiedToast = false }
        }
    }

    private var sectionDivider: some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(Color(.separatorColor).opacity(0.15))
                .frame(height: 1)
            Text("History")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary.opacity(0.5))
                .fixedSize()
            Rectangle()
                .fill(Color(.separatorColor).opacity(0.15))
                .frame(height: 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var footerView: some View {
        VStack(spacing: 0) {
            Divider()
                .opacity(0.5)

            HStack(spacing: 4) {
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary.opacity(0.5))
                Text("\(clipboardMonitor.history.count) items")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.6))
                Spacer()
                Button(action: { showClearConfirmation = true }) {
                    Text("Clear")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.red.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }

    private var filteredItems: [ClipboardItem] {
        if searchQuery.isEmpty {
            return clipboardMonitor.history
        }
        return searchService.search(clipboardMonitor.history, query: searchQuery)
    }
}
