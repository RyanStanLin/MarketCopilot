import Foundation
import MarketCore

enum AlertDeliveryError: Error, LocalizedError {
    case permissionDenied
    var errorDescription: String? { L10n.text("Enable MarketCopilot notifications in System Settings → Notifications.") }
}
