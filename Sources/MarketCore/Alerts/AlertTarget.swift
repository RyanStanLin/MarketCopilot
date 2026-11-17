import Foundation

public struct AlertTarget: Codable, Equatable, Sendable, Identifiable {
    public var product: MarketProduct
    public var accountAddress: String
    public var marketID: String
    public var title: String
    public var outcome: String?
    public var destination: URL?
    public var priceDecimals: Int
    public var id: String { "\(product.rawValue):\(accountAddress.lowercased()):\(marketID)" }

    public init(product: MarketProduct, accountAddress: String, marketID: String,
                title: String, outcome: String? = nil, destination: URL? = nil, priceDecimals: Int = 2) {
        self.product = product; self.accountAddress = accountAddress.lowercased(); self.marketID = marketID
        self.title = title; self.outcome = outcome; self.destination = destination
        self.priceDecimals = max(0, min(12, priceDecimals))
    }
}
