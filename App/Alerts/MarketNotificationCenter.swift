import AppKit
import MarketCore
import UserNotifications

@MainActor
final class MarketNotificationCenter: NSObject, UNUserNotificationCenterDelegate {
    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
    }

    func permission() async -> AlertPermission {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .authorized: return .authorized
        case .provisional: return .provisional
        @unknown default: return .unknown
        }
    }

    func requestPermission() async throws -> AlertPermission {
        _ = try await center.requestAuthorization(options: [.alert, .sound])
        return await permission()
    }

    func deliver(_ event: AlertEvent) async throws {
        guard await permission().allowsNotifications else { throw AlertDeliveryError.permissionDenied }
        let content = UNMutableNotificationContent()
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

    func sendTest() async throws {
        guard await permission().allowsNotifications else { throw AlertDeliveryError.permissionDenied }
        let content = UNMutableNotificationContent()
        content.title = "MarketCopilot"
        content.subtitle = L10n.text("Test notification")
        content.body = L10n.text("Your market alerts will appear here. This is a test, not a market event.")
        content.sound = .default
        try await center.add(UNNotificationRequest(identifier: "market-alert-test", content: content, trigger: nil))
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
