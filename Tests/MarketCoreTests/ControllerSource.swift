import Foundation
@testable import MarketCore

actor ControllerSource: PortfolioDataSource {
    var predictionCalls: [String] = []
    var perpsCalls = 0
    private let heldWallet: String?
    private var continuations: [CheckedContinuation<PredictionSnapshot, any Error>] = []
    private var waiters: [CheckedContinuation<Void, Never>] = []
    private var failure: APIError?
    init(heldWallet: String? = nil, failure: APIError? = nil) { self.heldWallet = heldWallet; self.failure = failure }
    func predictions(account: AccountConfiguration, credentials: PredictionCredentials?) async throws -> PredictionSnapshot {
        predictionCalls.append(account.walletAddress)
        if account.walletAddress == heldWallet {
            return try await withCheckedThrowingContinuation { continuation in
                continuations.append(continuation)
                for waiter in waiters { waiter.resume() }; waiters = []
            }
        }
        if let failure { throw failure }
        return PredictionSnapshot(holdingsValue: 2, cash: 1)
    }
    func waitUntilHeld() async {
        if !continuations.isEmpty { return }
        await withCheckedContinuation { waiters.append($0) }
    }
    func releaseHeld() {
        for continuation in continuations { continuation.resume(returning: PredictionSnapshot(holdingsValue: 999, cash: 1)) }
        continuations = []
    }
    func perps(credentials: PerpsCredentials) -> PerpsSnapshot {
        perpsCalls += 1
        return PerpsSnapshot(portfolio: 5, cash: 1, positions: [])
    }
    func validatePerps(credentials: PerpsCredentials, expectedOwner: String?, now: Date) {}
    func instruments() -> [Int: Instrument] { [:] }
    func quotes(instrumentIDs: Set<Int>) -> [Int: MarketQuote] { [:] }
    func profile(wallet: String) -> AccountProfile { AccountProfile(name: wallet, avatar: nil, wallet: wallet) }
}
