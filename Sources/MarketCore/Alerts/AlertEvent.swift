import Foundation

public struct AlertEvent: Sendable, Identifiable {
    public let id: UUID
    public let rule: MarketAlertRule
    public let value: Decimal
    public let timestamp: Date

    public init(rule: MarketAlertRule, value: Decimal, timestamp: Date) {
        id = UUID(); self.rule = rule; self.value = value; self.timestamp = timestamp
    }
}
