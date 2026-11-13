import AppKit
import MarketCore
import Network

@MainActor
final class AppCoordinator {
    private let store: AppStore
    private var controller: PortfolioController?
    private let monitor = NWPathMonitor()
    private var observers: [NSObjectProtocol] = []
    private var cacheTask: Task<Void, Never>?
    private var isSleeping = false

    init(store: AppStore) { self.store = store }

    func start() {
        guard !store.isDesignPreview else { return }
        do {
            let configuration = try APIConfiguration.bundled()
            controller = PortfolioController(configuration: configuration, source: PolymarketDataSource(configuration: configuration))
            controller?.onUpdate = { [weak store] update in store?.apply(update) }
            store.refreshRequested = { [weak self] in Task { await self?.controller?.refresh() } }
            store.settingsApplied = { [weak self] in self?.restart() }
            store.drawerChanged = { [weak self] in
                guard let self else { return }
                self.controller?.setDrawerExpanded(self.store.isPerpsExpanded)
            }
            restart()
            observeLifecycle()
            cacheTask = Task { [weak self] in
                while !Task.isCancelled {
                    do { try await ContinuousClock().sleep(for: .seconds(30)) } catch { break }
                    self?.store.persistSnapshot()
                }
            }
        } catch { store.settingsNotice = error.localizedDescription }
    }

    func restart() {
        guard !isSleeping else { return }
        controller?.start(account: store.account, secrets: store.activeSecrets,
                          settings: store.refreshSettings, cached: store.snapshot)
        controller?.setDrawerExpanded(store.isPerpsExpanded)
    }

    func stop() {
        controller?.stop(); cacheTask?.cancel()
        monitor.cancel()
        for observer in observers { NSWorkspace.shared.notificationCenter.removeObserver(observer) }
        observers = []
        store.persistSnapshot()
    }

    private func observeLifecycle() {
        let center = NSWorkspace.shared.notificationCenter
        observers.append(center.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.isSleeping = true
                self?.controller?.stop(); self?.store.persistSnapshot()
            }
        })
        observers.append(center.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.isSleeping = false; self?.restart() }
        })
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                if path.status == .satisfied { self?.restart() }
                else {
                    self?.controller?.stop()
                    self?.store.predictionStatus = "Offline — showing the last valid snapshot."
                    self?.store.perpsStatus = "Offline — showing the last valid snapshot."
                }
            }
        }
        monitor.start(queue: DispatchQueue(label: "in.ryanl.MarketCopilot.network"))
    }
}
