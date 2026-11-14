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
    public var status: String?
    public var isArchived: Bool?
    public var isRedeemable: Bool?
    public var id: String { tokenID }

    // An OPEN request also includes resolved, unredeemed tokens. Old caches without
    // lifecycle metadata wait for a fresh response instead of displaying history.
    public var isActive: Bool {
        status == "OPEN" && (shares ?? 0) > 0 && isArchived != true && isRedeemable != true
    }

    public init(tokenID: String, conditionID: String, title: String? = nil, icon: URL? = nil,
                outcome: String? = nil, outcomeIndex: Int? = nil, shares: Decimal? = nil,
                averagePrice: Decimal? = nil, currentPrice: Decimal? = nil, currentValue: Decimal? = nil,
                unrealizedPnl: Decimal? = nil, returnOnEquity: Decimal? = nil,
                eventSlug: String? = nil, slug: String? = nil, status: String? = nil,
                isArchived: Bool? = nil, isRedeemable: Bool? = nil) {
        self.tokenID = tokenID; self.conditionID = conditionID
        self.title = title; self.icon = icon; self.outcome = outcome; self.outcomeIndex = outcomeIndex
        self.shares = shares; self.averagePrice = averagePrice; self.currentPrice = currentPrice
        self.currentValue = currentValue; self.unrealizedPnl = unrealizedPnl; self.returnOnEquity = returnOnEquity
        self.eventSlug = eventSlug; self.slug = slug
        self.status = status; self.isArchived = isArchived; self.isRedeemable = isRedeemable
    }
}
