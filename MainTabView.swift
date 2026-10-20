import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            CalendarScreen()
                .tabItem { Label("倒班日历", systemImage: "calendar") }
            ReminderScreen()
                .tabItem { Label("闹钟提醒", systemImage: "alarm") }
            StatisticsScreen()
                .tabItem { Label("统计", systemImage: "chart.bar") }
            TeamScreen()
                .tabItem { Label("同事", systemImage: "person.2") }
            SettingsScreen()
                .tabItem { Label("设置", systemImage: "gearshape") }
        }
        .tint(.indigo)
    }
}
