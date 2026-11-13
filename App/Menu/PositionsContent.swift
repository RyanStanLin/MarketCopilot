import SwiftUI
import MarketCore

struct PositionsContent: View {
    let store: AppStore

    var body: some View {
        VStack(spacing: 0) {
            SectionHeading(title: "Positions")
            VStack(spacing: DesignTokens.rowGap) {
                if store.positions.isEmpty {
                    Text(L10n.text(store.snapshot.perps == nil ? "Connect Perps in Settings" : "No open positions"))
                        .font(DesignTokens.caption).foregroundStyle(DesignTokens.secondary)
                        .frame(maxWidth: .infinity).frame(height: DesignTokens.positionHeight)
                } else {
                    ForEach(store.positions) { position in PositionRow(position: position, store: store) }
                }
            }.padding(.vertical, 6)
        }
        .padding(.horizontal, DesignTokens.inset).padding(.vertical, 8)
    }
}
