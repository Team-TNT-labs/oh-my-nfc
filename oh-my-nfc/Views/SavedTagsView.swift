import SwiftUI

struct SavedTagsView: View {
    @Environment(NFCManager.self) private var nfcManager
    @Environment(SavedTagStore.self) private var store
    @State private var showingAdd = false
    @State private var editingTag: SavedTag?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    SectionTitle("Saved Tags")
                    Spacer()
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                            .foregroundStyle(.blue)
                    }
                }
                .padding(.horizontal)
                .padding(.top)

                if store.tags.isEmpty {
                    Spacer()
                    emptyState
                    Spacer()
                } else {
                    ScrollView {
                        tagListContent
                            .padding(.top, 16)
                            .padding(.bottom)
                    }
                }
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
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No Saved Tags")
                .font(.title3)
            Text("Save frequently used tag data\nand write to NFC instantly.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Create New Tag") {
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
                    var textToWrite = tag.content
                    if tag.type == .url && !textToWrite.contains("://") {
                        textToWrite = "https://\(textToWrite)"
                    }
                    nfcManager.write(text: textToWrite)
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
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: tag.type.icon)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.orange)
                    .frame(width: 40, height: 40)
                    .background(.orange.opacity(0.12), in: .rect(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(tag.name)
                        .font(.body.weight(.semibold))

                    Text(tag.content)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Text(tag.type.label)
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.orange.opacity(0.12), in: .capsule)
                    .foregroundStyle(.orange)
            }

            HStack(spacing: 8) {
                Button {
                    onWrite()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.caption.weight(.bold))
                        Text("Write")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(.blue.gradient, in: .rect(cornerRadius: 10))
                    .foregroundStyle(.white)
                }
                .buttonStyle(.plain)

                Button {
                    onEdit()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "pencil")
                            .font(.caption.weight(.bold))
                        Text("Edit")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(.tertiarySystemGroupedBackground), in: .rect(cornerRadius: 10))
                    .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)

                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.subheadline.weight(.semibold))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(.red.opacity(0.1), in: .rect(cornerRadius: 10))
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .cardStyle()
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
                Section("Name") {
                    TextField("Tag Name", text: $name)
                }

                Section("Type") {
                    Picker("Type", selection: $type) {
                        Text("Text").tag(NFCRecord.RecordType.text)
                        Text("URL").tag(NFCRecord.RecordType.url)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Content") {
                    if type == .url {
                        TextField("", text: $content)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    } else {
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $content)
                                .frame(minHeight: 80)
                            if content.isEmpty {
                                Text("Enter text to save to tag")
                                    .foregroundStyle(.gray.opacity(0.5))
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? String(localized: "Edit Tag") : String(localized: "New Tag"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
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
