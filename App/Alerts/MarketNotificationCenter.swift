import AppKit
import MarketCore
import Security
import UserNotifications

@MainActor
final class MarketNotificationCenter: NSObject, UNUserNotificationCenterDelegate {
    private let center = UNUserNotificationCenter.current()
    private let hasTimeSensitiveEntitlement: Bool

    override init() {
        if let task = SecTaskCreateFromSelf(nil) {
            hasTimeSensitiveEntitlement = SecTaskCopyValueForEntitlement(
                task, "com.apple.developer.usernotifications.time-sensitive" as CFString, nil
            ) as? Bool == true
        } else {
            hasTimeSensitiveEntitlement = false
        }
        super.init()
        center.delegate = self
    }

    func access() async -> AlertNotificationAccess {
        let settings = await center.notificationSettings()
        let permission: AlertPermission = switch settings.authorizationStatus {
        case .notDetermined: .notDetermined
        case .denied: .denied
        case .authorized: .authorized
        case .provisional: .provisional
        @unknown default: .unknown
        }
        let timeSensitive: AlertNotificationAccess.TimeSensitive = switch settings.timeSensitiveSetting {
        case .enabled: .enabled
        case .disabled: .disabled
        case .notSupported: .notSupported
        @unknown default: .unknown
        }
        return AlertNotificationAccess(permission: permission,
                                       timeSensitive: hasTimeSensitiveEntitlement ? timeSensitive : .requiresSigning)
    }

    func requestPermission() async throws -> AlertNotificationAccess {
        _ = try await center.requestAuthorization(options: [.alert, .sound])
        return await access()
    }

    func deliver(_ event: AlertEvent, timeSensitive: Bool) async throws {
        guard await access().permission.allowsNotifications else { throw AlertDeliveryError.permissionDenied }
        let content = UNMutableNotificationContent()
        content.interruptionLevel = timeSensitive && hasTimeSensitiveEntitlement ? .timeSensitive : .active
        content.title = event.rule.target.title
        content.subtitle = event.rule.trigger.title
        content.body = AlertPresentation.message(event)
        if event.rule.playsSound { content.sound = .default }
        content.threadIdentifier = event.rule.target.id
        if let url = event.rule.target.destination { content.userInfo = ["marketURL": url.absoluteString] }
        let request = UNNotificationRequest(identifier: "market-alert-\(event.id)", content: content, trigger: nil)
        try Task.checkCancellation()
        try await center.add(request)
    }

    func sendTest(timeSensitive: Bool) async throws {
        guard await access().permission.allowsNotifications else { throw AlertDeliveryError.permissionDenied }
        let content = UNMutableNotificationContent()
        content.interruptionLevel = timeSensitive && hasTimeSensitiveEntitlement ? .timeSensitive : .active
        content.title = "MarketCopilot"
        content.subtitle = L10n.text("Test notification")
        content.body = L10n.text("Your market alerts will appear here. This is a test, not a market event.")
        content.sound = .default
        try await center.add(UNNotificationRequest(identifier: "market-alert-test-\(UUID())", content: content, trigger: nil))
    }

    func cancel(eventID: UUID) {
        let id = "market-alert-\(eventID)"
        center.removePendingNotificationRequests(withIdentifiers: [id])
        center.removeDeliveredNotifications(withIdentifiers: [id])
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                            withCompletionHandler completionHandler: @escaping () -> Void) {
        let address = response.notification.request.content.userInfo["marketURL"] as? String
        Task { @MainActor in
            if let address, let url = URL(string: address), url.scheme == "https",
               let host = url.host(), host == "polymarket.com" || host.hasSuffix(".polymarket.com") {
                NSWorkspace.shared.open(url)
            }
        }
        completionHandler()
    }
}
