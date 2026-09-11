# DualChatPoC / 双开架构验证

这是一个最小 iOS 双实例 PoC，用于验证：**同一套 SwiftUI 代码，以两个不同 Bundle ID 安装后，是否能在同一台 iPhone 上形成两个独立 App、两个独立沙箱和两份独立本地状态。**

> 这一版不包含微信代码、不模拟微信协议、不绕过任何第三方授权，也不尝试规避 Apple 或其他应用的安全机制。

## 两个实例

- `DualChatA` → `art.zcssr.dualchat.a` → 桌面显示名 `双开 A`
- `DualChatB` → `art.zcssr.dualchat.b` → 桌面显示名 `双开 B`

两个 Target 共用 `Sources/` 下的同一套代码。

## 真机验证方法

1. 从 GitHub Actions 下载 `DualChatPoC-unsigned-IPA` 构建产物。
2. 使用你自己的合法签名方式分别给 `DualChatA-unsigned.ipa` 与 `DualChatB-unsigned.ipa` 签名并安装。
3. 打开 A：输入 `账号甲`，点击登录，把计数改成 7，写一条备注。
4. 打开 B。
5. 如果 B 仍显示未登录、计数为 0、备注为空，并且 Bundle ID / Documents 路径 / 安装实例 ID 与 A 不同，则第一阶段验证成功。

## 本地构建（macOS）

需要 Xcode 和 XcodeGen：

```bash
brew install xcodegen
xcodegen generate
open DualChatPoC.xcodeproj
```

也可以直接运行 GitHub Actions：`Build DualChat PoC`。

## 当前验证范围

- [x] 同代码生成两个 iOS App Target
- [x] 不同 Bundle ID
- [x] 独立 UserDefaults 状态
- [x] 独立 App Container / Documents 路径
- [x] GitHub Actions Simulator 编译验证
- [x] GitHub Actions unsigned iphoneos 构建
- [x] 自动打包两个 unsigned IPA
- [ ] 真机安装验证
- [ ] Keychain 隔离验证
- [ ] Push / App Groups / Extensions 行为验证
- [ ] 对具体目标应用能力边界进行合法性与兼容性评估

## 为什么先做这一版

真正的双开问题首先要拆成两个层次：

1. **iOS 应用身份与数据隔离**：不同 Bundle ID 是否能形成两个独立实例。
2. **具体第三方应用兼容性**：Keychain、Push、App Groups、Extensions、服务端校验、更新策略等。

这一版只验证第 1 层。先把最基础的工程链路跑通，再决定第 2 层是否值得继续投入。
