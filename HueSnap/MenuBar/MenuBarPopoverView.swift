import SwiftUI

struct MenuBarPopoverView: View {
    @State var viewModel: HueSnapViewModel

    private let columns = [
        GridItem(.adaptive(minimum: 52, maximum: 60), spacing: 6)
    ]

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                    Divider()
                        .padding(.horizontal, 12)

                    pickerButtonSection
                    Divider()
                        .padding(.horizontal, 12)

                    if !viewModel.history.isEmpty {
                        historySection
                        Divider()
                            .padding(.horizontal, 12)
                    }

                    paletteSection

                    if let color = viewModel.currentColor {
                        Divider()
                            .padding(.horizontal, 12)
                        currentColorSection(color: color)
                        Divider()
                            .padding(.horizontal, 12)
                        actionButtonsSection(color: color)
                        Divider()
                            .padding(.horizontal, 12)
                        formatSection
                    }

                    Divider()
                        .padding(.horizontal, 12)
                    quitSection
                }
                .padding(.vertical, 8)
            }
            .frame(width: 340, height: 520)

            if let toast = viewModel.copiedToast {
                toastOverlay(text: toast)
            }
        }
        .background(Color(.controlBackgroundColor))
    }

    private var headerSection: some View {
        HStack {
            Text("HueSnap")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Spacer()

            Button {
                if let appDelegate = NSApplication.shared.delegate as? AppDelegate {
                    appDelegate.openSettings()
                }
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .scaleEffect(0.95)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var pickerButtonSection: some View {
        Button {
            viewModel.startPicking()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "eyedropper")
                    .font(.system(size: 14, weight: .medium))
                Text("⌘+⇧+C  \(locStr("开始取色"))")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.accentColor)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(locStr("取色历史"))
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(viewModel.history) { color in
                        historyColorButton(color: color)
                    }
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 36)
        }
        .padding(.vertical, 4)
    }

    private func historyColorButton(color: PickedColor) -> some View {
        Button {
            viewModel.selectFromHistory(color)
        } label: {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(red: color.red, green: color.green, blue: color.blue))
                .frame(width: 28, height: 28)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color(.separatorColor).opacity(0.3), lineWidth: 1)
                )
                .overlay(
                    Group {
                        if viewModel.currentColor?.id == color.id {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(Color.accentColor, lineWidth: 2)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var paletteSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(locStr("色板"))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)

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
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(0.95)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)

            if viewModel.palette.isEmpty {
                Text(locStr("保存到色板"))
                    .font(.system(size: 11, weight: .regular, design: .rounded))
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
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 4)
    }

    private func paletteColorButton(color: PickedColor) -> some View {
        Button {
            viewModel.selectPaletteColor(color)
        } label: {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(red: color.red, green: color.green, blue: color.blue))
                .frame(width: 52, height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color(.separatorColor).opacity(0.3), lineWidth: 1)
                )
                .overlay(
                    Group {
                        if viewModel.currentColor?.id == color.id {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.accentColor, lineWidth: 2)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
    }

    private func currentColorSection(color: PickedColor) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(red: color.red, green: color.green, blue: color.blue))
                .frame(width: 40, height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color(.separatorColor).opacity(0.3), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 1) {
                Text(color.hex)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                HStack(spacing: 8) {
                    Text(color.rgbString())
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)

                    let twName = viewModel.closestTailwindName(red: color.red, green: color.green, blue: color.blue)
                    Text("tailwind: \(twName)")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }

    private func actionButtonsSection(color: PickedColor) -> some View {
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
                    Label(locStr("保存到色板"), systemImage: "square.and.arrow.down")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.accentColor.opacity(0.85))
                        )
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }

    private func copyButton(title: String, format: ColorFormat) -> some View {
        Button {
            viewModel.copyCurrentColor(format: format)
        } label: {
            Text(title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(.controlBackgroundColor))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color(.separatorColor).opacity(0.5), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var formatSection: some View {
        HStack {
            Text(locStr("输出格式"))
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)

            Spacer()

            Picker("", selection: $viewModel.selectedFormat) {
                ForEach(ColorFormat.allCases, id: \.self) { format in
                    Text(format.rawValue).tag(format)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 120)
            .scaleEffect(0.85)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }

    private var quitSection: some View {
        Button {
            NSApplication.shared.terminate(nil)
        } label: {
            Text(locStr("退出应用"))
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }

    private func toastOverlay(text: String) -> some View {
        VStack {
            Spacer()
            Text(text)
                .font(.system(size: 12, weight: .medium, design: .rounded))
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

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
