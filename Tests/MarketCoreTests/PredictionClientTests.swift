import Foundation
import Testing
@testable import MarketCore

@Suite("Official Prediction API")
struct PredictionClientTests {
    @Test func signsCanonicalPathWithUrlSafeHmacAndPreservesPadding() throws {
        let signature = try CLOBAuthentication.signature(secret: "dGVzdC1zZWNyZXQ=", timestamp: "1700000000",
                                                         method: "get", path: "/balance-allowance")
        // Independently computed with Python hmac.sha256 + urlsafe_b64encode.
        #expect(signature == "7sNNKh8J45Qt3mybPDV2Wal05yNQuc0jn4exnFlxjm8=")
        #expect(throws: APIError.self) {
            try CLOBAuthentication.signature(secret: "!invalid!", timestamp: "1", method: "GET", path: "/balance-allowance")
        }
    }

    @Test func cashUsesSignerHeadersWalletTypeAndSixDecimalUnits() async throws {
        let transport = StubHTTPTransport([
            "/time": [.init(body: "1700000000")],
            "/balance-allowance": [.init(body: #"{"balance":"2980000","allowances":{}}"#)]])
        let client = PredictionClient(configuration: try .bundled(), http: HTTPClient(transport: transport))
        var account = AccountConfiguration()
        account.walletAddress = "0x1111111111111111111111111111111111111111"
        account.signerAddress = "0x2222222222222222222222222222222222222222"
        let cash = try await client.cash(account: account, credentials: PredictionCredentials(apiKey: "fixture", secret: "dGVzdC1zZWNyZXQ=", passphrase: "fixture"))
        #expect(cash == Decimal(string: "2.98"))
        let request = try #require(await transport.requests.last)
        #expect(request.value(forHTTPHeaderField: "POLY_ADDRESS") == account.signerAddress)
        #expect(request.value(forHTTPHeaderField: "POLY_SIGNATURE") == "7sNNKh8J45Qt3mybPDV2Wal05yNQuc0jn4exnFlxjm8=")
        #expect(request.url?.query()?.contains("signature_type=3") == true)
        #expect(request.httpMethod == "GET")
    }

    @Test func walksAllPositionCursorsKeepingWalletAnchorAndDeduplicatingTokens() async throws {
        let transport = StubHTTPTransport(["/v2/positions": [
            .init(body: #"{"data":[{"token_id":"first","condition_id":"condition"}],"pagination":{"has_more":true,"next_cursor":"opaque+cursor"}}"#),
            .init(body: #"{"data":[{"token_id":"first","condition_id":"condition"},{"token_id":"second","condition_id":"other"}],"pagination":{"has_more":false,"next_cursor":null}}"#)]])
        let client = PredictionClient(configuration: try .bundled(), http: HTTPClient(transport: transport))
        let positions = try await client.positions(wallet: "wallet-fixture")
        #expect(positions.map(\.tokenID) == ["first", "second"])
        let requests = await transport.requests
        let second = try #require(requests.last?.url)
        let query = URLComponents(url: second, resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(query.contains(.init(name: "user", value: "wallet-fixture")))
        #expect(query.contains(.init(name: "cursor", value: "opaque+cursor")))
        #expect(!query.contains(where: { $0.name == "offset" }))
    }

    @Test func rejectsRepeatingCursorsInsteadOfReturningPartialHoldings() async throws {
        let body = #"{"data":[],"pagination":{"has_more":true,"next_cursor":"repeat"}}"#
        let transport = StubHTTPTransport(["/v2/positions": [.init(body: body), .init(body: body)]])
        let client = PredictionClient(configuration: try .bundled(), http: HTTPClient(transport: transport))
        await #expect(throws: APIError.self) { try await client.positions(wallet: "fixture") }
    }

    @Test func decodesPortfolioNumbersAsDecimalAndMissingCashStaysUnavailable() async throws {
        let transport = StubHTTPTransport([
            "/v2/value": [.init(body: #"{"data":{"proxy_wallet":"fixture","value":123456.1234}}"#)],
            "/v2/positions": [.init(body: #"{"data":[],"pagination":{"has_more":false}}"#)]])
        let client = PredictionClient(configuration: try .bundled(), http: HTTPClient(transport: transport))
        var account = AccountConfiguration(); account.walletAddress = "fixture"
        let result = try await client.snapshot(account: account, credentials: nil)
        #expect(result.holdingsValue == Decimal(string: "123456.1234"))
        #expect(result.cash == nil)
        #expect(result.portfolio == nil)
    }

    @Test func rateLimitPreservesRetryAfterWithoutExposingResponseSecrets() async throws {
        let transport = StubHTTPTransport(["/v2/value": [.init(body: #"{"error":"secret should not be echoed"}"#, status: 429, headers: ["Retry-After": "17"])]])
        let client = PredictionClient(configuration: try .bundled(), http: HTTPClient(transport: transport))
        do {
            _ = try await client.holdingsValue(wallet: "fixture")
            Issue.record("Expected a rate limit")
        } catch let error as APIError {
            #expect(error.status == 429)
            #expect(error.retryAfter == 17)
            #expect(!error.localizedDescription.contains("secret"))
        }
    }
}
