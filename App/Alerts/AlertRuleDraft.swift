import Foundation
import MarketCore

struct AlertRuleDraft {
    var original: MarketAlertRule?
    var trigger: AlertTriggerKind = .priceAbove
    var thresholdInput = ""
    var movementUnit: AlertMovementUnit = .percent
    var windowMinutes = 5
    var repeats = false
    var cooldownMinutes = 10
    var playsSound = true
    var isEnabled = true

    init(target: AlertTarget, rule: MarketAlertRule?, currentPrice: Decimal?) {
        original = rule
        if let rule {
            trigger = rule.trigger; movementUnit = rule.movementUnit
            windowMinutes = Int(rule.windowSeconds / 60); repeats = rule.repeats
            cooldownMinutes = Int(rule.cooldownSeconds / 60); playsSound = rule.playsSound; isEnabled = rule.isEnabled
            let value = target.product == .predictions && [.priceAbove, .priceBelow].contains(rule.trigger)
                ? rule.threshold * 100 : rule.threshold
            thresholdInput = NSDecimalNumber(decimal: value).stringValue
        } else { applyDefaults(target: target, currentPrice: currentPrice) }
    }

    mutating func applyDefaults(target: AlertTarget, currentPrice: Decimal?) {
        if trigger.isRapidMove {
            movementUnit = target.product == .predictions ? .priceChange : .percent
            thresholdInput = target.product == .predictions ? "5" : "3"
            repeats = true
        } else if [.priceAbove, .priceBelow].contains(trigger), let price = currentPrice {
            thresholdInput = NSDecimalNumber(decimal: price * (target.product == .predictions ? 100 : 1)).stringValue
        } else if trigger == .nearLiquidation { thresholdInput = "5" }
        else { thresholdInput = "" }
    }

    func rule(target: AlertTarget) throws -> MarketAlertRule {
        let threshold: Decimal
        if trigger == .positionEnded { threshold = 0 }
        else {
            // Retain the unparsed edit so invalid input cannot silently reuse an earlier amount.
            let input = thresholdInput.trimmingCharacters(in: .whitespacesAndNewlines)
            guard input.range(of: #"^[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)$"#, options: .regularExpression) != nil,
                  let value = Decimal(string: input, locale: Locale(identifier: "en_US_POSIX")), !value.isNaN else {
                throw AlertValidationError.invalidThreshold
            }
            threshold = target.product == .predictions && [.priceAbove, .priceBelow].contains(trigger) ? value / 100 : value
        }
        return try MarketAlertRule(id: original?.id ?? UUID(), target: target, trigger: trigger, threshold: threshold,
            movementUnit: movementUnit, windowSeconds: TimeInterval(windowMinutes * 60), repeats: repeats,
            cooldownSeconds: TimeInterval(cooldownMinutes * 60), playsSound: playsSound,
            isEnabled: isEnabled, lastTriggeredAt: original?.lastTriggeredAt, createdAt: original?.createdAt ?? .now).validated()
    }

    func thresholdTitle(target: AlertTarget) -> String {
        switch trigger {
        case .priceAbove, .priceBelow: L10n.text(target.product == .predictions ? "Target price (¢)" : "Target price (USD)")
        case .rapidRise, .rapidFall:
            L10n.text(movementUnit == .percent ? "Movement (%)" : target.product == .predictions ? "Movement (¢ / percentage points)" : "Movement (USD)")
        case .profitAbove, .profitBelow: L10n.text("Unrealized PnL (USD)")
        case .returnAbove, .returnBelow: L10n.text("Return (%)")
        case .nearLiquidation: L10n.text("Distance to liquidation (%)")
        case .fundingAbove, .fundingBelow: L10n.text("Cumulative Funding (USD)")
        case .positionEnded: ""
        }
    }
}
