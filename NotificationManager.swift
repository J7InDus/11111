import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    func requestPermissionIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    @MainActor
    func refreshSchedule(store: ShiftStore) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let enabledRules = store.settings.reminders.filter(\.enabled)
        guard !enabledRules.isEmpty else { return }

        // Schedule a rolling 21-day window. iOS local notifications have a finite pending-request limit.
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        for offset in 0..<21 {
            guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            let entry = store.entry(for: date)
            guard entry.kind == .day || entry.kind == .night || (entry.kind == .other && store.settings.remindOnOtherShift) else { continue }

            let shiftStart = calendar.date(bySettingHour: entry.startHour, minute: entry.startMinute, second: 0, of: date) ?? date
            for rule in enabledRules {
                guard let fireDate = calendar.date(byAdding: .minute, value: -rule.minutesBefore, to: shiftStart),
                      fireDate > Date() else { continue }
                let content = UNMutableNotificationContent()
                content.title = "\(rule.title) · \(entry.displayTitle)"
                content.body = "\(DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)) 上班时间 \(String(format: "%02d:%02d", entry.startHour, entry.startMinute))。"
                content.sound = .default
                let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let request = UNNotificationRequest(identifier: "\(DateKey.string(from: date))-\(rule.id.uuidString)", content: content, trigger: trigger)
                center.add(request)
            }
        }
    }
}
