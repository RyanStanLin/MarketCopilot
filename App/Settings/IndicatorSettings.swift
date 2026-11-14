import MarketCore
import SwiftUI

struct IndicatorSettings: View {
    @Bindable var store: AppStore

    var body: some View {
        Form {
            Section("Live color indicator") {
                Toggle("Live color indicator", isOn: $store.refreshDraft.liveColor.enabled)
                Text("Higher values flash green; lower values flash red. The number and its caption fade back together. Colors are blended with the secondary label color for contrast.")
                    .font(.caption).foregroundStyle(.secondary)
                TextField("Fade duration (seconds)", value: $store.refreshDraft.liveColor.duration, format: .number)
                Text("Choose 0.1–10 seconds. Each metric can be enabled independently.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Metrics") {
                ForEach(LiveMetricKind.allCases) { metric in
                    Toggle(metric.title, isOn: Binding(
                        get: { store.refreshDraft.liveColor.metrics.contains(metric) },
                        set: { enabled in
                            if enabled { store.refreshDraft.liveColor.metrics.insert(metric) }
                            else { store.refreshDraft.liveColor.metrics.remove(metric) }
                        }))
                }
            }.disabled(!store.refreshDraft.liveColor.enabled)
        }
        .formStyle(.grouped)
        .onChange(of: store.refreshDraft.liveColor) { store.applyDisplayPreferences() }
    }
}
