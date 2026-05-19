import SwiftUI

struct HistoryItemRow: View {
    let item: ClipboardItem
    let onCopy: () -> Void
    let onToggleFavorite: () -> Void
    let onDelete: () -> Void
    var isSelected: Bool = false

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onToggleFavorite) {
                Image(systemName: item.isFavorite ? "pin.fill" : "pin")
                    .font(.system(size: 10))
                    .foregroundColor(item.isFavorite ? .orange : .secondary.opacity(0.4))
                    .frame(width: 20, height: 20)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(item.isFavorite ? "Unpin" : "Pin to favorites")

            contentView
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 6) {
                if isHovering {
                    Button(action: onCopy) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                    .help("Copy")
                    .transition(.move(edge: .trailing).combined(with: .opacity))

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.red)
                    .help("Delete")
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                }

                Text(Formatters.relativeTime(from: item.createdAt))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.6))
                    .frame(minWidth: 36, alignment: .trailing)
            }
            .animation(.easeInOut(duration: 0.15), value: isHovering)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : isHovering ? Color(.selectedControlColor).opacity(0.25) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovering = hovering
            }
        }
        .onTapGesture {
            onCopy()
        }
    }

    @ViewBuilder
    private var contentView: some View {
        HStack(spacing: 8) {
            switch item.type {
            case .text, .rtf:
                typeIcon
                    .foregroundColor(.accentColor)

                Text(item.textPreview)
                    .font(.system(size: 12, design: isCode(item.textPreview) ? .monospaced : .default))
                    .lineLimit(2)
                    .foregroundColor(.primary)

            case .image:
                if let imageData = item.imageData, let nsImage = NSImage(data: imageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 36, height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color(.separatorColor).opacity(0.2))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        )
                }
                Text("Image")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

            case .files:
                Image(systemName: "folder")
                    .font(.system(size: 11))
                    .foregroundColor(.accentColor)
                if let urls = item.fileURLs, let firstURL = urls.first {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(URL(string: firstURL)?.lastPathComponent ?? "")
                            .font(.system(size: 12))
                            .lineLimit(1)
                            .foregroundColor(.primary)
                        if urls.count > 1 {
                            Text("+\(urls.count - 1) more")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var typeIcon: some View {
        Image(systemName: Formatters.contentTypeIcon(for: item.type))
            .font(.system(size: 11))
            .frame(width: 16)
    }

    private func isCode(_ text: String) -> Bool {
        let patterns = ["func ", "import ", "class ", "struct ", "enum ", "let ", "var ", "if ", "for ", "while ", "return ", "def ", "public ", "private ", "```", "//", "/*", "#include", "interface"]
        return patterns.contains { text.hasPrefix($0) }
    }
}
