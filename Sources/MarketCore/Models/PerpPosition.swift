import Foundation

public struct PerpPosition: Codable, Equatable, Sendable, Identifiable {
    public var id: Int
    public var symbol: String
    public var size: Decimal
    public var entryPrice: Decimal
    public var leverage: Int
    public var cross: Bool
    public var margin: Decimal
    public var positionValue: Decimal
    public var liquidationPrice: Decimal?
    public var unrealizedPnl: Decimal
    public var returnOnEquity: Decimal
    public var cumulativeFunding: Decimal

    public var isLong: Bool { size > 0 }

    public init(id: Int, symbol: String, size: Decimal, entryPrice: Decimal, leverage: Int,
                cross: Bool = false, margin: Decimal, positionValue: Decimal,
                liquidationPrice: Decimal?, unrealizedPnl: Decimal,
                returnOnEquity: Decimal, cumulativeFunding: Decimal) {
        self.id = id; self.symbol = symbol; self.size = size; self.entryPrice = entryPrice
        self.leverage = leverage; self.cross = cross; self.margin = margin
        self.positionValue = positionValue; self.liquidationPrice = liquidationPrice
        self.unrealizedPnl = unrealizedPnl; self.returnOnEquity = returnOnEquity
        self.cumulativeFunding = cumulativeFunding
    }
}
