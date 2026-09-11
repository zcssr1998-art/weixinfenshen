import SwiftUI

@main
struct DualChatPoCApp: App {
    @StateObject private var store = LocalAccountStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
