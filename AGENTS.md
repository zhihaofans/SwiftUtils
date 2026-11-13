# SwiftUtils AGENTS.md

给 agent 的操作说明。只写验证过的事实；与 `TODO.md` 冲突时先问。

## 仓库

- Swift Package，product `SwiftUtils`，唯一库目标 `SwiftUtils`
- 平台：macOS 12 / iOS 17 / watchOS 26（见 `Package.swift` 的 `platforms`）
- 工具链：`swift-tools-version: 6.2`，Swift 5 语言模式
- 依赖：**无第三方依赖**。0.0.32 起移除了 `swift-log`，`Package.resolved` 已删除；再加依赖时记得把 `Package.resolved` 一起提交
- `HttpUtil` 是纯 Foundation 实现（已移除 Alamofire）

## 目录

- `Sources/SwiftUtils/Utils/`：App 工具类（Http / Keychain / Permission / Notification / Log / Device / App / Clipboard / File / Async …）
- `Sources/SwiftUtils/Extensions/`：Foundation / SwiftUI 扩展
- `Tests/SwiftUtilsTests/`：XCTest；部分用例通过 `@testable` 访问 internal 类型与查询构造函数
- `Scripts/`：开发期脚本，目前只有 `check-platforms.sh`

## 命令（本机验证过）

```bash
swift build
swift test
./Scripts/check-platforms.sh        # macOS 构建 + iOS / watchOS 交叉编译
./Scripts/check-platforms.sh ios    # 只跑一个平台：macos / ios / watchos
```

**`swift build` / `swift test` 只验 macOS。** iOS / watchOS 必须用脚本里的 `--sdk` + `--triple` 交叉编译，
否则「平台」只存在于 `Package.swift` 里 —— `AuthUtil` 曾经因此一直编不过 watchOS 却没被发现。

受限沙箱里 `swift test` 可能报 module cache 不可写（`/var/folders/...` 被拒）。把缓存和临时目录指到仓库内：

```bash
mkdir -p .build/tmp .build/modulecache
TMPDIR="$PWD/.build/tmp" \
SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/modulecache" \
CLANG_MODULE_CACHE_PATH="$PWD/.build/modulecache" \
swift test --scratch-path .build/scratch --cache-path .build/cache \
  --manifest-cache none --disable-sandbox
```

## 平台矩阵（查过 SDK 头文件 / 交叉编译验证）

新增工具类之前先对照这张表；标的 ✗ 的 API 不能出现在无条件编译的代码里。

| API | macOS 12 | iOS 17 | watchOS 26 | 用法 |
|---|---|---|---|---|
| `PDFKit` | ✓ | ✓ | ✗ 框架不存在 | 必须 `#if os(iOS) \|\| os(macOS)` |
| `AVAssetExportSession` | ✓ | ✓ | ✗ `API_UNAVAILABLE(watchos)` | 同上 |
| `UIGraphicsImageRenderer` / `UIGraphicsPDFRenderer` | ✓ | ✓ | ✗ unavailable | 图片处理走 ImageIO，PDF 走 CoreGraphics |
| `UIImage` / `jpegData` / `pngData` | ✓ | ✓ | ✓ watchOS 2+ | 数据 API 能用，渲染器不能用 |
| `ImageIO`（`CGImageSource` / `CGImageDestination`） | ✓ | ✓ | ✓ | 三平台一套 |
| `AVAudioApplication` | ✗ 需 macOS 14 | ✓ | ✓ | 本包 macOS 12 编不过 |
| `Duration` / `Task.sleep(for:)` | ✗ 需 macOS 13 | ✓ | ✓ | 公开 API 用 `TimeInterval` |
| `OSLogStore` | ✓ 12 | ✓ 15 | ✓ 8 | 日志导出可用 |
| 安全作用域书签（`withSecurityScope`） | ✓ | ✗ | ✗ | 仅 macOS / Catalyst；`startAccessing` 本身三平台有 |
| `LAError.biometryNotAvailable/NotEnrolled/Lockout` | ✓ | ✓ | ✗ unavailable | watchOS 上用 `.deviceOwnerAuthentication` |

## 约定

- 回调统一投递到主队列（`HttpUtil` / `PermissionUtil` / `AuthUtil` / `NotificationUtil`）
- 平台能力按三层判断：编译期 `#if`、设备能力、权限状态；watchOS 上不存在的能力返回 `.unavailable`，不要伪装成 `.denied`
- 日期格式化统一用 `Date.timeFormatter(_:)`（`zh_CN` + `Asia/Shanghai`）；新增格式化方法不要绕开它
- 例外：**相对时间**用 `RelativeTimeFormatter`，它跟用户时区走（「昨天」在旅行时会算错），不要套固定上海时区
- 并发工具优先复用 `ResumeOnceGate`（回调只 resume 一次）与 `withTimeout`；不要再各写一份 `NSLock` gate
- 新增文件、体积、格式化的实现优先包系统 API（`NSFileCoordinator` / `ByteCountFormatStyle` / `RelativeDateTimeFormatter`），不手写单位表和 ICU 逻辑
- 日志统一走 `SU.log` / `LogUtil`，不要直接 `print` 或 `os.Logger`；App 在启动处 `SU.configureLogging(backend: OSLogBackend(subsystem:category:))`，subsystem 与宿主自己的保持同一个
- 新增日志后端实现 `LogBackend` 即可，不要再往 `LogUtil` 里加分发分支
- 新增公开 API 必须有测试；测试只在 macOS 跑，iOS / watchOS 靠 `./Scripts/check-platforms.sh` 编译覆盖
- 提交信息用中文、主题单行；沿用 `模块: 一句话` 或 `fix: / docs:` 前缀，一次提交只做一件事
- 发布 = 打 `0.0.x` tag（Swift Package 没有版本字段）；打 tag 前先确认

## 已知坑

- `PermissionUtil` 的 `check` / `request` 都会先查 Info.plist usage description：缺 key 返回 `.misconfigured`（配置问题），不会去调系统 API（那会被 TCC 终止）；设备没有能力才是 `.unavailable`。`.photoLibraryAddOnly` 只认 `NSPhotoLibraryAddUsageDescription`
- macOS 数据保护钥匙串需要宿主带 `keychain-access-groups` / `application-identifier` entitlement；缺了会回退旧文件钥匙串并打错误日志
- 测试进程没有权限 usage description、也没有钥匙串 entitlement：相关用例会跳过，或需要注入 `info` 字典
- `ClipboardUtil.getString` 在 iOS 16+ 会触发系统粘贴授权弹窗，不要放在启动路径
- `LogUtil` 默认写 stderr；真机 Release 上 stderr 不落盘，App 必须换成 `OSLogBackend` 才能在 Console / 导出里看到日志
- `ByteCountFormatter` **没有** `locale` 属性，测试没法钉住输出；要可测就用 `ByteCountFormatStyle`（`FileSizeFormatter` 已封装）
- `ByteCountFormatStyle` 会把 1500 字节显示成 "2 kB"（kB 档系统取整），这是系统行为，不要为「看起来精确」回去手写单位表
- 写图片时改方向：顶层 `Orientation`、`{Exif}.Orientation`、`{TIFF}.Orientation` 要一起改成 1，并清掉 `{Exif}` 里的旧 `PixelXDimension` / `PixelYDimension`。只改顶层的话，查看器看着正常，但事后用 `CGImageSourceCreateThumbnailAtIndex` 取缩略图会转 90°（`ImageUtil.normalizedProperties` 已处理）
- `AVAssetExportSession` 在目标文件已存在时直接失败，导出前必须先删；`exportAsynchronously` 无论成败都会回调，必须再看 `status`
- `MediaUtil.info` 对损坏文件会抛底层 `AVError`，不会返回 0 秒空视频——别在调用处 `try?` 吞掉
- `OSLogBackend` 的 `privacy:` 参数只接受字面量 `.public` / `.private`，不能传变量（编译器报 "must be a static method or property"），所以实现里是 if/else 两条路径
- `OSLogBackend` 默认 `.private`：在 Console / 导出里显示 `<private>`。路径、Token 不该默认公开，需要可读的字段显式 `isPublic: true` 或单独构造消息
- `LogExporter` 只能读当前进程的日志（`scope: .currentProcessIdentifier`），且导出内容遵循写入时的隐私标记
- `ConsoleBackend` 写的是 **stderr**，不是 stdout；日志测试里别去截 stdout
- `configureLogger(label:logLevel:)` 是旧名兼容层：传了 `label` 会**切回** `ConsoleBackend`，要 OSLog 请用 `configureLogging(backend:)`
- `withTimeout` 超时后只能**请求**取消：卡在非协作系统调用里的任务会继续跑到结束，结果被丢弃
- `TemporaryDirectory` 是引用类型，最后一个强引用释放时 `deinit` 删除目录；想提前删调 `remove()`，别指望把它存进模型里长期持有
