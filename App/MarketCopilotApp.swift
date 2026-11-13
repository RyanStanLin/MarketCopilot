import SwiftUI
import MarketCore

@main
struct MarketCopilotApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        let _ = delegate.store.refreshSettings.language
        Settings {
            SettingsRoot(store: delegate.store)
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button(L10n.text("Settings…"), action: delegate.showSettings).keyboardShortcut(",")
            }
            CommandGroup(after: .appSettings) {
                Button(L10n.text("Show Portfolio"), action: delegate.showPortfolio)
                    .keyboardShortcut("p", modifiers: [.command, .shift])
            }
        }
    }
}
