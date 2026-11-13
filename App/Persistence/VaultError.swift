import Foundation
import Security
import MarketCore

struct VaultError: LocalizedError {
    let status: OSStatus
    var errorDescription: String? { L10n.format("Keychain: %@", SecCopyErrorMessageString(status, nil) as String? ?? L10n.text("Access failed")) }
}
