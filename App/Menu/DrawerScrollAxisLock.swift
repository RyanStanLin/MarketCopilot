import SwiftUI

/// Keeps native vertical momentum and bounce while locking the horizontal axis.
struct DrawerScrollAxisLock: NSViewRepresentable {
    func makeNSView(context: Context) -> DrawerScrollProbe { DrawerScrollProbe() }

    func updateNSView(_ nsView: DrawerScrollProbe, context: Context) {
        nsView.configureScrolling()
    }
}
