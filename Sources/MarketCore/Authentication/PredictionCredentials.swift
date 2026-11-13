import Foundation

public struct PredictionCredentials: Codable, Equatable, Sendable {
    public var apiKey: String
    public var secret: String
    public var passphrase: String
    public init(apiKey: String, secret: String, passphrase: String) {
        self.apiKey = apiKey; self.secret = secret; self.passphrase = passphrase
    }
}
