import SwiftUI

struct NotificationSettings: View {
    let store: AppStore

    var body: some View {
        Form {
            AlertPermissionSection(store: store)
            Section("Saved alerts") {
                if store.alertRules.isEmpty {
                    Text("Right-click a market or contract and choose Set notifications… to create an alert.")
                        .foregroundStyle(.secondary)
                }
                ForEach(store.alertRules) { rule in
                    AlertRuleRow(store: store, rule: rule, showTarget: true) { store.openAlertSettings(rule.target) }
                }
            }
            Section {
                Text("Alerts are saved per account and active position. Disconnected accounts and positions that are no longer active pause price and PnL monitoring.")
                    .font(.caption).foregroundStyle(.secondary)
                Text(store.alertNotice).font(.caption).foregroundStyle(.secondary).textSelection(.enabled)
            }
        }.formStyle(.grouped)
    }
}
