import ServiceManagement
import MarketCore
import SwiftUI

struct GeneralSettings: View {
    @Bindable var store: AppStore
    @State private var confirmingDisconnect = false
    @State private var predictionOffsetInput = ""
    @State private var perpsOffsetInput = ""

    var body: some View {
        Form {
            Section("Language") {
                Picker("Display language", selection: $store.refreshDraft.language) {
                    ForEach(AppLanguage.allCases) { Text($0.title).tag($0) }
                }
                .onChange(of: store.refreshDraft.language) { store.applyDisplayPreferences() }
            }
            Section("Cash offsets") {
                TextField("Predictions cash offset", text: $predictionOffsetInput, prompt: Text("+10 / -500"))
                    .onSubmit(applyCashOffsets)
                TextField("Perps cash offset", text: $perpsOffsetInput, prompt: Text("+10 / -500"))
                    .onSubmit(applyCashOffsets)
                Text("Each offset adjusts that account's Cash and Portfolio. Combined totals include both offsets. Position details stay unchanged.")
                    .font(.caption).foregroundStyle(.secondary)
                LabeledContent("Adjusted Cash") {
                    Text(MarketFormat.currency(store.statusCash)).contentTransition(.numericText())
                        .animation(DesignTokens.numberAnimation, value: store.statusCash)
                }
                LabeledContent("Adjusted Portfolio") {
                    Text(MarketFormat.currency(store.statusPortfolio)).contentTransition(.numericText())
                        .animation(DesignTokens.numberAnimation, value: store.statusPortfolio)
                }
                Button("Apply cash offsets", action: applyCashOffsets)
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
            .onAppear {
                predictionOffsetInput = NSDecimalNumber(decimal: store.refreshSettings.predictionCashOffset).stringValue
                perpsOffsetInput = NSDecimalNumber(decimal: store.refreshSettings.perpsCashOffset).stringValue
            }
    }

    private func parseOffset(_ text: String) -> Decimal? {
        let input = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard input.range(of: #"^[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)$"#, options: .regularExpression) != nil,
              let value = Decimal(string: input, locale: Locale(identifier: "en_US_POSIX")), !value.isNaN else { return nil }
        return value
    }

    private func applyCashOffsets() {
        guard let prediction = parseOffset(predictionOffsetInput), let perps = parseOffset(perpsOffsetInput) else {
            store.settingsNotice = ConfigurationError.invalidCashOffset.localizedDescription
            return
        }
        store.refreshDraft.predictionCashOffset = prediction
        store.refreshDraft.perpsCashOffset = perps
        store.applyDisplayPreferences()
    }
}
