import Foundation

public protocol PortfolioDataSource: Sendable {
    func predictions(account: AccountConfiguration, credentials: PredictionCredentials?) async throws -> PredictionSnapshot
    func perps(credentials: PerpsCredentials) async throws -> PerpsSnapshot
    func validatePerps(credentials: PerpsCredentials, expectedOwner: String?, now: Date) async throws
    func instruments() async throws -> [Int: Instrument]
    func quotes(instrumentIDs: Set<Int>) async throws -> [Int: MarketQuote]
    func profile(wallet: String) async throws -> AccountProfile
}
