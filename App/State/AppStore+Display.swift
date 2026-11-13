import Foundation
import MarketCore

extension AppStore {
    func applyDisplayPreferences() {
        guard !refreshDraft.cashOffset.isNaN else {
            settingsNotice = ConfigurationError.invalidCashOffset.localizedDescription
            return
        }
        let languageChanged = refreshSettings.language != refreshDraft.language
        refreshSettings.language = refreshDraft.language
        refreshSettings.cashOffset = refreshDraft.cashOffset
        L10n.language = refreshSettings.language
        persistSnapshot()
        settingsNotice = L10n.text("Display preferences saved.")
        displayPreferencesChanged()
        if languageChanged { settingsApplied() }
    }
}
