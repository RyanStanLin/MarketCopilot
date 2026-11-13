import Foundation

public struct AccountSecrets: Codable, Equatable, Sendable {
    public var predictionKey = ""
    public var predictionSecret = ""
    public var predictionPassphrase = ""
    public var perpsProxy = ""
    public var perpsSecret = ""
    public init() {}

    public var prediction: PredictionCredentials? {
        guard !predictionKey.isEmpty, !predictionSecret.isEmpty, !predictionPassphrase.isEmpty else { return nil }
        return PredictionCredentials(apiKey: predictionKey, secret: predictionSecret, passphrase: predictionPassphrase)
    }
    public var perps: PerpsCredentials? {
        guard AccountConfiguration.isAddress(perpsProxy), !perpsSecret.isEmpty else { return nil }
        return PerpsCredentials(proxy: perpsProxy, secret: perpsSecret)
    }

    public func validated(account: AccountConfiguration) throws -> Self {
        var value = self
        value.predictionKey = predictionKey.trimmingCharacters(in: .whitespacesAndNewlines)
        value.predictionSecret = predictionSecret.trimmingCharacters(in: .whitespacesAndNewlines)
        value.predictionPassphrase = predictionPassphrase.trimmingCharacters(in: .whitespacesAndNewlines)
        value.perpsProxy = perpsProxy.trimmingCharacters(in: .whitespacesAndNewlines)
        value.perpsSecret = perpsSecret.trimmingCharacters(in: .whitespacesAndNewlines)
        let predictionParts = [value.predictionKey, value.predictionSecret, value.predictionPassphrase]
        if predictionParts.contains(where: { !$0.isEmpty }),
           predictionParts.contains(where: \.isEmpty) || account.signerAddress.isEmpty {
            throw ConfigurationError.incompletePredictionCredentials
        }
        if !value.perpsProxy.isEmpty || !value.perpsSecret.isEmpty {
            guard value.perps != nil else { throw ConfigurationError.incompletePerpsCredentials }
        }
        return value
    }
}
