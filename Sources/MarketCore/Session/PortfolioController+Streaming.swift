import Foundation

extension PortfolioController {
    func configureSockets() {
        guard automaticallySchedulesUpdates, account != nil else { return }
        do {
            if settings.predictionMode == .webSocket {
                let assets = Set(snapshot.predictions?.positions.map(\.tokenID) ?? []).sorted()
                if !assets.isEmpty {
                    ensureSocket("predictionMarket", signature: assets.joined(separator: ","), product: .predictions,
                                 subscription: try .predictionMarket(configuration: configuration, assetIDs: assets))
                } else { cancelSocket("predictionMarket") }
                if let credentials = secrets.prediction, !authenticationBlocked.contains(.predictions) {
                    ensureSocket("predictionUser", signature: "account", product: .predictions,
                        subscription: try .predictionUser(configuration: configuration, credentials: credentials, conditionIDs: []))
                } else { cancelSocket("predictionUser") }
            } else { cancelSocket("predictionMarket"); cancelSocket("predictionUser") }

            if settings.perpsMode == .webSocket, let credentials = secrets.perps, perpsValidated,
               !authenticationBlocked.contains(.perps) {
                ensureSocket("perps", signature: "account", product: .perps,
                             subscription: try .perps(configuration: configuration, credentials: credentials, instrumentIDs: []))
                let ids = requestedQuoteIDs.sorted()
                if !ids.isEmpty {
                    ensureSocket("perpsQuotes", signature: ids.map(String.init).joined(separator: ","), product: .perps,
                                 subscription: try .perpsMarket(configuration: configuration, instrumentIDs: ids))
                } else { cancelSocket("perpsQuotes") }
            } else { cancelSocket("perps"); cancelSocket("perpsQuotes") }
        } catch { onUpdate?(.status(.perps, L10n.text("The streaming subscription could not be prepared."))) }
    }

    func ensureSocket(_ key: String, signature: String, product: MarketProduct, subscription: SocketSubscription) {
        guard socketSignatures[key] != signature else { return }
        cancelSocket(key)
        socketSignatures[key] = signature
        let token = generation
        let pump = SocketPump(factory: socketFactory, clock: clock)
        socketTasks[key] = Task { [weak self] in
            var attempt = 0
            while let self, self.isCurrent(token) {
                let connectedAt = self.clock.now
                self.streamParsers[key] = PerpsStreamParser()
                do {
                    try await pump.run(subscription, ready: { [weak self] in
                        await self?.socketReady(key: key, product: product, token: token)
                    }, message: { [weak self] text in
                        await self?.socketMessage(text, key: key, token: token)
                    })
                    break
                } catch {
                    guard self.isCurrent(token) else { break }
                    self.healthySockets.remove(key)
                    self.failed(error, product: product, token: token)
                    if (error as? APIError)?.isAuthenticationFailure == true { break }
                    self.requestEventRefresh(token: token)
                    if self.clock.now.timeIntervalSince(connectedAt) >= 30 { attempt = 0 }
                    let delay = RetryPolicy.delay(attempt: attempt, retryAfter: (error as? APIError)?.retryAfter, jitter: Double.random(in: 0...1))
                    attempt += 1
                    do { try await self.clock.sleep(seconds: delay) } catch { break }
                }
            }
        }
    }

    func cancelSocket(_ key: String) {
        socketTasks.removeValue(forKey: key)?.cancel()
        socketSignatures[key] = nil; healthySockets.remove(key); streamParsers[key] = nil
    }

    func socketReady(key: String, product: MarketProduct, token: UUID) {
        guard isCurrent(token) else { return }
        healthySockets.insert(key)
        onUpdate?(.status(product, L10n.text("WebSocket connected · REST reconciliation active.")))
    }

    func socketMessage(_ text: String, key: String, token: UUID) {
        guard isCurrent(token) else { return }
        do {
            if key == "perps" || key == "perpsQuotes" {
                var parser = streamParsers[key] ?? PerpsStreamParser()
                let events = try parser.parse(text)
                streamParsers[key] = parser
                for event in events {
                    switch event {
                    case .portfolio(let value):
                        lastPerpsPush = clock.now
                        acceptPerps(value)
                        onUpdate?(.status(.perps, L10n.format("WebSocket · Updated %@", value.timestamp.formatted(.dateTime.hour().minute().second().locale(L10n.locale)))))
                        configureSockets()
                    case .quote(let id, let value):
                        if key == "perpsQuotes" { lastQuoteStream = clock.now }
                        mergeQuotes([id: value]); scheduleQuoteFlush(token: token)
                    case .accountChanged: requestEventRefresh(token: token)
                    }
                }
            } else {
                let object = try JSONSerialization.jsonObject(with: Data(text.utf8))
                let objects = (object as? [[String: Any]]) ?? (object as? [String: Any]).map { [$0] } ?? []
                let relevant = ["book", "price_change", "best_bid_ask", "last_trade_price", "market_resolved", "trade", "order"]
                if objects.contains(where: { relevant.contains($0["event_type"] as? String ?? "") }) {
                    requestEventRefresh(token: token)
                }
            }
        } catch { onUpdate?(.status(key.hasPrefix("perps") ? .perps : .predictions, L10n.text("A streaming update could not be decoded; REST reconciliation remains active."))) }
    }

    func requestEventRefresh(token: UUID) {
        guard eventTask == nil else { return }
        let elapsed = clock.now.timeIntervalSince(min(lastPredictionREST, lastPerpsREST))
        let delay = max(0.25, min(5, settings.pollingInterval) - elapsed)
        eventTask = Task { [weak self] in
            guard let self else { return }
            do { try await self.clock.sleep(seconds: delay) } catch { return }
            guard self.isCurrent(token) else { return }
            self.eventTask = nil
            await self.refresh(force: true)
        }
    }

    func scheduleQuoteFlush(token: UUID) {
        guard quoteFlushTask == nil else { return }
        quoteFlushTask = Task { [weak self] in
            guard let self else { return }
            do { try await self.clock.sleep(seconds: 0.25) } catch { return }
            guard self.isCurrent(token) else { return }
            self.quoteFlushTask = nil
            self.onUpdate?(.quotes(self.quoteCache))
        }
    }
}
