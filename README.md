# DualChatPoC / 双开架构验证

这是一个 iOS 双实例 PoC，用于逐层验证：**同一套 SwiftUI 代码，以两个不同 Bundle ID 安装后，是否能在同一台 iPhone 上形成两个独立 App，并保持独立沙箱、普通偏好数据、Keychain 安全数据和 URL 路由。**

> 本项目不包含微信代码、不模拟微信协议、不绕过第三方授权，也不尝试规避 Apple 或其他应用的安全机制。

## 两个实例

- `DualChatA` → `art.zcssr.dualchat.a` → 桌面显示名 `双开 A` → `dualchata://`
- `DualChatB` → `art.zcssr.dualchat.b` → 桌面显示名 `双开 B` → `dualchatb://`

两个 Target 共用 `Sources/` 下的同一套代码。

## Phase 1：已完成真机验证

用户已在同一台 iPhone 上同时安装 A/B：

- A：登录 `账号甲`，计数设为 7。
- B：仍为未登录，计数保持 0。
- 两边 Bundle ID、安装实例 ID 不同。

因此已确认：Bundle Identity、UserDefaults 和 App 沙箱彼此独立。

## Phase 2：Keychain + URL Scheme + App Group 预检

### Keychain

A/B 故意使用**相同的 Keychain service 和 account 名**。分别生成安全令牌：

1. A 生成令牌，记录 `A-...`。
2. B 生成令牌，记录 `B-...`。
3. 在 A/B 分别点击“重新读取 Keychain”。
4. 若各自始终只读到自己的令牌，则默认 Keychain access group 隔离成立。

### URL Scheme

A/B 分别注册：

- A：`dualchata://`
- B：`dualchatb://`

在任一实例点击“唤起另一个实例”。若能跳转到另一个 App，并在目标实例中显示收到的 URL，则实例路由配置成功。

### App Group

当前版本只做预检，不强制加入 `com.apple.security.application-groups` entitlement。第三方自签使用的 provisioning profile 如果没有对应 App Group 权限，强行声明 entitlement 可能导致安装失败。

预期 Group：

- A：`group.art.zcssr.dualchat.a`
- B：`group.art.zcssr.dualchat.b`

待有匹配的开发者签名 / provisioning profile 后再开启并验证宿主 App 与 Extension 的共享容器。

## 构建

GitHub Actions 会自动完成：

- XcodeGen 生成 Xcode 工程
- Simulator 编译 A/B
- iphoneos Release 编译 A/B
- 打包两个 unsigned IPA
- 上传 `DualChatPoC-unsigned-IPA` Artifact

本地 macOS：

```bash
brew install xcodegen
xcodegen generate
open DualChatPoC.xcodeproj
```

## 当前进度

- [x] 同代码生成两个 iOS App Target
- [x] 不同 Bundle ID
- [x] 独立 UserDefaults 状态
- [x] 独立 App Container / Documents 路径
- [x] Phase 1 真机双实例验证
- [x] Keychain 隔离测试代码
- [x] 独立 URL Scheme / 跨实例唤起测试
- [x] App Group 权限预检
- [x] GitHub Actions Simulator + iphoneos 构建
- [x] 自动打包两个 unsigned IPA
- [ ] Phase 2 真机 Keychain / URL Scheme 验证
- [ ] 正式 App Group entitlement + provisioning 验证
- [ ] Extension 隔离实验
- [ ] Push Notification 身份/Token 行为实验
- [ ] 对具体目标应用能力边界进行合法性与兼容性评估

## 工程原则

先验证 iOS 平台能力，再讨论具体大型 App。否则一旦失败，很难判断问题来自代码、签名、entitlement、extension、服务端校验还是目标 App 自身逻辑。
