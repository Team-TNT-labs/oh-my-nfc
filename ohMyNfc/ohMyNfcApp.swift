import SwiftUI

@main
struct ohMyNfcApp: App {
    @State private var nfcManager = NFCManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(nfcManager)
        }
    }
}
