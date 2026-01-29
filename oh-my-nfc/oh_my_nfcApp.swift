import SwiftUI

@main
struct oh_my_nfcApp: App {
    @State private var nfcManager = NFCManager()
    @State private var savedTagStore = SavedTagStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(nfcManager)
                .environment(savedTagStore)
        }
    }
}
