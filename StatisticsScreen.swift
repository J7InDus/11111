import SwiftUI

struct StatisticsScreen: View {
    @EnvironmentObject private var store: ShiftStore
    @State private var month = Calendar.current.startOfMonth(for: Date())

    private var days: [Date] {
        guard let range = Calendar.current.range(of: .day, in: .month, for: month) else { return [] }
        let first = Calendar.current.startOfMonth(for: month)
        return range.compactMap { Calendar.current.date(byAdding: .day, value: $0 - 1, to: first) }
    }
    private var counts: [ShiftKind: Int] {
        Dictionary(grouping: days, by: { store.entry(for: $0).kind }).mapValues(\.count)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Button { shiftMonth(-1) } label: { Image(systemName: "chevron.left") }
                        Spacer()
                        Text(month.formatted(.dateTime.year().month())).font(.headline)
                        Spacer()
                        Button { shiftMonth(1) } label: { Image(systemName: "chevron.right") }
                    }
                    .buttonStyle(.plain)
                }
                Section("当月统计") {
                    statistic("总天数", value: "\(days.count)", symbol: "calendar")
                    statistic("上班天数", value: "\(days.filter { let k = store.entry(for: $0).kind; return k == .day || k == .night || k == .other }.count)", symbol: "briefcase")
                    statistic("休息天数", value: "\(counts[.rest, default: 0])", symbol: "bed.double")
                    statistic("白班次数", value: "\(counts[.day, default: 0])", symbol: "sun.max")
                    statistic("夜班次数", value: "\(counts[.night, default: 0])", symbol: "moon.stars")
                }
                Section("每天班次") {
                    ForEach(days, id: \.self) { date in
                        HStack {
                            Text(date.formatted(.dateTime.month().day().weekday(.abbreviated)))
                            Spacer()
                            Text(store.entry(for: date).displayTitle)
                                .foregroundStyle(store.entry(for: date).kind == .rest ? .green : .primary)
                        }
                    }
                }
            }
            .navigationTitle("排班统计")
        }
    }

    private func statistic(_ title: String, value: String, symbol: String) -> some View {
        HStack {
            Label(title, systemImage: symbol)
            Spacer()
            Text(value).font(.headline)
        }
    }
    private func shiftMonth(_ amount: Int) {
        if let next = Calendar.current.date(byAdding: .month, value: amount, to: month) { month = next }
    }
}
