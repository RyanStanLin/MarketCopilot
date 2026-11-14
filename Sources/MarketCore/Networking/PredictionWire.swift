import Foundation

enum PredictionWire {
    struct ValueEnvelope: Decodable, Sendable {
        let data: Value
        struct Value: Decodable, Sendable { let value: APIAmount }
    }
    struct PositionPage: Decodable, Sendable {
        let data: [Position]
        let pagination: Pagination
    }
    struct Position: Decodable, Sendable {
        let tokenID: String
        let conditionID: String
        let title: String?
        let icon: String?
        let outcome: String?
        let outcome_index: Int?
        let current_size: APIAmount?
        let avg_price: APIAmount?
        let current_price: APIAmount?
        let current_value: APIAmount?
        let unrealized_pnl: APIAmount?
        let percent_pnl: APIAmount?
        let event_slug: String?
        let slug: String?
        let status: String?
        let archived: Bool?
        let redeemable: Bool?
        enum CodingKeys: String, CodingKey {
            case tokenID = "token_id", conditionID = "condition_id"
            case title, icon, outcome, outcome_index, current_size, avg_price, current_price, current_value
            case unrealized_pnl, percent_pnl, event_slug, slug, status, archived, redeemable
        }
        var position: PredictionPosition {
            PredictionPosition(tokenID: tokenID, conditionID: conditionID, title: title,
                icon: icon.flatMap(URL.init(string:)), outcome: outcome, outcomeIndex: outcome_index,
                shares: current_size?.value, averagePrice: avg_price?.value, currentPrice: current_price?.value,
                currentValue: current_value?.value, unrealizedPnl: unrealized_pnl?.value,
                returnOnEquity: percent_pnl.map { $0.value / 100 }, eventSlug: event_slug, slug: slug,
                status: status, isArchived: archived, isRedeemable: redeemable)
        }
    }
    struct Pagination: Decodable, Sendable {
        let nextCursor: String?
        let hasMore: Bool
        enum CodingKeys: String, CodingKey { case nextCursor = "next_cursor", hasMore = "has_more" }
    }
    struct Balance: Decodable, Sendable { let balance: APIAmount }
    struct ProfileSearch: Decodable, Sendable { let profiles: [Profile]? }
    struct Profile: Decodable, Sendable {
        let name: String?
        let pseudonym: String?
        let profileImage: URL?
        let proxyWallet: String?
    }
}
