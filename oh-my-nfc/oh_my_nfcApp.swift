import SwiftUI

@main
struct oh_my_nfcApp: App {
    @State private var nfcManager = NFCManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(nfcManager)
        }
    }
}
