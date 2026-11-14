import Foundation

public enum ConfigurationError: LocalizedError, Equatable, Sendable {
    case invalidWallet, invalidProfile, invalidSigner, invalidPerpsOwner, incompletePredictionCredentials, incompletePerpsCredentials, invalidRefreshInterval, invalidCashOffset, invalidLiveColorDuration
    public var errorDescription: String? {
        let message = switch self {
        case .invalidWallet: "Enter a valid Polymarket account wallet address (0x followed by 40 hex digits)."
        case .invalidProfile: "Enter your Polymarket account wallet, @username or polymarket.com profile link."
        case .invalidCashOffset: "Enter a valid positive or negative cash offset."
        case .invalidLiveColorDuration: "Live color duration must be between 0.1 and 10 seconds."
        case .invalidSigner: "Enter a valid signer address. This can differ from the account wallet."
        case .invalidPerpsOwner: "Enter a valid Perps account owner address."
        case .incompletePredictionCredentials: "Prediction access needs the signer address, API key, secret and passphrase together."
        case .incompletePerpsCredentials: "Perps access needs both the proxy address and its secret."
        case .invalidRefreshInterval: "Polling must be 1–300 seconds; reconciliation must be 10–600 seconds."
        }
        return L10n.text(message)
    }
}
