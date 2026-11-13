import Foundation
import Testing
@testable import MarketCore

@Suite("Official Perps API")
struct PerpsClientTests {
    static let portfolio = #"{"positions":[{"instrument_id":2,"symbol":"US100-USD","size":"-0.01","entry_price":"27951","leverage":24,"cross":false,"initial_margin":"18.20","position_value":"437.17","liquidation_price":"30000","unrealized_pnl":"-3.70","return_on_equity":"-0.205","cumulative_funding":"-0.0372"}],"margin":{"total_account_value":"17.72","available_order_margin":"0.02"},"timestamp":1700000000000}"#

    @Test func decodesShortPositionsAndAuthoritativeEquityWithoutAddingNotional() async throws {
        let transport = StubHTTPTransport(["/v1/account/portfolio": [.init(body: Self.portfolio)]])
        let client = PerpsClient(configuration: try .bundled(), http: HTTPClient(transport: transport))
        let result = try await client.snapshot(credentials: .init(proxy: "fixture-proxy", secret: "fixture-secret"))
        #expect(result.portfolio == Decimal(string: "17.72"))
        #expect(result.cash == Decimal(string: "0.02"))
        let position = try #require(result.positions.first)
        #expect(position.id == 2)
        #expect(position.symbol == "US100-USD")
        #expect(position.size == Decimal(string: "-0.01"))
        #expect(position.entryPrice == 27_951)
        #expect(!position.isLong)
        #expect(position.leverage == 24)
        #expect(position.margin == Decimal(string: "18.20"))
        #expect(position.positionValue == Decimal(string: "437.17"))
        #expect(position.liquidationPrice == 30_000)
        #expect(position.cumulativeFunding == Decimal(string: "-0.0372"))
        #expect(position.returnOnEquity == Decimal(string: "-0.205"))
        #expect(position.unrealizedPnl == Decimal(string: "-3.70"))
        let request = try #require(await transport.requests.first)
        #expect(request.value(forHTTPHeaderField: "POLYMARKET-PROXY") == "fixture-proxy")
        #expect(request.value(forHTTPHeaderField: "POLYMARKET-SECRET") == "fixture-secret")
    }

    @Test func missingPrivateFieldsAreErrorsInsteadOfInventedZeroes() async throws {
        let transport = StubHTTPTransport(["/v1/account/portfolio": [.init(body: #"{"positions":[],"equity":"100","timestamp":1700000000000}"#)]])
        let client = PerpsClient(configuration: try .bundled(), http: HTTPClient(transport: transport))
        await #expect(throws: APIError.self) { try await client.snapshot(credentials: .init(proxy: "fixture", secret: "fixture")) }
    }

    @Test func validatesOwnerAndRejectsExpiredProxies() async throws {
        let body = #"{"address":"owner","keys":[{"proxy":"proxy","expiry":1700000000000}]}"#
        let transport = StubHTTPTransport(["/v1/account/credentials": [.init(body: body), .init(body: body)]])
        let client = PerpsClient(configuration: try .bundled(), http: HTTPClient(transport: transport))
        await #expect(throws: APIError.self) {
            try await client.validate(credentials: .init(proxy: "proxy", secret: "fixture"), expectedOwner: "other", now: Date(timeIntervalSince1970: 1_600_000_000))
        }
        await #expect(throws: APIError.self) {
            try await client.validate(credentials: .init(proxy: "proxy", secret: "fixture"), expectedOwner: "owner", now: Date(timeIntervalSince1970: 1_800_000_000))
        }
    }

    @Test func acceptsMatchingOwnerAndUnexpiredProxy() async throws {
        let body = #"{"address":"0xOwner","keys":[{"proxy":"0xProxy","expiry":1800000000000}]}"#
        let transport = StubHTTPTransport(["/v1/account/credentials": [.init(body: body)]])
        let client = PerpsClient(configuration: try .bundled(), http: HTTPClient(transport: transport))
        let owner = try await client.validate(credentials: .init(proxy: "0xproxy", secret: "fixture"), expectedOwner: "0xowner", now: Date(timeIntervalSince1970: 1_700_000_000))
        #expect(owner == "0xOwner")
    }

    @Test func zeroSizeIsRemovedAndUnliquidatableLongHasNoInventedPrice() async throws {
        let zero = Self.portfolio.replacingOccurrences(of: #""size":"-0.01""#, with: #""size":"0""#)
        let long = Self.portfolio.replacingOccurrences(of: #""size":"-0.01""#, with: #""size":"0.01""#)
            .replacingOccurrences(of: #""liquidation_price":"30000""#, with: #""liquidation_price":"0""#)
        let transport = StubHTTPTransport(["/v1/account/portfolio": [.init(body: zero), .init(body: long)]])
        let client = PerpsClient(configuration: try .bundled(), http: HTTPClient(transport: transport))
        let empty = try await client.snapshot(credentials: .init(proxy: "fixture", secret: "fixture"))
        #expect(empty.positions.isEmpty)
        let snapshot = try await client.snapshot(credentials: .init(proxy: "fixture", secret: "fixture"))
        #expect(snapshot.positions.first?.isLong == true)
        #expect(snapshot.positions.first?.liquidationPrice == nil)
    }

    @Test func metadataUsesDisplaySymbolPrecisionAndLightDarkLogos() async throws {
        let body = #"[{"instrument_id":1,"symbol":"SP500-USD","display_symbol":"USA500-USD","quote_asset":"pUSD","price_decimals":1,"logo":{"light":"https://assets.perpetuals.polymarket.com/light.svg","dark":"https://assets.perpetuals.polymarket.com/dark.svg"}}]"#
        let transport = StubHTTPTransport(["/v1/info/instruments": [.init(body: body)]])
        let client = PerpsClient(configuration: try .bundled(), http: HTTPClient(transport: transport))
        let instruments = try await client.instruments()
        #expect(instruments[1]?.displaySymbol == "USA500")
        #expect(instruments[1]?.priceDecimals == 1)
        #expect(instruments[1]?.lightLogo?.lastPathComponent == "light.svg")
        #expect(instruments[1]?.darkLogo?.lastPathComponent == "dark.svg")
    }

    @Test func quoteReadsSeparateMarkFromBidAndAsk() async throws {
        let transport = StubHTTPTransport([
            "/v1/info/tickers": [.init(body: #"[{"instrument_id":2,"mark_price":"28210.1","timestamp":1700000000000}]"#)],
            "/v1/info/bbo": [.init(body: #"[{"instrument_id":2,"bid_price":"28209.9","ask_price":"28210.2"}]"#)]])
        let client = PerpsClient(configuration: try .bundled(), http: HTTPClient(transport: transport))
        let quotes = try await client.quotes(instrumentIDs: [2])
        #expect(quotes[2]?.mark == Decimal(string: "28210.1"))
        #expect(quotes[2]?.bid == Decimal(string: "28209.9"))
        #expect(quotes[2]?.ask == Decimal(string: "28210.2"))
    }
}
