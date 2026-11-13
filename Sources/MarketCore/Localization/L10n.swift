import Foundation
import Synchronization

/// Shared by SwiftUI, AppKit and background API errors; resources remain in the package bundle.
public enum L10n {
    private static let selection = Mutex<AppLanguage>(.system)
    public static var language: AppLanguage {
        get { selection.withLock { $0 } }
        set { selection.withLock { $0 = newValue } }
    }
    public static var locale: Locale { language.locale }

    public static func text(_ key: String) -> String {
        let selected = language.localization
        guard let path = Bundle.module.path(forResource: selected, ofType: "lproj"),
              let bundle = Bundle(path: path) else { return key }
        return bundle.localizedString(forKey: key, value: key, table: nil)
    }

    public static func format(_ key: String, _ arguments: any CVarArg...) -> String {
        String(format: text(key), locale: locale, arguments: arguments)
    }
}
