import SwiftUI

struct MenuHoverModifier: ViewModifier {
    let kind: MenuHoverKind
    let id: String
    @State private var hovered = false
    @Environment(\.menuIsVisible) private var menuIsVisible
    @Environment(\.previewHoveredItems) private var previewHoveredItems
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let highlighted = menuIsVisible && (hovered || previewHoveredItems.contains(id))
        content
            .background {
                UnevenRoundedRectangle(cornerRadii: kind.radii)
                    .fill(DesignTokens.subtleBorder)
                    .padding(kind.insets)
                    .opacity(highlighted ? 1 : 0)
            }
            .onHover { hovered = $0 }
            .onChange(of: menuIsVisible) { _, visible in if !visible { hovered = false } }
            .animation(reduceMotion ? nil : .easeOut(duration: 0.13), value: highlighted)
    }
}

extension EnvironmentValues {
    @Entry var menuIsVisible = true
    @Entry var previewHoveredItems: Set<String> = []
}

extension View {
    func menuHover(_ kind: MenuHoverKind, id: String) -> some View {
        modifier(MenuHoverModifier(kind: kind, id: id))
    }
}
