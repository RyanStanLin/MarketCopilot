import Foundation

public struct SocketSubscription: Sendable {
    public let url: URL
    let authentication: String?
    let subscription: String
    let heartbeat: String
    let expectsSubscriptionAck: Bool

    static func perps(configuration: APIConfiguration, credentials: PerpsCredentials,
                      instrumentIDs: [Int]) throws -> Self {
        let channels = ["portfolio", "balances", "fills", "funding"] + instrumentIDs.sorted().flatMap { ["tickers::\($0)", "bbo::\($0)"] }
        return Self(url: configuration.perpsSocket,
            authentication: try json(["id": 1, "req": "post", "op": ["type": "auth", "args": ["proxy": credentials.proxy, "secret": credentials.secret]]]),
            subscription: try json(["id": 2, "req": "sub", "chs": channels]),
            heartbeat: try json(["req": "post", "op": ["type": "ping"]]), expectsSubscriptionAck: true)
    }

    static func perpsMarket(configuration: APIConfiguration, instrumentIDs: [Int]) throws -> Self {
        Self(url: configuration.perpsSocket, authentication: nil,
             subscription: try json(["id": 2, "req": "sub", "chs": instrumentIDs.sorted().flatMap { ["tickers::\($0)", "bbo::\($0)"] }]),
             heartbeat: try json(["req": "post", "op": ["type": "ping"]]), expectsSubscriptionAck: true)
    }

    static func predictionMarket(configuration: APIConfiguration, assetIDs: [String]) throws -> Self {
        Self(url: configuration.predictionMarketSocket, authentication: nil,
             subscription: try json(["type": "market", "assets_ids": assetIDs.sorted(), "custom_feature_enabled": true]),
             heartbeat: "PING", expectsSubscriptionAck: false)
    }

    static func predictionUser(configuration: APIConfiguration, credentials: PredictionCredentials, conditionIDs: [String]) throws -> Self {
        Self(url: configuration.predictionUserSocket, authentication: nil,
             subscription: try json(["type": "user", "markets": conditionIDs.sorted(),
                "auth": ["apiKey": credentials.apiKey, "secret": credentials.secret, "passphrase": credentials.passphrase]]),
             heartbeat: "PING", expectsSubscriptionAck: false)
    }

    static func json(_ object: [String: Any]) throws -> String {
        String(decoding: try JSONSerialization.data(withJSONObject: object, options: .sortedKeys), as: UTF8.self)
    }
}
