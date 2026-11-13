import Foundation

public struct PerpsSnapshot: Codable, Equatable, Sendable {
    public var portfolio: Decimal
    public var cash: Decimal
    public var positions: [PerpPosition]
    public var timestamp: Date

    public init(portfolio: Decimal, cash: Decimal, positions: [PerpPosition], timestamp: Date = .now) {
        self.portfolio = portfolio; self.cash = cash; self.positions = positions; self.timestamp = timestamp
    }
}
