import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var langManager = LocalizationManager.shared

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(verbatim: loc("设置", "Settings"))
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
                    groupHeader(icon: "magnifyingglass", title: loc("扫描", "Scan"))
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(verbatim: loc("最小文件大小", "Minimum File Size"))
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
                        Text(verbatim: loc("小于此大小的文件将被跳过", "Files smaller than this will be skipped"))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)

                    Divider()
                        .padding(.horizontal, 20)

                    groupHeader(icon: "trash", title: loc("删除", "Delete"))
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            DeleteOptionCard(
                                isSelected: viewModel.deleteToTrash,
                                icon: "trash",
                                title: loc("移到废纸篓", "Move to Trash"),
                                subtitle: loc("安全，可还原", "Safe, Recoverable")
                            )
                            .onTapGesture { viewModel.deleteToTrash = true }

                            DeleteOptionCard(
                                isSelected: !viewModel.deleteToTrash,
                                icon: "xmark.bin",
                                title: loc("直接删除", "Delete Permanently"),
                                subtitle: loc("不可恢复", "Irreversible")
                            )
                            .onTapGesture { viewModel.deleteToTrash = false }
                        }
                        .frame(height: 68)

                        HStack(spacing: 6) {
                            Image(systemName: "info.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            Text(verbatim: loc("推荐「移到废纸篓」，误删可从废纸篓找回", "Recommended: Move to Trash, recoverable if deleted by mistake"))
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)

                    Divider()
                        .padding(.horizontal, 20)

                    groupHeader(icon: "line.3.horizontal.decrease", title: loc("筛选", "Filter"))
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(verbatim: loc("文件类型", "File Types"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Picker("", selection: $viewModel.fileTypeFilter) {
                            ForEach(FileTypeFilter.allCases, id: \.self) { filter in
                                Text(verbatim: filter.localizedName).tag(filter)
                            }
                        }
                        .pickerStyle(.radioGroup)
                        .labelsHidden()
                        Text(verbatim: loc("仅扫描所选类型的文件，设为「全部文件」则扫描所有类型", "Only scan selected file types. Set to 'All Files' to scan everything"))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)

                    Divider()
                        .padding(.horizontal, 20)

                    groupHeader(icon: "globe", title: loc("语言", "Language"))
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    VStack(alignment: .leading, spacing: 6) {
                        Picker("", selection: $langManager.currentLanguage) {
                            ForEach(AppLanguage.allCases, id: \.self) { lang in
                                Text(verbatim: lang.displayName).tag(lang)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        Text(verbatim: loc("选择App显示语言", "Choose the display language for the app"))
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
                Button(action: { dismiss() }, label: {
                    Text(verbatim: loc("完成", "Done"))
                })
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .frame(width: 520, height: 540)
    }

    private func groupHeader(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.blue)
            Text(verbatim: title)
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
                Text(verbatim: title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .medium : .regular)
                Text(verbatim: subtitle)
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
