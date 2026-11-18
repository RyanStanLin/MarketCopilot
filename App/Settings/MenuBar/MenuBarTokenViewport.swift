import SwiftUI

struct MenuBarTokenViewport: NSViewRepresentable {
    let store: AppStore
    let drag: MenuBarReorderState
    let scroller: MenuBarScrollDriver

    func makeNSView(context: Context) -> MenuBarViewportView {
        MenuBarViewportView(content: MenuBarTokenLane(store: store, drag: drag, scroller: scroller), driver: scroller)
    }

    func updateNSView(_ view: MenuBarViewportView, context: Context) {
        view.host.rootView = MenuBarTokenLane(store: store, drag: drag, scroller: scroller)
        view.updateEdges()
    }

    static func dismantleNSView(_ view: MenuBarViewportView, coordinator: ()) { view.detach() }
}
