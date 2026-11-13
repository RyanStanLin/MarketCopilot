import MarketCore
import SwiftUI

struct AccountSettings: View {
    @Bindable var store: AppStore

    var body: some View {
        Form {
            Section {
                TextField("Wallet or profile", text: $store.accountDraft.walletAddress, prompt: Text("0x… / @username / profile link"))
                    .accessibilityIdentifier("accountWallet")
            } header: { Text("Predictions") } footer: {
                Text("Google and email accounts work with your account wallet, @username or Polymarket profile link. Holdings and pUSD cash are read automatically; no API keys are required. You can leave this empty when connecting only Perps.")
            }
            Section {
                DisclosureGroup("Advanced Predictions access (optional)") {
                TextField("Signer address", text: $store.accountDraft.signerAddress)
                Picker("Wallet type", selection: $store.accountDraft.walletType) {
                    ForEach(WalletType.allCases) { Text($0.title).tag($0) }
                }
                SecureField("API key", text: $store.secretsDraft.predictionKey)
                SecureField("API secret", text: $store.secretsDraft.predictionSecret)
                SecureField("Passphrase", text: $store.secretsDraft.predictionPassphrase)
                Text("Existing CLOB L2 credentials optionally enable private order/trade notifications. Public wallet reads remain available without them.")
                    .font(.caption).foregroundStyle(.secondary)
                }
            }
            Section {
                TextField("Account owner (optional)", text: $store.accountDraft.perpsAddress)
                TextField("Proxy address", text: $store.secretsDraft.perpsProxy)
                SecureField("Proxy secret", text: $store.secretsDraft.perpsSecret)
            } header: { Text("Perps · delegated credentials") } footer: {
                Text("Use the proxy address and secret from an official Perps session. The optional owner verifies the expected account. Wallet private keys are never needed.")
            }
            Section {
                Link("Find your Polymarket account wallet", destination: URL(string: "https://docs.polymarket.com/trading/wallets-auth#connect-your-account")!)
                Link("Perps session guide", destination: URL(string: "https://docs.polymarket.com/perps/authenticated-sessions")!)
                Text("Secrets are saved only in your macOS Keychain. This app reads data and does not place orders or move funds.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }.formStyle(.grouped).textFieldStyle(.roundedBorder)
            .disabled(store.isSavingAccount)
    }
}
