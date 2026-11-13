import Foundation

public struct MarketQuote: Codable, Equatable, Sendable {
    public var mark: Decimal?
    public var bid: Decimal?
    public var ask: Decimal?
    public var timestamp: Date

    public init(mark: Decimal? = nil, bid: Decimal? = nil, ask: Decimal? = nil, timestamp: Date = .now) {
        self.mark = mark; self.bid = bid; self.ask = ask; self.timestamp = timestamp
    }
}
