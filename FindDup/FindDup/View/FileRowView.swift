import SwiftUI

struct FileRowView: View {
    let file: FileInfo
    let isSelected: Bool
    let isPreserved: Bool
    let onToggle: () -> Void
    @ObservedObject private var langManager = LocalizationManager.shared

    var body: some View {
        let _ = langManager
        HStack(spacing: 10) {
            if isPreserved {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(width: 16)
            } else {
                Toggle("", isOn: Binding(
                    get: { isSelected },
                    set: { _ in onToggle() }
                ))
                .toggleStyle(.checkbox)
                .labelsHidden()
            }

            FileIconView(fileExtension: file.fileExtension)
                .frame(width: 24, height: 24)
                .foregroundStyle(isPreserved ? .tertiary : .primary)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(file.fileName)
                        .font(.callout)
                        .lineLimit(1)
                        .foregroundStyle(isPreserved ? .tertiary : .primary)
                    if isPreserved {
                        Text(verbatim: loc("保留", "Preserved"))
                            .font(.caption2)
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                Text(file.url.deletingLastPathComponent().path)
                    .font(.caption2)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(file.formattedSize)
                    .font(.caption)
                    .foregroundStyle(isPreserved ? .tertiary : .secondary)

                Text(file.modificationDate, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .opacity(isPreserved ? 0.7 : 1)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}

struct FileIconView: View {
    let fileExtension: String

    var body: some View {
        Group {
            if ["jpg", "jpeg", "png", "gif", "heic", "webp"].contains(fileExtension) {
                Image(systemName: "photo")
                    .foregroundStyle(.blue)
            } else if ["pdf", "doc", "docx", "txt", "md", "rtf"].contains(fileExtension) {
                Image(systemName: "doc.text")
                    .foregroundStyle(.orange)
            } else if ["mp4", "mov", "avi", "mkv"].contains(fileExtension) {
                Image(systemName: "video")
                    .foregroundStyle(.purple)
            } else if ["mp3", "wav", "aac", "flac", "m4a"].contains(fileExtension) {
                Image(systemName: "music.note")
                    .foregroundStyle(.red)
            } else {
                Image(systemName: "doc")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
