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
    var isPicking = false
    var copiedToast: String?

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
        guard !isPicking else { return }
        isPicking = true
        colorPickerService.startPicking()
    }

    func copyCurrentColor(format: ColorFormat) {
        guard let color = currentColor else { return }

        let string: String
        switch format {
        case .hex:
            string = color.hex
        case .rgb:
            string = color.rgbString()
        case .hsl:
            string = color.hslString()
        case .tailwind:
            let match = tailwindService.closestMatch(red: color.red, green: color.green, blue: color.blue)
            string = match.name
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)

        showToast(locStr("已复制") + " · \(color.hex)")
    }

    func saveToPalette() {
        guard let color = currentColor else { return }
        if !palette.contains(where: { $0.hex == color.hex }) {
            palette.append(color)
            savePalette()
            showToast(color.hex + " · " + locStr("保存到色板"))
        }
    }

    func removeFromPalette(at indexSet: IndexSet) {
        palette.remove(atOffsets: indexSet)
        savePalette()
    }

    func removeFromPalette(_ color: PickedColor) {
        palette.removeAll { $0.id == color.id }
        savePalette()
    }

    func movePaletteItem(from source: IndexSet, to destination: Int) {
        palette.move(fromOffsets: source, toOffset: destination)
        savePalette()
    }

    func selectFromHistory(_ color: PickedColor) {
        currentColor = color
    }

    func selectPaletteColor(_ color: PickedColor) {
        currentColor = color
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
        } catch {
            print("Import error: \(error)")
        }
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
            self.isPicking = false
            let string = self.copyColorAndToast(color: color, format: self.selectedFormat)
            ColorPickerService.showFloatingToast(message: locStr("已复制") + " · \(string)")
        }

        colorPickerService.onCancel = { [weak self] in
            self?.isPicking = false
        }
    }

    @discardableResult
    private func copyColorAndToast(color: PickedColor, format: ColorFormat) -> String {
        let string: String
        switch format {
        case .hex:
            string = color.hex
        case .rgb:
            string = color.rgbString()
        case .hsl:
            string = color.hslString()
        case .tailwind:
            let match = tailwindService.closestMatch(red: color.red, green: color.green, blue: color.blue)
            string = match.name
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)

        showToast(locStr("已复制") + " · \(string)")
        return string
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
