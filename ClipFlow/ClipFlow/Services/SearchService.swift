import Foundation

class SearchService {
    func search(_ items: [ClipboardItem], query: String) -> [ClipboardItem] {
        guard !query.isEmpty else { return items }

        let lowercasedQuery = query.lowercased()

        return items.filter { item in
            switch item.type {
            case .text, .rtf:
                return item.textContent?.lowercased().contains(lowercasedQuery) ?? false
            case .image:
                return false
            case .files:
                return item.fileURLs?.contains { url in
                    url.lowercased().contains(lowercasedQuery)
                } ?? false
            }
        }
    }
}
