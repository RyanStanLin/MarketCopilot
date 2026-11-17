import MarketCore
import SwiftUI

struct AlertRulesWindow: View {
    let store: AppStore
    let target: AlertTarget
    @State private var selection: UUID?
    @State private var newDraftID = UUID()
    private var rules: [MarketAlertRule] { store.alertRules.filter { $0.target.id == target.id } }

    init(store: AppStore, target: AlertTarget, selectedRuleID: UUID? = nil) {
        self.store = store; self.target = target
        _selection = State(initialValue: selectedRuleID)
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                Button("New alert", systemImage: "plus", action: newAlert)
                    .padding(12).frame(maxWidth: .infinity)
                List {
                    ForEach(rules) { rule in
                        AlertRuleRow(store: store, rule: rule, showTarget: false, edit: { selection = rule.id })
                    }
                    if rules.isEmpty {
                        Text("No alerts for this position yet.").font(.caption).foregroundStyle(.secondary)
                    }
                }
                Text("Alerts run while MarketCopilot is open, including when the menu is closed. Refresh speed follows Updates settings.")
                    .font(.caption).foregroundStyle(.secondary).padding(12)
            }.navigationTitle("Position alerts").navigationSplitViewColumnWidth(min: 230, ideal: 250, max: 290)
        } detail: {
            AlertRuleEditor(store: store, target: target, rule: rules.first { $0.id == selection }, saved: select)
                .id(selection ?? newDraftID)
        }
        .frame(minWidth: 740, minHeight: 660)
        .environment(\.locale, store.locale)
        .onChange(of: rules.map(\.id)) {
            if let selection, !rules.contains(where: { $0.id == selection }) { newAlert() }
        }
    }

    private func newAlert() { selection = nil; newDraftID = UUID(); store.alertNotice = "" }
    private func select(_ id: UUID) { selection = id }
}
