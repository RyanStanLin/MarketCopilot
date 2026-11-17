import Foundation

struct AlertEvaluationState: Sendable {
    var revision: UUID
    var lastReading: AlertReading?
    var condition: Bool?
    var pendingEvent: UUID?
    var prices: [AlertReading] = []

    mutating func movement(_ reading: AlertReading, rule: MarketAlertRule, maximumGap: TimeInterval) -> Decimal? {
        // Bound history to one point per second and one look-back window plus a baseline.
        if let last = prices.last,
           floor(last.timestamp.timeIntervalSince1970) == floor(reading.timestamp.timeIntervalSince1970) {
            prices[prices.count - 1] = reading
        } else { prices.append(reading) }
        let cutoff = reading.timestamp.addingTimeInterval(-rule.windowSeconds)
        while prices.count > 1 && prices[1].timestamp <= cutoff { prices.removeFirst() }
        guard let baseline = prices.first, baseline.timestamp <= cutoff,
              cutoff.timeIntervalSince(baseline.timestamp) <= maximumGap else { return nil }
        if rule.movementUnit == .percent {
            guard baseline.value > 0 else { return nil }
            return (reading.value - baseline.value) / baseline.value * 100
        }
        return (reading.value - baseline.value) * (rule.target.product == .predictions ? 100 : 1)
    }
}
