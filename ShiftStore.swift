import Foundation
import SwiftUI

@MainActor
final class ShiftStore: ObservableObject {
    @Published var settings: ShiftSettings { didSet { save() } }
    @Published var overrides: [String: ShiftEntry] { didSet { save() } }
    @Published var team: [TeamMember] { didSet { save() } }

    private let settingsKey = "shift.settings.v2"
    private let overridesKey = "shift.overrides.v2"
    private let teamKey = "shift.team.v2"

    init() {
        let d = UserDefaults.standard
        if let data = d.data(forKey: settingsKey),
           let value = try? JSONDecoder().decode(ShiftSettings.self, from: data) {
            settings = value
        } else {
            settings = ShiftSettings()
        }
        if let data = d.data(forKey: overridesKey),
           let value = try? JSONDecoder().decode([String: ShiftEntry].self, from: data) {
            overrides = value
        } else { overrides = [:] }
        if let data = d.data(forKey: teamKey),
           let value = try? JSONDecoder().decode([TeamMember].self, from: data) {
            team = value
        } else { team = [] }
    }

    private func save() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(settings) { UserDefaults.standard.set(data, forKey: settingsKey) }
        if let data = try? encoder.encode(overrides) { UserDefaults.standard.set(data, forKey: overridesKey) }
        if let data = try? encoder.encode(team) { UserDefaults.standard.set(data, forKey: teamKey) }
    }

    func entry(for date: Date) -> ShiftEntry {
        let key = DateKey.string(from: date)
        if let custom = overrides[key] { return custom }
        let pattern = settings.pattern.isEmpty ? [.day, .night, .rest, .rest] : settings.pattern
        let anchor = Calendar.current.startOfDay(for: settings.anchorDate)
        let target = Calendar.current.startOfDay(for: date)
        let delta = Calendar.current.dateComponents([.day], from: anchor, to: target).day ?? 0
        let index = ((settings.anchorKindIndex + delta) % pattern.count + pattern.count) % pattern.count
        return ShiftEntry.defaultEntry(for: date, kind: pattern[index], settings: settings)
    }

    func setEntry(_ entry: ShiftEntry, for date: Date) {
        var copy = entry
        copy.dayKey = DateKey.string(from: date)
        overrides[copy.dayKey] = copy
        NotificationManager.shared.refreshSchedule(store: self)
    }

    func resetEntry(for date: Date) {
        overrides.removeValue(forKey: DateKey.string(from: date))
        NotificationManager.shared.refreshSchedule(store: self)
    }

    func setPattern(_ pattern: [ShiftKind]) {
        settings.pattern = pattern.isEmpty ? [.day, .night, .rest, .rest] : pattern
        settings.anchorKindIndex = 0
        overrides = overrides.filter { _, value in value.note.contains("[保留]") }
        NotificationManager.shared.refreshSchedule(store: self)
    }

    func payload() -> BackupPayload {
        BackupPayload(settings: settings, overrides: overrides, team: team)
    }

    func restore(_ payload: BackupPayload) {
        settings = payload.settings
        overrides = payload.overrides
        team = payload.team
        NotificationManager.shared.refreshSchedule(store: self)
    }
}
