import SwiftUI

struct WriteView: View {
    @Environment(NFCManager.self) private var nfcManager
    @State private var writeText = ""
    @State private var selectedType: WriteType = .text
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
                VStack(spacing: 24) {
                    SectionTitle("NFC 쓰기")
                    typeSelector
                    inputSection
                    writeButton
                    statusSection
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

    // MARK: - Type Selector

    private var typeSelector: some View {
        HStack(spacing: 12) {
            ForEach(WriteType.allCases, id: \.self) { type in
                Button {
                    withAnimation(.snappy(duration: 0.2)) {
                        selectedType = type
                        writeText = ""
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: type.icon)
                        Text(type.rawValue)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        selectedType == type
                            ? AnyShapeStyle(.blue)
                            : AnyShapeStyle(.clear)
                    )
                    .foregroundStyle(selectedType == type ? .white : .primary)
                    .clipShape(.rect(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(.regularMaterial, in: .rect(cornerRadius: 16))
    }

    // MARK: - Input

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("내용", systemImage: selectedType.icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            if selectedType == .text {
                TextEditor(text: $writeText)
                    .focused($isFocused)
                    .frame(minHeight: 120)
                    .padding(12)
                    .scrollContentBackground(.hidden)
                    .background(.background, in: .rect(cornerRadius: 14))
                    .overlay(alignment: .topLeading) {
                        if writeText.isEmpty {
                            Text(selectedType.placeholder)
                                .foregroundStyle(.tertiary)
                                .padding(.leading, 17)
                                .padding(.top, 20)
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
                    .background(.background, in: .rect(cornerRadius: 14))
            }

            Text("\(writeText.utf8.count) bytes")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .background(.regularMaterial, in: .rect(cornerRadius: 20))
    }

    // MARK: - Write Button

    private var writeButton: some View {
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
            HStack(spacing: 10) {
                Image(systemName: "square.and.pencil")
                    .font(.title3)
                Text("태그에 쓰기")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(writeText.isEmpty ? .gray : .blue, in: .rect(cornerRadius: 16))
            .foregroundStyle(.white)
            .shadow(color: writeText.isEmpty ? .clear : .blue.opacity(0.3), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(writeText.isEmpty || nfcManager.isScanning)
    }

    // MARK: - Status

    @ViewBuilder
    private var statusSection: some View {
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
    WriteView()
        .environment(NFCManager())
}
