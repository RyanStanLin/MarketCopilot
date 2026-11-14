import AppKit
import SwiftUI
import MarketCore
import Observation

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = AppStore(designPreview: CommandLine.arguments.contains("--design-preview"))
    private var statusItem: NSStatusItem?
    private var statusHost: StatusHostingView?
    private var panel: MenuPanel?
    private var clickMonitor: Any?
    private var localMonitor: Any?
    private var settingsWindow: NSWindow?
    private var coordinator: AppCoordinator?
    private var menuTopLeft: CGPoint?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.target = self
        item.button?.action = #selector(toggleMenu)
        item.button?.sendAction(on: [.leftMouseDown])
        item.button?.setAccessibilityLabel(MarketCore.name)
        statusItem = item
        store.openSettings = { [weak self] in self?.showSettings() }
        store.displayPreferencesChanged = { [weak self] in
            self?.settingsWindow?.title = L10n.text("MarketCopilot Settings")
            self?.updateStatus()
        }
        store.renderedMenuHeightChanged = { [weak self] height in self?.resizeMenu(height: height) }
        updateStatus()
        observeStatus()
        installMonitors()
        NSApp.appearance = nil
        #if DEBUG
        if CommandLine.arguments.contains("--validate-native") && store.isDesignPreview {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                NativeValidation.run(self.store)
            }
            return
        }
        if CommandLine.arguments.contains("--render-design") && store.isDesignPreview {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                DesignRenderer.render(self.store)
            }
            return
        }
        if CommandLine.arguments.contains("--validate-motion") && store.isDesignPreview {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.toggleMenu()
                // Exercise the complete two-position fixture even before the status bar has laid out.
                self.store.maximumMenuHeight = 760
                if let panel = self.panel { MenuMotionValidation.run(store: self.store, panel: panel) }
            }
            return
        }
        #endif
        if store.isDesignPreview {
            store.isPerpsExpanded = CommandLine.arguments.contains("--expanded")
            DispatchQueue.main.async { [weak self] in self?.toggleMenu() }
        }
        coordinator = AppCoordinator(store: store)
        coordinator?.start()
        if CommandLine.arguments.contains("--settings") {
            DispatchQueue.main.async { [weak self] in self?.showSettings() }
        }
    }

    func applicationWillTerminate(_ notification: Notification) { coordinator?.stop() }

    @objc private func toggleMenu() {
        guard let button = statusItem?.button, let window = button.window else { return }
        if store.isMenuOpen { closeMenu(); return }
        let menu = panel ?? MenuPanel()
        if panel == nil {
            let host = NSHostingView(rootView: MenuHostRoot(store: store))
            host.sizingOptions = []
            menu.contentView = host
            menu.onCancel = { [weak self] in self?.closeMenu() }
        }
        let anchor = window.convertToScreen(button.convert(button.bounds, to: nil))
        let visible = (window.screen ?? NSScreen.main)?.visibleFrame ?? .zero
        let x = min(max(visible.minX + 8, anchor.minX), visible.maxX - DesignTokens.menuWidth - 8)
        menuTopLeft = CGPoint(x: x, y: anchor.minY - 4)
        store.maximumMenuHeight = max(DesignTokens.collapsedHeight, anchor.minY - visible.minY - 12)
        panel = menu
        resizeMenu(height: store.menuHeight)
        menu.makeKeyAndOrderFront(nil)
        withAnimation(NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? nil : .spring(response: 0.26, dampingFraction: 0.9)) { store.isMenuOpen = true }
        store.refreshRequested()
    }

    func showSettings() {
        closeMenu()
        if settingsWindow == nil {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 580, height: 640),
                                  styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
            window.title = L10n.text("MarketCopilot Settings")
            window.contentView = NSHostingView(rootView: SettingsRoot(store: store))
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = window
        }
        NSApp.activate()
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    func showPortfolio() {
        if !store.isMenuOpen { toggleMenu() }
    }

    private func closeMenu() {
        guard store.isMenuOpen else { return }
        withAnimation(NSWorkspace.shared.accessibilityDisplayShouldReduceMotion ? nil : .easeInOut(duration: 0.16)) { store.isMenuOpen = false } completion: { [weak self] in
            guard let self, !self.store.isMenuOpen else { return }
            self.panel?.orderOut(nil)
            self.menuTopLeft = nil
        }
    }

    private func resizeMenu(height: CGFloat) {
        guard let panel, let menuTopLeft else { return }
        let scale = panel.backingScaleFactor
        let frame = MenuInteraction.frame(topLeft: menuTopLeft, width: DesignTokens.menuWidth,
                                          height: ceil(height * scale) / scale)
        guard panel.frame != frame else { return }
        // SwiftUI owns the spring; AppKit follows its actual rendered height without a second animation.
        panel.setFrame(frame, display: true)
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
        let portfolioWidth = max(textWidth(MarketFormat.currency(store.statusPortfolio), size: 13), textWidth(L10n.text("Portfolio"), size: 10))
        let cashWidth = max(textWidth(MarketFormat.currency(store.statusCash), size: 13), textWidth(L10n.text("Cash"), size: 10))
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
            let point = NSEvent.mouseLocation
            Task { @MainActor in self?.dismissIfOutside(point) }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .keyDown]) { [weak self] event in
            guard let self else { return event }
            if event.type == .keyDown && event.keyCode == 53 && self.store.isMenuOpen { self.closeMenu(); return nil }
            if event.type == .keyDown && self.store.isMenuOpen && [125, 126].contains(event.keyCode) {
                self.store.navigateDrawer(event.keyCode == 125 ? 1 : -1)
                return nil
            }
            if event.type != .keyDown {
                self.dismissIfOutside(NSEvent.mouseLocation)
            }
            return event
        }
    }

    private func dismissIfOutside(_ point: CGPoint) {
        guard store.isMenuOpen, let panel, let button = statusItem?.button, let window = button.window else { return }
        let statusFrame = window.convertToScreen(button.convert(button.bounds, to: nil))
        if MenuInteraction.shouldDismiss(point: point, menuFrame: panel.frame, statusFrame: statusFrame) { closeMenu() }
    }
}
