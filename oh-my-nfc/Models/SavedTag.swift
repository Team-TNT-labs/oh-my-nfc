import Foundation

struct SavedTag: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var type: NFCRecord.RecordType
    var content: String
    let createdAt: Date

    init(name: String, type: NFCRecord.RecordType, content: String) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.content = content
        self.createdAt = Date()
    }

    init(from record: NFCRecord, name: String? = nil) {
        self.id = UUID()
        self.name = name ?? record.content.prefix(30).description
        self.type = record.type
        self.content = record.content
        self.createdAt = Date()
    }
}
