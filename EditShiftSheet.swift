import SwiftUI

struct EditShiftSheet: View {
    @EnvironmentObject private var store: ShiftStore
    @Environment(\.dismiss) private var dismiss
    let date: Date

    @State private var kind: ShiftKind = .day
    @State private var title = ""
    @State private var startHour = 8
    @State private var startMinute = 0
    @State private var endHour = 20
    @State private var endMinute = 0
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("日期") { Text(date.formatted(date: .complete, time: .omitted)) }
                Section("班次") {
                    Picker("班次类型", selection: $kind) {
                        ForEach(ShiftKind.allCases) { item in Text(item.rawValue).tag(item) }
                    }
                    TextField("自定义名称（可选）", text: $title)
                    TextField("备注", text: $note, axis: .vertical)
                }
                if kind == .day || kind == .night || kind == .other {
                    Section("上班时间") {
                        timePickers(label: "开始", hour: $startHour, minute: $startMinute)
                        timePickers(label: "结束", hour: $endHour, minute: $endMinute)
                    }
                }
                Section {
                    Button("恢复自动排班") {
                        store.resetEntry(for: date)
                        dismiss()
                    }
                    .foregroundStyle(.red)
                }
            }
            .navigationTitle("编辑班次")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let entry = ShiftEntry(dayKey: DateKey.string(from: date), kind: kind,
                                               title: title.isEmpty ? nil : title,
                                               startHour: startHour, startMinute: startMinute,
                                               endHour: endHour, endMinute: endMinute, note: note)
                        store.setEntry(entry, for: date)
                        dismiss()
                    }
                }
            }
            .onAppear {
                let entry = store.entry(for: date)
                kind = entry.kind; title = entry.title ?? ""; startHour = entry.startHour
                startMinute = entry.startMinute; endHour = entry.endHour; endMinute = entry.endMinute; note = entry.note
            }
        }
    }

    private func timePickers(label: String, hour: Binding<Int>, minute: Binding<Int>) -> some View {
        HStack {
            Text(label)
            Spacer()
            Picker("小时", selection: hour) {
                ForEach(0..<24, id: \.self) { Text(String(format: "%02d", $0)).tag($0) }
            }.labelsHidden().pickerStyle(.menu)
            Text(":")
            Picker("分钟", selection: minute) {
                ForEach([0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55], id: \.self) {
                    Text(String(format: "%02d", $0)).tag($0)
                }
            }.labelsHidden().pickerStyle(.menu)
        }
    }
}
