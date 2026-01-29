import SwiftUI

struct SavedTagsView: View {
    @Environment(NFCManager.self) private var nfcManager
    @Environment(SavedTagStore.self) private var store
    @State private var showingAdd = false
    @State private var editingTag: SavedTag?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        SectionTitle("저장된 태그")
                        Spacer()
                        Button {
                            showingAdd = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.horizontal)

                    if store.tags.isEmpty {
                        emptyState
                            .padding(.top, 80)
                    } else {
                        tagListContent
                    }
                }
                .padding(.vertical)
            }
            .toolbar(.hidden, for: .navigationBar)
            .background(Color(.systemGroupedBackground))
            .sheet(isPresented: $showingAdd) {
                SavedTagEditView(mode: .add)
            }
            .sheet(item: $editingTag) { tag in
                SavedTagEditView(mode: .edit(tag))
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tag")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("저장된 태그 없음")
                .font(.headline)
            Text("자주 사용하는 태그 데이터를 저장해두고\n바로 NFC에 쓸 수 있습니다.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("새 태그 만들기") {
                showingAdd = true
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 4)
        }
    }

    private var tagListContent: some View {
        LazyVStack(spacing: 10) {
            ForEach(store.tags) { tag in
                SavedTagRow(tag: tag) {
                    nfcManager.write(text: tag.content)
                } onEdit: {
                    editingTag = tag
                } onDelete: {
                    withAnimation {
                        store.delete(tag)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Row

struct SavedTagRow: View {
    let tag: SavedTag
    let onWrite: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: tag.type.icon)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.orange)
                    .frame(width: 36, height: 36)
                    .background(.orange.opacity(0.1), in: .circle)

                VStack(alignment: .leading, spacing: 2) {
                    Text(tag.name)
                        .font(.subheadline.weight(.semibold))

                    Text(tag.content)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                HStack(spacing: 4) {
                    Text(tag.type.label)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.orange.opacity(0.1), in: .capsule)
                        .foregroundStyle(.orange)
                }
            }

            HStack(spacing: 8) {
                Button {
                    onWrite()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "wave.3.right")
                        Text("쓰기")
                    }
                    .font(.caption.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(.blue, in: .rect(cornerRadius: 8))
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)

                Button {
                    onEdit()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                        Text("편집")
                    }
                    .font(.caption.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(.secondary.opacity(0.15), in: .rect(cornerRadius: 8))
                    .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)

                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.caption.weight(.semibold))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .background(.red.opacity(0.1), in: .rect(cornerRadius: 8))
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(.background, in: .rect(cornerRadius: 14))
        .shadow(color: .black.opacity(0.03), radius: 6, y: 2)
    }
}

// MARK: - Edit / Add Sheet

struct SavedTagEditView: View {
    enum Mode: Identifiable {
        case add
        case edit(SavedTag)

        var id: String {
            switch self {
            case .add: "add"
            case .edit(let tag): tag.id.uuidString
            }
        }
    }

    let mode: Mode
    @Environment(SavedTagStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var content = ""
    @State private var type: NFCRecord.RecordType = .text

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("이름") {
                    TextField("태그 이름", text: $name)
                }

                Section("타입") {
                    Picker("타입", selection: $type) {
                        Text("텍스트").tag(NFCRecord.RecordType.text)
                        Text("URL").tag(NFCRecord.RecordType.url)
                    }
                    .pickerStyle(.segmented)
                }

                Section("내용") {
                    if type == .url {
                        TextField("https://example.com", text: $content)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    } else {
                        TextEditor(text: $content)
                            .frame(minHeight: 80)
                    }
                }
            }
            .navigationTitle(isEditing ? "태그 편집" : "새 태그")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        save()
                        dismiss()
                    }
                    .disabled(name.isEmpty || content.isEmpty)
                }
            }
            .onAppear {
                if case .edit(let tag) = mode {
                    name = tag.name
                    content = tag.content
                    type = tag.type
                }
            }
        }
    }

    private func save() {
        if case .edit(var tag) = mode {
            tag.name = name
            tag.content = content
            tag.type = type
            store.update(tag)
        } else {
            let tag = SavedTag(name: name, type: type, content: content)
            store.add(tag)
        }
    }
}

#Preview {
    SavedTagsView()
        .environment(NFCManager())
        .environment(SavedTagStore())
}
