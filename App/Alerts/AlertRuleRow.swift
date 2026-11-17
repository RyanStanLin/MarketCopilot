import MarketCore
import SwiftUI

struct AlertRuleRow: View {
    let store: AppStore
    let rule: MarketAlertRule
    let showTarget: Bool
    let edit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                Button(action: edit) {
                    VStack(alignment: .leading, spacing: 4) {
                        if showTarget { Text(rule.target.title).font(.headline).lineLimit(2) }
                        Text(AlertPresentation.summary(rule)).multilineTextAlignment(.leading)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }.buttonStyle(.plain)
                Toggle("Enabled", isOn: Binding(get: { rule.isEnabled }, set: changeEnabled))
                    .labelsHidden().toggleStyle(.switch).controlSize(.small)
                    .disabled(store.isRequestingAlertPermission)
            }
            Text(store.alertMonitoringStatus(rule)).font(.caption).foregroundStyle(.secondary)
            if let date = rule.lastTriggeredAt {
                Text(L10n.format("Last triggered: %@", date.formatted(.dateTime.month().day().hour().minute().locale(store.locale))))
                    .font(.caption).foregroundStyle(.secondary)
            }
            HStack {
                Button("Edit alert", action: edit)
                Spacer()
                Button("Delete alert", systemImage: "trash", role: .destructive, action: delete)
                    .labelStyle(.iconOnly)
                    .disabled(store.isRequestingAlertPermission)
            }.font(.caption)
        }.padding(.vertical, 5)
    }

    private func changeEnabled(_ enabled: Bool) { store.setAlertEnabled(rule.id, enabled: enabled) }
    private func delete() { store.deleteAlertRule(rule.id) }
}
