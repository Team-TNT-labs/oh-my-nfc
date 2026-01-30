import SwiftUI

struct ReadView: View {
    @Environment(NFCManager.self) private var nfcManager
    @Environment(SavedTagStore.self) private var savedTagStore
    @State private var savedRecordID: UUID?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    SectionTitle("NFC Read")
                    scanButton
                    statusSection
                    if !nfcManager.scannedRecords.isEmpty {
                        resultsSection
                    }
                }
                .padding()
            }
            .toolbar(.hidden, for: .navigationBar)
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

                Text(nfcManager.isScanning ? String(localized: "Scanning...") : String(localized: "Scan Tag"))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("Hold the top of your iPhone near an NFC tag")
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
            Text("Scan Results")
                .font(.title3.weight(.semibold))
                .padding(.horizontal, 4)

            ForEach(nfcManager.scannedRecords) { record in
                RecordCard(record: record) {
                    let tag = SavedTag(from: record)
                    savedTagStore.add(tag)
                    savedRecordID = record.id
                }
                .overlay(alignment: .topTrailing) {
                    if savedRecordID == record.id {
                        Text("Saved")
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
                .font(.title2.weight(.medium))
                .foregroundStyle(.blue)
                .frame(width: 46, height: 46)
                .background(.blue.opacity(0.12), in: .rect(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 3) {
                Text(record.type.label)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Text(record.content)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(3)
                    .textSelection(.enabled)
            }

            Spacer(minLength: 4)

            HStack(spacing: 10) {
                if let onSave {
                    Button {
                        onSave()
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.orange)
                            .frame(width: 36, height: 36)
                            .background(.orange.opacity(0.12), in: .rect(cornerRadius: 8))
                    }
                }

                if record.type == .url {
                    Button {
                        if let url = URL(string: record.content) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Image(systemName: "safari")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.blue)
                            .frame(width: 36, height: 36)
                            .background(.blue.opacity(0.12), in: .rect(cornerRadius: 8))
                    }
                }
            }
        }
        .cardStyle()
    }
}

#Preview {
    ReadView()
        .environment(NFCManager())
        .environment(SavedTagStore())
}
