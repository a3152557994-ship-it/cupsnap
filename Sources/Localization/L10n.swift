import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case zh = "zh"
    case en = "en"

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .zh: return "简体中文"
        case .en: return "English"
        }
    }
}

@MainActor
final class L10n: ObservableObject {
    static let shared = L10n()

    @Published var lang: AppLanguage {
        didSet {
            UserDefaults.standard.set(lang.rawValue, forKey: "cupsnap_lang_v1")
        }
    }

    var isZh: Bool { lang == .zh }

    private init() {
        let args = ProcessInfo.processInfo.arguments
        if let idx = args.firstIndex(of: "-ui_lang"), idx + 1 < args.count {
            let forced = args[idx + 1].lowercased()
            self.lang = forced.hasPrefix("en") ? .en : .zh
            return
        }
        if let saved = UserDefaults.standard.string(forKey: "cupsnap_lang_v1"),
           let parsed = AppLanguage(rawValue: saved) {
            self.lang = parsed
        } else {
            let preferred = Locale.preferredLanguages.first ?? "zh"
            self.lang = preferred.lowercased().hasPrefix("zh") ? .zh : .en
        }
    }

    func t(_ zh: String, _ en: String) -> String {
        lang == .zh ? zh : en
    }
}
