import SwiftUI

struct ReadView: View {
    @Environment(NFCManager.self) private var nfcManager
    @Environment(SavedTagStore.self) private var savedTagStore
    @State private var savedRecordID: UUID?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    scanButton
                    statusSection
                    if !nfcManager.scannedRecords.isEmpty {
                        resultsSection
                    }
                }
                .padding()
            }
            .navigationTitle("NFC 읽기")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground))
        }
    }

    // MARK: - Scan Button

    private var scanButton: some View {
        Button {
            nfcManager.startScan()
        } label: {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(.blue.gradient)
                        .frame(width: 120, height: 120)
                        .shadow(color: .blue.opacity(0.3), radius: 20, y: 10)

                    Image(systemName: "wave.3.right")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(.white)
                        .symbolEffect(.variableColor.iterative, isActive: nfcManager.isScanning)
                }

                Text(nfcManager.isScanning ? "스캔 중..." : "태그 스캔하기")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("iPhone 상단을 NFC 태그에 가까이 대세요")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(.regularMaterial, in: .rect(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .disabled(nfcManager.isScanning)
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

    // MARK: - Results

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("스캔 결과")
                .font(.headline)
                .padding(.horizontal, 4)

            ForEach(nfcManager.scannedRecords) { record in
                RecordCard(record: record) {
                    let tag = SavedTag(from: record)
                    savedTagStore.add(tag)
                    savedRecordID = record.id
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

// MARK: - Record Card

struct RecordCard: View {
    let record: NFCRecord
    var onSave: (() -> Void)?

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: record.type.icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 44, height: 44)
                .background(.blue.opacity(0.1), in: .circle)

            VStack(alignment: .leading, spacing: 4) {
                Text(record.type.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Text(record.content)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(3)
                    .textSelection(.enabled)
            }

            Spacer()

            if let onSave {
                Button {
                    onSave()
                } label: {
                    Image(systemName: "square.and.arrow.down")
                        .font(.title3)
                        .foregroundStyle(.orange)
                }
            }

            if record.type == .url {
                Button {
                    if let url = URL(string: record.content) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Image(systemName: "safari")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding()
        .background(.background, in: .rect(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}

#Preview {
    ReadView()
        .environment(NFCManager())
        .environment(SavedTagStore())
}
