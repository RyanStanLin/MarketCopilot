import Foundation

extension PredictionClient {
    public func resolveWallet(_ input: String) async throws -> String {
        var identifier = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if AccountConfiguration.isAddress(identifier) { return identifier }
        if identifier.contains("/") {
            if !identifier.contains("://") { identifier = "https://" + identifier }
            guard let url = URL(string: identifier), url.scheme == "https",
                  ["polymarket.com", "www.polymarket.com"].contains(url.host()?.lowercased() ?? ""),
                  let path = url.pathComponents.last, path != "/" else { throw ConfigurationError.invalidProfile }
            identifier = path
            if AccountConfiguration.isAddress(identifier) { return identifier }
        }
        if identifier.hasPrefix("@") { identifier.removeFirst() }
        guard !identifier.isEmpty, identifier.count <= 100,
              identifier.allSatisfy({ $0.isLetter || $0.isNumber || "._-".contains($0) }) else {
            throw ConfigurationError.invalidProfile
        }
        let search = try await searchProfiles(identifier)
        let matches = (search.profiles ?? []).filter {
            [$0.name, $0.pseudonym].compactMap { $0 }.contains { $0.caseInsensitiveCompare(identifier) == .orderedSame }
        }
        let wallets = Set(matches.compactMap(\.proxyWallet).filter(AccountConfiguration.isAddress).map { $0.lowercased() })
        guard wallets.count == 1, let wallet = wallets.first else {
            throw APIError(status: 0, reason: "No unique matching Polymarket profile was found. Copy the account wallet address from your Polymarket profile menu instead.")
        }
        return wallet
    }
}
