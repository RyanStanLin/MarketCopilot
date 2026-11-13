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
        enum CodingKeys: String, CodingKey { case tokenID = "token_id", conditionID = "condition_id" }
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
