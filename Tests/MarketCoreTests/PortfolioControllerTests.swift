import Foundation
import Testing
@testable import MarketCore

@Suite("Portfolio refresh coordination") @MainActor
struct PortfolioControllerTests {
    static let oldWallet = "0x1111111111111111111111111111111111111111"
    static let newWallet = "0x2222222222222222222222222222222222222222"

    private func account(_ wallet: String) -> AccountConfiguration {
        var value = AccountConfiguration(); value.walletAddress = wallet; return value
    }

    @Test func accountSwitchDiscardsOldInFlightResponses() async throws {
        let source = ControllerSource(heldWallet: Self.oldWallet)
        let controller = PortfolioController(configuration: try .bundled(), source: source, automaticallySchedulesUpdates: false)
        controller.start(account: account(Self.oldWallet), secrets: AccountSecrets(), settings: RefreshSettings())
        let old = Task { await controller.refresh() }
        await source.waitUntilHeld()
        controller.start(account: account(Self.newWallet), secrets: AccountSecrets(), settings: RefreshSettings())
        await controller.refresh()
        #expect(controller.snapshot.predictions?.holdingsValue == 2)
        await source.releaseHeld()
        await old.value
        #expect(controller.snapshot.predictions?.holdingsValue == 2)
        #expect(controller.snapshot.predictions?.portfolio == 3)
        controller.stop()
    }

    @Test func simultaneousRefreshRequestsShareOneInFlightRead() async throws {
        let source = ControllerSource(heldWallet: Self.oldWallet)
        let controller = PortfolioController(configuration: try .bundled(), source: source, automaticallySchedulesUpdates: false)
        controller.start(account: account(Self.oldWallet), secrets: AccountSecrets(), settings: RefreshSettings())
        let first = Task { await controller.refresh() }
        await source.waitUntilHeld()
        var secondEntered = false
        let second = Task { secondEntered = true; await controller.refresh() }
        while !secondEntered { await Task.yield() }
        #expect(await source.predictionCalls.count == 1)
        await source.releaseHeld()
        await first.value; await second.value
        #expect(await source.predictionCalls.count == 1)
        #expect(controller.snapshot.predictions?.holdingsValue == 999)
        controller.stop()
    }

    @Test func authFailureRetainsCacheAndStopsAutomaticRetries() async throws {
        let source = ControllerSource(failure: APIError(status: 401, reason: "Expired"))
        let cached = PortfolioSnapshot(predictions: PredictionSnapshot(holdingsValue: 20, cash: 5))
        let controller = PortfolioController(configuration: try .bundled(), source: source, automaticallySchedulesUpdates: false)
        controller.start(account: account(Self.newWallet), secrets: AccountSecrets(), settings: RefreshSettings(), cached: cached)
        await controller.refresh()
        await controller.refresh(force: false)
        #expect(await source.predictionCalls.count == 1)
        #expect(controller.snapshot == cached)
        #expect(controller.authenticationBlocked.contains(.predictions))
        controller.stop()
    }

    @Test func retryAfterBlocksEvenForcedRefreshUntilItsBoundary() async throws {
        let source = ControllerSource(failure: APIError(status: 429, reason: "Busy", retryAfter: 17))
        let clock = AdjustableClock()
        let controller = PortfolioController(configuration: try .bundled(), source: source, clock: clock, automaticallySchedulesUpdates: false)
        controller.start(account: account(Self.newWallet), secrets: AccountSecrets(), settings: RefreshSettings())
        await controller.refresh(); clock.advance(16); await controller.refresh()
        #expect(await source.predictionCalls.count == 1)
        clock.advance(1); await controller.refresh()
        #expect(await source.predictionCalls.count == 2)
        controller.stop()
    }

    @Test func olderRestSnapshotsCannotReplaceNewerPushAndQuoteUpdatesMerge() throws {
        let controller = PortfolioController(configuration: try .bundled(), source: ControllerSource(), automaticallySchedulesUpdates: false)
        controller.acceptPerps(PerpsSnapshot(portfolio: 100, cash: 20, positions: [], timestamp: Date(timeIntervalSince1970: 200)))
        controller.acceptPerps(PerpsSnapshot(portfolio: 1, cash: 1, positions: [], timestamp: Date(timeIntervalSince1970: 100)))
        #expect(controller.snapshot.perps?.portfolio == 100)
        controller.mergeQuotes([2: MarketQuote(mark: 10, timestamp: Date(timeIntervalSince1970: 200))])
        controller.mergeQuotes([2: MarketQuote(bid: 9, ask: 11, timestamp: Date(timeIntervalSince1970: 201))])
        controller.mergeQuotes([2: MarketQuote(mark: 1, timestamp: Date(timeIntervalSince1970: 100))])
        #expect(controller.quoteCache[2]?.mark == 10)
        #expect(controller.quoteCache[2]?.bid == 9)
        #expect(controller.quoteCache[2]?.ask == 11)
    }

    @Test func quietPortfolioStreamFallsBackToPollingAfterFifteenSeconds() async throws {
        let source = ControllerSource()
        let clock = AdjustableClock()
        let controller = PortfolioController(configuration: try .bundled(), source: source, clock: clock, automaticallySchedulesUpdates: false)
        var secrets = AccountSecrets()
        secrets.perpsProxy = Self.oldWallet; secrets.perpsSecret = "fixture"
        controller.start(account: account(Self.newWallet), secrets: secrets, settings: RefreshSettings())
        await controller.refresh()
        controller.healthySockets.insert("perps"); controller.lastPerpsPush = clock.now
        clock.advance(5); await controller.refresh(force: false)
        #expect(await source.perpsCalls == 1)
        clock.advance(11); await controller.refresh(force: false)
        #expect(await source.perpsCalls == 2)
        controller.stop()
    }

    @Test func emptyOrderBookClearsOldBidAskWithoutDiscardingMark() throws {
        let controller = PortfolioController(configuration: try .bundled(), source: ControllerSource(), automaticallySchedulesUpdates: false)
        controller.mergeQuotes([2: MarketQuote(mark: 10, bid: 9, ask: 11, timestamp: Date(timeIntervalSince1970: 100))])
        controller.mergeQuotes([2: MarketQuote(timestamp: Date(timeIntervalSince1970: 101))])
        #expect(controller.quoteCache[2]?.mark == 10)
        #expect(controller.quoteCache[2]?.bid == nil)
        #expect(controller.quoteCache[2]?.ask == nil)
    }

    @Test func pollingModeCreatesNoWebSocketSubscriptions() throws {
        let controller = PortfolioController(configuration: try .bundled(), source: ControllerSource())
        var settings = RefreshSettings(); settings.predictionMode = .polling; settings.perpsMode = .polling
        var secrets = AccountSecrets(); secrets.perpsProxy = Self.oldWallet; secrets.perpsSecret = "fixture"
        let cached = PortfolioSnapshot(predictions: PredictionSnapshot(holdingsValue: 1, cash: 1,
            positions: [PredictionPosition(tokenID: "first", conditionID: "condition")]))
        controller.start(account: account(Self.newWallet), secrets: secrets, settings: settings, cached: cached)
        controller.pollTask?.cancel(); controller.pollTask = nil
        controller.perpsValidated = true
        controller.configureSockets()
        #expect(controller.socketTasks.isEmpty)
        #expect(controller.healthySockets.isEmpty)
        controller.stop()
    }
}

final class AdjustableClock: SessionClock, @unchecked Sendable {
    private let lock = NSLock()
    private var value = Date(timeIntervalSince1970: 1_700_000_000)
    var now: Date { lock.withLock { value } }
    func advance(_ seconds: TimeInterval) { lock.withLock { value.addTimeInterval(seconds) } }
    func sleep(seconds: TimeInterval) async throws { try await ContinuousClock().sleep(for: .seconds(seconds)) }
}
