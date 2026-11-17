import AppKit
import MarketCore

extension AppStore {
    var perpsAlertAccount: String {
        AccountConfiguration.isAddress(account.perpsAddress) ? account.perpsAddress
            : activeSecrets.perps?.proxy ?? ""
    }

    func isAlertAccountActive(_ target: AlertTarget) -> Bool {
        let address = target.product == .predictions ? account.walletAddress : perpsAlertAccount
        return !address.isEmpty && address.lowercased() == target.accountAddress.lowercased()
            && (target.product == .predictions || activeSecrets.perps != nil)
    }

    var monitoredAlertInstrumentIDs: Set<Int> {
        Set(alertRules.compactMap { rule in
            guard rule.isEnabled, rule.target.product == .perps, rule.trigger.needsPrice,
                  isAlertAccountActive(rule.target) else { return nil }
            return Int(rule.target.marketID)
        })
    }

    func alertTarget(for position: PerpPosition) -> AlertTarget {
        AlertTarget(product: .perps, accountAddress: perpsAlertAccount, marketID: String(position.id),
                    title: instruments[position.id]?.displaySymbol ?? position.symbol,
                    destination: perpsWebsiteURL, priceDecimals: instruments[position.id]?.priceDecimals ?? 2)
    }

    func alertTarget(for position: PredictionPosition) -> AlertTarget {
        let slug = position.eventSlug.flatMap { $0.isEmpty ? nil : $0 } ?? position.slug
        return AlertTarget(product: .predictions, accountAddress: account.walletAddress, marketID: position.tokenID,
                           title: position.title ?? L10n.text("Prediction"), outcome: position.outcome,
                           destination: slug.flatMap { predictionWebsiteURL?.appending(component: $0) })
    }

    func alertPrice(for target: AlertTarget) -> Decimal? {
        guard isAlertAccountActive(target) else { return nil }
        if target.product == .predictions { return predictionPositions.first { $0.id == target.marketID }?.currentPrice }
        return Int(target.marketID).flatMap { quotes[$0]?.mark }
    }

    func refreshAlertPermission() async {
        guard !isDesignPreview else { return }
        let previous = alertPermission
        alertNotificationAccess = await alertNotifications.access()
        if alertPermission.allowsNotifications && (previous == .denied || previous == .notDetermined) { resetAlertMonitoring() }
    }

    func requestAlertPermission() async -> Bool {
        guard !isDesignPreview else { alertNotice = L10n.text("Design preview does not send notifications."); return false }
        isRequestingAlertPermission = true
        defer { isRequestingAlertPermission = false }
        alertNotificationAccess = await alertNotifications.access()
        if alertPermission.allowsNotifications { return true }
        do {
            alertNotificationAccess = try await alertNotifications.requestPermission()
            if alertPermission.allowsNotifications { resetAlertMonitoring() }
        }
        catch { alertNotice = error.localizedDescription; return false }
        if !alertPermission.allowsNotifications { alertNotice = AlertDeliveryError.permissionDenied.localizedDescription }
        return alertPermission.allowsNotifications
    }

    func saveAlertRule(_ input: MarketAlertRule) async -> MarketAlertRule? {
        do {
            var rule = try input.validated()
            let existingRevision = alertRules.first { $0.id == input.id }?.revision
            rule.revision = UUID()
            alertNotice = ""
            if rule.isEnabled, !(await requestAlertPermission()) {
                rule.isEnabled = false
                alertNotice = L10n.text("Alert saved paused. Enable notifications, then enable this rule.")
            }
            if let existingRevision, alertRules.first(where: { $0.id == input.id })?.revision != existingRevision {
                alertNotice = L10n.text("This alert changed while saving. Open it again before editing.")
                return nil
            }
            var updated = alertRules
            if let index = updated.firstIndex(where: { $0.id == rule.id }) {
                rule.lastTriggeredAt = updated[index].lastTriggeredAt
                rule.createdAt = updated[index].createdAt
                updated[index] = rule
            }
            else { updated.append(rule) }
            try persistAlertRules(updated)
            cancelAlertDelivery(ruleID: rule.id)
            alertEngine.reset(ruleID: rule.id)
            alertRules = updated
            updateAlertWarmup()
            alertRulesChanged()
            if alertNotice.isEmpty { alertNotice = L10n.text("Alert saved.") }
            return rule
        } catch { alertNotice = error.localizedDescription; return nil }
    }

    func setAlertEnabled(_ id: UUID, enabled: Bool) {
        guard let rule = alertRules.first(where: { $0.id == id }) else { return }
        Task {
            var updated = rule
            updated.isEnabled = enabled
            _ = await saveAlertRule(updated)
        }
    }

    func deleteAlertRule(_ id: UUID) {
        do {
            let updated = alertRules.filter { $0.id != id }
            try persistAlertRules(updated)
            cancelAlertDelivery(ruleID: id); alertEngine.reset(ruleID: id)
            alertRules = updated; alertRulesChanged()
            updateAlertWarmup()
            alertNotice = L10n.text("Alert deleted.")
        } catch { alertNotice = error.localizedDescription }
    }

    func persistAlertRules(_ rules: [MarketAlertRule]) throws {
        guard !isDesignPreview else { return }
        guard let repository else { throw CocoaError(.fileWriteUnknown) }
        try repository.saveAlerts(rules)
    }

    func sendTestNotification() {
        Task {
            guard await requestAlertPermission() else { return }
            do {
                try await alertNotifications.sendTest(timeSensitive: refreshSettings.timeSensitiveNotifications)
                await refreshAlertPermission()
                alertNotice = L10n.text("Test notification submitted to macOS.")
            } catch { alertNotice = error.localizedDescription }
        }
    }

    func openNotificationSystemSettings() {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app"))
    }

    func setTimeSensitiveNotifications(_ enabled: Bool) {
        refreshSettings.timeSensitiveNotifications = enabled
        refreshDraft.timeSensitiveNotifications = enabled
        persistSnapshot()
        alertNotice = L10n.text("Notification priority saved.")
    }

    func alertMonitoringStatus(_ rule: MarketAlertRule) -> String {
        guard rule.isEnabled else { return L10n.text(rule.lastTriggeredAt == nil ? "Paused" : "Triggered · Paused") }
        guard isAlertAccountActive(rule.target) else { return L10n.text("Different account · Paused") }
        if alertPermission == .denied { return alertPermission.title }
        let health = rule.target.product == .predictions ? predictionHealth : perpsHealth
        if health.channel == .cache || health.issue != nil || health.updatedAt == nil {
            return L10n.text("Waiting for fresh data")
        }
        let active = rule.target.product == .predictions
            ? predictionPositions.contains { $0.id == rule.target.marketID }
            : positions.contains { String($0.id) == rule.target.marketID }
        guard active else { return L10n.text("Waiting for an active position") }
        if warmingAlertIDs.contains(rule.id) { return L10n.text("Warming up price history") }
        return L10n.text("Monitoring")
    }
}
