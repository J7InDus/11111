import SwiftUI
import UniformTypeIdentifiers

struct SettingsScreen: View {
    @EnvironmentObject private var store: ShiftStore
    @State private var anchorDate = Date()
    @State private var patternSelection = "白班、夜班、休息、休息"
    @State private var showImporter = false
    @State private var exportURL: URL?
    @State private var errorMessage: String?
    @State private var showError = false

    private let patterns: [String: [ShiftKind]] = [
        "上一休一": [.day, .rest],
        "上二休二": [.day, .day, .rest, .rest],
        "白班、夜班、休息、休息": [.day, .night, .rest, .rest],
        "白班、白班、夜班、夜班、休息、休息": [.day, .day, .night, .night, .rest, .rest],
        "四班三运转（示例循环）": [.day, .day, .night, .night, .rest, .rest, .rest]
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("自动排班") {
                    Picker("排班模式", selection: $patternSelection) {
                        ForEach(Array(patterns.keys).sorted(), id: \.self) { Text($0).tag($0) }
                    }
                    DatePicker("已知班次的起始日期", selection: $anchorDate, displayedComponents: .date)
                    Text("起始日期会被视为所选循环中的第一个班次。选择一个你确认班次的日期，日历才能准确推算前后排班。")
                        .font(.footnote).foregroundStyle(.secondary)
                    Button("应用排班规则") {
                        store.settings.anchorDate = Calendar.current.startOfDay(for: anchorDate)
                        store.setPattern(patterns[patternSelection] ?? [.day, .night, .rest, .rest])
                    }
                }
                Section("班次时间") {
                    timeRow("白班开始", hour: $store.settings.dayStartHour, minute: $store.settings.dayStartMinute)
                    timeRow("白班结束", hour: $store.settings.dayEndHour, minute: $store.settings.dayEndMinute)
                    timeRow("夜班开始", hour: $store.settings.nightStartHour, minute: $store.settings.nightStartMinute)
                    timeRow("夜班结束", hour: $store.settings.nightEndHour, minute: $store.settings.nightEndMinute)
                    Button("保存时间并更新提醒") {
                        NotificationManager.shared.refreshSchedule(store: store)
                    }
                }
                Section("数据备份") {
                    Button {
                        exportBackup()
                    } label: { Label("导出备份 JSON", systemImage: "square.and.arrow.up") }
                    Button {
                        showImporter = true
                    } label: { Label("导入备份 JSON", systemImage: "square.and.arrow.down") }
                    Text("备份包含排班规则、单日修改、提醒设置和同事名单。建议定期导出保存。")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("应用信息") {
                    LabeledContent("数据存储", value: "本机")
                    LabeledContent("广告 SDK", value: "不集成")
                    LabeledContent("版本", value: "源码原型 1.0")
                }
            }
            .navigationTitle("设置")
            .onAppear {
                anchorDate = store.settings.anchorDate
                if !patterns.values.contains(store.settings.pattern) {
                    patternSelection = "自定义循环"
                } else {
                    patternSelection = patterns.first(where: { $0.value == store.settings.pattern })?.key ?? "白班、夜班、休息、休息"
                }
            }
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json], allowsMultipleSelection: false) { result in
                do {
                    guard let url = try result.get().first else { return }
                    let accessing = url.startAccessingSecurityScopedResource()
                    defer { if accessing { url.stopAccessingSecurityScopedResource() } }
                    let data = try Data(contentsOf: url)
                    let payload = try JSONDecoder().decode(BackupPayload.self, from: data)
                    store.restore(payload)
                } catch {
                    errorMessage = "导入失败：\(error.localizedDescription)"
                    showError = true
                }
            }
            .alert("提示", isPresented: $showError) {
                Button("好", role: .cancel) {}
            } message: { Text(errorMessage ?? "发生错误") }
            .sheet(item: Binding(
                get: { exportURL.map(ExportFile.init(url:)) },
                set: { exportURL = $0?.url }
            )) { item in
                ShareExportView(url: item.url)
            }
        }
    }

    private func timeRow(_ label: String, hour: Binding<Int>, minute: Binding<Int>) -> some View {
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

    private func exportBackup() {
        do {
            var encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(store.payload())
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("ShiftAssistant-Backup.json")
            try data.write(to: url, options: .atomic)
            exportURL = url
        } catch {
            errorMessage = "导出失败：\(error.localizedDescription)"
            showError = true
        }
    }
}

private struct ExportFile: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

private struct ShareExportView: View {
    let url: URL
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "doc.zipper").font(.system(size: 48))
                Text("备份文件已生成")
                ShareLink(item: url) { Label("分享或保存备份", systemImage: "square.and.arrow.up") }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("导出备份")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private extension JSONEncoder {
    static var pretty: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}
