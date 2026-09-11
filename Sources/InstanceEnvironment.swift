import Foundation

enum InstanceEnvironment {
    static var bundleID: String {
        Bundle.main.bundleIdentifier ?? "unknown.bundle"
    }

    static var isA: Bool {
        bundleID.hasSuffix(".a")
    }

    static var instanceName: String {
        isA ? "A 实例" : "B 实例"
    }

    static var shortName: String {
        isA ? "A" : "B"
    }

    static var appGroupID: String {
        isA ? "group.art.zcssr.dualchat.a" : "group.art.zcssr.dualchat.b"
    }

    static var ownURLScheme: String {
        isA ? "dualchata" : "dualchatb"
    }

    static var peerURLScheme: String {
        isA ? "dualchatb" : "dualchata"
    }

    // Phase 2.1：业务层显式按 Bundle ID 隔离 Keychain 命名空间。
    // 即使第三方自签把两个 App 放进同一个可访问 Keychain group，
    // A/B 也不会再因为 service/account 相同而覆盖同一条记录。
    static var privateKeychainService: String {
        "DualChatPoC.Private.\(bundleID)"
    }

    static let privateKeychainAccount = "session-token"

    // 保留一个共享探针名称，仅用于诊断签名是否让 A/B 共享默认 Keychain group。
    static let sharedProbeService = "DualChatPoC.SharedProbe"
    static let sharedProbeAccount = "shared-probe"
}
