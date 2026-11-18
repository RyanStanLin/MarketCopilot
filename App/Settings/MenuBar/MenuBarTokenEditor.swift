import MarketCore
import SwiftUI

struct MenuBarTokenEditor: View {
    let store: AppStore
    @State private var drag = MenuBarReorderState()
    @State private var scroller = MenuBarScrollDriver()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 0) {
            MenuBarTokenViewport(store: store, drag: drag, scroller: scroller)
                .frame(maxWidth: .infinity)
            Button("Add", action: add).buttonStyle(.bordered).controlSize(.regular)
                .frame(width: MenuBarEditorTokens.addWidth, height: MenuBarEditorTokens.controlHeight)
                .help("Add a Menu Bar token")
                .padding(.horizontal, MenuBarEditorTokens.inset)
                .frame(height: MenuBarEditorTokens.height)
                .padding(.bottom, MenuBarEditorTokens.scrollerHeight)
        }
        .frame(height: MenuBarEditorTokens.height + MenuBarEditorTokens.scrollerHeight)
        .onChange(of: store.isMenuBarEditorOpen) { _, open in if !open { drag.reset() } }
        .onDisappear { drag.reset() }
        .environment(\.locale, store.locale)
    }

    private func add() {
        withAnimation(reduceMotion ? nil : DesignTokens.drawerAnimation) { store.addMenuBarToken() }
    }
}
