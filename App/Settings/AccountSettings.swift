import MarketCore
import SwiftUI

struct AccountSettings: View {
    @Bindable var store: AppStore

    var body: some View {
        Form {
            Section {
                TextField("Account wallet", text: $store.accountDraft.walletAddress).accessibilityIdentifier("accountWallet")
                TextField("Signer address", text: $store.accountDraft.signerAddress)
                Picker("Wallet type", selection: $store.accountDraft.walletType) {
                    ForEach(WalletType.allCases) { Text($0.title).tag($0) }
                }
            } header: { Text("Polymarket account") } footer: {
                Text("Copy the account wallet from your Polymarket profile menu. The API signer can be a different address.")
            }
            Section {
                SecureField("API key", text: $store.secretsDraft.predictionKey)
                SecureField("API secret", text: $store.secretsDraft.predictionSecret)
                SecureField("Passphrase", text: $store.secretsDraft.predictionPassphrase)
            } header: { Text("Predictions · CLOB credentials") } footer: {
                Text("Official CLOB L2 credentials. A public wallet address alone cannot provide the authenticated cash balance.")
            }
            Section {
                TextField("Account owner (optional)", text: $store.accountDraft.perpsAddress)
                TextField("Proxy address", text: $store.secretsDraft.perpsProxy)
                SecureField("Proxy secret", text: $store.secretsDraft.perpsSecret)
            } header: { Text("Perps · delegated credentials") } footer: {
                Text("Use the proxy address and secret from an official Perps session. The optional owner verifies the expected account. Wallet private keys are never needed.")
            }
            Section {
                Link("CLOB authentication guide", destination: URL(string: "https://docs.polymarket.com/getting-started/api#authentication")!)
                Link("Perps session guide", destination: URL(string: "https://docs.polymarket.com/perps/authenticated-sessions")!)
                Text("Secrets are saved only in your macOS Keychain. This app reads data and does not place orders or move funds.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }.formStyle(.grouped).textFieldStyle(.roundedBorder)
    }
}
