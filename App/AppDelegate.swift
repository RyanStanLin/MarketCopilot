import AppKit
import SwiftUI
import MarketCore
import Observation
import QuartzCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = AppStore(designPreview: CommandLine.arguments.contains("--design-preview"))
    private var statusItem: NSStatusItem?
    private var statusHost: StatusHostingView?
    private var panel: MenuPanel?
    private var clickMonitor: Any?
    private var localMonitor: Any?
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.target = self
        item.button?.action = #selector(toggleMenu)
        item.button?.setAccessibilityLabel(MarketCore.name)
        statusItem = item
        store.openSettings = { [weak self] in self?.showSettings() }
        store.layoutChanged = { [weak self] in self?.resizeMenu(animated: true) }
        updateStatus()
        observeStatus()
        installMonitors()
        if CommandLine.arguments.contains("--dark") { NSApp.appearance = NSAppearance(named: .darkAqua) }
        if CommandLine.arguments.contains("--light") { NSApp.appearance = NSAppearance(named: .aqua) }
        #if DEBUG
        if CommandLine.arguments.contains("--render-design") && store.isDesignPreview {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                DesignRenderer.render(self.store)
            }
            return
        }
        #endif
        if store.isDesignPreview {
            store.isPerpsExpanded = CommandLine.arguments.contains("--expanded")
            DispatchQueue.main.async { [weak self] in self?.toggleMenu() }
        }
    }

    @objc private func toggleMenu() {
        guard let button = statusItem?.button, let window = button.window else { return }
        if store.isMenuOpen { closeMenu(); return }
        let menu = panel ?? MenuPanel()
        if panel == nil {
            let host = NSHostingView(rootView: PortfolioMenu(store: store))
            host.sizingOptions = []
            menu.contentView = host
            menu.onCancel = { [weak self] in self?.closeMenu() }
        }
        let anchor = window.convertToScreen(button.convert(button.bounds, to: nil))
        let visible = (window.screen ?? NSScreen.main)?.visibleFrame ?? .zero
        store.maximumMenuHeight = max(DesignTokens.collapsedHeight, anchor.minY - visible.minY - 12)
        panel = menu
        resizeMenu(animated: false)
        menu.makeKeyAndOrderFront(nil)
        withAnimation(.spring(response: 0.26, dampingFraction: 0.9)) { store.isMenuOpen = true }
        store.refreshRequested()
    }

    func showSettings() {
        closeMenu()
        if settingsWindow == nil {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 580, height: 640),
                                  styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
            window.title = "MarketCopilot Settings"
            window.contentView = NSHostingView(rootView: SettingsRoot(store: store))
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = window
        }
        NSApp.activate()
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    private func closeMenu() {
        guard store.isMenuOpen else { return }
        withAnimation(.easeInOut(duration: 0.16)) { store.isMenuOpen = false } completion: { [weak self] in
            guard let self, !self.store.isMenuOpen else { return }
            self.panel?.orderOut(nil)
        }
    }

    private func resizeMenu(animated: Bool) {
        guard let button = statusItem?.button, let window = button.window, let panel else { return }
        let anchor = window.convertToScreen(button.convert(button.bounds, to: nil))
        let visible = (window.screen ?? NSScreen.main)?.visibleFrame ?? .zero
        let x = min(max(visible.minX + 8, anchor.minX), visible.maxX - DesignTokens.menuWidth - 8)
        let frame = NSRect(x: x, y: anchor.minY - 4 - store.menuHeight, width: DesignTokens.menuWidth, height: store.menuHeight)
        if animated && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.38
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                panel.animator().setFrame(frame, display: true)
            }
        } else { panel.setFrame(frame, display: true) }
    }

    private func updateStatus() {
        guard let item = statusItem, let button = item.button else { return }
        let height = button.bounds.height > 0 ? button.bounds.height : NSStatusBar.system.thickness
        let label = StatusLabel(store: store, availableHeight: height)
        if let statusHost { statusHost.rootView = label } else {
            let host = StatusHostingView(rootView: label)
            host.sizingOptions = []
            button.addSubview(host)
            statusHost = host
        }
        let portfolioWidth = max(textWidth(MarketFormat.currency(store.statusPortfolio), size: 13), textWidth("Portfolio", size: 10))
        let cashWidth = max(textWidth(MarketFormat.currency(store.statusCash), size: 13), textWidth("Cash", size: 10))
        let width = ceil((portfolioWidth + cashWidth + 8) * min(1, height / 26)) + 12
        item.length = width
        statusHost?.frame = NSRect(x: 0, y: 0, width: width, height: height)
        button.toolTip = store.statusDescription
    }

    private func textWidth(_ text: String, size: CGFloat) -> CGFloat {
        (text as NSString).size(withAttributes: [.font: NSFont.systemFont(ofSize: size)]).width
    }

    private func observeStatus() {
        withObservationTracking {
            _ = store.statusPortfolio; _ = store.statusCash; _ = store.statusDescription
        } onChange: { [weak self] in
            Task { @MainActor in self?.updateStatus(); self?.observeStatus() }
        }
    }

    private func installMonitors() {
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in self?.closeMenu() }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .keyDown]) { [weak self] event in
            guard let self else { return event }
            if event.type == .keyDown && event.keyCode == 53 { self.closeMenu(); return nil }
            if event.type != .keyDown, event.window !== self.panel, event.window !== self.statusItem?.button?.window {
                self.closeMenu()
            }
            return event
        }
    }
}
