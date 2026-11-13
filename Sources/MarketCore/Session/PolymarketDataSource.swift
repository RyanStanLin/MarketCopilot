import Foundation

public struct PolymarketDataSource: PortfolioDataSource {
    private let predictionClient: PredictionClient
    private let perpsClient: PerpsClient
    public init(configuration: APIConfiguration, http: HTTPClient? = nil) {
        predictionClient = PredictionClient(configuration: configuration, http: http)
        perpsClient = PerpsClient(configuration: configuration, http: http)
    }
    public func predictions(account: AccountConfiguration, credentials: PredictionCredentials?) async throws -> PredictionSnapshot {
        try await predictionClient.snapshot(account: account, credentials: credentials)
    }
    public func perps(credentials: PerpsCredentials) async throws -> PerpsSnapshot { try await perpsClient.snapshot(credentials: credentials) }
    public func validatePerps(credentials: PerpsCredentials, expectedOwner: String?, now: Date) async throws {
        try await perpsClient.validate(credentials: credentials, expectedOwner: expectedOwner, now: now)
    }
    public func instruments() async throws -> [Int: Instrument] { try await perpsClient.instruments() }
    public func quotes(instrumentIDs: Set<Int>) async throws -> [Int: MarketQuote] { try await perpsClient.quotes(instrumentIDs: instrumentIDs) }
    public func profile(wallet: String) async throws -> AccountProfile { try await predictionClient.profile(wallet: wallet) }
}
