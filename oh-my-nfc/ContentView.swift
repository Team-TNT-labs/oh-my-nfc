import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("NFC", systemImage: "sensor.tag.radiowaves.forward") {
                NFCView()
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
