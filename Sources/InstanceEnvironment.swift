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

    // 两个实例故意使用完全相同的 service/account。
    // 若读取结果仍彼此独立，证明默认 Keychain access group 已由签名身份隔离。
    static let keychainService = "DualChatPoC.SharedService"
    static let keychainAccount = "session-token"
}
