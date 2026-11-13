import SwiftUI

@main
struct MarketCopilotApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        Settings {
            Text("MarketCopilot")
                .padding(32)
                .frame(width: 480, height: 320)
        }
    }
}
