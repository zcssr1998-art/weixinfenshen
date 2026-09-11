import Foundation
import Security

@MainActor
final class KeychainStore: ObservableObject {
    @Published private(set) var token: String = ""
    @Published private(set) var statusText: String = "尚未测试"
    @Published private(set) var statusCode: OSStatus = errSecSuccess
    @Published private(set) var accessGroup: String = "尚未读取"

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
                return
            }

            if let data = dict[kSecValueData as String] as? Data,
               let value = String(data: data, encoding: .utf8) {
                token = value
            } else {
                token = ""
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

        default:
            token = ""
            accessGroup = "读取失败"
            statusText = "读取失败：\(status)"
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
            statusText = "已删除"
        } else {
            statusText = "删除失败：\(status)"
        }
        refresh()
    }
}
