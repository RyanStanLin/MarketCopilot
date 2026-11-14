import MarketCore
import SwiftUI

struct DataHealthSection: View {
    let store: AppStore
    var body: some View {
        TimelineView(.animation(minimumInterval: 1, paused: !store.isMenuOpen)) { context in
            VStack(spacing: 0) {
                DataHealthRow(title: "Prediction Last Update", health: store.predictionHealth, now: context.date,
                              staleAfter: store.predictionHealth.channel == .webSocket ? 15 : max(15, store.refreshSettings.pollingInterval * 3), detail: store.predictionStatus)
                DataHealthRow(title: "Perps Last Update", health: store.perpsHealth, now: context.date,
                              staleAfter: store.perpsHealth.channel == .webSocket ? 15 : max(15, store.refreshSettings.pollingInterval * 3), detail: store.perpsStatus)
            }
        }
    }
}
