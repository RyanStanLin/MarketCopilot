import Foundation
import MarketCore

extension AppStore {
    func apply(_ update: PortfolioUpdate) {
        switch update {
        case .predictions(let value):
            snapshot.predictions = value
            evaluateAlerts(for: .predictions)
        case .perps(let value):
            snapshot.perps = value
            evaluateAlerts(for: .perps)
        case .quotes(let values):
            quotes = values; liveAlertQuoteIDs.formUnion(values.keys)
            evaluateAlerts(for: .perps)
        case .instruments(let values): instruments = values
        case .profile(let value):
            if let name = value.name, !name.isEmpty { accountName = name }
            avatarURL = value.avatar
        case .status(let product, let text):
            if product == .predictions { predictionStatus = text } else { perpsStatus = text }
        case .health(let product, let value):
            if product == .predictions { predictionHealth = value } else { perpsHealth = value }
        case .busy(let busy):
            isRefreshing = busy; isConnecting = busy
            if !busy && account.isConfigured {
                settingsNotice = L10n.format("Predictions: %@\nPerps: %@", L10n.text(predictionStatus), L10n.text(perpsStatus))
            }
        }
    }
}
