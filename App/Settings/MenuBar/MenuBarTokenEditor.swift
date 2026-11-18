import MarketCore
import SwiftUI

struct MenuBarTokenEditor: View {
    let store: AppStore
    @State private var drag = MenuBarReorderState()
    @State private var scroller = MenuBarScrollDriver()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    HStack(spacing: MenuBarEditorTokens.gap) {
                        ForEach(drag.tokens(from: store.refreshSettings.menuBarTokens)) { token in
                            MenuBarTokenCell(token: token, store: store, drag: drag)
                                .id(token.id)
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }
                    }
                    .padding(.top, MenuBarEditorTokens.inset)
                    .padding(.bottom, MenuBarEditorTokens.inset + MenuBarEditorTokens.scrollerHeight)
                    .background(MenuBarScrollProbe(driver: scroller))
                }
                .scrollClipDisabled()
                .scrollIndicators(.visible, axes: .horizontal)
                .scrollEdgeEffectStyle(.soft, for: .horizontal)
                .safeAreaInset(edge: .leading, spacing: 0) {
                    Color.clear.frame(width: MenuBarEditorTokens.inset).allowsHitTesting(false)
                }
                .safeAreaInset(edge: .trailing, spacing: 0) {
                    Button("Add", action: add).buttonStyle(.bordered).controlSize(.regular)
                        .frame(width: MenuBarEditorTokens.addWidth, height: MenuBarEditorTokens.controlHeight)
                        .help("Add a Menu Bar token")
                        .padding(.horizontal, MenuBarEditorTokens.inset)
                        .frame(height: MenuBarEditorTokens.height)
                        .padding(.bottom, MenuBarEditorTokens.scrollerHeight)
                }
                .onChange(of: store.refreshSettings.menuBarTokens.count) { oldCount, newCount in
                    if newCount > oldCount, let last = store.refreshSettings.menuBarTokens.last {
                        withAnimation(reduceMotion ? nil : DesignTokens.drawerAnimation) { proxy.scrollTo(last.id, anchor: .trailing) }
                    }
                }
            }
            .task(id: drag.isLifted) {
                while drag.isLifted, store.isMenuBarEditorOpen, !Task.isCancelled {
                    let velocity = drag.edgeVelocity(viewportWidth: geometry.size.width)
                    if scroller.scroll(by: velocity / 60) {
                        drag.scrolled(direction: velocity, reduceMotion: reduceMotion)
                    }
                    do { try await Task.sleep(for: .milliseconds(16)) } catch { break }
                }
            }
        }
        .coordinateSpace(name: "menuBarEditor")
        .frame(height: MenuBarEditorTokens.height + MenuBarEditorTokens.scrollerHeight)
        .background(MenuBarEditorTokens.background, in: .rect(cornerRadius: 8))
        .onChange(of: store.isMenuBarEditorOpen) { _, open in if !open { drag.reset() } }
        .onDisappear { drag.reset() }
        .environment(\.locale, store.locale)
    }

    private func add() {
        withAnimation(reduceMotion ? nil : DesignTokens.drawerAnimation) { store.addMenuBarToken() }
    }
}
