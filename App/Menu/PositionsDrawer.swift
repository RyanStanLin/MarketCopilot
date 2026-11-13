import SwiftUI

struct PositionsDrawer: View {
    let store: AppStore
    let height: CGFloat

    var body: some View {
        Group {
            if DesignTokens.drawerHeight(positionCount: store.positions.count) > height {
                ScrollView { PositionsContent(store: store) }.scrollIndicators(.never)
            } else {
                PositionsContent(store: store)
            }
        }
        .frame(height: max(0, height - 2), alignment: .top)
        .background(.fill.quaternary)
        .padding(.vertical, 1)
        .background(DesignTokens.drawerBorder)
        .accessibilityIdentifier("positionsDrawer")
    }
}
