import Foundation

public protocol SocketConnection: Sendable {
    func send(_ message: String) async throws
    func receive() async throws -> String
    func close() async
}
