import Foundation

/// Evaluates only observed, fresh data. Configuration and successful delivery are persisted by the app.
public struct AlertEngine: Sendable {
    private var states: [UUID: AlertEvaluationState] = [:]
    public init() {}
    public mutating func reset() { states = [:] }
    public mutating func reset(ruleID: UUID) { states[ruleID] = nil }
    public func isWarmingUp(_ rule: MarketAlertRule) -> Bool {
        rule.trigger.isRapidMove && states[rule.id]?.hasCompleteWindow != true
    }

    public mutating func acknowledge(_ event: AlertEvent) {
        guard states[event.rule.id]?.pendingEvent == event.id else { return }
        states[event.rule.id]?.pendingEvent = nil
    }

    public mutating func evaluate(_ rules: [MarketAlertRule], observation: AlertObservation,
                                 now: Date, maximumGap: TimeInterval) -> [AlertEvent] {
        rules.compactMap { rule in
            if observation.targetID == rule.target.id,
               observation.readings[.activePosition]?.value == 0, rule.trigger != .positionEnded {
                reset(ruleID: rule.id)
                return nil
            }
            guard rule.isEnabled, rule.target.id == observation.targetID,
                  let reading = observation.readings[rule.trigger.metric] else { return nil }
            return evaluate(rule, reading: reading, now: now, maximumGap: maximumGap)
        }
    }

    private mutating func evaluate(_ rule: MarketAlertRule, reading: AlertReading,
                                  now: Date, maximumGap: TimeInterval) -> AlertEvent? {
        guard !reading.value.isNaN, maximumGap.isFinite, maximumGap > 0,
              (-5...maximumGap).contains(now.timeIntervalSince(reading.timestamp)) else { return nil }
        var state = states.removeValue(forKey: rule.id) ?? AlertEvaluationState(revision: rule.revision)
        defer { states[rule.id] = state }
        if state.revision != rule.revision { state = AlertEvaluationState(revision: rule.revision) }
        if let previous = state.lastReading {
            guard reading.timestamp > previous.timestamp else { return nil }
            if reading.timestamp.timeIntervalSince(previous.timestamp) > maximumGap {
                state = AlertEvaluationState(revision: rule.revision)
            }
        }
        let hadPrevious = state.lastReading != nil
        state.lastReading = reading
        let value: Decimal
        if rule.trigger.isRapidMove {
            guard let movement = state.movement(reading, rule: rule, maximumGap: maximumGap) else { return nil }
            value = movement
        } else { value = reading.value }

        let condition: Bool
        if rule.trigger == .positionEnded { condition = value == 0 }
        else if rule.trigger == .rapidFall { condition = value <= -rule.threshold }
        else { condition = rule.trigger.crossesDown ? value <= rule.threshold : value >= rule.threshold }
        let previousCondition = state.condition
        state.condition = condition
        // Threshold alerts arm on their first observation. A completed rolling window
        // and a current liquidation warning can trigger on their first matching value.
        guard condition, previousCondition != true,
              hadPrevious || rule.trigger == .nearLiquidation || rule.trigger.isRapidMove,
              state.pendingEvent == nil else { return nil }
        if let last = rule.lastTriggeredAt, rule.repeats {
            guard now.timeIntervalSince(last) >= rule.cooldownSeconds else { return nil }
        }
        let event = AlertEvent(rule: rule, value: value, timestamp: reading.timestamp)
        state.pendingEvent = event.id
        return event
    }
}
