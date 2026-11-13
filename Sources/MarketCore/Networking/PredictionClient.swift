import Foundation

public struct PredictionClient: Sendable {
    private let http: HTTPClient
    private let configuration: APIConfiguration

    public init(configuration: APIConfiguration, http: HTTPClient = HTTPClient()) {
        self.configuration = configuration; self.http = http
    }

    public func snapshot(account: AccountConfiguration, credentials: PredictionCredentials?) async throws -> PredictionSnapshot {
        async let value = holdingsValue(wallet: account.walletAddress)
        async let positions = positions(wallet: account.walletAddress)
        async let balance: Decimal? = cash(account: account, credentials: credentials)
        return try await PredictionSnapshot(holdingsValue: value, cash: balance, positions: positions)
    }

    public func holdingsValue(wallet: String) async throws -> Decimal {
        let envelope = try await http.get(PredictionWire.ValueEnvelope.self, base: configuration.data,
                                         path: "/v2/value", query: [.init(name: "user", value: wallet)])
        return envelope.data.value.value
    }

    public func positions(wallet: String) async throws -> [PredictionPosition] {
        var values: [PredictionPosition] = []
        var visited = Set<String>()
        var cursor: String?
        repeat {
            var query = [URLQueryItem(name: "user", value: wallet), .init(name: "status", value: "OPEN"),
                         .init(name: "include_archived", value: "true")]
            if let cursor { query.append(.init(name: "cursor", value: cursor)) }
            else { query.append(.init(name: "limit", value: "1000")) }
            let page = try await http.get(PredictionWire.PositionPage.self, base: configuration.data, path: "/v2/positions", query: query)
            values.append(contentsOf: page.data.map { PredictionPosition(tokenID: $0.tokenID, conditionID: $0.conditionID) })
            cursor = page.pagination.nextCursor
            if page.pagination.hasMore {
                guard let cursor, !cursor.isEmpty, visited.insert(cursor).inserted else {
                    throw APIError(status: 0, reason: "The position feed returned an invalid pagination cursor. Refresh again.")
                }
            } else { cursor = nil }
        } while cursor != nil
        var tokens = Set<String>()
        return values.filter { tokens.insert($0.tokenID).inserted }
    }

    public func cash(account: AccountConfiguration, credentials: PredictionCredentials?) async throws -> Decimal? {
        guard let credentials else { return nil }
        guard AccountConfiguration.isAddress(account.signerAddress) else { throw ConfigurationError.invalidSigner }
        let serverTime = try await http.get(Int64.self, base: configuration.clob, path: "/time")
        let headers = try CLOBAuthentication.headers(credentials: credentials, signer: account.signerAddress,
                                                    timestamp: String(serverTime), path: "/balance-allowance")
        let balance = try await http.get(PredictionWire.Balance.self, base: configuration.clob,
            path: "/balance-allowance", query: [.init(name: "asset_type", value: "COLLATERAL"),
                .init(name: "signature_type", value: String(account.walletType.rawValue))], headers: headers)
        let divisor = pow(Decimal(10), configuration.collateralDecimals)
        return balance.balance.value / divisor
    }

    public func profile(wallet: String) async throws -> AccountProfile {
        let value = try await http.get(PredictionWire.Profile.self, base: configuration.gamma,
                                      path: "/public-profile", query: [.init(name: "address", value: wallet)])
        return AccountProfile(name: value.name ?? value.pseudonym, avatar: value.profileImage, wallet: value.proxyWallet)
    }
}
