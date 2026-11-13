import MarketCore
import SwiftUI

struct UpdateSettings: View {
    @Bindable var store: AppStore

    var body: some View {
        Form {
            Section("Transport") {
                Picker("Predictions", selection: $store.refreshDraft.predictionMode) {
                    ForEach(TransportMode.allCases) { Text($0.title).tag($0) }
                }
                Picker("Perps", selection: $store.refreshDraft.perpsMode) {
                    ForEach(TransportMode.allCases) { Text($0.title).tag($0) }
                }
                Text("WebSocket is preferred where supported, with polling fallback. Prediction cash uses a read-only Polygon balance query. Updates continue while the menu is closed.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Frequency") {
                TextField("Polling interval (seconds)", value: $store.refreshDraft.pollingInterval, format: .number)
                TextField("Reconciliation (seconds)", value: $store.refreshDraft.reconciliationInterval, format: .number)
                Text("Polling: 1–300 seconds. Reconciliation: 10–600 seconds. Opening the menu or Perps drawer always requests fresh data. Official Perps portfolio pushes arrive about every 5 seconds.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Connection status") {
                LabeledContent("Predictions") { Text(store.predictionStatus).textSelection(.enabled) }
                LabeledContent("Perps") { Text(store.perpsStatus).textSelection(.enabled) }
                Button("Refresh now", action: store.refreshRequested).disabled(store.isRefreshing)
            }
        }.formStyle(.grouped)
    }
}
