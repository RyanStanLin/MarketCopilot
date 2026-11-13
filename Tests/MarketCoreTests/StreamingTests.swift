import Foundation
import Testing
@testable import MarketCore

@Suite("Official WebSocket protocols")
struct StreamingTests {
    @Test func tickerAndBookFramesPreserveDistinctPricesAndRejectOldSequences() throws {
        var parser = PerpsStreamParser()
        let first = try parser.parse(#"{"ch":"tickers::2","sq":10,"ts":1700000000000,"data":{"iid":2,"mark":"28210.1"}}"#)
        guard case .quote(let id, let quote) = try #require(first.first) else { Issue.record("Expected a quote"); return }
        #expect(id == 2); #expect(quote.mark == Decimal(string: "28210.1")); #expect(quote.bid == nil)
        #expect(try parser.parse(#"{"ch":"tickers::2","sq":9,"ts":1700000000001,"data":{"iid":2,"mark":"1"}}"#).isEmpty)
        let book = try parser.parse(#"{"ch":"bbo::2","sq":8,"ts":1700000000002,"data":{"iid":2,"bp":"28209.9","ap":"28210.2"}}"#)
        guard case .quote(_, let bbo) = try #require(book.first) else { Issue.record("Expected BBO"); return }
        #expect(bbo.mark == nil)
        #expect(bbo.bid == Decimal(string: "28209.9")); #expect(bbo.ask == Decimal(string: "28210.2"))
    }

    @Test func portfolioPushUsesTheSameAuthoritativeFieldsAsRest() throws {
        var parser = PerpsStreamParser()
        let text = "{\"ch\":\"portfolio\",\"sq\":1,\"ts\":1700000000000,\"data\":" + PerpsClientTests.portfolio + "}"
        let events = try parser.parse(text)
        guard case .portfolio(let snapshot) = try #require(events.first) else { Issue.record("Expected portfolio"); return }
        #expect(snapshot.portfolio == Decimal(string: "17.72"))
        #expect(snapshot.positions.first?.cumulativeFunding == Decimal(string: "-0.0372"))
        #expect(snapshot.positions.first?.isLong == false)
    }

    @Test func subscriptionsAuthenticateBeforeSubscribingAndUseOfficialHeartbeat() async throws {
        let socket = RecordedSocket([
            #"{"id":1,"data":{"status":"ok"}}"#,
            #"{"id":2,"data":[{"status":"ok"}]}"#,
            #"{"ch":"tickers::2","sq":1,"ts":1,"data":{"iid":2,"mark":"2"}}"#])
        let subscription = try SocketSubscription.perps(configuration: .bundled(), credentials: .init(proxy: "fixture", secret: "fixture"), instrumentIDs: [2])
        let state = SocketObservations()
        let pump = SocketPump(factory: RecordedSocketFactory(socket: socket), clock: SystemSessionClock())
        await #expect(throws: URLError.self) {
            try await pump.run(subscription, ready: { await state.connected() }, message: { await state.record($0) })
        }
        let frames = await socket.sent
        #expect(frames.count == 2)
        let auth = try JSONSerialization.jsonObject(with: Data(frames[0].utf8)) as? [String: Any]
        let subscribe = try JSONSerialization.jsonObject(with: Data(frames[1].utf8)) as? [String: Any]
        #expect((auth?["op"] as? [String: Any])?["type"] as? String == "auth")
        #expect(subscribe?["req"] as? String == "sub")
        #expect(await state.isConnected)
        #expect(await state.messages.count == 1)
        #expect(await socket.closed)
        let heartbeat = try JSONSerialization.jsonObject(with: Data(subscription.heartbeat.utf8)) as? [String: Any]
        #expect(heartbeat?["req"] as? String == "post")
        #expect((heartbeat?["op"] as? [String: Any])?["type"] as? String == "ping")
    }

    @Test func rejectedAuthenticationNeverSendsPrivateSubscriptions() async throws {
        let socket = RecordedSocket([#"{"id":1,"data":{"status":"err","error":"unauthorized"}}"#])
        let subscription = try SocketSubscription.perps(configuration: .bundled(), credentials: .init(proxy: "fixture", secret: "fixture"), instrumentIDs: [])
        let state = SocketObservations()
        let pump = SocketPump(factory: RecordedSocketFactory(socket: socket), clock: SystemSessionClock())
        let rejection = try await #require(throws: APIError.self) {
            try await pump.run(subscription, ready: { await state.connected() }, message: { await state.record($0) })
        }
        #expect(rejection.status == 401)
        #expect(await socket.sent.count == 1)
        #expect(await state.isConnected == false)
        #expect(await socket.closed)
    }

    @Test func retryBackoffIsBoundedAndHonorsServerDelay() {
        #expect(RetryPolicy.delay(attempt: 0) == 1)
        #expect(RetryPolicy.delay(attempt: 2) == 4)
        #expect(RetryPolicy.delay(attempt: 100) == 30)
        #expect(RetryPolicy.delay(attempt: 0, retryAfter: 60) == 60)
    }

    @Test func predictionSubscriptionsKeepPublicAssetsAndPrivateCredentialFieldsDistinct() throws {
        let configuration = try APIConfiguration.bundled()
        let publicStream = try SocketSubscription.predictionMarket(configuration: configuration, assetIDs: ["b", "a"])
        let publicJSON = try JSONSerialization.jsonObject(with: Data(publicStream.subscription.utf8)) as? [String: Any]
        #expect(publicJSON?["assets_ids"] as? [String] == ["a", "b"])
        #expect(publicJSON?["type"] as? String == "market")
        #expect(publicJSON?["auth"] == nil)
        let credentials = PredictionCredentials(apiKey: "key-fixture", secret: "secret-fixture", passphrase: "phrase-fixture")
        let userStream = try SocketSubscription.predictionUser(configuration: configuration, credentials: credentials, conditionIDs: [])
        let privateJSON = try JSONSerialization.jsonObject(with: Data(userStream.subscription.utf8)) as? [String: Any]
        let auth = try #require(privateJSON?["auth"] as? [String: String])
        #expect(auth == ["apiKey": "key-fixture", "secret": "secret-fixture", "passphrase": "phrase-fixture"])
        #expect(privateJSON?["type"] as? String == "user")
        #expect(userStream.heartbeat == "PING")
    }
}

actor RecordedSocket: SocketConnection {
    var sent: [String] = []
    var closed = false
    private var incoming: [String]
    init(_ incoming: [String]) { self.incoming = incoming }
    func send(_ message: String) { sent.append(message) }
    func receive() throws -> String {
        guard !incoming.isEmpty else { throw URLError(.networkConnectionLost) }
        return incoming.removeFirst()
    }
    func close() { closed = true }
}

struct RecordedSocketFactory: SocketFactory {
    let socket: RecordedSocket
    func connect(to url: URL) -> any SocketConnection { socket }
}

actor SocketObservations {
    var isConnected = false
    var messages: [String] = []
    func connected() { isConnected = true }
    func record(_ text: String) { messages.append(text) }
}
