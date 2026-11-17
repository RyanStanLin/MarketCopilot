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
    var predictionWebsiteURL = (try? APIConfiguration.bundled())?.predictionWebsite
    var isMenuOpen = false
    var isPerpsExpanded = false
    var isPredictionsExpanded = false
    var drawerKeyboardRequest = 0
    var drawerKeyboardDirection = 1
    var maximumMenuHeight: CGFloat = 760
    var predictionStatus = "Connect your account in Settings."
    var perpsStatus = "Connect your account in Settings."
    var predictionHealth = DataHealth()
    var perpsHealth = DataHealth()
    var isRefreshing = false
    var account = AccountConfiguration()
    var accountDraft = AccountConfiguration()
    var refreshSettings = RefreshSettings()
    var refreshDraft = RefreshSettings()
    var secretsDraft = AccountSecrets()
    var settingsNotice = ""
    var isConnecting = false
    var isSavingAccount = false
    var alertRules: [MarketAlertRule] = []
    var alertNotificationAccess = AlertNotificationAccess()
    var alertPermission: AlertPermission { alertNotificationAccess.permission }
    var alertNotice = ""
    var isRequestingAlertPermission = false
    var warmingAlertIDs = Set<UUID>()
    let isDesignPreview: Bool

    @ObservationIgnored var openSettings: () -> Void = {}
    @ObservationIgnored var openAlertSettings: (AlertTarget, UUID?) -> Void = { _, _ in }
    @ObservationIgnored var alertRulesChanged: () -> Void = {}
    @ObservationIgnored let alertNotifications = MarketNotificationCenter()
    @ObservationIgnored var alertEngine = AlertEngine()
    @ObservationIgnored var liveAlertQuoteIDs = Set<Int>()
    @ObservationIgnored var alertDeliveryTasks: [UUID: Task<Void, Never>] = [:]
    @ObservationIgnored var pendingAlertEvents: [UUID: UUID] = [:]
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
    var predictionPositions: [PredictionPosition] { snapshot.predictions?.positions.filter(\.isActive) ?? [] }
    var menuHeight: CGFloat {
        let open = isPerpsExpanded || isPredictionsExpanded
        return DesignTokens.collapsedHeight - (open ? DesignTokens.separatorHeight : 0)
            + (isPerpsExpanded ? expandedDrawerHeight : 0)
            + (isPredictionsExpanded ? expandedPredictionDrawerHeight + 2 : 0)
    }
    var expandedDrawerHeight: CGFloat {
        min(DesignTokens.drawerHeight(positionCount: positions.count), max(42, maximumMenuHeight - DesignTokens.collapsedHeight + DesignTokens.separatorHeight))
    }
    var expandedPredictionDrawerHeight: CGFloat {
        min(DesignTokens.predictionDrawerHeight(positionCount: predictionPositions.count), max(42, maximumMenuHeight - DesignTokens.collapsedHeight + DesignTokens.separatorHeight - 2))
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
        if isPerpsExpanded { isPredictionsExpanded = false }
        drawerChanged()
        if isPerpsExpanded { refreshRequested() }
    }

    func togglePredictionsDrawer() {
        isPredictionsExpanded.toggle()
        if isPredictionsExpanded { isPerpsExpanded = false }
        drawerChanged()
        if isPredictionsExpanded { refreshRequested() }
    }

    func navigateDrawer(_ direction: Int) {
        drawerKeyboardDirection = direction
        drawerKeyboardRequest &+= 1
    }
}
