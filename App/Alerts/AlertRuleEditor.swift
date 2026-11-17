import MarketCore
import SwiftUI

struct AlertRuleEditor: View {
    let store: AppStore
    let target: AlertTarget
    let saved: (UUID) -> Void
    @State private var draft: AlertRuleDraft
    @State private var isSaving = false

    init(store: AppStore, target: AlertTarget, rule: MarketAlertRule?, saved: @escaping (UUID) -> Void) {
        self.store = store; self.target = target; self.saved = saved
        _draft = State(initialValue: AlertRuleDraft(target: target, rule: rule, currentPrice: store.alertPrice(for: target)))
    }

    var body: some View {
        Form {
            Section {
                Text(target.title).font(.headline).textSelection(.enabled)
                if let outcome = target.outcome { Text(L10n.text(outcome)).foregroundStyle(.secondary) }
                LabeledContent("Current price") {
                    Text(target.product == .predictions ? MarketFormat.cents(store.alertPrice(for: target))
                         : MarketFormat.currency(store.alertPrice(for: target), fractionDigits: target.priceDecimals))
                        .contentTransition(.numericText())
                        .animation(DesignTokens.numberAnimation, value: store.alertPrice(for: target))
                }
            }
            Section("Trigger") {
                Picker("Condition", selection: $draft.trigger) {
                    ForEach(AlertTriggerKind.allCases.filter { $0.supports(target.product) }) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                if draft.trigger.isRapidMove {
                    Picker("Movement basis", selection: $draft.movementUnit) {
                        ForEach(AlertMovementUnit.allCases) { unit in Text(unit.title).tag(unit) }
                    }
                    Picker("Time window", selection: $draft.windowMinutes) {
                        ForEach([1, 5, 15, 30, 60], id: \.self) { minutes in
                            Text(L10n.format("%lld min", Int64(minutes))).tag(minutes)
                        }
                    }
                }
                if draft.trigger != .positionEnded {
                    TextField(draft.thresholdTitle(target: target), text: $draft.thresholdInput)
                        .accessibilityIdentifier("alertThreshold")
                }
                if draft.trigger.isRapidMove {
                    Text("Compares the latest price with the price one full window ago. A full window of fresh history is required after launch, reconnection or editing.")
                        .font(.caption).foregroundStyle(.secondary)
                } else if draft.trigger == .nearLiquidation {
                    Text("Uses the current mark price and official liquidation price. A current buffer below the threshold can notify immediately.")
                        .font(.caption).foregroundStyle(.secondary)
                } else if draft.trigger != .positionEnded {
                    Text("Fires on a new crossing, not on a condition that was already met when armed. PnL is unrealized and is unaffected by Cash offsets.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Section("Delivery") {
                Toggle("Enabled", isOn: $draft.isEnabled)
                Toggle("Repeat on new crossings", isOn: $draft.repeats)
                if draft.repeats {
                    Stepper(L10n.format("Cooldown: %lld min", Int64(draft.cooldownMinutes)), value: $draft.cooldownMinutes, in: 1...1440)
                }
                Toggle("Play a sound", isOn: $draft.playsSound)
                Text("Repeating rules re-arm only after the condition clears. One-shot rules pause after successful delivery.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            AlertPermissionSection(store: store)
            Section {
                Button(draft.original == nil ? "Create alert" : "Save alert", action: save)
                    .buttonStyle(.borderedProminent).disabled(isSaving || store.isRequestingAlertPermission)
                    .accessibilityIdentifier("saveMarketAlert")
                if isSaving { ProgressView().controlSize(.small) }
                Text(store.alertNotice).font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
            }
        }
        .formStyle(.grouped)
        .onChange(of: draft.trigger) { draft.applyDefaults(target: target, currentPrice: store.alertPrice(for: target)) }
        .animation(DesignTokens.drawerAnimation, value: draft.repeats)
    }

    private func save() {
        let rule: MarketAlertRule
        do { rule = try draft.rule(target: target) }
        catch { store.alertNotice = error.localizedDescription; return }
        isSaving = true
        Task {
            defer { isSaving = false }
            if let value = await store.saveAlertRule(rule) {
                draft = AlertRuleDraft(target: target, rule: value, currentPrice: store.alertPrice(for: target))
                saved(value.id)
            }
        }
    }
}
