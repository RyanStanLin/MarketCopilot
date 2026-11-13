import SwiftUI

struct SettingsRoot: View {
    let store: AppStore

    var body: some View {
        VStack(spacing: 0) {
            TabView {
                Tab("Account", systemImage: "person.crop.circle") { AccountSettings(store: store) }
                Tab("Updates", systemImage: "arrow.triangle.2.circlepath") { UpdateSettings(store: store) }
                Tab("General", systemImage: "gearshape") { GeneralSettings(store: store) }
            }
            Divider()
            HStack(spacing: 12) {
                Text(store.settingsNotice).font(.caption).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading).textSelection(.enabled)
                if store.isConnecting || store.isSavingAccount { ProgressView().controlSize(.small) }
                Button("Save & Connect", action: store.saveWorkspace)
                    .buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction)
                    .disabled(store.isConnecting || store.isSavingAccount).accessibilityIdentifier("saveAccount")
            }.padding(16)
        }
        .frame(width: 580, height: 640)
        .environment(\.locale, store.locale)
    }
}
