import SwiftUI

@main
struct MarketCopilotApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        Settings {
            SettingsRoot(store: delegate.store)
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings…", action: delegate.showSettings).keyboardShortcut(",")
            }
            CommandGroup(after: .appSettings) {
                Button("Show Portfolio", action: delegate.showPortfolio)
                    .keyboardShortcut("p", modifiers: [.command, .shift])
            }
        }
    }
}
