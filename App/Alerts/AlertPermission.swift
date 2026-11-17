import MarketCore

enum AlertPermission: Equatable {
    case unknown, notDetermined, denied, authorized, provisional
    var allowsNotifications: Bool { self == .authorized || self == .provisional }
    var title: String {
        let key = switch self {
        case .unknown: "Checking notification access…"
        case .notDetermined: "Notifications are not enabled"
        case .denied: "Notifications are disabled in System Settings"
        case .authorized: "Notifications are allowed"
        case .provisional: "Notifications are delivered quietly"
        }
        return L10n.text(key)
    }
}
