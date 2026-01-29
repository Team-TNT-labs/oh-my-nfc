import Foundation

@Observable
class SavedTagStore {
    private static let key = "savedTags"

    var tags: [SavedTag] = [] {
        didSet { save() }
    }

    init() {
        load()
    }

    func add(_ tag: SavedTag) {
        tags.insert(tag, at: 0)
    }

    func delete(at offsets: IndexSet) {
        tags.remove(atOffsets: offsets)
    }

    func delete(_ tag: SavedTag) {
        tags.removeAll { $0.id == tag.id }
    }

    func update(_ tag: SavedTag) {
        if let index = tags.firstIndex(where: { $0.id == tag.id }) {
            tags[index] = tag
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(tags) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.key),
              let decoded = try? JSONDecoder().decode([SavedTag].self, from: data) else { return }
        tags = decoded
    }
}
