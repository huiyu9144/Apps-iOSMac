import Cocoa

class RecognitionManager: ObservableObject {
    @Published var isRecognizing = false

    static let shared = RecognitionManager()

    private init() {}

    func recognize(image: NSImage, languages: [String]) async -> String {
        await MainActor.run { self.isRecognizing = true }
        defer {
            Task { @MainActor in self.isRecognizing = false }
        }

        let result = await OCRService.shared.recognizeText(in: image, languages: languages)

        switch result {
        case .success(let text):
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return ""
            }
            return text
        case .failure:
            return ""
        }
    }
}
