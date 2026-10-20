import SwiftUI
import UserNotifications

struct ReminderScreen: View {
    @EnvironmentObject private var store: ShiftStore
    @State private var authorizationText = "检查中…"

    var body: some View {
        NavigationStack {
            Form {
                Section("提醒状态") {
                    HStack {
                        Label("通知权限", systemImage: "bell.badge")
                        Spacer()
                        Text(authorizationText).foregroundStyle(.secondary)
                    }
                    Button("请求通知权限") {
                        Task {
                            _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                            await updateAuthorization()
                        }
                    }
                    Button("立即重新安排提醒") {
                        NotificationManager.shared.refreshSchedule(store: store)
                    }
                }
                Section("提醒规则") {
                    ForEach($store.settings.reminders) { $rule in
                        VStack(alignment: .leading, spacing: 10) {
                            Toggle(rule.title, isOn: $rule.enabled)
                            HStack {
                                Text("上班前")
                                Picker("提前分钟", selection: $rule.minutesBefore) {
                                    ForEach([5, 10, 15, 30, 45, 60, 90, 120, 180], id: \.self) {
                                        Text($0 >= 60 ? "\($0 / 60)小时\($0 % 60 == 0 ? "" : "\($0 % 60)分钟")" : "\($0)分钟").tag($0)
                                    }
                                }
                                .labelsHidden()
                                .pickerStyle(.menu)
                                Spacer()
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onChange(of: store.settings.reminders) { _ in
                        NotificationManager.shared.refreshSchedule(store: store)
                    }
                }
                Section("提醒说明") {
                    Text("应用会滚动安排未来 21 天的本地通知，并在班次或提醒规则变化后重新安排。请在 iPhone 设置中允许通知和声音。")
                    Text("iOS 本地通知不是系统时钟的强制闹铃；专注模式、静音设置或系统状态可能影响提醒体验。")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("倒班闹钟")
            .task { await updateAuthorization() }
        }
    }

    @MainActor
    private func updateAuthorization() async {
        let status = await UNUserNotificationCenter.current().notificationSettings()
        switch status.authorizationStatus {
        case .authorized, .provisional, .ephemeral: authorizationText = "已允许"
        case .denied: authorizationText = "未允许"
        case .notDetermined: authorizationText = "尚未请求"
        @unknown default: authorizationText = "未知"
        }
    }
}
