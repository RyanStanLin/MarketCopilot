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
    private var menuBarSettingsWindow: NSWindow?
    private var alertWindow: NSWindow?
    private var isTrackingContextMenu = false
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
        store.openMenuBarSettings = { [weak self] in self?.showMenuBarSettings() }
        store.openAlertSettings = { [weak self] target, ruleID in self?.showAlertSettings(target: target, selectedRuleID: ruleID) }
        store.displayPreferencesChanged = { [weak self] in
            self?.settingsWindow?.title = L10n.text("MarketCopilot Settings")
            self?.alertWindow?.title = L10n.text("Position alerts")
            self?.menuBarSettingsWindow?.title = L10n.text("Customize Menu Bar")
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

    private func showMenuBarSettings() {
        closeMenu()
        if menuBarSettingsWindow == nil {
            let size = NSSize(width: MenuBarEditorTokens.width, height: MenuBarEditorTokens.height)
            let window = NSWindow(contentRect: NSRect(origin: .zero, size: size),
                                  styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
            window.title = L10n.text("Customize Menu Bar")
            window.contentView = NSHostingView(rootView: MenuBarTokenEditor(store: store))
            window.contentMinSize = size
            window.contentMaxSize = NSSize(width: .greatestFiniteMagnitude, height: size.height)
            window.isReleasedWhenClosed = false
            window.center()
            menuBarSettingsWindow = window
        }
        NSApp.activate()
        menuBarSettingsWindow?.makeKeyAndOrderFront(nil)
    }

    private func showAlertSettings(target: AlertTarget, selectedRuleID: UUID?) {
        closeMenu()
        let window = alertWindow ?? NSWindow(contentRect: NSRect(x: 0, y: 0, width: 800, height: 720),
            styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        if alertWindow == nil { window.isReleasedWhenClosed = false; window.center() }
        window.title = L10n.text("Position alerts")
        window.contentView = NSHostingView(rootView: AlertRulesWindow(store: store, target: target, selectedRuleID: selectedRuleID))
        alertWindow = window
        NSApp.activate(); window.makeKeyAndOrderFront(nil)
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
        let tokens = store.statusTokens
        let contentWidth = tokens.reduce(0) { $0 + $1.width } + CGFloat(max(0, tokens.count - 1)) * 8
        let width = ceil(contentWidth * min(1, height / DesignTokens.statusHeight)) + 12
        item.length = width
        statusHost?.frame = NSRect(x: 0, y: 0, width: width, height: height)
        button.toolTip = store.menuBarStatusDescription
    }

    private func observeStatus() {
        withObservationTracking {
            _ = store.statusTokens; _ = store.statusDescription
        } onChange: { [weak self] in
            Task { @MainActor in self?.updateStatus(); self?.observeStatus() }
        }
    }

    private func installMonitors() {
        NotificationCenter.default.addObserver(self, selector: #selector(contextMenuBegan), name: NSMenu.didBeginTrackingNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(contextMenuEnded), name: NSMenu.didEndTrackingNotification, object: nil)
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            let point = NSEvent.mouseLocation
            Task { @MainActor in self?.dismissIfOutside(point) }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .keyDown]) { [weak self] event in
            guard let self else { return event }
            if self.isTrackingContextMenu { return event }
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
        guard !isTrackingContextMenu else { return }
        guard store.isMenuOpen, let panel, let button = statusItem?.button, let window = button.window else { return }
        let statusFrame = window.convertToScreen(button.convert(button.bounds, to: nil))
        if MenuInteraction.shouldDismiss(point: point, menuFrame: panel.frame, statusFrame: statusFrame) { closeMenu() }
    }

    @objc private func contextMenuBegan(_ notification: Notification) { if store.isMenuOpen { isTrackingContextMenu = true } }
    @objc private func contextMenuEnded(_ notification: Notification) { isTrackingContextMenu = false }
}
