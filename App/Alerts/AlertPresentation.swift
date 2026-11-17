import Foundation
import MarketCore

enum AlertPresentation {
    static func measurement(_ value: Decimal, rule: MarketAlertRule) -> String {
        switch rule.trigger {
        case .priceAbove, .priceBelow:
            rule.target.product == .predictions ? MarketFormat.cents(value) : MarketFormat.currency(value, fractionDigits: rule.target.priceDecimals)
        case .rapidRise, .rapidFall:
            rule.movementUnit == .percent ? MarketFormat.percent(value / 100)
                : rule.target.product == .predictions ? MarketFormat.cents(value / 100) : MarketFormat.currency(value, signed: true)
        case .returnAbove, .returnBelow, .nearLiquidation: MarketFormat.percent(value / 100)
        case .positionEnded: L10n.text("No longer active")
        default: MarketFormat.currency(value, signed: true)
        }
    }

    static func summary(_ rule: MarketAlertRule) -> String {
        if rule.trigger == .positionEnded { return rule.trigger.title }
        let threshold = measurement(rule.threshold, rule: rule)
        return rule.trigger.isRapidMove
            ? L10n.format("%@ · %@ in %lld min", rule.trigger.title, threshold, Int64(rule.windowSeconds / 60))
            : rule.trigger.title + " · " + threshold
    }

    static func message(_ event: AlertEvent) -> String {
        let rule = event.rule
        let outcome = rule.target.outcome.map { L10n.text($0) + "\n" } ?? ""
        if rule.trigger == .positionEnded {
            return outcome + L10n.text("This position is no longer in the latest active holdings.")
        }
        return outcome + summary(rule) + "\n" + L10n.format("Observed: %@", measurement(event.value, rule: rule))
    }
}
