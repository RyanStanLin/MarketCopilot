import MarketCore

struct AlertNotificationAccess: Equatable {
    var permission: AlertPermission = .unknown
    var timeSensitive: TimeSensitive = .unknown

    enum TimeSensitive: Equatable {
        case unknown, enabled, disabled, notSupported, requiresSigning

        var title: String {
            let key = switch self {
            case .unknown: "Checking Time Sensitive access…"
            case .enabled: "Time Sensitive: allowed by macOS"
            case .disabled: "Time Sensitive: disabled in System Settings"
            case .notSupported: "Time Sensitive: unavailable on this system"
            case .requiresSigning: "Time Sensitive: requires developer signing"
            }
            return L10n.text(key)
        }
    }
}
