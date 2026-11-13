import ServiceManagement
import SwiftUI

struct GeneralSettings: View {
    @Bindable var store: AppStore
    @State private var confirmingDisconnect = false

    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Launch at login", isOn: $store.refreshDraft.launchAtLogin)
                if SMAppService.mainApp.status == .requiresApproval {
                    Button("Open Login Items Settings", action: SMAppService.openSystemSettingsLoginItems)
                }
            }
            Section("Appearance") {
                Text("Follows your Mac's light or dark appearance. The menu respects Reduce Motion and Reduce Transparency.")
                Text("Portfolio includes cash and position equity. Perps Cash is available order margin; it can differ from withdrawable collateral.")
                    .foregroundStyle(.secondary)
            }
            Section("Account") {
                Button("Disconnect account…", role: .destructive) { confirmingDisconnect = true }
                    .disabled(!store.account.isConfigured)
                    .confirmationDialog("Remove the locally saved account, credentials and portfolio cache?", isPresented: $confirmingDisconnect) {
                        Button("Disconnect", role: .destructive, action: store.disconnect)
                    }
            }
            Section {
                LabeledContent("MarketCopilot", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")
                Button("Quit MarketCopilot") { NSApp.terminate(nil) }
            }
        }.formStyle(.grouped)
    }
}
