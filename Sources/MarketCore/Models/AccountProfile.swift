import Foundation

public struct AccountProfile: Equatable, Sendable {
    public let name: String?
    public let avatar: URL?
    public let wallet: String?
    public init(name: String?, avatar: URL?, wallet: String?) { self.name = name; self.avatar = avatar; self.wallet = wallet }
}
