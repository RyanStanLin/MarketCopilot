import Foundation

public enum AlertValidationError: Error, LocalizedError, Sendable {
    case invalidTarget, invalidThreshold, invalidWindow, invalidCooldown
    public var errorDescription: String? {
        L10n.text(switch self {
        case .invalidTarget: "Connect the matching account before creating this alert."
        case .invalidThreshold: "Enter a valid threshold. Prediction prices use 0–100 cents; movement and liquidation buffers must be positive."
        case .invalidWindow: "Choose a time window from 1 to 60 minutes."
        case .invalidCooldown: "Choose a cooldown from 1 to 1440 minutes."
        })
    }
}
