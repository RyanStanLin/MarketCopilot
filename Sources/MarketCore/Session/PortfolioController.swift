import Foundation

/// Coordinates one account. Every asynchronous callback is scoped to a generation.
@MainActor
public final class PortfolioController {
    public var onUpdate: ((PortfolioUpdate) -> Void)?
    public internal(set) var snapshot = PortfolioSnapshot()
    let source: any PortfolioDataSource
    let configuration: APIConfiguration
    let clock: any SessionClock
    let socketFactory: any SocketFactory
    let automaticallySchedulesUpdates: Bool
    var account: AccountConfiguration?
    var secrets = AccountSecrets()
    var settings = RefreshSettings()
    var generation = UUID()
    var drawerExpanded = false
    var perpsValidated = false
    var authenticationBlocked = Set<MarketProduct>()
    var retryNotBefore: [MarketProduct: Date] = [:]
    var lastPredictionREST = Date.distantPast
    var lastPerpsREST = Date.distantPast
    var lastPerpsPush = Date.distantPast
    var lastMetadata = Date.distantPast
    var lastProfile = Date.distantPast
    var refreshTask: Task<Void, Never>?
    var pollTask: Task<Void, Never>?
    var eventTask: Task<Void, Never>?
    var socketTasks: [String: Task<Void, Never>] = [:]
    var socketSignatures: [String: String] = [:]
    var healthySockets = Set<String>()
    var streamParsers: [String: PerpsStreamParser] = [:]
    var quoteCache: [Int: MarketQuote] = [:]
    var quoteFlushTask: Task<Void, Never>?

    public init(configuration: APIConfiguration, source: any PortfolioDataSource,
                socketFactory: any SocketFactory = NativeSocketFactory(), clock: any SessionClock = SystemSessionClock(),
                automaticallySchedulesUpdates: Bool = true) {
        self.configuration = configuration; self.source = source
        self.socketFactory = socketFactory; self.clock = clock
        self.automaticallySchedulesUpdates = automaticallySchedulesUpdates
    }

    public func start(account: AccountConfiguration, secrets: AccountSecrets, settings: RefreshSettings,
                      cached: PortfolioSnapshot = PortfolioSnapshot()) {
        stop()
        guard account.isConfigured else { return }
        self.account = account; self.secrets = secrets; self.settings = settings; snapshot = cached
        onUpdate?(.status(.predictions, L10n.text("Connecting…"))); onUpdate?(.status(.perps, L10n.text("Connecting…")))
        guard automaticallySchedulesUpdates else { return }
        let token = generation
        pollTask = Task { [weak self] in
            while let self, !Task.isCancelled, self.generation == token {
                await self.refresh(force: false)
                do { try await self.clock.sleep(seconds: self.settings.pollingInterval) } catch { break }
            }
        }
    }

    public func stop() {
        generation = UUID()
        pollTask?.cancel(); pollTask = nil
        refreshTask?.cancel(); refreshTask = nil
        eventTask?.cancel(); eventTask = nil
        quoteFlushTask?.cancel(); quoteFlushTask = nil
        for task in socketTasks.values { task.cancel() }
        socketTasks = [:]; socketSignatures = [:]; healthySockets = []; streamParsers = [:]
        quoteCache = [:]; authenticationBlocked = []; retryNotBefore = [:]
        perpsValidated = false; account = nil
        lastPredictionREST = .distantPast; lastPerpsREST = .distantPast
        lastPerpsPush = .distantPast
        lastMetadata = .distantPast; lastProfile = .distantPast
        onUpdate?(.busy(false))
    }

    public func setDrawerExpanded(_ expanded: Bool) {
        drawerExpanded = expanded
        configureSockets()
    }

    public func refresh(force: Bool = true) async {
        guard account != nil else { return }
        if let existing = refreshTask { await existing.value; return }
        let token = generation
        onUpdate?(.busy(true))
        let task = Task { [weak self] in
            guard let self else { return }
            async let predictions: Void = self.refreshPredictions(token: token, force: force)
            async let perps: Void = self.refreshPerps(token: token, force: force)
            async let metadata: Void = self.refreshMetadata(token: token, force: force)
            _ = await (predictions, perps, metadata)
        }
        refreshTask = task
        await task.value
        guard generation == token else { return }
        refreshTask = nil
        onUpdate?(.busy(false))
        configureSockets()
    }

    func isCurrent(_ token: UUID) -> Bool { generation == token && account != nil && !Task.isCancelled }

    func mayRefresh(_ product: MarketProduct, force: Bool, last: Date, interval: TimeInterval) -> Bool {
        if let until = retryNotBefore[product], until > clock.now { return false }
        if authenticationBlocked.contains(product), !force { return false }
        return force || clock.now.timeIntervalSince(last) >= interval
    }

    func failed(_ error: any Error, product: MarketProduct, token: UUID) {
        guard isCurrent(token), !(error is CancellationError) else { return }
        if let api = error as? APIError {
            if api.isAuthenticationFailure { authenticationBlocked.insert(product) }
            if let seconds = api.retryAfter { retryNotBefore[product] = clock.now.addingTimeInterval(seconds) }
        }
        let date = product == .predictions ? snapshot.predictions?.timestamp : snapshot.perps?.timestamp
        let suffix = date.map { L10n.format(" Last valid update: %@.", $0.formatted(.dateTime.hour().minute().second().locale(L10n.locale))) } ?? ""
        onUpdate?(.status(product, error.localizedDescription + suffix))
    }
}
