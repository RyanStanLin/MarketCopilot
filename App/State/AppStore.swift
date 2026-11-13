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
    let isDesignPreview: Bool

    @ObservationIgnored var openSettings: () -> Void = {}
    @ObservationIgnored var renderedMenuHeightChanged: (CGFloat) -> Void = { _ in }
    @ObservationIgnored var refreshRequested: () -> Void = {}
    @ObservationIgnored var drawerChanged: () -> Void = {}
    @ObservationIgnored var settingsApplied: () -> Void = {}
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
    var statusPortfolio: Decimal? { isDesignPreview ? Decimal(string: "26.09") : snapshot.portfolio }
    var statusCash: Decimal? { isDesignPreview ? Decimal(string: "8.01") : snapshot.cash }
    var statusDescription: String { predictionStatus + "\n" + perpsStatus }

    func toggleDrawer() {
        isPerpsExpanded.toggle()
        drawerChanged()
        if isPerpsExpanded { refreshRequested() }
    }
}
