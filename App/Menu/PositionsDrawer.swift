import SwiftUI

struct PositionsDrawer: View {
    let store: AppStore

    var body: some View {
        Group {
            if DesignTokens.drawerHeight(positionCount: store.positions.count) > store.drawerHeight {
                ScrollView { PositionsContent(store: store) }.scrollIndicators(.never)
            } else {
                PositionsContent(store: store)
            }
        }
        .frame(height: store.drawerHeight - 2)
        .background(DesignTokens.iconFill)
        .padding(.vertical, 1)
        .background(DesignTokens.drawerBorder)
        .accessibilityIdentifier("positionsDrawer")
    }
}
