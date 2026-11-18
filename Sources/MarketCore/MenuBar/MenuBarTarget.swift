public struct MenuBarTarget: Codable, Equatable, Sendable, Identifiable {
    public var product: MarketProduct
    public var accountAddress: String
    public var marketID: String
    public var name: String
    public var outcome: String?
    public var id: String { "\(product.rawValue):\(accountAddress.lowercased()):\(marketID)" }

    public init(product: MarketProduct, accountAddress: String, marketID: String, name: String, outcome: String? = nil) {
        self.product = product; self.accountAddress = accountAddress
        self.marketID = marketID; self.name = name; self.outcome = outcome
    }

    public var displayName: String {
        guard let outcome, !outcome.isEmpty else { return name }
        return "\(name) · \(L10n.text(outcome))"
    }
}
