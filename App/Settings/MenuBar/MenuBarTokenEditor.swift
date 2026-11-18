import MarketCore
import SwiftUI

struct MenuBarTokenEditor: View {
    let store: AppStore
    @State private var draggedID: UUID?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 8) {
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    HStack(spacing: MenuBarEditorTokens.gap) {
                        ForEach(store.refreshSettings.menuBarTokens) { token in
                            MenuBarTokenView(token: token, store: store, draggedID: $draggedID)
                                .id(token.id)
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }
                    }
                }
                .scrollIndicators(.hidden).frame(height: MenuBarEditorTokens.tokenHeight)
                .onChange(of: store.refreshSettings.menuBarTokens.count) { oldCount, newCount in
                    if newCount > oldCount, let last = store.refreshSettings.menuBarTokens.last {
                        withAnimation(reduceMotion ? nil : DesignTokens.drawerAnimation) { proxy.scrollTo(last.id, anchor: .trailing) }
                    }
                }
            }
            Button("Add", action: add).buttonStyle(.bordered).controlSize(.regular)
                .frame(width: 57, height: MenuBarEditorTokens.controlHeight)
                .help("Add a Menu Bar token")
        }
        .padding(MenuBarEditorTokens.inset)
        .frame(minWidth: MenuBarEditorTokens.width)
        .frame(height: MenuBarEditorTokens.height)
        .background(MenuBarEditorTokens.background, in: .rect(cornerRadius: 8))
        .onDrop(of: [MenuBarDragType.token], delegate: MenuBarDropDelegate(store: store, targetID: nil,
                                                                       draggedID: $draggedID, reduceMotion: reduceMotion))
        .environment(\.locale, store.locale)
    }

    private func add() {
        withAnimation(reduceMotion ? nil : DesignTokens.drawerAnimation) { store.addMenuBarToken() }
    }
}
