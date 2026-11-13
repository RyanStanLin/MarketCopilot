import Foundation

public enum ConfigurationError: LocalizedError, Equatable, Sendable {
    case invalidWallet, invalidSigner, invalidPerpsOwner, incompletePredictionCredentials, incompletePerpsCredentials, invalidRefreshInterval
    public var errorDescription: String? {
        switch self {
        case .invalidWallet: "Enter a valid Polymarket account wallet address (0x followed by 40 hex digits)."
        case .invalidSigner: "Enter a valid signer address. This can differ from the account wallet."
        case .invalidPerpsOwner: "Enter a valid Perps account owner address."
        case .incompletePredictionCredentials: "Prediction access needs the signer address, API key, secret and passphrase together."
        case .incompletePerpsCredentials: "Perps access needs both the proxy address and its secret."
        case .invalidRefreshInterval: "Polling must be 1–300 seconds; reconciliation must be 10–600 seconds."
        }
    }
}
