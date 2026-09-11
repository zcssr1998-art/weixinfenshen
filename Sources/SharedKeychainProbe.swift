import Foundation
import Security

@MainActor
final class SharedKeychainProbe: ObservableObject {
    @Published private(set) var observedValue: String = "尚未测试"
    @Published private(set) var observedAccessGroup: String = "尚未测试"
    @Published private(set) var statusText: String = "尚未测试"

    func writeMyMarker() {
        let marker = "\(InstanceEnvironment.shortName)-probe-\(UUID().uuidString.prefix(8))"
        guard let data = marker.data(using: .utf8) else { return }

        let lookup: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: InstanceEnvironment.sharedProbeService,
            kSecAttrAccount as String: InstanceEnvironment.sharedProbeAccount
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

        statusText = status == errSecSuccess ? "共享探针写入成功" : "共享探针写入失败：\(status)"
        readProbe()
    }

    func readProbe() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: InstanceEnvironment.sharedProbeService,
            kSecAttrAccount as String: InstanceEnvironment.sharedProbeAccount,
            kSecReturnData as String: true,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess, let dict = item as? [String: Any] else {
            observedValue = status == errSecItemNotFound ? "（没有共享探针）" : "读取失败：\(status)"
            observedAccessGroup = "不可用"
            statusText = status == errSecItemNotFound ? "当前看不到共享探针" : "读取失败：\(status)"
            return
        }

        if let data = dict[kSecValueData as String] as? Data,
           let value = String(data: data, encoding: .utf8) {
            observedValue = value
        } else {
            observedValue = "数据格式异常"
        }

        if let group = dict[kSecAttrAccessGroup as String] as? String, !group.isEmpty {
            observedAccessGroup = group
        } else {
            observedAccessGroup = "系统未返回"
        }

        statusText = "共享探针读取成功"
    }

    func deleteProbe() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: InstanceEnvironment.sharedProbeService,
            kSecAttrAccount as String: InstanceEnvironment.sharedProbeAccount
        ]
        let status = SecItemDelete(query as CFDictionary)
        statusText = (status == errSecSuccess || status == errSecItemNotFound) ? "共享探针已删除" : "删除失败：\(status)"
        readProbe()
    }
}
