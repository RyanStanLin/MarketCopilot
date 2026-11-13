import Foundation

extension PortfolioController {
    func refreshPredictions(token: UUID, force: Bool) async {
        guard let account, mayRefresh(.predictions, force: force, last: lastPredictionREST, interval: settings.pollingInterval) else { return }
        guard AccountConfiguration.isAddress(account.walletAddress) else {
            onUpdate?(.status(.predictions, "Add a Polymarket wallet or profile in Settings to include Predictions."))
            return
        }
        do {
            let result = try await source.predictions(account: account, credentials: secrets.prediction)
            guard isCurrent(token) else { return }
            snapshot.predictions = result; lastPredictionREST = clock.now
            authenticationBlocked.remove(.predictions); retryNotBefore[.predictions] = nil
            onUpdate?(.predictions(result))
            let transport = healthySockets.contains("predictionMarket") || healthySockets.contains("predictionUser") ? "WebSocket + REST" : "Polling"
            let text = result.cash == nil ? "Holdings updated · Cash temporarily unavailable; totals include known holdings."
                : transport + " · Updated " + result.timestamp.formatted(date: .omitted, time: .standard)
            onUpdate?(.status(.predictions, text))
        } catch { failed(error, product: .predictions, token: token) }
    }

    func refreshPerps(token: UUID, force: Bool) async {
        guard let account else { return }
        guard let credentials = secrets.perps else {
            onUpdate?(.status(.perps, "Add Perps proxy credentials to read equity, cash and position details.")); return
        }
        let receivingPushes = healthySockets.contains("perps") && clock.now.timeIntervalSince(lastPerpsPush) <= 15
        let interval = receivingPushes ? settings.reconciliationInterval : settings.pollingInterval
        guard mayRefresh(.perps, force: force, last: lastPerpsREST, interval: interval) else { return }
        do {
            if !perpsValidated {
                try await source.validatePerps(credentials: credentials, expectedOwner: account.perpsAddress, now: clock.now)
                guard isCurrent(token) else { return }
                perpsValidated = true
            }
            let result = try await source.perps(credentials: credentials)
            guard isCurrent(token) else { return }
            acceptPerps(result)
            lastPerpsREST = clock.now
            authenticationBlocked.remove(.perps); retryNotBefore[.perps] = nil
            let transport = healthySockets.contains("perps") ? "WebSocket" : "Polling"
            onUpdate?(.status(.perps, transport + " · Updated " + result.timestamp.formatted(date: .omitted, time: .standard)))
            if drawerExpanded {
                let quotes = try await source.quotes(instrumentIDs: Set(result.positions.map(\.id)))
                guard isCurrent(token) else { return }
                mergeQuotes(quotes, replaceBook: true); onUpdate?(.quotes(quoteCache))
            }
        } catch { failed(error, product: .perps, token: token) }
    }

    func refreshMetadata(token: UUID, force: Bool) async {
        if clock.now.timeIntervalSince(lastMetadata) >= 60 {
            do {
                let instruments = try await source.instruments()
                guard isCurrent(token) else { return }
                lastMetadata = clock.now; onUpdate?(.instruments(instruments))
            } catch { /* Optional metadata must not block authoritative account reads. */ }
        }
        if let account, AccountConfiguration.isAddress(account.walletAddress), clock.now.timeIntervalSince(lastProfile) >= 600 {
            do {
                let profile = try await source.profile(wallet: account.walletAddress)
                guard isCurrent(token) else { return }
                lastProfile = clock.now; onUpdate?(.profile(profile))
            } catch { /* Wallets without a public profile remain valid watch accounts. */ }
        }
    }

    func acceptPerps(_ value: PerpsSnapshot) {
        guard value.timestamp >= (snapshot.perps?.timestamp ?? .distantPast) else { return }
        let ordered = value.preservingPositionOrder(from: snapshot.perps?.positions ?? [])
        snapshot.perps = ordered; onUpdate?(.perps(ordered))
    }

    func mergeQuotes(_ updates: [Int: MarketQuote], replaceBook: Bool = false) {
        for (id, value) in updates {
            var merged = quoteCache[id] ?? MarketQuote(timestamp: .distantPast)
            guard value.timestamp >= merged.timestamp else { continue }
            if let mark = value.mark { merged.mark = mark }
            if replaceBook || value.mark == nil {
                merged.bid = value.bid; merged.ask = value.ask
            } else {
                if let bid = value.bid { merged.bid = bid }
                if let ask = value.ask { merged.ask = ask }
            }
            merged.timestamp = value.timestamp
            quoteCache[id] = merged
        }
    }
}
