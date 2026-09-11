import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var store: LocalAccountStore
    @State private var showResetConfirmation = false

    private var bundleID: String {
        Bundle.main.bundleIdentifier ?? "unknown.bundle"
    }

    private var instanceName: String {
        bundleID.hasSuffix(".a") ? "A 实例" : "B 实例"
    }

    private var documentsPath: String {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path ?? "Unavailable"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("实例身份") {
                    LabeledContent("当前实例", value: instanceName)
                    LabeledContent("Bundle ID", value: bundleID)
                    LabeledContent("安装实例 ID") {
                        Text(store.installID)
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                    }
                    LabeledContent("设备", value: UIDevice.current.model)
                    LabeledContent("iOS", value: UIDevice.current.systemVersion)
                }

                Section("独立账号状态（PoC）") {
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

                Section("隔离验证") {
                    Stepper("本实例计数：\(store.counter)", value: $store.counter)
                    TextField("只保存在当前实例里的备注", text: $store.note, axis: .vertical)
                        .lineLimit(2...5)

                    Text("测试方法：A 里登录『账号甲』、把计数改成 7；再打开 B。若 B 仍是未登录且计数为 0，说明两个 App 的偏好数据与应用沙箱已经独立。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

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

                Section("边界") {
                    Text("这一版不包含微信代码、不模拟微信协议，也没有绕过任何第三方授权。它只验证：同一套 iOS 代码能否以两个独立 App 身份同时安装，并各自保存独立状态。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button("清空当前实例数据", role: .destructive) {
                        showResetConfirmation = true
                    }
                }
            }
            .navigationTitle("双开架构 PoC")
            .confirmationDialog("只清空当前这个实例？", isPresented: $showResetConfirmation) {
                Button("清空", role: .destructive) {
                    store.resetLocalData()
                }
                Button("取消", role: .cancel) {}
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(LocalAccountStore())
}
