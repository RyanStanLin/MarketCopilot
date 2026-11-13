import Foundation

/// One authenticated connection. The controller owns reconnect/backoff and REST fallback.
struct SocketPump: Sendable {
    let factory: any SocketFactory
    let clock: any SessionClock

    func run(_ subscription: SocketSubscription,
             ready: @escaping @Sendable () async -> Void,
             message: @escaping @Sendable (String) async -> Void) async throws {
        let connection = factory.connect(to: subscription.url)
        let heartbeat = Task {
            do {
                while !Task.isCancelled {
                    try await clock.sleep(seconds: 10)
                    try await connection.send(subscription.heartbeat)
                }
            } catch { await connection.close() }
        }
        do {
            try await withTaskCancellationHandler {
                if let authentication = subscription.authentication {
                    try await connection.send(authentication)
                    let response = try await connection.receive()
                    try Self.checkAcknowledgement(response, authentication: true)
                }
                try await connection.send(subscription.subscription)
                if subscription.expectsSubscriptionAck {
                    try Self.checkAcknowledgement(try await connection.receive())
                }
                await ready()
                while !Task.isCancelled {
                    let text = try await connection.receive()
                    try Task.checkCancellation()
                    if text == "PONG" || text == "pong" { continue }
                    try Self.checkError(text)
                    await message(text)
                }
            } onCancel: { Task { await connection.close() } }
            heartbeat.cancel()
            await connection.close()
        } catch {
            heartbeat.cancel()
            await connection.close()
            throw error
        }
    }

    static func checkAcknowledgement(_ text: String, authentication: Bool = false) throws {
        guard let object = try JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any] else {
            throw APIError(status: 0, reason: "The streaming server returned an invalid acknowledgement.")
        }
        let data = object["data"]
        let statuses = (data as? [[String: Any]]) ?? (data as? [String: Any]).map { [$0] } ?? []
        guard !statuses.isEmpty, statuses.allSatisfy({ $0["status"] as? String == "ok" }) else {
            throw APIError(status: authentication ? 401 : 400, reason: "Streaming authentication or subscription was rejected.")
        }
    }

    static func checkError(_ text: String) throws {
        guard let object = try? JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any] else { return }
        if object["error"] != nil || object["type"] as? String == "error" {
            let detail = ((object["error"] as? String) ?? (object["message"] as? String) ?? "").lowercased()
            let isAuth = ["auth", "credential", "api key", "apikey"].contains(where: detail.contains)
            throw APIError(status: isAuth ? 401 : 400, reason: "The streaming server rejected the subscription.")
        }
    }
}
