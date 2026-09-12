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

## Phase 2.1：Keychain + URL Scheme + 签名诊断

### 业务 Keychain

A/B 的业务令牌现在按 Bundle ID 使用不同的 Keychain service：

- A：`DualChatPoC.Private.art.zcssr.dualchat.a`
- B：`DualChatPoC.Private.art.zcssr.dualchat.b`

这样即使第三方自签环境让两个 App 落入同一个可访问 Keychain group，也不会因为相同 service/account 直接覆盖同一条业务记录。

### 共享 Keychain 探针

项目另外保留一套故意相同的 `service/account`，只用于判断签名后的 A/B 是否共享某个 Keychain access group。

验证方式：

1. A 写入 `A-probe-*`。
2. 打开 B，只读取共享探针。
3. 如果 B 能看到 A 的 marker，则说明当前签名配置让两个实例至少共享一个可访问 Keychain group。

这不等同于业务令牌一定会串读；业务令牌已经使用独立命名空间。

### URL Scheme

A/B 分别注册：

- A：`dualchata://`
- B：`dualchatb://`

在任一实例点击“唤起另一个实例”。若能跳转到另一个 App，并在目标实例中显示收到的 URL，则实例路由配置成功。

## Phase 2.2：冷启动隔离自检

这一阶段专门处理此前出现过的现象：**A/B 在当前运行期间看起来各自正常，但彻底关闭后重新打开，B 又读到了 A 的令牌。**

现在每个实例在自己生成业务令牌时，会在本实例独立的 `UserDefaults` 中保存该令牌的 SHA-256 指纹基准。以后每次 App 启动、重新读取 Keychain 时都会自动比对：

- 绿色：当前 Keychain 令牌与本实例历史基准一致。
- 红色：当前读取结果与本实例基准不一致，说明存在跨实例串读、覆盖或其他持久化异常。
- 橙色：还没有建立基准，或旧版本遗留令牌无法直接判断。

只保存指纹，不把 Keychain 明文令牌复制进 UserDefaults。

### 必测回归顺序

1. A 生成本实例令牌并建立基准。
2. 彻底关闭 A。
3. B 生成本实例令牌并建立基准。
4. 彻底关闭 B。
5. 重开 A，确认“冷启动隔离自检”为绿色。
6. 重开 B，确认“冷启动隔离自检”为绿色。
7. 再以 B → A 的顺序重复一次。
8. 同时记录 A/B 的 Bundle ID、业务 Keychain Service、Access Group、基准指纹与当前指纹。

只有以上冷启动顺序通过，才把 Keychain 隔离标记为真机验证完成。

## App Group

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
- [x] Keychain 独立业务命名空间
- [x] 共享 Keychain signing probe
- [x] 冷启动 Keychain 指纹自检
- [x] 独立 URL Scheme / 跨实例唤起测试
- [x] App Group 权限预检
- [x] GitHub Actions Simulator + iphoneos 构建
- [x] 自动打包两个 unsigned IPA
- [ ] Phase 2.2 真机冷启动 A/B 回归验证
- [ ] 正式 App Group entitlement + provisioning 验证
- [ ] Extension 隔离实验
- [ ] Push Notification 身份/Token 行为实验
- [ ] 对具体目标应用能力边界进行合法性与兼容性评估

## 工程原则

先验证 iOS 平台能力，再讨论具体大型 App。否则一旦失败，很难判断问题来自代码、签名、entitlement、extension、服务端校验还是目标 App 自身逻辑。
