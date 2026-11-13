import Foundation
import MarketCore

extension AppStore {
    func applyDisplayPreferences() {
        guard !refreshDraft.predictionCashOffset.isNaN, !refreshDraft.perpsCashOffset.isNaN else {
            settingsNotice = ConfigurationError.invalidCashOffset.localizedDescription
            return
        }
        let languageChanged = refreshSettings.language != refreshDraft.language
        refreshSettings.language = refreshDraft.language
        refreshSettings.predictionCashOffset = refreshDraft.predictionCashOffset
        refreshSettings.perpsCashOffset = refreshDraft.perpsCashOffset
        L10n.language = refreshSettings.language
        persistSnapshot()
        settingsNotice = L10n.text("Display preferences saved.")
        displayPreferencesChanged()
        if languageChanged { settingsApplied() }
    }
}
