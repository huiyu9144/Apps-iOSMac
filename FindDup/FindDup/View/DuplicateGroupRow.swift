import SwiftUI

struct DuplicateGroupRow: View {
    let group: DuplicateGroup
    let isExpanded: Bool
    let isGroupSelected: Bool
    let isGroupPartiallySelected: Bool
    let selectedFileIDs: Set<UUID>
    let selectMode: ResultViewModel.SelectMode
    let onToggle: () -> Void
    let onToggleGroup: () -> Void
    let onToggleFile: (UUID) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggle) {
                HStack(spacing: 8) {
                    Button(action: {
                        onToggleGroup()
                    }) {
                        Image(systemName: isGroupPartiallySelected
                            ? "minus.circle"
                            : (isGroupSelected ? "checkmark.circle.fill" : "circle"))
                            .font(.title3)
                            .foregroundStyle(isGroupSelected || isGroupPartiallySelected ? .blue : .secondary)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Image(systemName: "doc.on.doc")
                        .font(.title3)
                        .foregroundStyle(.blue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(group.displayName)
                            .font(.body)
                            .fontWeight(.medium)
                            .lineLimit(1)
                            .foregroundStyle(.primary)

                        Text(verbatim: "\(group.fileCount) " + loc("个副本 · 共 ", " copies · ") + group.formattedTotalSize)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle")
                            .font(.caption)
                        Text(verbatim: loc("可节省 ", "Save ") + group.formattedWastedSize)
                            .font(.caption)
                    }
                    .foregroundStyle(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.green.opacity(0.1))
                    .cornerRadius(6)

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 0) {
                    Divider()
                    ForEach(Array(group.files.enumerated()), id: \.element.id) { index, file in
                        FileRowView(
                            file: file,
                            isSelected: selectedFileIDs.contains(file.id),
                            isPreserved: index == 0 && selectMode == .extras,
                            onToggle: { onToggleFile(file.id) }
                        )
                        if file.id != group.files.last?.id {
                            Divider()
                        }
                    }
                }
                .padding(.leading, 40)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(.background)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.25), lineWidth: 0.5)
        )
    }
}
