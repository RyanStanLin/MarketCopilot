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
            L10n.language = settings.language
            self.instruments = instruments
            if account.isConfigured {
                secretsDraft = try KeychainVault().load(identity: account.identity)
                activeSecrets = secretsDraft
                let address = account.walletAddress.isEmpty ? account.perpsAddress : account.walletAddress
                accountName = String(address.prefix(6)) + "…" + address.suffix(4)
            }
            if let cached {
                snapshot = cached
                predictionHealth = DataHealth(updatedAt: cached.predictions?.timestamp, channel: .cache)
                perpsHealth = DataHealth(updatedAt: cached.perps?.timestamp, channel: .cache)
                predictionStatus = L10n.text("Cached data — reconnecting.")
                perpsStatus = L10n.text("Cached data — reconnecting.")
            }
        } catch { settingsNotice = error.localizedDescription }
    }

    func saveWorkspace() {
        guard !isDesignPreview else {
            settingsNotice = L10n.text("Design preview is isolated from saved accounts. Relaunch without --design-preview to connect.")
            return
        }
        guard !isSavingAccount else { return }
        isSavingAccount = true
        settingsNotice = L10n.text("Connecting your account…")
        let draft = accountDraft, settings = refreshDraft, secrets = secretsDraft
        Task { await saveResolvedWorkspace(draft: draft, refresh: settings, secrets: secrets) }
    }

    private func saveResolvedWorkspace(draft: AccountConfiguration, refresh: RefreshSettings, secrets: AccountSecrets) async {
        defer { isSavingAccount = false }
        do {
            let settings = try refresh.validated()
            let configuration = try APIConfiguration.bundled()
            var resolved = draft
            resolved.walletAddress = draft.walletAddress.trimmingCharacters(in: .whitespacesAndNewlines)
            resolved.perpsAddress = draft.perpsAddress.trimmingCharacters(in: .whitespacesAndNewlines)
            if !resolved.walletAddress.isEmpty {
                resolved.walletAddress = try await PredictionClient(configuration: configuration).resolveWallet(resolved.walletAddress)
            } else {
                let trimmedSecrets = try secrets.validated(account: resolved)
                guard let perps = trimmedSecrets.perps else { throw ConfigurationError.incompletePerpsCredentials }
                if resolved.perpsAddress.isEmpty {
                    resolved.perpsAddress = try await PerpsClient(configuration: configuration)
                        .validate(credentials: perps, expectedOwner: nil)
                }
            }
            let account = try resolved.validated()
            let secrets = try secrets.validated(account: account)
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
            refreshSettings = settings; refreshDraft = settings; secretsDraft = secrets; activeSecrets = secrets
            L10n.language = settings.language
            displayPreferencesChanged()
            let address = account.walletAddress.isEmpty ? account.perpsAddress : account.walletAddress
            accountName = String(address.prefix(6)) + "…" + address.suffix(4)
            settingsNotice = L10n.text("Saved. Connecting to Polymarket…")
            if loginChanged {
                do {
                    if settings.launchAtLogin { try SMAppService.mainApp.register() }
                    else { try await SMAppService.mainApp.unregister() }
                } catch { settingsNotice = L10n.format("Account saved. Login item: %@", error.localizedDescription) }
            }
            settingsApplied()
        } catch { settingsNotice = error.localizedDescription }
    }

    func persistSnapshot() {
        guard !isDesignPreview else { return }
        do { try repository?.save(account: account, settings: refreshSettings, snapshot: snapshot, instruments: instruments) }
        catch { settingsNotice = L10n.format("Cache could not be saved: %@", error.localizedDescription) }
    }

    func disconnect() {
        guard !isDesignPreview else { return }
        do {
            try KeychainVault().clear(identity: account.identity)
            account = AccountConfiguration(); accountDraft = account
            secretsDraft = AccountSecrets(); activeSecrets = AccountSecrets(); snapshot = PortfolioSnapshot(); quotes = [:]
            accountName = "Connect account"; avatarURL = nil
            predictionHealth = DataHealth(); perpsHealth = DataHealth()
            predictionStatus = L10n.text("Connect your account in Settings.")
            perpsStatus = predictionStatus
            try repository?.save(account: account, settings: refreshSettings, snapshot: nil, instruments: instruments)
            settingsNotice = L10n.text("Account disconnected. Local credentials and portfolio cache removed.")
            settingsApplied()
        } catch { settingsNotice = error.localizedDescription }
    }
}
