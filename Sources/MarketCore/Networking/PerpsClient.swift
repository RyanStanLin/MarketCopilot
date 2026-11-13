import Foundation

public struct PerpsClient: Sendable {
    private let http: HTTPClient
    private let configuration: APIConfiguration
    public init(configuration: APIConfiguration, http: HTTPClient = HTTPClient()) {
        self.configuration = configuration; self.http = http
    }

    public func snapshot(credentials: PerpsCredentials) async throws -> PerpsSnapshot {
        try await http.get(PerpsWire.Portfolio.self, base: configuration.perps,
                           path: "/v1/account/portfolio", headers: headers(credentials)).snapshot
    }

    @discardableResult
    public func validate(credentials: PerpsCredentials, expectedOwner: String?, now: Date = .now) async throws -> String {
        let response = try await http.get(PerpsWire.Credentials.self, base: configuration.perps,
                                         path: "/v1/account/credentials", headers: headers(credentials))
        if let expectedOwner, !expectedOwner.isEmpty,
           response.address.lowercased() != expectedOwner.lowercased() {
            throw APIError(status: 401, reason: "The Perps credentials belong to a different account owner.")
        }
        guard let key = response.keys.first(where: { $0.proxy.lowercased() == credentials.proxy.lowercased() }),
              Double(key.expiry) > now.timeIntervalSince1970 * 1000 else {
            throw APIError(status: 401, reason: "The Perps proxy is expired or revoked. Import fresh session credentials.")
        }
        return response.address
    }

    public func instruments() async throws -> [Int: Instrument] {
        let rows = try await http.get([PerpsWire.InstrumentRow].self, base: configuration.perps, path: "/v1/info/instruments")
        return Dictionary(rows.map { ($0.instrument_id, $0.instrument) }, uniquingKeysWith: { _, latest in latest })
    }

    public func quotes(instrumentIDs: Set<Int>) async throws -> [Int: MarketQuote] {
        guard !instrumentIDs.isEmpty else { return [:] }
        async let tickers = http.get([PerpsWire.Ticker].self, base: configuration.perps, path: "/v1/info/tickers")
        async let bbo = http.get([PerpsWire.BBO].self, base: configuration.perps, path: "/v1/info/bbo")
        var result: [Int: MarketQuote] = [:]
        for ticker in try await tickers where instrumentIDs.contains(ticker.instrument_id) {
            result[ticker.instrument_id] = MarketQuote(mark: ticker.mark_price.value,
                timestamp: ticker.timestamp.map { Date(timeIntervalSince1970: Double($0) / 1000) } ?? .now)
        }
        for quote in try await bbo where instrumentIDs.contains(quote.instrument_id) {
            var value = result[quote.instrument_id] ?? MarketQuote()
            value.bid = quote.bid_price.value > 0 ? quote.bid_price.value : nil
            value.ask = quote.ask_price.value > 0 ? quote.ask_price.value : nil
            result[quote.instrument_id] = value
        }
        return result
    }

    private func headers(_ credentials: PerpsCredentials) -> [String: String] {
        ["POLYMARKET-PROXY": credentials.proxy, "POLYMARKET-SECRET": credentials.secret]
    }
}
