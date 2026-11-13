import AppKit
import MarketCore
import Observation
import SwiftUI

@MainActor @Observable
final class AppStore {
    var snapshot = PortfolioSnapshot()
    var instruments: [Int: Instrument] = [:]
    var quotes: [Int: MarketQuote] = [:]
    var accountName = "Connect account"
    var avatarURL: URL?
    var perpsWebsiteURL = (try? APIConfiguration.bundled())?.perpsWebsite
    var isMenuOpen = false
    var isPerpsExpanded = false
    var maximumMenuHeight: CGFloat = 760
    var predictionStatus = "Connect your account in Settings."
    var perpsStatus = "Connect your account in Settings."
    var isRefreshing = false
    var account = AccountConfiguration()
    var accountDraft = AccountConfiguration()
    var refreshSettings = RefreshSettings()
    var refreshDraft = RefreshSettings()
    var secretsDraft = AccountSecrets()
    var settingsNotice = ""
    var isConnecting = false
    var isSavingAccount = false
    let isDesignPreview: Bool

    @ObservationIgnored var openSettings: () -> Void = {}
    @ObservationIgnored var renderedMenuHeightChanged: (CGFloat) -> Void = { _ in }
    @ObservationIgnored var refreshRequested: () -> Void = {}
    @ObservationIgnored var drawerChanged: () -> Void = {}
    @ObservationIgnored var settingsApplied: () -> Void = {}
    @ObservationIgnored var displayPreferencesChanged: () -> Void = {}
    @ObservationIgnored var repository: WorkspaceRepository?
    @ObservationIgnored var activeSecrets = AccountSecrets()
    #if DEBUG
    @ObservationIgnored var menuLayoutObserved: (String, CGRect) -> Void = { _, _ in }
    #endif

    init(designPreview: Bool = false) {
        #if DEBUG
        isDesignPreview = designPreview
        if designPreview { DesignFixture.populate(self) }
        else { loadWorkspace() }
        #else
        isDesignPreview = false
        loadWorkspace()
        #endif
    }

    var positions: [PerpPosition] { snapshot.perps?.positions ?? [] }
    var menuHeight: CGFloat {
        DesignTokens.menuHeight(expanded: isPerpsExpanded, positionCount: positions.count, maximum: maximumMenuHeight)
    }
    var expandedDrawerHeight: CGFloat {
        DesignTokens.menuHeight(expanded: true, positionCount: positions.count, maximum: maximumMenuHeight)
            - DesignTokens.collapsedHeight + DesignTokens.separatorHeight
    }
    var balances: BalancePresentation {
        BalancePresentation(snapshot: snapshot, predictionCashOffset: refreshSettings.predictionCashOffset,
                            perpsCashOffset: refreshSettings.perpsCashOffset)
    }
    var statusPortfolio: Decimal? {
        if isDesignPreview {
            return Decimal(string: "26.09").map { $0 + refreshSettings.predictionCashOffset + refreshSettings.perpsCashOffset }
        }
        return balances.portfolio
    }
    var statusCash: Decimal? {
        if isDesignPreview {
            return Decimal(string: "8.01").map { $0 + refreshSettings.predictionCashOffset + refreshSettings.perpsCashOffset }
        }
        return balances.cash
    }
    var locale: Locale { refreshSettings.language.locale }
    var statusDescription: String {
        let totals = snapshot.hasPartialTotals ? L10n.text("Totals include the available balances and holdings. Some sources are unavailable.") + "\n" : ""
        let predictionOffset = refreshSettings.predictionCashOffset == 0 ? "" : "\n" + L10n.format("Predictions offset: %@", MarketFormat.currency(refreshSettings.predictionCashOffset, signed: true))
        let perpsOffset = refreshSettings.perpsCashOffset == 0 ? "" : "\n" + L10n.format("Perps offset: %@", MarketFormat.currency(refreshSettings.perpsCashOffset, signed: true))
        return totals + L10n.text(predictionStatus) + "\n" + L10n.text(perpsStatus) + predictionOffset + perpsOffset
    }

    func toggleDrawer() {
        isPerpsExpanded.toggle()
        drawerChanged()
        if isPerpsExpanded { refreshRequested() }
    }
}
