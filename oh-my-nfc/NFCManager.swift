import CoreNFC
import SwiftUI

@Observable
class NFCManager: NSObject {
    var scannedRecords: [NFCRecord] = []
    var scanHistory: [NFCRecord] = []
    var isScanning = false
    var message = ""
    var lastError = ""

    private var session: NFCNDEFReaderSession?
    private var writeMessage: NFCNDEFMessage?
    private var isWriteMode = false

    var isAvailable: Bool {
        NFCNDEFReaderSession.readingAvailable
    }

    // MARK: - Read

    func startScan() {
        guard isAvailable else {
            lastError = "이 기기에서는 NFC를 사용할 수 없습니다."
            return
        }
        isWriteMode = false
        scannedRecords = []
        lastError = ""
        message = ""
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
        session?.alertMessage = "NFC 태그를 iPhone 상단에 가까이 대세요"
        session?.begin()
        isScanning = true
    }

    // MARK: - Write

    func write(text: String) {
        guard isAvailable else {
            lastError = "이 기기에서는 NFC를 사용할 수 없습니다."
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
        session?.alertMessage = "쓸 NFC 태그를 iPhone 상단에 가까이 대세요"
        session?.begin()
        isScanning = true
    }

    func clearHistory() {
        scanHistory.removeAll()
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

        return NFCRecord(type: .unknown, content: "읽을 수 없는 데이터")
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
            self.message = "\(records.count)개 레코드를 읽었습니다."
            self.isScanning = false
        }
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [any NFCNDEFTag]) {
        guard let tag = tags.first else {
            session.invalidate(errorMessage: "태그를 찾을 수 없습니다.")
            return
        }

        session.connect(to: tag) { error in
            if let error {
                session.invalidate(errorMessage: "연결 실패: \(error.localizedDescription)")
                return
            }

            tag.queryNDEFStatus { status, capacity, error in
                if let error {
                    session.invalidate(errorMessage: "상태 조회 실패: \(error.localizedDescription)")
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
            session.invalidate(errorMessage: "NDEF를 지원하지 않는 태그입니다.")
        case .readOnly, .readWrite:
            tag.readNDEF { message, error in
                if let error {
                    session.invalidate(errorMessage: "읽기 실패: \(error.localizedDescription)")
                    return
                }
                if let message {
                    let records = message.records.map { self.parseRecord($0) }
                    DispatchQueue.main.async {
                        self.scannedRecords = records
                        self.scanHistory.insert(contentsOf: records, at: 0)
                        self.message = "\(records.count)개 레코드를 읽었습니다."
                    }
                }
                session.invalidate()
            }
        @unknown default:
            session.invalidate(errorMessage: "알 수 없는 태그 상태입니다.")
        }
    }

    private func handleWrite(session: NFCNDEFReaderSession, tag: NFCNDEFTag, status: NFCNDEFStatus, capacity: Int) {
        guard status == .readWrite else {
            session.invalidate(errorMessage: "이 태그에는 쓸 수 없습니다. (읽기 전용)")
            return
        }

        guard let writeMessage else {
            session.invalidate(errorMessage: "쓸 데이터가 없습니다.")
            return
        }

        let messageLength = writeMessage.length
        guard messageLength <= capacity else {
            session.invalidate(errorMessage: "데이터가 너무 큽니다. (\(messageLength)/\(capacity) bytes)")
            return
        }

        tag.writeNDEF(writeMessage) { error in
            if let error {
                session.invalidate(errorMessage: "쓰기 실패: \(error.localizedDescription)")
            } else {
                session.alertMessage = "쓰기 완료!"
                session.invalidate()
                DispatchQueue.main.async {
                    self.message = "NFC 태그에 성공적으로 기록했습니다."
                    self.isScanning = false
                }
            }
        }
    }
}
