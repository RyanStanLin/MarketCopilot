import AppKit
import SwiftUI
import MarketCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var panel: MenuPanel?
    private var clickMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "Portfolio —  Cash —"
        item.button?.target = self
        item.button?.action = #selector(toggleMenu)
        item.button?.setAccessibilityLabel(MarketCore.name)
        statusItem = item
    }

    @objc private func toggleMenu() {
        guard let button = statusItem?.button, let window = button.window else { return }
        if let panel, panel.isVisible { panel.orderOut(nil); return }
        let menu = panel ?? MenuPanel()
        menu.contentView = NSHostingView(rootView:
            VStack(alignment: .leading) {
                Text(MarketCore.name).font(.headline)
                Spacer()
                Text("Connect your account in Settings.").foregroundStyle(.secondary)
                Spacer()
            }.padding(14).frame(width: 308, height: 327)
                .background(.regularMaterial, in: .rect(cornerRadius: 16))
        )
        let anchor = window.convertToScreen(button.convert(button.bounds, to: nil))
        menu.setFrame(NSRect(x: anchor.minX, y: anchor.minY - 330, width: 308, height: 327), display: true)
        menu.makeKeyAndOrderFront(nil)
        panel = menu
        if clickMonitor == nil {
            clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
                Task { @MainActor in self?.panel?.orderOut(nil) }
            }
        }
    }
}
