import MarketCore
import SwiftUI

private struct LiveColorEnvironmentKey: EnvironmentKey {
    static let defaultValue = LiveColorSettings()
}

extension EnvironmentValues {
    var liveColorSettings: LiveColorSettings {
        get { self[LiveColorEnvironmentKey.self] }
        set { self[LiveColorEnvironmentKey.self] = newValue }
    }
}
