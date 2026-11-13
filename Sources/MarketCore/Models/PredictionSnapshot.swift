import Foundation

public struct PredictionSnapshot: Codable, Equatable, Sendable {
    public var holdingsValue: Decimal
    public var cash: Decimal?
    public var positions: [PredictionPosition]
    public var timestamp: Date
    public var portfolio: Decimal? { cash.map { holdingsValue + $0 } }

    public init(holdingsValue: Decimal, cash: Decimal?, positions: [PredictionPosition] = [], timestamp: Date = .now) {
        self.holdingsValue = holdingsValue; self.cash = cash
        self.positions = positions; self.timestamp = timestamp
    }
}
