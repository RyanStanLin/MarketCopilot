import Foundation
import MarketCore
import ServiceManagement

extension AppStore {
    func loadWorkspace() {
        do {
            let repository = try WorkspaceRepository()
            self.repository = repository
            let (account, settings, cached, instruments) = try repository.load()
            self.account = account; accountDraft = account
            refreshSettings = settings; refreshDraft = settings
            self.instruments = instruments
            if account.isConfigured {
                secretsDraft = try KeychainVault().load(identity: account.identity)
                accountName = String(account.walletAddress.prefix(6)) + "…" + account.walletAddress.suffix(4)
            }
            if let cached {
                snapshot = cached
                predictionStatus = "Cached data — reconnecting."
                perpsStatus = "Cached data — reconnecting."
            }
        } catch { settingsNotice = error.localizedDescription }
    }

    func saveWorkspace() {
        guard !isDesignPreview else {
            settingsNotice = "Design preview is isolated from saved accounts. Relaunch without --design-preview to connect."
            return
        }
        do {
            let account = try accountDraft.validated()
            let settings = try refreshDraft.validated()
            let secrets = try secretsDraft.validated(account: account)
            guard let repository else { throw CocoaError(.fileWriteUnknown) }
            let sameAccount = self.account.identity == account.identity
            try KeychainVault().save(secrets, identity: account.identity)
            try repository.save(account: account, settings: settings,
                                snapshot: sameAccount ? snapshot : nil, instruments: instruments)
            if !sameAccount {
                snapshot = PortfolioSnapshot(); quotes = [:]; avatarURL = nil
            }
            let loginChanged = refreshSettings.launchAtLogin != settings.launchAtLogin
            self.account = account; accountDraft = account
            refreshSettings = settings; refreshDraft = settings; secretsDraft = secrets
            accountName = String(account.walletAddress.prefix(6)) + "…" + account.walletAddress.suffix(4)
            settingsNotice = "Saved. Connecting to Polymarket…"
            if loginChanged {
                do {
                    if settings.launchAtLogin { try SMAppService.mainApp.register() }
                    else { try SMAppService.mainApp.unregister() }
                } catch { settingsNotice = "Account saved. Login item: " + error.localizedDescription }
            }
            settingsApplied()
        } catch { settingsNotice = error.localizedDescription }
    }

    func persistSnapshot() {
        guard !isDesignPreview else { return }
        do { try repository?.save(account: account, settings: refreshSettings, snapshot: snapshot, instruments: instruments) }
        catch { settingsNotice = "Cache could not be saved: " + error.localizedDescription }
    }

    func disconnect() {
        guard !isDesignPreview else { return }
        do {
            try KeychainVault().clear(identity: account.identity)
            account = AccountConfiguration(); accountDraft = account
            secretsDraft = AccountSecrets(); snapshot = PortfolioSnapshot(); quotes = [:]
            accountName = "Connect account"; avatarURL = nil
            predictionStatus = "Connect your account in Settings."
            perpsStatus = predictionStatus
            try repository?.save(account: account, settings: refreshSettings, snapshot: nil, instruments: instruments)
            settingsNotice = "Account disconnected. Local credentials and portfolio cache removed."
            settingsApplied()
        } catch { settingsNotice = error.localizedDescription }
    }
}
