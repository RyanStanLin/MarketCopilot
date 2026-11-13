import Foundation

public struct AccountConfiguration: Codable, Equatable, Sendable {
    public var walletAddress = ""
    public var signerAddress = ""
    public var walletType: WalletType = .depositWallet
    public var perpsAddress = ""
    public init() {}

    public var isConfigured: Bool { Self.isAddress(walletAddress) }
    public var identity: String { walletAddress.lowercased() + ":" + perpsAddress.lowercased() }

    public func validated() throws -> Self {
        var result = self
        result.walletAddress = walletAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        result.signerAddress = signerAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        result.perpsAddress = perpsAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Self.isAddress(result.walletAddress) else { throw ConfigurationError.invalidWallet }
        guard result.signerAddress.isEmpty || Self.isAddress(result.signerAddress) else { throw ConfigurationError.invalidSigner }
        guard result.perpsAddress.isEmpty || Self.isAddress(result.perpsAddress) else { throw ConfigurationError.invalidPerpsOwner }
        return result
    }

    public static func isAddress(_ text: String) -> Bool {
        text.count == 42 && text.hasPrefix("0x") && text.dropFirst(2).allSatisfy(\.isHexDigit)
    }
}
