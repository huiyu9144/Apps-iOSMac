import AppKit
import SwiftUI

enum ColorFormat: String, CaseIterable {
    case hex = "Hex"
    case rgb = "RGB"
    case hsl = "HSL"
    case tailwind = "Tailwind"
}

@MainActor
@Observable
class HueSnapViewModel {
    var history: [PickedColor] = []
    var palette: [PickedColor] = []
    var currentColor: PickedColor?
    var selectedFormat: ColorFormat = .hex
    var copiedToast: String?
    var onContentChanged: (() -> Void)?

    private let colorPickerService = ColorPickerService()
    private let tailwindService = TailwindService()
    private let maxHistoryCount = 20
    private let paletteKey = "huesnap_palette"
    private var toastDismissTask: Task<Void, Never>?

    init() {
        loadPalette()
        setupColorPickerCallbacks()
    }

    func startPicking() {
        colorPickerService.startPicking()
    }

    func copyCurrentColor(format: ColorFormat) {
        guard let color = currentColor else { return }
        let string = formatColor(color: color, format: format)
        copyToPasteboard(string)
        showToast(locStr("已复制") + " · \(color.hex)")
    }

    func saveToPalette() {
        guard let color = currentColor else { return }
        if !palette.contains(where: { $0.hex == color.hex }) {
            palette.append(color)
            savePalette()
            showToast(color.hex + " · " + locStr("保存到色板"))
        }
        onContentChanged?()
    }

    func removeFromPalette(_ color: PickedColor) {
        palette.removeAll { $0.id == color.id }
        savePalette()
        onContentChanged?()
    }

    func selectFromHistory(_ color: PickedColor) {
        currentColor = color
        onContentChanged?()
    }

    func selectPaletteColor(_ color: PickedColor) {
        currentColor = color
        onContentChanged?()
    }

    func closestTailwindName(red: Double, green: Double, blue: Double) -> String {
        tailwindService.closestMatch(red: red, green: green, blue: blue).name
    }

    func exportPalette() {
        do {
            let data = try JSONEncoder().encode(palette)
            let panel = NSSavePanel()
            panel.title = locStr("导出色板")
            panel.allowedContentTypes = [.json]
            panel.nameFieldStringValue = "huesnap-palette.json"
            panel.canCreateDirectories = true

            guard panel.runModal() == .OK, let url = panel.url else { return }

            try data.write(to: url)
            showToast(locStr("完成"))
        } catch {
            print("Export error: \(error)")
        }
    }

    func importPalette() {
        let panel = NSOpenPanel()
        panel.title = locStr("导入色板")
        panel.allowedContentTypes = [.json]
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let data = try Data(contentsOf: url)
            let imported = try JSONDecoder().decode([PickedColor].self, from: data)
            for color in imported {
                if !palette.contains(where: { $0.hex == color.hex }) {
                    palette.append(color)
                }
            }
            savePalette()
            showToast(locStr("完成"))
            onContentChanged?()
        } catch {
            print("Import error: \(error)")
        }
    }

    private func formatColor(color: PickedColor, format: ColorFormat) -> String {
        switch format {
        case .hex:
            return color.hex
        case .rgb:
            return color.rgbString()
        case .hsl:
            return color.hslString()
        case .tailwind:
            return tailwindService.closestMatch(red: color.red, green: color.green, blue: color.blue).name
        }
    }

    private func copyToPasteboard(_ string: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
    }

    private func showToast(_ message: String) {
        toastDismissTask?.cancel()
        withAnimation(.easeInOut(duration: 0.2)) {
            copiedToast = message
        }
        toastDismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            withAnimation(.easeInOut(duration: 0.2)) {
                self.copiedToast = nil
            }
        }
    }

    private func setupColorPickerCallbacks() {
        colorPickerService.onColorPicked = { [weak self] color in
            guard let self = self else { return }
            self.currentColor = color
            self.history.insert(color, at: 0)
            if self.history.count > self.maxHistoryCount {
                self.history = Array(self.history.prefix(self.maxHistoryCount))
            }
            let string = self.formatColor(color: color, format: self.selectedFormat)
            self.copyToPasteboard(string)
            ColorPickerService.showFloatingToast(message: locStr("已复制") + " · \(string)")
            self.onContentChanged?()
        }

        colorPickerService.onCancel = {
        }
    }

    private func loadPalette() {
        guard let data = UserDefaults.standard.data(forKey: paletteKey) else { return }
        do {
            palette = try JSONDecoder().decode([PickedColor].self, from: data)
        } catch {
            palette = []
        }
    }

    private func savePalette() {
        do {
            let data = try JSONEncoder().encode(palette)
            UserDefaults.standard.set(data, forKey: paletteKey)
        } catch {
            print("Save palette error: \(error)")
        }
    }
}
