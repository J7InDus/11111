import SwiftUI

struct TeamScreen: View {
    @EnvironmentObject private var store: ShiftStore
    @State private var name = ""
    @State private var note = ""

    var body: some View {
        NavigationStack {
            List {
                Section("添加同事") {
                    TextField("姓名或称呼", text: $name)
                    TextField("备注（车组、岗位等）", text: $note)
                    Button("添加") {
                        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                        store.team.append(TeamMember(name: name.trimmingCharacters(in: .whitespacesAndNewlines), note: note))
                        name = ""; note = ""
                    }
                }
                Section("本机保存的名单") {
                    if store.team.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "person.2").font(.largeTitle).foregroundStyle(.secondary)
                            Text("暂无同事").font(.headline)
                            Text("添加的名单只保存在本机。").font(.footnote).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                    } else {
                        ForEach(store.team) { member in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(member.name).font(.headline)
                                if !member.note.isEmpty { Text(member.note).font(.subheadline).foregroundStyle(.secondary) }
                            }
                        }
                        .onDelete { indexes in store.team.remove(atOffsets: indexes) }
                    }
                }
                Section {
                    Text("当前是本地名单功能，不包含账号、云同步或同事之间的实时排班共享。")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("同事排班")
            .toolbar { EditButton() }
        }
    }
}
