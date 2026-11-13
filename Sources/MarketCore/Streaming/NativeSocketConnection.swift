import Foundation

actor NativeSocketConnection: SocketConnection {
    private let task: URLSessionWebSocketTask
    private let session: URLSession
    init(url: URL) {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        session = URLSession(configuration: configuration)
        task = session.webSocketTask(with: url)
        task.resume()
    }
    func send(_ message: String) async throws { try await task.send(.string(message)) }
    func receive() async throws -> String {
        switch try await task.receive() {
        case .string(let text): return text
        case .data(let data):
            guard let text = String(data: data, encoding: .utf8) else { throw URLError(.cannotDecodeRawData) }
            return text
        @unknown default: throw URLError(.cannotDecodeRawData)
        }
    }
    func close() {
        task.cancel(with: .goingAway, reason: nil)
        session.invalidateAndCancel()
    }
}
