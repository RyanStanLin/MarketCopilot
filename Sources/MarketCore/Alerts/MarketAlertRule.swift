import Foundation

public struct MarketAlertRule: Codable, Equatable, Sendable, Identifiable {
    public var id: UUID
    public var revision: UUID
    public var target: AlertTarget
    public var trigger: AlertTriggerKind
    public var threshold: Decimal
    public var movementUnit: AlertMovementUnit
    public var windowSeconds: TimeInterval
    public var repeats: Bool
    public var cooldownSeconds: TimeInterval
    public var playsSound: Bool
    public var isEnabled: Bool
    public var lastTriggeredAt: Date?
    public var createdAt: Date

    public init(id: UUID = UUID(), target: AlertTarget, trigger: AlertTriggerKind, threshold: Decimal,
                movementUnit: AlertMovementUnit = .percent, windowSeconds: TimeInterval = 300,
                repeats: Bool = false, cooldownSeconds: TimeInterval = 600, playsSound: Bool = true,
                isEnabled: Bool = true, lastTriggeredAt: Date? = nil, createdAt: Date = .now) {
        self.id = id; revision = UUID(); self.target = target; self.trigger = trigger; self.threshold = threshold
        self.movementUnit = movementUnit; self.windowSeconds = windowSeconds; self.repeats = repeats
        self.cooldownSeconds = cooldownSeconds; self.playsSound = playsSound; self.isEnabled = isEnabled
        self.lastTriggeredAt = lastTriggeredAt; self.createdAt = createdAt
    }

    public func validated() throws -> Self {
        guard AccountConfiguration.isAddress(target.accountAddress), !target.marketID.isEmpty,
              trigger.supports(target.product) else { throw AlertValidationError.invalidTarget }
        guard !threshold.isNaN else { throw AlertValidationError.invalidThreshold }
        if [.priceAbove, .priceBelow].contains(trigger) {
            guard target.product == .predictions ? (0...1).contains(threshold) : threshold > 0 else {
                throw AlertValidationError.invalidThreshold
            }
        }
        if trigger.isRapidMove {
            guard threshold > 0, !(movementUnit == .priceChange && target.product == .predictions && threshold > 100) else {
                throw AlertValidationError.invalidThreshold
            }
        }
        if trigger == .nearLiquidation && !(threshold > 0 && threshold <= 100) { throw AlertValidationError.invalidThreshold }
        guard windowSeconds.isFinite, (60...3600).contains(windowSeconds) else { throw AlertValidationError.invalidWindow }
        guard cooldownSeconds.isFinite, (60...86400).contains(cooldownSeconds) else { throw AlertValidationError.invalidCooldown }
        return self
    }
}
