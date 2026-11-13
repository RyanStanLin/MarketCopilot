import Foundation

public enum AppLanguage: String, Codable, CaseIterable, Sendable, Identifiable {
    case system, english = "en", simplifiedChinese = "zh-Hans", traditionalChinese = "zh-Hant"
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .system: L10n.text("Follow System")
        case .english: "English"
        case .simplifiedChinese: "简体中文"
        case .traditionalChinese: "繁體中文"
        }
    }
    public var localization: String {
        self == .system ? (Bundle.preferredLocalizations(from: ["en", "zh-Hans", "zh-Hant"]).first ?? "en") : rawValue
    }
    public var locale: Locale { Locale(identifier: localization) }
}
