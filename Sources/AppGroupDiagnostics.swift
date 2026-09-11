import Foundation

@MainActor
final class AppGroupDiagnostics: ObservableObject {
    @Published private(set) var containerPath: String = ""
    @Published private(set) var markerText: String = ""
    @Published private(set) var statusText: String = "尚未测试"
    @Published private(set) var isAvailable: Bool = false

    init() {
        refresh()
    }

    func refresh() {
        guard let url = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: InstanceEnvironment.appGroupID
        ) else {
            isAvailable = false
            containerPath = ""
            markerText = ""
            statusText = "不可用：当前签名/Provisioning 未授予这个 App Group"
            return
        }

        isAvailable = true
        containerPath = url.path
        let markerURL = url.appendingPathComponent("dualchat-marker.txt")

        if let data = try? Data(contentsOf: markerURL),
           let value = String(data: data, encoding: .utf8) {
            markerText = value
            statusText = "App Group 可用，已读取标记"
        } else {
            markerText = ""
            statusText = "App Group 可用，尚无标记"
        }
    }

    func writeMarker() {
        guard let url = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: InstanceEnvironment.appGroupID
        ) else {
            refresh()
            return
        }

        let formatter = ISO8601DateFormatter()
        let value = "实例 \(InstanceEnvironment.shortName) | \(formatter.string(from: Date())) | \(UUID().uuidString)"
        let markerURL = url.appendingPathComponent("dualchat-marker.txt")

        do {
            try value.data(using: .utf8)?.write(to: markerURL, options: .atomic)
            markerText = value
            statusText = "写入成功"
            isAvailable = true
            containerPath = url.path
        } catch {
            statusText = "写入失败：\(error.localizedDescription)"
        }
    }
}
