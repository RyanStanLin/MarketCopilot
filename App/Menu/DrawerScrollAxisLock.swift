import SwiftUI

/// Configures just the drawer's enclosing native scroll view.
struct DrawerScrollAxisLock: NSViewRepresentable {
    func makeNSView(context: Context) -> DrawerScrollProbe { DrawerScrollProbe() }

    func updateNSView(_ nsView: DrawerScrollProbe, context: Context) {
        nsView.lockHorizontalAxis()
    }
}
