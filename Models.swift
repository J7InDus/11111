import Foundation

enum ShiftKind: String, CaseIterable, Codable, Identifiable {
    case day = "白班"
    case night = "夜班"
    case rest = "休息"
    case other = "其他"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .day: return "sun.max.fill"
        case .night: return "moon.stars.fill"
        case .rest: return "bed.double.fill"
        case .other: return "calendar"
        }
    }

    var colorName: String {
        switch self {
        case .day: return "orange"
        case .night: return "indigo"
        case .rest: return "green"
        case .other: return "gray"
        }
    }
}

struct ShiftEntry: Codable, Identifiable, Equatable {
    var id: String { dayKey }
    var dayKey: String
    var kind: ShiftKind
    var title: String?
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var note: String

    var displayTitle: String { title?.isEmpty == false ? title! : kind.rawValue }

    static func defaultEntry(for date: Date, kind: ShiftKind, settings: ShiftSettings) -> ShiftEntry {
        let times: (Int, Int, Int, Int)
        switch kind {
        case .day: times = (settings.dayStartHour, settings.dayStartMinute, settings.dayEndHour, settings.dayEndMinute)
        case .night: times = (settings.nightStartHour, settings.nightStartMinute, settings.nightEndHour, settings.nightEndMinute)
        case .rest, .other: times = (0, 0, 0, 0)
        }
        return ShiftEntry(dayKey: DateKey.string(from: date), kind: kind, title: nil,
                          startHour: times.0, startMinute: times.1,
                          endHour: times.2, endMinute: times.3, note: "")
    }
}

struct ReminderRule: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var title: String
    var minutesBefore: Int
    var enabled: Bool = true
}

struct ShiftSettings: Codable {
    var pattern: [ShiftKind] = [.day, .night, .rest, .rest]
    var anchorDate: Date = Calendar.current.startOfDay(for: Date())
    var anchorKindIndex: Int = 0
    var dayStartHour = 8
    var dayStartMinute = 0
    var dayEndHour = 20
    var dayEndMinute = 0
    var nightStartHour = 20
    var nightStartMinute = 0
    var nightEndHour = 8
    var nightEndMinute = 0
    var reminders: [ReminderRule] = [
        ReminderRule(title: "起床提醒", minutesBefore: 120),
        ReminderRule(title: "准备提醒", minutesBefore: 60),
        ReminderRule(title: "出门提醒", minutesBefore: 15)
    ]
    var remindOnOtherShift = true
}

struct TeamMember: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var note: String = ""
}

struct BackupPayload: Codable {
    var version = 1
    var settings: ShiftSettings
    var overrides: [String: ShiftEntry]
    var team: [TeamMember]
}

enum DateKey {
    static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func string(from date: Date) -> String { formatter.string(from: date) }
    static func date(from key: String) -> Date? { formatter.date(from: key) }
}
