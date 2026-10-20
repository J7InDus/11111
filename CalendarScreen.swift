import SwiftUI

struct CalendarScreen: View {
    @EnvironmentObject private var store: ShiftStore
    @State private var month = Calendar.current.startOfMonth(for: Date())
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var editing = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdays = ["日", "一", "二", "三", "四", "五", "六"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Button { moveMonth(-1) } label: { Image(systemName: "chevron.left").padding(8) }
                        Spacer()
                        Text(month.formatted(.dateTime.year().month()))
                            .font(.title2.bold())
                        Spacer()
                        Button { moveMonth(1) } label: { Image(systemName: "chevron.right").padding(8) }
                    }
                    HStack {
                        ForEach(weekdays, id: \.self) { day in
                            Text(day).font(.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity)
                        }
                    }
                    LazyVGrid(columns: columns, spacing: 7) {
                        ForEach(Array(monthCells.enumerated()), id: \.offset) { _, date in
                            if let date {
                                dayCell(date)
                            } else {
                                Color.clear.frame(height: 54)
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label(selectedDate.formatted(date: .complete, time: .omitted), systemImage: "calendar.day.timeline.left")
                                .font(.headline)
                            Spacer()
                            Button("编辑班次") { editing = true }
                                .buttonStyle(.borderedProminent)
                        }
                        let entry = store.entry(for: selectedDate)
                        HStack(spacing: 12) {
                            Image(systemName: entry.kind.symbol)
                                .font(.title2)
                                .frame(width: 48, height: 48)
                                .background(color(for: entry.kind).opacity(0.14), in: RoundedRectangle(cornerRadius: 12))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.displayTitle).font(.title3.bold())
                                if entry.kind == .day || entry.kind == .night || entry.kind == .other {
                                    Text("\(time(entry.startHour, entry.startMinute)) — \(time(entry.endHour, entry.endMinute))\(entry.endHour * 60 + entry.endMinute <= entry.startHour * 60 + entry.startMinute ? "（次日）" : "")")
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("好好休息").foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                        }
                        if !entry.note.isEmpty { Text(entry.note).font(.subheadline).foregroundStyle(.secondary) }
                        Button {
                            selectedDate = Calendar.current.startOfDay(for: Date())
                            month = Calendar.current.startOfMonth(for: Date())
                        } label: {
                            Label("回到今天", systemImage: "location.fill")
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
                    VStack(alignment: .leading, spacing: 8) {
                        Text("班次图例").font(.headline)
                        HStack(spacing: 12) {
                            legend(.day); legend(.night); legend(.rest); legend(.other)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                }
                .padding()
            }
            .navigationTitle("倒班日历")
            .sheet(isPresented: $editing) { EditShiftSheet(date: selectedDate) }
        }
    }

    private var monthCells: [Date?] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: month),
              let first = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) else { return [] }
        let weekday = calendar.component(.weekday, from: first) - 1
        var result = Array<Date?>(repeating: nil, count: weekday)
        for day in range {
            result.append(calendar.date(byAdding: .day, value: day - 1, to: first))
        }
        while result.count % 7 != 0 { result.append(nil) }
        return result
    }

    private func dayCell(_ date: Date) -> some View {
        let entry = store.entry(for: date)
        let selected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
        let today = Calendar.current.isDateInToday(date)
        return Button { selectedDate = date } label: {
            VStack(spacing: 4) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.subheadline.weight(selected ? .bold : .regular))
                Circle().fill(color(for: entry.kind)).frame(width: 6, height: 6)
                Text(entry.kind == .day ? "白" : entry.kind == .night ? "夜" : entry.kind == .rest ? "休" : "其他")
                    .font(.system(size: 9))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(selected ? Color.indigo.opacity(0.16) : (today ? Color.secondary.opacity(0.08) : .clear),
                        in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(selected ? Color.indigo : .clear, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
    }

    private func legend(_ kind: ShiftKind) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color(for: kind)).frame(width: 8, height: 8)
            Text(kind.rawValue).font(.caption)
        }
    }

    private func color(for kind: ShiftKind) -> Color {
        switch kind {
        case .day: return .orange
        case .night: return .indigo
        case .rest: return .green
        case .other: return .gray
        }
    }

    private func moveMonth(_ amount: Int) {
        if let next = Calendar.current.date(byAdding: .month, value: amount, to: month) { month = next }
    }
    private func time(_ h: Int, _ m: Int) -> String { String(format: "%02d:%02d", h, m) }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let c = dateComponents([.year, .month], from: date)
        return self.date(from: c) ?? date
    }
}
