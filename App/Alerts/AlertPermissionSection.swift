import AppKit
import SwiftUI

struct AlertPermissionSection: View {
    let store: AppStore

    var body: some View {
        Section("macOS notifications") {
            Label(store.alertPermission.title, systemImage: store.alertPermission.allowsNotifications ? "bell.badge" : "bell.slash")
            HStack {
                if !store.alertPermission.allowsNotifications {
                    if store.alertPermission == .denied {
                        Button("Open System Settings", action: store.openNotificationSystemSettings)
                    } else {
                        Button("Enable notifications", action: requestPermission)
                    }
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
