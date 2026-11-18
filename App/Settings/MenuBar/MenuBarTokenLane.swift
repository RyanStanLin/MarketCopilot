import MarketCore
import SwiftUI

struct MenuBarTokenLane: View {
    let store: AppStore
    let drag: MenuBarReorderState
    let scroller: MenuBarScrollDriver
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
                    .padding(.horizontal, MenuBarEditorTokens.inset)
                    .padding(.top, MenuBarEditorTokens.inset)
                    .padding(.bottom, MenuBarEditorTokens.inset + MenuBarEditorTokens.scrollerHeight)
                    .background(MenuBarScrollProbe(driver: scroller))
                }
                .scrollIndicators(.visible, axes: .horizontal)
                .scrollEdgeEffectHidden(true, for: .horizontal)
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
        .environment(\.locale, store.locale)
    }
}
