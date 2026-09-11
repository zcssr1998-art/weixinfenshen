import Foundation

@MainActor
final class DeepLinkStore: ObservableObject {
    @Published private(set) var lastReceivedURL: String = "尚未收到"
    @Published private(set) var lastReceivedAt: String = ""

    func handle(_ url: URL) {
        lastReceivedURL = url.absoluteString
        lastReceivedAt = ISO8601DateFormatter().string(from: Date())
    }
}
