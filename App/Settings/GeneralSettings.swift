import ServiceManagement
import MarketCore
import SwiftUI

struct GeneralSettings: View {
    @Bindable var store: AppStore
    @State private var confirmingDisconnect = false
    @State private var cashOffsetInput = ""

    var body: some View {
        Form {
            Section("Language") {
                Picker("Display language", selection: $store.refreshDraft.language) {
                    ForEach(AppLanguage.allCases) { Text($0.title).tag($0) }
                }
                .onChange(of: store.refreshDraft.language) { store.applyDisplayPreferences() }
            }
            Section("Cash offset") {
                TextField("Adjustment", text: $cashOffsetInput, prompt: Text("+10 / -500"))
                    .onSubmit(applyCashOffset)
                Text("Add or subtract from combined Cash only. Portfolio and individual account balances stay unchanged.")
                    .font(.caption).foregroundStyle(.secondary)
                LabeledContent("Adjusted Cash", value: MarketFormat.currency(store.statusCash))
                Button("Apply cash offset", action: applyCashOffset)
            }
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
            .onAppear { cashOffsetInput = NSDecimalNumber(decimal: store.refreshSettings.cashOffset).stringValue }
    }

    private func applyCashOffset() {
        let input = cashOffsetInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard input.range(of: #"^[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)$"#, options: .regularExpression) != nil,
              let value = Decimal(string: input, locale: Locale(identifier: "en_US_POSIX")), !value.isNaN else {
            store.settingsNotice = ConfigurationError.invalidCashOffset.localizedDescription
            return
        }
        store.refreshDraft.cashOffset = value
        store.applyDisplayPreferences()
    }
}
