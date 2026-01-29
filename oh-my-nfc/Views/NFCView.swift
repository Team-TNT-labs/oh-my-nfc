import SwiftUI

struct NFCView: View {
    @Environment(NFCManager.self) private var nfcManager
    @Environment(SavedTagStore.self) private var savedTagStore
    @State private var writeText = ""
    @State private var selectedType: WriteType = .text
    @State private var savedRecordID: UUID?
    @FocusState private var isFocused: Bool

    enum WriteType: String, CaseIterable {
        case text = "텍스트"
        case url = "URL"

        var icon: String {
            switch self {
            case .text: "doc.text"
            case .url: "link"
            }
        }

        var placeholder: String {
            switch self {
            case .text: "태그에 쓸 텍스트를 입력하세요"
            case .url: "https://example.com"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // MARK: - Read
                    readSection

                    // MARK: - Write
                    writeSection
                }
                .padding()
            }
            .toolbar(.hidden, for: .navigationBar)
            .background(Color(.systemGroupedBackground))
            .onTapGesture {
                isFocused = false
            }
        }
    }

    // MARK: - Read Section

    private var readSection: some View {
        VStack(spacing: 16) {
            SectionTitle("읽기")

            Button {
                nfcManager.startScan()
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(.blue.gradient)
                            .frame(width: 52, height: 52)

                        Image(systemName: "wave.3.right")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(.white)
                            .symbolEffect(.variableColor.iterative, isActive: nfcManager.isScanning)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(nfcManager.isScanning ? "스캔 중..." : "태그 스캔하기")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("iPhone 상단을 NFC 태그에 가까이 대세요")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding()
                .background(.regularMaterial, in: .rect(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .disabled(nfcManager.isScanning)

            statusMessages

            if !nfcManager.scannedRecords.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("스캔 결과")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    ForEach(nfcManager.scannedRecords) { record in
                        RecordCard(record: record) {
                            let tag = SavedTag(from: record)
                            savedTagStore.add(tag)
                            withAnimation(.snappy) {
                                savedRecordID = record.id
                            }
                        }
                        .overlay(alignment: .topTrailing) {
                            if savedRecordID == record.id {
                                Text("저장됨")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(.green, in: .capsule)
                                    .padding(8)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Write Section

    private var writeSection: some View {
        VStack(spacing: 16) {
            SectionTitle("쓰기")

            // Type selector
            HStack(spacing: 12) {
                ForEach(WriteType.allCases, id: \.self) { type in
                    Button {
                        withAnimation(.snappy(duration: 0.2)) {
                            selectedType = type
                            writeText = ""
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: type.icon)
                                .font(.subheadline)
                            Text(type.rawValue)
                                .font(.subheadline.weight(.medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedType == type
                                ? AnyShapeStyle(.blue)
                                : AnyShapeStyle(.clear)
                        )
                        .foregroundStyle(selectedType == type ? .white : .primary)
                        .clipShape(.rect(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(.regularMaterial, in: .rect(cornerRadius: 13))

            // Input
            VStack(alignment: .leading, spacing: 8) {
                if selectedType == .text {
                    TextEditor(text: $writeText)
                        .focused($isFocused)
                        .frame(minHeight: 80)
                        .padding(10)
                        .scrollContentBackground(.hidden)
                        .background(.background, in: .rect(cornerRadius: 12))
                        .overlay(alignment: .topLeading) {
                            if writeText.isEmpty {
                                Text(selectedType.placeholder)
                                    .foregroundStyle(.tertiary)
                                    .padding(.leading, 15)
                                    .padding(.top, 18)
                                    .allowsHitTesting(false)
                            }
                        }
                } else {
                    TextField(selectedType.placeholder, text: $writeText)
                        .focused($isFocused)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding()
                        .background(.background, in: .rect(cornerRadius: 12))
                }

                Text("\(writeText.utf8.count) bytes")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            // Write button
            Button {
                isFocused = false
                let textToWrite: String
                if selectedType == .url && !writeText.contains("://") {
                    textToWrite = "https://\(writeText)"
                } else {
                    textToWrite = writeText
                }
                nfcManager.write(text: textToWrite)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.pencil")
                    Text("태그에 쓰기")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(writeText.isEmpty ? .gray : .blue, in: .rect(cornerRadius: 14))
                .foregroundStyle(.white)
                .shadow(color: writeText.isEmpty ? .clear : .blue.opacity(0.3), radius: 10, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(writeText.isEmpty || nfcManager.isScanning)
        }
    }

    // MARK: - Status

    @ViewBuilder
    private var statusMessages: some View {
        if !nfcManager.message.isEmpty {
            Label(nfcManager.message, systemImage: "checkmark.circle.fill")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.green)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.green.opacity(0.1), in: .rect(cornerRadius: 12))
        }

        if !nfcManager.lastError.isEmpty {
            Label(nfcManager.lastError, systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.red.opacity(0.1), in: .rect(cornerRadius: 12))
        }
    }
}

#Preview {
    NFCView()
        .environment(NFCManager())
        .environment(SavedTagStore())
}
