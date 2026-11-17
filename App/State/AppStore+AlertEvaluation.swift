import Foundation
import MarketCore

extension AppStore {
    func resetAlertMonitoring() {
        for (id, task) in alertDeliveryTasks { task.cancel(); alertNotifications.cancel(eventID: id) }
        alertDeliveryTasks = [:]; pendingAlertEvents = [:]
        liveAlertQuoteIDs = []; alertEngine.reset()
        updateAlertWarmup()
    }

    func cancelAlertDelivery(ruleID: UUID) {
        if let eventID = pendingAlertEvents.removeValue(forKey: ruleID) {
            alertDeliveryTasks.removeValue(forKey: eventID)?.cancel()
            alertNotifications.cancel(eventID: eventID)
        }
    }

    func evaluateAlerts(for product: MarketProduct) {
        guard !isDesignPreview else { return }
        let health = product == .predictions ? predictionHealth : perpsHealth
        guard health.channel != .cache, health.issue == nil else { return }
        let rules = alertRules.filter { $0.isEnabled && $0.target.product == product && isAlertAccountActive($0.target) }
        var seen = Set<String>()
        let freshQuotes = quotes.filter { liveAlertQuoteIDs.contains($0.key) }
        for rule in rules where seen.insert(rule.target.id).inserted {
            let observation: AlertObservation
            if product == .predictions, let value = snapshot.predictions {
                observation = .prediction(target: rule.target, snapshot: value)
            } else if product == .perps, let value = snapshot.perps {
                observation = .perps(target: rule.target, snapshot: value, quotes: freshQuotes)
            } else { continue }
            let events = alertEngine.evaluate(rules, observation: observation, now: .now,
                                               maximumGap: max(15, refreshSettings.pollingInterval * 2.5))
            for event in events { dispatchAlert(event) }
        }
        updateAlertWarmup()
    }

    func updateAlertWarmup() {
        warmingAlertIDs = Set(alertRules.filter { $0.isEnabled && alertEngine.isWarmingUp($0) }.map(\.id))
    }

    private func dispatchAlert(_ event: AlertEvent) {
        guard pendingAlertEvents[event.rule.id] == nil else { alertEngine.acknowledge(event); return }
        pendingAlertEvents[event.rule.id] = event.id
        alertDeliveryTasks[event.id] = Task { [weak self] in
            guard let self else { return }
            defer {
                self.alertDeliveryTasks[event.id] = nil
                if self.pendingAlertEvents[event.rule.id] == event.id { self.pendingAlertEvents[event.rule.id] = nil }
                self.alertEngine.acknowledge(event)
            }
            do {
                guard self.isCurrentAlert(event) else { return }
                try Task.checkCancellation()
                try await self.alertNotifications.deliver(event, timeSensitive: self.refreshSettings.timeSensitiveNotifications)
                guard !Task.isCancelled, self.isCurrentAlert(event),
                      let index = self.alertRules.firstIndex(where: { $0.id == event.rule.id }) else {
                    self.alertNotifications.cancel(eventID: event.id)
                    return
                }
                var updated = self.alertRules
                updated[index].lastTriggeredAt = .now
                if !updated[index].repeats { updated[index].isEnabled = false }
                self.alertRules = updated
                try self.persistAlertRules(updated)
                self.alertRulesChanged()
            } catch is CancellationError { }
            catch {
                self.alertNotice = L10n.format("Notification could not be sent: %@", error.localizedDescription)
                await self.refreshAlertPermission()
            }
        }
    }

    private func isCurrentAlert(_ event: AlertEvent) -> Bool {
        isAlertAccountActive(event.rule.target) && alertRules.contains {
            $0.id == event.rule.id && $0.revision == event.rule.revision && $0.isEnabled
        }
    }
}
