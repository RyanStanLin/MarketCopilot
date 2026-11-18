import MarketCore
import SwiftUI

struct MenuBarTokenCell: View {
    let token: MenuBarToken
    let store: AppStore
    let drag: MenuBarReorderState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var lifted: Bool { drag.activeID == token.id && !drag.isSettling }

    var body: some View {
        ZStack {
            Color.clear
            MenuBarTokenView(token: token, store: store, drag: drag)
                .modifier(MenuBarWiggle(id: token.id, enabled: store.isMenuBarEditorOpen && !reduceMotion && drag.activeID != token.id))
                .scaleEffect(lifted && !reduceMotion ? 1.035 : 1)
                .opacity(lifted ? 0.82 : 1)
                .shadow(color: MenuBarEditorTokens.shadow.opacity(lifted ? 0.3 : 0.08),
                        radius: lifted ? 8 : 1, x: 0, y: lifted ? 3 : 0.5)
                .animation(reduceMotion ? nil : DesignTokens.pressAnimation, value: lifted)
                .offset(drag.offset(for: token.id))
        }
        .frame(width: MenuBarEditorTokens.tokenWidth(token), height: MenuBarEditorTokens.tokenHeight)
        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named("menuBarEditor")) } action: { rect in
            if drag.frames[token.id] != rect { drag.frames[token.id] = rect }
        }
        .zIndex(drag.activeID == token.id ? 100 : 0)
    }
}
