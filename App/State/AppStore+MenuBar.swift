import MarketCore
import SwiftUI

extension AppStore {
    private static let fallbackMenuBarIcon = MenuBarToken(metric: .appIcon)

    var statusTokens: [StatusTokenValue] {
        let tokens = refreshSettings.menuBarTokens
        return (tokens.isEmpty ? [Self.fallbackMenuBarIcon] : tokens).map(statusTokenValue)
    }

    var menuBarStatusDescription: String {
        statusTokens.map(\.help).joined(separator: "\n") + "\n\n" + statusDescription
    }

    var menuBarQuoteIDs: Set<Int> {
        Set(refreshSettings.menuBarTokens.compactMap { token in
            guard token.metric.needsQuote, let target = token.target, target.product == .perps,
                  isCurrentMenuBarAccount(target) else { return nil }
            return Int(target.marketID)
        })
    }

    func isCurrentMenuBarAccount(_ target: MenuBarTarget) -> Bool {
        let address = target.product == .perps ? perpsAlertAccount : account.walletAddress
        return !address.isEmpty && address.lowercased() == target.accountAddress.lowercased()
    }

    func menuBarTargets(for metric: MenuBarMetric) -> [MenuBarTarget] {
        var targets: [MenuBarTarget] = []
        if metric.supports(.perps), !perpsAlertAccount.isEmpty {
            targets = positions.map {
                MenuBarTarget(product: .perps, accountAddress: perpsAlertAccount, marketID: String($0.id),
                              name: instruments[$0.id]?.displaySymbol ?? $0.symbol)
            }
            if [.price, .bid, .ask].contains(metric) {
                let heldIDs = Set(positions.map(\.id))
                targets += instruments.values.filter { !heldIDs.contains($0.id) }
                    .sorted { $0.displaySymbol.localizedStandardCompare($1.displaySymbol) == .orderedAscending }
                    .map { MenuBarTarget(product: .perps, accountAddress: perpsAlertAccount,
                                        marketID: String($0.id), name: $0.displaySymbol) }
            }
        }
        if metric.supports(.predictions), !account.walletAddress.isEmpty {
            targets += predictionPositions.map {
                MenuBarTarget(product: .predictions, accountAddress: account.walletAddress, marketID: $0.tokenID,
                              name: $0.title ?? L10n.text("Prediction"), outcome: $0.outcome)
            }
        }
        return targets
    }

    func addMenuBarToken() {
        setMenuBarTokens(refreshSettings.menuBarTokens + [MenuBarToken(metric: .appIcon)])
    }

    func deleteMenuBarToken(_ id: UUID) {
        setMenuBarTokens(refreshSettings.menuBarTokens.filter { $0.id != id })
    }

    func changeMenuBarMetric(_ metric: MenuBarMetric, tokenID: UUID) {
        var tokens = refreshSettings.menuBarTokens
        guard let index = tokens.firstIndex(where: { $0.id == tokenID }) else { return }
        tokens[index].metric = metric
        if !metric.needsTarget { tokens[index].target = nil }
        else if tokens[index].target.map({ metric.supports($0.product) && isCurrentMenuBarAccount($0) }) != true {
            tokens[index].target = menuBarTargets(for: metric).first
        }
        setMenuBarTokens(tokens)
    }

    func changeMenuBarTarget(_ target: MenuBarTarget, tokenID: UUID) {
        var tokens = refreshSettings.menuBarTokens
        guard let index = tokens.firstIndex(where: { $0.id == tokenID }),
              tokens[index].metric.supports(target.product), isCurrentMenuBarAccount(target) else { return }
        tokens[index].target = target
        setMenuBarTokens(tokens)
    }

    func moveMenuBarToken(_ id: UUID, to destination: UUID) {
        var tokens = refreshSettings.menuBarTokens
        guard let source = tokens.firstIndex(where: { $0.id == id }),
              let target = tokens.firstIndex(where: { $0.id == destination }), source != target else { return }
        let moved = tokens.remove(at: source)
        tokens.insert(moved, at: target)
        setMenuBarTokens(tokens)
    }

    func stepMenuBarToken(_ id: UUID, direction: Int) {
        let tokens = refreshSettings.menuBarTokens
        guard let index = tokens.firstIndex(where: { $0.id == id }), tokens.indices.contains(index + direction) else { return }
        moveMenuBarToken(id, to: tokens[index + direction].id)
    }

    func restoreMenuBarDefaults() { setMenuBarTokens(MenuBarToken.defaultLayout) }

    private func setMenuBarTokens(_ tokens: [MenuBarToken]) {
        guard tokens != refreshSettings.menuBarTokens else { return }
        refreshSettings.menuBarTokens = tokens
        refreshDraft.menuBarTokens = tokens
        persistSnapshot()
        settingsNotice = L10n.text("Menu Bar saved.")
        displayPreferencesChanged()
        menuBarTokensChanged()
    }
}
