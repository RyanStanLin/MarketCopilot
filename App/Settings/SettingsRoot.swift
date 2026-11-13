import SwiftUI

struct SettingsRoot: View {
    let store: AppStore

    var body: some View {
        Form {
            Section("Account") {
                Text("Connect official Polymarket API credentials to view your portfolio.")
                Text(store.predictionStatus).foregroundStyle(.secondary)
                Text(store.perpsStatus).foregroundStyle(.secondary)
            }
            Section {
                Button("Quit MarketCopilot") { NSApp.terminate(nil) }
            }
        }
        .formStyle(.grouped).frame(width: 540, height: 440)
    }
}
