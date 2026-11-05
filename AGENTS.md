# SwiftUtils AGENTS.md

给 agent 的操作说明。只写验证过的事实；与 `TODO.md` 冲突时先问。

## 仓库

- Swift Package，product `SwiftUtils`，唯一库目标 `SwiftUtils`
- 平台：macOS 12 / iOS 17 / watchOS 26（见 `Package.swift` 的 `platforms`）
- 工具链：`swift-tools-version: 6.2`，Swift 5 语言模式
- 依赖：只剩 `swift-log`（`Package.resolved` 必须提交）；已移除 Alamofire，`HttpUtil` 是纯 Foundation 实现

## 目录

- `Sources/SwiftUtils/Utils/`：App 工具类（Http / Keychain / Permission / Notification / Log / Device / App / Clipboard …）
- `Sources/SwiftUtils/Extensions/`：Foundation / SwiftUI 扩展
- `Tests/SwiftUtilsTests/`：XCTest；部分用例通过 `@testable` 访问 internal 类型与查询构造函数

## 命令（本机验证过）

```bash
swift build
swift test
```

受限沙箱里 `swift test` 可能报 module cache 不可写（`/var/folders/...` 被拒）。把缓存和临时目录指到仓库内：

```bash
mkdir -p .build/tmp .build/modulecache
TMPDIR="$PWD/.build/tmp" \
SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/modulecache" \
CLANG_MODULE_CACHE_PATH="$PWD/.build/modulecache" \
swift test --scratch-path .build/scratch --cache-path .build/cache \
  --manifest-cache none --disable-sandbox
```

## 约定

- 回调统一投递到主队列（`HttpUtil` / `PermissionUtil` / `AuthUtil` / `NotificationUtil`）
- 平台能力按三层判断：编译期 `#if`、设备能力、权限状态；watchOS 上不存在的能力返回 `.unavailable`，不要伪装成 `.denied`
- 日期格式化统一用 `Date.timeFormatter(_:)`（`zh_CN` + `Asia/Shanghai`）；新增格式化方法不要绕开它
- 提交信息用中文、主题单行；沿用 `模块: 一句话` 或 `fix: / docs:` 前缀，一次提交只做一件事
- 发布 = 打 `0.0.x` tag（Swift Package 没有版本字段）；打 tag 前先确认

## 已知坑

- `PermissionUtil.request` 会先检查 Info.plist usage description：缺 key 直接返回 `.unavailable`，不会去调系统 API（那会被 TCC 终止）。`.photoLibraryAddOnly` 只认 `NSPhotoLibraryAddUsageDescription`
- macOS 数据保护钥匙串需要宿主带 `keychain-access-groups` / `application-identifier` entitlement；缺了会回退旧文件钥匙串并打错误日志
- 测试进程没有权限 usage description、也没有钥匙串 entitlement：相关用例会跳过，或需要注入 `info` 字典
- `ClipboardUtil.getString` 在 iOS 16+ 会触发系统粘贴授权弹窗，不要放在启动路径
- `LogUtil` 默认走 swift-log 的 stderr handler；宿主不 `LoggingSystem.bootstrap` 时，真机 Release 基本看不到日志
