import Foundation
import MarketCore

extension AppStore {
    func applyDisplayPreferences() {
        do { _ = try refreshDraft.liveColor.validated() }
        catch { settingsNotice = error.localizedDescription; return }
        guard !refreshDraft.predictionCashOffset.isNaN, !refreshDraft.perpsCashOffset.isNaN else {
            settingsNotice = ConfigurationError.invalidCashOffset.localizedDescription
            return
        }
        let languageChanged = refreshSettings.language != refreshDraft.language
        refreshSettings.language = refreshDraft.language
        refreshSettings.liveColor = refreshDraft.liveColor
        refreshSettings.predictionCashOffset = refreshDraft.predictionCashOffset
        refreshSettings.perpsCashOffset = refreshDraft.perpsCashOffset
        L10n.language = refreshSettings.language
        persistSnapshot()
        settingsNotice = L10n.text("Display preferences saved.")
        displayPreferencesChanged()
        if languageChanged { settingsApplied() }
    }
}
