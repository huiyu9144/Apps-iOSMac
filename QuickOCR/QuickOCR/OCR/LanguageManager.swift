import Foundation

struct LanguageOption: Identifiable {
    let code: String
    let displayName: String
    let isDefault: Bool

    var id: String { code }
}

class LanguageManager {
    static let shared = LanguageManager()

    let availableLanguages: [LanguageOption] = [
        LanguageOption(code: "zh-Hans", displayName: "Chinese (Simplified)", isDefault: true),
        LanguageOption(code: "en-US", displayName: "English", isDefault: true),
        LanguageOption(code: "ja-JP", displayName: "Japanese", isDefault: false),
        LanguageOption(code: "ko-KR", displayName: "Korean", isDefault: false),
    ]

    private init() {}

    func displayName(for code: String) -> String {
        availableLanguages.first { $0.code == code }?.displayName ?? code
    }

    func defaultLanguages() -> [String] {
        availableLanguages.filter { $0.isDefault }.map { $0.code }
    }
}
