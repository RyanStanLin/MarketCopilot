import Foundation

public protocol SocketFactory: Sendable {
    func connect(to url: URL) -> any SocketConnection
}

public struct NativeSocketFactory: SocketFactory {
    public init() {}
    public func connect(to url: URL) -> any SocketConnection { NativeSocketConnection(url: url) }
}
