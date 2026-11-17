import AppKit
import SwiftUI

struct AlertPermissionSection: View {
    let store: AppStore

    var body: some View {
        Section("macOS notifications") {
            Label(store.alertPermission.title, systemImage: store.alertPermission.allowsNotifications ? "bell.badge" : "bell.slash")
            Toggle("Time Sensitive notifications", isOn: Binding(
                get: { store.refreshSettings.timeSensitiveNotifications },
                set: store.setTimeSensitiveNotifications
            ))
            if store.refreshSettings.timeSensitiveNotifications {
                Label(store.alertNotificationAccess.timeSensitive.title,
                      systemImage: store.alertNotificationAccess.timeSensitive == .enabled ? "bolt.fill" : "exclamationmark.circle")
                    .font(.caption).foregroundStyle(.secondary)
                if store.alertNotificationAccess.timeSensitive == .requiresSigning {
                    Text("Time Sensitive requires a paid Apple Developer team and provisioning profile. This build uses standard notifications.")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    Text("Allow Time Sensitive notifications for MarketCopilot in System Settings and in your active Focus. macOS still controls banners and sounds.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            HStack {
                if !store.alertPermission.allowsNotifications && store.alertPermission != .denied {
                    Button("Enable notifications", action: requestPermission)
                } else {
                    Button("Open System Settings", action: store.openNotificationSystemSettings)
                }
                Button("Send test notification", action: store.sendTestNotification)
            }.disabled(store.isRequestingAlertPermission)
        }
        .task { await store.refreshAlertPermission() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            Task { await store.refreshAlertPermission() }
        }
    }

    private func requestPermission() { Task { _ = await store.requestAlertPermission() } }
}
