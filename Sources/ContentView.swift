import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var store: LocalAccountStore
    @EnvironmentObject private var keychain: KeychainStore
    @EnvironmentObject private var appGroup: AppGroupDiagnostics
    @EnvironmentObject private var deepLink: DeepLinkStore
    @Environment(\.openURL) private var openURL

    @State private var showResetConfirmation = false

    private var documentsPath: String {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path ?? "Unavailable"
    }

    var body: some View {
        NavigationStack {
            Form {
                identitySection
                accountSection
                sandboxSection
                keychainSection
                deepLinkSection
                appGroupSection
                diagnosticsSection
                boundarySection

                Section {
                    Button("清空当前实例普通数据", role: .destructive) {
                        showResetConfirmation = true
                    }
                }
            }
            .navigationTitle("双开架构 PoC · Phase 2")
            .confirmationDialog("只清空当前这个实例的 UserDefaults 数据？", isPresented: $showResetConfirmation) {
                Button("清空", role: .destructive) {
                    store.resetLocalData()
                }
                Button("取消", role: .cancel) {}
            }
        }
    }

    private var identitySection: some View {
        Section("实例身份") {
            LabeledContent("当前实例", value: InstanceEnvironment.instanceName)
            LabeledContent("Bundle ID", value: InstanceEnvironment.bundleID)
            LabeledContent("安装实例 ID") {
                Text(store.installID)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
            }
            LabeledContent("设备", value: UIDevice.current.model)
            LabeledContent("iOS", value: UIDevice.current.systemVersion)
        }
    }

    private var accountSection: some View {
        Section("独立账号状态（UserDefaults）") {
            TextField("给这个实例输入一个账号名", text: $store.accountName)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            HStack {
                Circle()
                    .frame(width: 10, height: 10)
                    .foregroundStyle(store.isLoggedIn ? .green : .secondary)
                Text(store.isLoggedIn ? "已登录：\(store.accountName)" : "未登录")
                Spacer()
            }

            if store.isLoggedIn {
                Button("退出这个实例") {
                    store.logout()
                }
            } else {
                Button("登录这个实例") {
                    store.login()
                }
                .disabled(store.accountName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private var sandboxSection: some View {
        Section("沙箱隔离") {
            Stepper("本实例计数：\(store.counter)", value: $store.counter)
            TextField("只保存在当前实例里的备注", text: $store.note, axis: .vertical)
                .lineLimit(2...5)

            Text("Phase 1 已由你的真机验证：A=账号甲/计数7，而 B=未登录/计数0。说明 Bundle Identity、UserDefaults 与应用沙箱已经彼此独立。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var keychainSection: some View {
        Section("Keychain 安全存储隔离") {
            HStack {
                Circle()
                    .frame(width: 10, height: 10)
                    .foregroundStyle(keychain.hasToken ? .green : .secondary)
                Text(keychain.statusText)
                    .font(.subheadline)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("安全令牌")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(keychain.token.isEmpty ? "（当前实例为空）" : keychain.token)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
            }

            Button(keychain.hasToken ? "覆盖生成本实例令牌" : "生成本实例令牌") {
                keychain.generateOrReplaceToken()
            }

            Button("重新读取 Keychain") {
                keychain.refresh()
            }

            if keychain.hasToken {
                Button("删除本实例 Keychain 令牌", role: .destructive) {
                    keychain.deleteToken()
                }
            }

            Text("A/B 故意使用完全相同的 Keychain service 与 account。分别生成令牌后，如果两个 App 仍只能读到自己的值，就证明签名身份对应的默认 Keychain access group 也已经隔离。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var deepLinkSection: some View {
        Section("URL Scheme / 实例路由") {
            LabeledContent("本实例 Scheme", value: "\(InstanceEnvironment.ownURLScheme)://")
            LabeledContent("目标实例", value: "\(InstanceEnvironment.peerURLScheme)://")

            VStack(alignment: .leading, spacing: 6) {
                Text("最近收到")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(deepLink.lastReceivedURL)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
                if !deepLink.lastReceivedAt.isEmpty {
                    Text(deepLink.lastReceivedAt)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Button("唤起另一个实例") {
                let nonce = UUID().uuidString.prefix(8)
                let urlString = "\(InstanceEnvironment.peerURLScheme)://ping?from=\(InstanceEnvironment.shortName)&nonce=\(nonce)"
                if let url = URL(string: urlString) {
                    openURL(url)
                }
            }

            Text("如果点按钮能直接跳到另一个 App，并在对方『最近收到』里显示 URL，说明两个实例的 URL 路由也能独立配置。这类能力会影响登录回调、支付回调和第三方授权。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var appGroupSection: some View {
        Section("App Group 预检") {
            LabeledContent("期望 Group", value: InstanceEnvironment.appGroupID)

            HStack {
                Circle()
                    .frame(width: 10, height: 10)
                    .foregroundStyle(appGroup.isAvailable ? .green : .orange)
                Text(appGroup.statusText)
                    .font(.subheadline)
            }

            if appGroup.isAvailable {
                VStack(alignment: .leading, spacing: 6) {
                    Text("共享容器")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(appGroup.containerPath)
                        .font(.caption2.monospaced())
                        .textSelection(.enabled)
                }

                Button("写入 App Group 标记") {
                    appGroup.writeMarker()
                }

                if !appGroup.markerText.isEmpty {
                    Text(appGroup.markerText)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                }
            }

            Button("重新检测 App Group") {
                appGroup.refresh()
            }

            Text("这一版只做预检，不强行把 App Group entitlement 塞进自签 IPA。原因是第三方签名所用的 provisioning profile 若没有对应权限，强行声明反而可能导致安装失败。后续拿到匹配的开发者签名后再开启。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var diagnosticsSection: some View {
        Section("沙箱诊断") {
            VStack(alignment: .leading, spacing: 8) {
                Text("Documents 路径")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(documentsPath)
                    .font(.caption2.monospaced())
                    .textSelection(.enabled)
            }
        }
    }

    private var boundarySection: some View {
        Section("当前阶段") {
            Text("Phase 2 仍不包含微信代码、不模拟微信协议，也不绕过任何第三方授权。现在验证的是复杂 App 双实例最基础的四层：Bundle Identity、沙箱/UserDefaults、Keychain、URL 路由；同时预检 App Group。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(LocalAccountStore())
        .environmentObject(KeychainStore())
        .environmentObject(AppGroupDiagnostics())
        .environmentObject(DeepLinkStore())
}
