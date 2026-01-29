import Foundation

struct NFCRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    let type: RecordType
    let content: String
    var tagType: String?
    var serialNumber: String?

    enum RecordType: String, Codable {
        case text
        case url
        case unknown

        var label: String {
            switch self {
            case .text: "텍스트"
            case .url: "URL"
            case .unknown: "기타"
            }
        }

        var icon: String {
            switch self {
            case .text: "doc.text"
            case .url: "link"
            case .unknown: "questionmark.circle"
            }
        }
    }

    init(type: RecordType, content: String, tagType: String? = nil, serialNumber: String? = nil) {
        self.id = UUID()
        self.date = Date()
        self.type = type
        self.content = content
        self.tagType = tagType
        self.serialNumber = serialNumber
    }
}
