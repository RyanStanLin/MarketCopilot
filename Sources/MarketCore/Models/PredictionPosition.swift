import Foundation

public struct PredictionPosition: Codable, Equatable, Sendable, Identifiable {
    public var tokenID: String
    public var conditionID: String
    public var title: String?
    public var icon: URL?
    public var outcome: String?
    public var outcomeIndex: Int?
    public var shares: Decimal?
    public var averagePrice: Decimal?
    public var currentPrice: Decimal?
    public var currentValue: Decimal?
    public var unrealizedPnl: Decimal?
    public var returnOnEquity: Decimal?
    public var eventSlug: String?
    public var slug: String?
    public var id: String { tokenID }

    public init(tokenID: String, conditionID: String, title: String? = nil, icon: URL? = nil,
                outcome: String? = nil, outcomeIndex: Int? = nil, shares: Decimal? = nil,
                averagePrice: Decimal? = nil, currentPrice: Decimal? = nil, currentValue: Decimal? = nil,
                unrealizedPnl: Decimal? = nil, returnOnEquity: Decimal? = nil,
                eventSlug: String? = nil, slug: String? = nil) {
        self.tokenID = tokenID; self.conditionID = conditionID
        self.title = title; self.icon = icon; self.outcome = outcome; self.outcomeIndex = outcomeIndex
        self.shares = shares; self.averagePrice = averagePrice; self.currentPrice = currentPrice
        self.currentValue = currentValue; self.unrealizedPnl = unrealizedPnl; self.returnOnEquity = returnOnEquity
        self.eventSlug = eventSlug; self.slug = slug
    }
}
