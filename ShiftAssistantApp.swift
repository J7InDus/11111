import SwiftUI
import UserNotifications

@main
struct ShiftAssistantApp: App {
    @StateObject private var store = ShiftStore()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(store)
                .task {
                    await NotificationManager.shared.requestPermissionIfNeeded()
                    NotificationManager.shared.refreshSchedule(store: store)
                }
        }
    }
}
