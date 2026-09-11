import SwiftUI

@main
struct DualChatPoCApp: App {
    @StateObject private var store = LocalAccountStore()
    @StateObject private var keychain = KeychainStore()
    @StateObject private var appGroup = AppGroupDiagnostics()
    @StateObject private var deepLink = DeepLinkStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(keychain)
                .environmentObject(appGroup)
                .environmentObject(deepLink)
                .onOpenURL { url in
                    deepLink.handle(url)
                }
        }
    }
}
