import SwiftUI

/// Debug geometry observation compiles away in the production menu.
struct MenuLayoutProbe: ViewModifier {
    let store: AppStore
    let component: String

    func body(content: Content) -> some View {
        #if DEBUG
        content.onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame in
            store.menuLayoutObserved(component, frame)
        }
        #else
        content
        #endif
    }
}
