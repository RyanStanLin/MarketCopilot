import SwiftUI

struct MenuHostRoot: View {
    let store: AppStore

    var body: some View {
        ZStack(alignment: .topLeading) {
            PortfolioMenu(store: store)
        }
        // The menu stays at the panel's top while its measured height changes.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
