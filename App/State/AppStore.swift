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
    var isMenuOpen = false
    var isPerpsExpanded = false
    var maximumMenuHeight: CGFloat = 760
    var predictionStatus = "Connect your account in Settings."
    var perpsStatus = "Connect your account in Settings."
    var isRefreshing = false
    let isDesignPreview: Bool

    @ObservationIgnored var openSettings: () -> Void = {}
    @ObservationIgnored var layoutChanged: () -> Void = {}
    @ObservationIgnored var refreshRequested: () -> Void = {}
    @ObservationIgnored var drawerChanged: () -> Void = {}

    init(designPreview: Bool = false) {
        isDesignPreview = designPreview
        if designPreview { DesignFixture.populate(self) }
    }

    var positions: [PerpPosition] { snapshot.perps?.positions ?? [] }
    var menuHeight: CGFloat {
        DesignTokens.menuHeight(expanded: isPerpsExpanded, positionCount: positions.count, maximum: maximumMenuHeight)
    }
    var drawerHeight: CGFloat { menuHeight - DesignTokens.collapsedHeight + DesignTokens.separatorHeight }
    var statusPortfolio: Decimal? { isDesignPreview ? Decimal(string: "26.09") : snapshot.portfolio }
    var statusCash: Decimal? { isDesignPreview ? Decimal(string: "8.01") : snapshot.cash }
    var statusDescription: String { predictionStatus + "\n" + perpsStatus }

    func toggleDrawer() {
        let motion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        withAnimation(motion ? nil : DesignTokens.drawerAnimation) { isPerpsExpanded.toggle() }
        layoutChanged()
        drawerChanged()
        if isPerpsExpanded { refreshRequested() }
    }
}
