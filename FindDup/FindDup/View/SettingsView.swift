import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("设置")
                    .font(.headline)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            Divider()

            ScrollView {
                VStack(spacing: 0) {
                    groupHeader(icon: "magnifyingglass", title: "扫描")
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("最小文件大小")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Picker("", selection: $viewModel.minimumFileSize) {
                            Text("1 KB").tag(Int64(1024))
                            Text("10 KB").tag(Int64(10 * 1024))
                            Text("100 KB").tag(Int64(100 * 1024))
                            Text("1 MB").tag(Int64(1024 * 1024))
                            Text("10 MB").tag(Int64(10 * 1024 * 1024))
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        Text("小于此大小的文件将被跳过")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)

                    Divider()
                        .padding(.horizontal, 20)

                    groupHeader(icon: "trash", title: "删除")
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            DeleteOptionCard(
                                isSelected: viewModel.deleteToTrash,
                                icon: "trash",
                                title: "移到废纸篓",
                                subtitle: "安全，可还原"
                            )
                            .onTapGesture { viewModel.deleteToTrash = true }

                            DeleteOptionCard(
                                isSelected: !viewModel.deleteToTrash,
                                icon: "xmark.bin",
                                title: "直接删除",
                                subtitle: "不可恢复"
                            )
                            .onTapGesture { viewModel.deleteToTrash = false }
                        }
                        .frame(height: 68)

                        HStack(spacing: 6) {
                            Image(systemName: "info.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            Text("推荐「移到废纸篓」，误删可从废纸篓找回")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)

                    Divider()
                        .padding(.horizontal, 20)

                    groupHeader(icon: "line.3.horizontal.decrease", title: "筛选")
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("文件类型")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Picker("", selection: $viewModel.fileTypeFilter) {
                            ForEach(FileTypeFilter.allCases, id: \.self) { filter in
                                Text(filter.rawValue).tag(filter)
                            }
                        }
                        .pickerStyle(.radioGroup)
                        .labelsHidden()
                        Text("仅扫描所选类型的文件，设为「全部文件」则扫描所有类型")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
            }

            Divider()

            HStack {
                Spacer()
                Button("完成") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .frame(width: 480, height: 480)
    }

    private func groupHeader(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.blue)
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            Spacer()
        }
    }
}

private struct DeleteOptionCard: View {
    let isSelected: Bool
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(isSelected ? .blue : .secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .medium : .regular)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.blue)
            }
        }
        .padding(12)
        .background(isSelected ? Color.blue.opacity(0.08) : Color.clear)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.gray.opacity(0.25), lineWidth: isSelected ? 1.5 : 0.5)
        )
    }
}
