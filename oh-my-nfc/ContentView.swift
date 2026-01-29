import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("읽기", systemImage: "sensor.tag.radiowaves.forward") {
                ReadView()
            }
            Tab("쓰기", systemImage: "square.and.pencil") {
                WriteView()
            }
            Tab("저장", systemImage: "tag") {
                SavedTagsView()
            }
            Tab("기록", systemImage: "clock.arrow.circlepath") {
                HistoryView()
            }
        }
        .tint(.blue)
    }
}

#Preview {
    ContentView()
        .environment(NFCManager())
        .environment(SavedTagStore())
}
