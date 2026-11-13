import Foundation

public struct PerpsCredentials: Codable, Equatable, Sendable {
    public var proxy: String
    public var secret: String
    public init(proxy: String, secret: String) { self.proxy = proxy; self.secret = secret }
}
