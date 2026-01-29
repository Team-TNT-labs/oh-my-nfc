import SwiftUI

struct NFCView: View {
    @Environment(NFCManager.self) private var nfcManager
    @Environment(SavedTagStore.self) private var savedTagStore
    @Environment(\.colorScheme) private var colorScheme
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
                VStack(spacing: 32) {
                    readSection
                    writeSection
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 24)
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
        VStack(alignment: .leading, spacing: 16) {
            SectionTitle("읽기")

            Button {
                nfcManager.startScan()
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.35, green: 0.55, blue: 1.0),
                                        Color(red: 0.20, green: 0.35, blue: 0.95)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 54, height: 54)

                        Image(systemName: "wave.3.right")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white)
                            .symbolEffect(.variableColor.iterative, isActive: nfcManager.isScanning)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(nfcManager.isScanning ? "스캔 중..." : "태그 스캔하기")
                            .font(.body.weight(.semibold))
                            .fontDesign(.rounded)
                            .foregroundStyle(.primary)
                        Text("iPhone 상단을 NFC 태그에 대세요")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.quaternary)
                }
                .cardStyle()
            }
            .buttonStyle(.plain)
            .disabled(nfcManager.isScanning)

            statusMessages

            if !nfcManager.scannedRecords.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Label("스캔 결과", systemImage: "checkmark.shield")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .padding(.leading, 4)

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
                                    .background(.green.gradient, in: .capsule)
                                    .padding(10)
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
        VStack(alignment: .leading, spacing: 16) {
            SectionTitle("쓰기")

            VStack(spacing: 16) {
                // Type selector
                HStack(spacing: 0) {
                    ForEach(WriteType.allCases, id: \.self) { type in
                        Button {
                            withAnimation(.snappy(duration: 0.25)) {
                                selectedType = type
                                writeText = ""
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: type.icon)
                                    .font(.subheadline.weight(.semibold))
                                Text(type.rawValue)
                                    .font(.body.weight(.medium))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                selectedType == type
                                    ? AnyShapeStyle(.blue.gradient)
                                    : AnyShapeStyle(.clear)
                            )
                            .foregroundStyle(selectedType == type ? .white : .secondary)
                            .clipShape(.rect(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(3)
                .background(
                    Color(.tertiarySystemGroupedBackground),
                    in: .rect(cornerRadius: 11)
                )

                // Input
                VStack(alignment: .trailing, spacing: 6) {
                    if selectedType == .text {
                        TextEditor(text: $writeText)
                            .focused($isFocused)
                            .frame(minHeight: 80)
                            .padding(10)
                            .scrollContentBackground(.hidden)
                            .background(
                                Color(.tertiarySystemGroupedBackground),
                                in: .rect(cornerRadius: 12)
                            )
                            .overlay(alignment: .topLeading) {
                                if writeText.isEmpty {
                                    Text(selectedType.placeholder)
                                        .foregroundStyle(.quaternary)
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
                            .padding(14)
                            .background(
                                Color(.tertiarySystemGroupedBackground),
                                in: .rect(cornerRadius: 12)
                            )
                    }

                    Text("\(writeText.utf8.count) bytes")
                        .font(.caption)
                        .foregroundStyle(.quaternary)
                        .padding(.trailing, 4)
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
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.body.weight(.semibold))
                        Text("태그에 쓰기")
                            .font(.body.weight(.bold))
                            .fontDesign(.rounded)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        writeText.isEmpty
                            ? AnyShapeStyle(Color(.quaternarySystemFill))
                            : AnyShapeStyle(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.35, green: 0.55, blue: 1.0),
                                        Color(red: 0.20, green: 0.35, blue: 0.95)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            ),
                        in: .rect(cornerRadius: 14)
                    )
                    .foregroundStyle(writeText.isEmpty ? AnyShapeStyle(.secondary) : AnyShapeStyle(.white))
                    .shadow(
                        color: writeText.isEmpty ? .clear : .blue.opacity(0.35),
                        radius: 16, y: 6
                    )
                }
                .buttonStyle(.plain)
                .disabled(writeText.isEmpty || nfcManager.isScanning)
            }
            .cardStyle()
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
                .padding(12)
                .background(.green.opacity(0.1), in: .rect(cornerRadius: 12))
        }

        if !nfcManager.lastError.isEmpty {
            Label(nfcManager.lastError, systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(.red.opacity(0.1), in: .rect(cornerRadius: 12))
        }
    }
}

#Preview {
    NFCView()
        .environment(NFCManager())
        .environment(SavedTagStore())
}
