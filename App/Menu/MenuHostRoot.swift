import SwiftUI

struct MenuHostRoot: View {
    let store: AppStore

    var body: some View {
        ZStack(alignment: .topLeading) {
            PortfolioMenu(store: store)
        }
        // The panel and drawer have different animation curves. Never center the
        // animated content inside the changing NSHostingView bounds.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
