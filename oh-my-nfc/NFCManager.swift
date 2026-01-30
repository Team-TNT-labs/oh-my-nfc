import CoreNFC
import SwiftUI

@Observable
class NFCManager: NSObject {
    private static let historyKey = "scanHistory"

    var scannedRecords: [NFCRecord] = []
    var scanHistory: [NFCRecord] = [] {
        didSet { saveHistory() }
    }
    var isScanning = false
    var message = ""
    var lastError = ""

    private var session: NFCNDEFReaderSession?
    private var writeMessage: NFCNDEFMessage?
    private var isWriteMode = false

    override init() {
        super.init()
        loadHistory()
    }

    var isAvailable: Bool {
        NFCNDEFReaderSession.readingAvailable
    }

    // MARK: - Read

    func startScan() {
        guard isAvailable else {
            lastError = String(localized: "NFC is not available on this device.")
            return
        }
        isWriteMode = false
        scannedRecords = []
        lastError = ""
        message = ""
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        session?.alertMessage = String(localized: "Hold your iPhone near an NFC tag")
        session?.begin()
        isScanning = true
    }

    // MARK: - Write

    func write(text: String) {
        guard isAvailable else {
            lastError = String(localized: "NFC is not available on this device.")
            return
        }
        isWriteMode = true
        lastError = ""
        message = ""

        let payload: NFCNDEFPayload
        if let url = URL(string: text), url.scheme != nil, url.host != nil {
            payload = NFCNDEFPayload.wellKnownTypeURIPayload(url: url)!
        } else {
            payload = NFCNDEFPayload(
                format: .nfcWellKnown,
                type: "T".data(using: .utf8)!,
                identifier: Data(),
                payload: Self.textPayloadData(text)
            )
        }

        writeMessage = NFCNDEFMessage(records: [payload])
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        session?.alertMessage = String(localized: "Hold your iPhone near an NFC tag to write")
        session?.begin()
        isScanning = true
    }

    func clearHistory() {
        scanHistory.removeAll()
    }

    // MARK: - History Persistence

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(scanHistory) {
            UserDefaults.standard.set(data, forKey: Self.historyKey)
        }
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: Self.historyKey),
              let decoded = try? JSONDecoder().decode([NFCRecord].self, from: data) else { return }
        scanHistory = decoded
    }

    // MARK: - Helpers

    private static func textPayloadData(_ text: String) -> Data {
        let language = "en"
        let langData = language.data(using: .ascii)!
        var payload = Data()
        payload.append(UInt8(langData.count))
        payload.append(langData)
        payload.append(text.data(using: .utf8)!)
        return payload
    }

    private func parseRecord(_ record: NFCNDEFPayload) -> NFCRecord {
        if let url = record.wellKnownTypeURIPayload() {
            return NFCRecord(type: .url, content: url.absoluteString)
        }

        let (text, _) = record.wellKnownTypeTextPayload()
        if let text, !text.isEmpty {
            return NFCRecord(type: .text, content: text)
        }

        if let payload = String(data: record.payload, encoding: .utf8), !payload.isEmpty {
            return NFCRecord(type: .unknown, content: payload)
        }

        return NFCRecord(type: .unknown, content: String(localized: "Unreadable data"))
    }
}

// MARK: - NFCNDEFReaderSessionDelegate

extension NFCManager: NFCNDEFReaderSessionDelegate {
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {}

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
            self.isScanning = false
            if let nfcError = error as? NFCReaderError,
               nfcError.code != .readerSessionInvalidationErrorFirstNDEFTagRead,
               nfcError.code != .readerSessionInvalidationErrorUserCanceled {
                self.lastError = error.localizedDescription
            }
        }
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        let records = messages.flatMap { $0.records }.map { parseRecord($0) }
        DispatchQueue.main.async {
            self.scannedRecords = records
            self.scanHistory.insert(contentsOf: records, at: 0)
            self.message = String(localized: "Read \(records.count) record(s).")
            self.isScanning = false
        }
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [any NFCNDEFTag]) {
        guard let tag = tags.first else {
            session.invalidate(errorMessage: String(localized: "Tag not found."))
            return
        }

        session.connect(to: tag) { error in
            if let error {
                session.invalidate(errorMessage: String(localized: "Connection failed: \(error.localizedDescription)"))
                return
            }

            tag.queryNDEFStatus { status, capacity, error in
                if let error {
                    session.invalidate(errorMessage: String(localized: "Status check failed: \(error.localizedDescription)"))
                    return
                }

                if self.isWriteMode {
                    self.handleWrite(session: session, tag: tag, status: status, capacity: capacity)
                } else {
                    self.handleRead(session: session, tag: tag, status: status)
                }
            }
        }
    }

    private func handleRead(session: NFCNDEFReaderSession, tag: NFCNDEFTag, status: NFCNDEFStatus) {
        switch status {
        case .notSupported:
            session.invalidate(errorMessage: String(localized: "This tag does not support NDEF."))
        case .readOnly, .readWrite:
            tag.readNDEF { message, error in
                if let error {
                    session.invalidate(errorMessage: String(localized: "Read failed: \(error.localizedDescription)"))
                    return
                }
                if let message {
                    let records = message.records.map { self.parseRecord($0) }
                    DispatchQueue.main.async {
                        self.scannedRecords = records
                        self.scanHistory.insert(contentsOf: records, at: 0)
                        self.message = String(localized: "Read \(records.count) record(s).")
                    }
                }
                session.invalidate()
            }
        @unknown default:
            session.invalidate(errorMessage: String(localized: "Unknown tag status."))
        }
    }

    private func handleWrite(session: NFCNDEFReaderSession, tag: NFCNDEFTag, status: NFCNDEFStatus, capacity: Int) {
        guard status == .readWrite else {
            session.invalidate(errorMessage: String(localized: "This tag is read-only."))
            return
        }

        guard let writeMessage else {
            session.invalidate(errorMessage: String(localized: "No data to write."))
            return
        }

        let messageLength = writeMessage.length
        guard messageLength <= capacity else {
            session.invalidate(errorMessage: String(localized: "Data too large. (\(messageLength)/\(capacity) bytes)"))
            return
        }

        tag.writeNDEF(writeMessage) { error in
            if let error {
                session.invalidate(errorMessage: String(localized: "Write failed: \(error.localizedDescription)"))
            } else {
                session.alertMessage = String(localized: "Write complete!")
                session.invalidate()
                DispatchQueue.main.async {
                    self.message = String(localized: "Successfully written to NFC tag.")
                    self.isScanning = false
                }
            }
        }
    }
}
