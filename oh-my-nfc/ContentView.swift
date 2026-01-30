import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("NFC", systemImage: "sensor.tag.radiowaves.forward") {
                NFCView()
            }
            Tab("Saved", systemImage: "tag") {
                SavedTagsView()
            }
            Tab("History", systemImage: "clock.arrow.circlepath") {
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
