import SwiftUI

struct HistoryView: View {
    @Environment(NFCManager.self) private var nfcManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        SectionTitle("스캔 기록")
                        Spacer()
                        if !nfcManager.scanHistory.isEmpty {
                            Button("전체 삭제", role: .destructive) {
                                withAnimation {
                                    nfcManager.clearHistory()
                                }
                            }
                            .font(.subheadline)
                            .foregroundStyle(.red)
                        }
                    }
                    .padding(.horizontal)

                    if nfcManager.scanHistory.isEmpty {
                        emptyState
                            .padding(.top, 80)
                    } else {
                        historyContent
                    }
                }
                .padding(.vertical)
            }
            .toolbar(.hidden, for: .navigationBar)
            .background(Color(.systemGroupedBackground))
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("스캔 기록 없음")
                .font(.headline)
            Text("NFC 태그를 스캔하면 여기에 기록이 남습니다.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("태그 스캔하기") {
                nfcManager.startScan()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 4)
        }
    }

    private var historyContent: some View {
        LazyVStack(spacing: 10) {
            ForEach(nfcManager.scanHistory) { record in
                HistoryRow(record: record)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - History Row

struct HistoryRow: View {
    let record: NFCRecord

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: record.type.icon)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.blue)
                .frame(width: 34, height: 34)
                .background(.blue.opacity(0.12), in: .rect(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(record.content)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Text(record.type.label)
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.12), in: .capsule)
                        .foregroundStyle(.blue)

                    Text(record.date.formatted(.relative(presentation: .named)))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Button {
                UIPasteboard.general.string = record.content
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 30, height: 30)
                    .background(Color(.tertiarySystemGroupedBackground), in: .rect(cornerRadius: 7))
            }
            .buttonStyle(.plain)
        }
        .cardStyle()
    }
}

#Preview {
    HistoryView()
        .environment(NFCManager())
}
