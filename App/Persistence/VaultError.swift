import Foundation
import Security

struct VaultError: LocalizedError {
    let status: OSStatus
    var errorDescription: String? { "Keychain: \(SecCopyErrorMessageString(status, nil) as String? ?? "Access failed")" }
}
