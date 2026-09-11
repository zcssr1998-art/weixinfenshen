import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var store: LocalAccountStore
    @EnvironmentObject private var keychain: KeychainStore
    @EnvironmentObject private var sharedProbe: SharedKeychainProbe
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
                signingProbeSection
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
            .navigationTitle("双开架构 PoC · Phase 2.1")
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
                Button("退出这个实例") { store.logout() }
            } else {
                Button("登录这个实例") { store.login() }
                    .disabled(store.accountName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private var sandboxSection: some View {
        Section("沙箱隔离") {
            Stepper("本实例计数：\(store.counter)", value: $store.counter)
            TextField("只保存在当前实例里的备注", text: $store.note, axis: .vertical)
                .lineLimit(2...5)

            Text("Phase 1 已真机验证：A/B 的 Bundle Identity、UserDefaults 与应用沙箱彼此独立。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var keychainSection: some View {
        Section("Keychain · 业务层隔离") {
            HStack {
                Circle()
                    .frame(width: 10, height: 10)
                    .foregroundStyle(keychain.hasToken ? .green : .secondary)
                Text(keychain.statusText)
                    .font(.subheadline)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("本实例 Keychain Service")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(InstanceEnvironment.privateKeychainService)
                    .font(.caption2.monospaced())
                    .textSelection(.enabled)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("安全令牌")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(keychain.token.isEmpty ? "（当前实例为空）" : keychain.token)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("该条目实际 Access Group")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(keychain.accessGroup)
                    .font(.caption2.monospaced())
                    .textSelection(.enabled)
            }

            Button(keychain.hasToken ? "覆盖生成本实例令牌" : "生成本实例令牌") {
                keychain.generateOrReplaceToken()
            }

            Button("重新读取本实例 Keychain") {
                keychain.refresh()
            }

            if keychain.hasToken {
                Button("删除本实例 Keychain 令牌", role: .destructive) {
                    keychain.deleteToken()
                }
            }

            Text("Phase 2.1 不再故意共用同一个 service。A/B 现在按 Bundle ID 使用不同 Keychain 命名空间，因此即使第三方自签让两个 App 共享某个 access group，也不应再互相覆盖这条业务令牌。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var signingProbeSection: some View {
        Section("Keychain · 签名层诊断") {
            Text("这一组故意让 A/B 使用完全相同的 service/account，只用于确认你的自签环境是否让两个 App 共享 Keychain 可访问组。")
                .font(.footnote)
                .foregroundStyle(.secondary)

            LabeledContent("状态", value: sharedProbe.statusText)

            VStack(alignment: .leading, spacing: 6) {
                Text("当前读到的共享探针")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(sharedProbe.observedValue)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("共享探针所属 Access Group")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(sharedProbe.observedAccessGroup)
                    .font(.caption2.monospaced())
                    .textSelection(.enabled)
            }

            Button("写入 \(InstanceEnvironment.shortName) 的共享探针") {
                sharedProbe.writeMyMarker()
            }

            Button("只读取共享探针") {
                sharedProbe.readProbe()
            }

            Button("删除共享探针", role: .destructive) {
                sharedProbe.deleteProbe()
            }

            Text("验证：A 写入后，打开 B 只点『读取』。如果 B 能看到 A-probe，说明当前签名确实给了 A/B 至少一个共同可访问的 Keychain group。")
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

                Button("写入 App Group 标记") { appGroup.writeMarker() }

                if !appGroup.markerText.isEmpty {
                    Text(appGroup.markerText)
                        .font(.caption.monospaced())
                        .textSelection(.enabled)
                }
            }

            Button("重新检测 App Group") { appGroup.refresh() }
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
            Text("Phase 2.1 仍只验证我们自己控制的 PoC。重点是区分『业务命名空间隔离』和『签名层 access group 隔离』，避免把第三方自签造成的共享误判成 iOS 双开本身失败。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(LocalAccountStore())
        .environmentObject(KeychainStore())
        .environmentObject(SharedKeychainProbe())
        .environmentObject(AppGroupDiagnostics())
        .environmentObject(DeepLinkStore())
}
