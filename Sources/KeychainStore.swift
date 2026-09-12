import CryptoKit
import Foundation
import Security

@MainActor
final class KeychainStore: ObservableObject {
    enum IsolationState {
        case unknown
        case passed
        case failed
    }

    @Published private(set) var token: String = ""
    @Published private(set) var statusText: String = "尚未测试"
    @Published private(set) var statusCode: OSStatus = errSecSuccess
    @Published private(set) var accessGroup: String = "尚未读取"
    @Published private(set) var isolationState: IsolationState = .unknown
    @Published private(set) var isolationCheckText: String = "尚未建立本实例基准"
    @Published private(set) var expectedFingerprintPreview: String = "未建立"
    @Published private(set) var actualFingerprintPreview: String = "尚未读取"

    private let defaults = UserDefaults.standard

    private var expectedFingerprintKey: String {
        "DualChatPoC.keychain.expectedFingerprint.\(InstanceEnvironment.bundleID)"
    }

    init() {
        refresh()
    }

    var hasToken: Bool {
        !token.isEmpty
    }

    func refresh() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: InstanceEnvironment.privateKeychainService,
            kSecAttrAccount as String: InstanceEnvironment.privateKeychainAccount,
            kSecReturnData as String: true,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        statusCode = status

        switch status {
        case errSecSuccess:
            guard let dict = item as? [String: Any] else {
                token = ""
                statusText = "读取成功，但结果格式异常"
                accessGroup = "无法解析"
                evaluateIsolation(actualToken: nil)
                return
            }

            if let data = dict[kSecValueData as String] as? Data,
               let value = String(data: data, encoding: .utf8) {
                token = value
                evaluateIsolation(actualToken: value)
            } else {
                token = ""
                evaluateIsolation(actualToken: nil)
            }

            if let group = dict[kSecAttrAccessGroup as String] as? String, !group.isEmpty {
                accessGroup = group
            } else {
                accessGroup = "系统未返回"
            }

            statusText = "读取成功"

        case errSecItemNotFound:
            token = ""
            accessGroup = "暂无条目；生成令牌后读取"
            statusText = "当前实例尚无 Keychain 令牌"
            evaluateIsolation(actualToken: nil)

        default:
            token = ""
            accessGroup = "读取失败"
            statusText = "读取失败：\(status)"
            isolationState = .unknown
            isolationCheckText = "Keychain 读取失败，无法判断隔离状态"
            actualFingerprintPreview = "读取失败"
            refreshExpectedFingerprintPreview()
        }
    }

    func generateOrReplaceToken() {
        let newToken = "\(InstanceEnvironment.shortName)-\(UUID().uuidString)"
        guard let data = newToken.data(using: .utf8) else { return }

        let lookup: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: InstanceEnvironment.privateKeychainService,
            kSecAttrAccount as String: InstanceEnvironment.privateKeychainAccount
        ]

        let update: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        var status = SecItemUpdate(lookup as CFDictionary, update as CFDictionary)

        if status == errSecItemNotFound {
            var add = lookup
            add[kSecValueData as String] = data
            add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            status = SecItemAdd(add as CFDictionary, nil)
        }

        statusCode = status
        statusText = status == errSecSuccess ? "写入成功" : "写入失败：\(status)"

        if status == errSecSuccess {
            rememberExpectedToken(newToken)
        }

        refresh()
    }

    func deleteToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: InstanceEnvironment.privateKeychainService,
            kSecAttrAccount as String: InstanceEnvironment.privateKeychainAccount
        ]

        let status = SecItemDelete(query as CFDictionary)
        statusCode = status

        if status == errSecSuccess || status == errSecItemNotFound {
            defaults.removeObject(forKey: expectedFingerprintKey)
            statusText = "已删除"
        } else {
            statusText = "删除失败：\(status)"
        }
        refresh()
    }

    private func rememberExpectedToken(_ value: String) {
        defaults.set(fingerprint(for: value), forKey: expectedFingerprintKey)
    }

    private func evaluateIsolation(actualToken: String?) {
        let expected = defaults.string(forKey: expectedFingerprintKey)
        expectedFingerprintPreview = fingerprintPreview(expected)

        guard let actualToken, !actualToken.isEmpty else {
            actualFingerprintPreview = "无令牌"
            if expected == nil {
                isolationState = .unknown
                isolationCheckText = "尚未建立基准：请生成本实例令牌"
            } else {
                isolationState = .failed
                isolationCheckText = "异常：本实例有历史基准，但当前 Keychain 令牌丢失"
            }
            return
        }

        let actual = fingerprint(for: actualToken)
        actualFingerprintPreview = fingerprintPreview(actual)

        guard let expected else {
            isolationState = .unknown
            isolationCheckText = "发现已有令牌但没有本实例基准；请覆盖生成一次建立基准"
            return
        }

        if actual == expected {
            isolationState = .passed
            isolationCheckText = "通过：当前读取结果与本实例保存的基准一致"
        } else {
            isolationState = .failed
            isolationCheckText = "失败：当前读取结果与本实例基准不一致，疑似跨实例串读或持久化异常"
        }
    }

    private func refreshExpectedFingerprintPreview() {
        expectedFingerprintPreview = fingerprintPreview(defaults.string(forKey: expectedFingerprintKey))
    }

    private func fingerprint(for value: String) -> String {
        guard let data = value.data(using: .utf8) else { return "" }
        return SHA256.hash(data: data)
            .map { String(format: "%02x", $0) }
            .joined()
    }

    private func fingerprintPreview(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return "未建立" }
        return String(value.prefix(12))
    }
}
