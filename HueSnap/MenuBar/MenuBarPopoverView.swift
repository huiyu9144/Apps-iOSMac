import SwiftUI

enum PopoverTab: String, CaseIterable {
    case home
    case settings

    var label: String {
        switch self {
        case .home: return locStr("首页")
        case .settings: return locStr("设置")
        }
    }
}

private struct ContentHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct MenuBarPopoverView: View {
    @Bindable var viewModel: HueSnapViewModel
    @State private var selectedTab: PopoverTab = .home
    @State private var contentHeight: CGFloat = 0
    @AppStorage("appLanguage") private var appLanguage: String = "system"

    private let columns = [
        GridItem(.adaptive(minimum: 52, maximum: 60), spacing: 6)
    ]

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 8) {
                    tabBar

                    if selectedTab == .home {
                        homeContent
                    } else {
                        settingsContent
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
            }
            .frame(width: 340)
            .frame(maxHeight: contentHeight > 0 ? min(contentHeight, 520) : 300)

            if let toast = viewModel.copiedToast {
                toastOverlay(text: toast)
            }
        }
        .background(Color(.windowBackgroundColor))
        .background(
            tabMeasurementContent
        )
        .onPreferenceChange(ContentHeightKey.self) { value in
            contentHeight = value
        }
    }

    @ViewBuilder
    private var tabMeasurementContent: some View {
        VStack(spacing: 8) {
            homeContent
            settingsContent
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(width: 340)
        .hidden()
        .background(
            GeometryReader { geo in
                Color.clear
                    .preference(key: ContentHeightKey.self, value: geo.size.height)
            }
        )
    }

    private var tabBar: some View {
        HStack(spacing: 8) {
            ForEach(Array(PopoverTab.allCases.enumerated()), id: \.element) { index, tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Text(tab.label)
                            .font(.system(size: selectedTab == tab ? 13 : 12, weight: selectedTab == tab ? .semibold : .regular, design: .default))
                            .foregroundColor(selectedTab == tab ? .primary : .secondary)
                        Rectangle()
                            .fill(selectedTab == tab ? Color.accentColor : Color.clear)
                            .frame(height: 2)
                            .frame(maxWidth: 20)
                            .clipShape(Capsule())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var homeContent: some View {
        pickerCard

        if !viewModel.history.isEmpty {
            historyCard
        }

        paletteCard

        if let color = viewModel.currentColor {
            currentColorCard(color: color)
            actionButtonsCard(color: color)
            formatCard
        }

        quitText
    }

    @ViewBuilder
    private var settingsContent: some View {
        languageCard
        aboutCard
        quitCard
    }

    private var pickerCard: some View {
        Button {
            viewModel.startPicking()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "eyedropper")
                    .font(.system(size: 14, weight: .medium))
                Text(locStr("开始取色"))
                    .font(.system(size: 14, weight: .semibold, design: .default))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(
                LinearGradient(colors: [Color.blue, Color.purple], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(locStr("取色历史"))
                .font(.system(size: 11, weight: .semibold, design: .default))
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.history) { color in
                        historyColorButton(color: color)
                    }
                }
            }
        }
        .padding(14)
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func historyColorButton(color: PickedColor) -> some View {
        Button {
            viewModel.selectFromHistory(color)
        } label: {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(red: color.red, green: color.green, blue: color.blue))
                .frame(width: 32, height: 32)
                .overlay(
                    Group {
                        if viewModel.currentColor?.id == color.id {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.white.opacity(0.6), lineWidth: 2)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var paletteCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(locStr("色板"))
                    .font(.system(size: 11, weight: .semibold, design: .default))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)

                Spacer()

                if !viewModel.palette.isEmpty {
                    Menu {
                        Button(locStr("导出色板")) {
                            viewModel.exportPalette()
                        }
                        Button(locStr("导入色板")) {
                            viewModel.importPalette()
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 32, height: 32)
                            .background(Color(.separatorColor).opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            if viewModel.palette.isEmpty {
                Text(locStr("保存到色板"))
                    .font(.system(size: 12, weight: .regular, design: .default))
                    .foregroundColor(Color(.tertiaryLabelColor))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(viewModel.palette) { color in
                        paletteColorButton(color: color)
                            .contextMenu {
                                Button(locStr("删除")) {
                                    viewModel.removeFromPalette(color)
                                }
                            }
                    }
                }
            }
        }
        .padding(14)
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func paletteColorButton(color: PickedColor) -> some View {
        Button {
            viewModel.selectPaletteColor(color)
        } label: {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(red: color.red, green: color.green, blue: color.blue))
                .frame(height: 40)
                .overlay(
                    Group {
                        if viewModel.currentColor?.id == color.id {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.white.opacity(0.6), lineWidth: 2)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
    }

    private func currentColorCard(color: PickedColor) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(red: color.red, green: color.green, blue: color.blue))
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(color.hex)
                    .font(.system(size: 16, weight: .bold, design: .default))
                    .foregroundColor(.primary)

                HStack(spacing: 8) {
                    Text(color.rgbString())
                        .font(.system(size: 11, weight: .medium, design: .default))
                        .foregroundColor(.secondary)

                    let twName = viewModel.closestTailwindName(red: color.red, green: color.green, blue: color.blue)
                    Text("tailwind: \(twName)")
                        .font(.system(size: 11, weight: .medium, design: .default))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(14)
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func actionButtonsCard(color: PickedColor) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                copyButton(title: locStr("复制Hex"), format: .hex)
                copyButton(title: locStr("复制RGB"), format: .rgb)
                copyButton(title: locStr("复制HSL"), format: .hsl)
            }

            HStack(spacing: 6) {
                copyButton(title: locStr("复制Tailwind"), format: .tailwind)

                Button {
                    viewModel.saveToPalette()
                } label: {
                    Text(locStr("保存到色板"))
                        .font(.system(size: 12, weight: .semibold, design: .default))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(colors: [Color.blue, Color.purple], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func copyButton(title: String, format: ColorFormat) -> some View {
        Button {
            viewModel.copyCurrentColor(format: format)
        } label: {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .default))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(.separatorColor).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var formatCard: some View {
        HStack {
            Text(locStr("输出格式"))
                .font(.system(size: 13, weight: .medium, design: .default))
                .foregroundColor(.secondary)

            Spacer()

            Picker("", selection: $viewModel.selectedFormat) {
                ForEach(ColorFormat.allCases, id: \.self) { format in
                    Text(format.rawValue).tag(format)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 110)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var quitText: some View {
        Button {
            NSApplication.shared.terminate(nil)
        } label: {
            Text(locStr("退出应用"))
                .font(.system(size: 12, weight: .medium, design: .default))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }

    private var languageCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "globe")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.blue)
                .frame(width: 30, height: 30)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text(locStr("语言"))
                    .font(.system(size: 14, weight: .semibold, design: .default))
                    .foregroundColor(.primary)
                Text(locStr("应用界面显示语言"))
                    .font(.system(size: 11, weight: .regular, design: .default))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Picker("", selection: $appLanguage) {
                ForEach(Language.allCases, id: \.rawValue) { lang in
                    Text(lang.displayName).tag(lang.rawValue)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 110)
            .onChange(of: appLanguage) { _, _ in
                notifyLanguageChange()
            }
        }
        .padding(14)
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var aboutCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "eyedropper")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.accentColor)
                .frame(width: 30, height: 30)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text("HueCatch")
                    .font(.system(size: 14, weight: .semibold, design: .default))
                    .foregroundColor(.primary)
                Text(locStr("版本") + " 1.0")
                    .font(.system(size: 11, weight: .regular, design: .default))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var quitCard: some View {
        Button {
            NSApplication.shared.terminate(nil)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.red)
                    .frame(width: 30, height: 30)
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                Text(locStr("退出应用"))
                    .font(.system(size: 14, weight: .medium, design: .default))
                    .foregroundColor(.red)

                Spacer()
            }
            .padding(14)
            .background(Color(.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func notifyLanguageChange() {
        if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
            appDelegate.rebuildPopoverContent()
        }
        NotificationCenter.default.post(name: NSNotification.Name("LanguageChanged"), object: nil)
    }

    private func toastOverlay(text: String) -> some View {
        VStack {
            Spacer()
            Text(text)
                .font(.system(size: 12, weight: .medium, design: .default))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.8))
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.bottom, 16)
        }
    }
}
