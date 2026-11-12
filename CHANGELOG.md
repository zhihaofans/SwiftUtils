# Changelog

格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循语义化版本。
本仓库用 git tag `0.0.x` 作为版本，`Package.swift` 里没有版本字段。

## [Unreleased]

### 新增

- `ImageUtil`：按 EXIF 方向转正的缩略图、转码（缩放时把方向归一并清掉旧的像素尺寸）、元数据读取与扁平化。走 ImageIO，三个平台同一套 API
- `PDFUtil`：页数、单页渲染（带白底，不会导出透明/黑底）、由图片生成 PDF（iOS / macOS；watchOS 没有 PDFKit）
- `MediaUtil`：音视频信息（时长 / 显示尺寸 / 有无音视频轨）、导出（导出前清理目标文件、检查失败状态）；iOS / macOS
- `AuthUtil.biometryInfo()`：生物识别可用性与类型，与 `authenticate` 共用同一套 `LAContext` 规则
- `FileUtil`：原子写 / 读（可选 `NSFileCoordinator` 协调）、`createDirectoryIfNeeded`、`removeIfExists`、`uniqueURL`（返回建议名）、`createUniqueFile`（内核级判重，并发保存不互相覆盖）、`makeTemporaryDirectory`、异步 `directorySize`
- `TemporaryDirectory`：临时目录句柄，最后一个引用释放时自动删除
- `SecurityScopedAccess`：同步 / 异步安全作用域访问；macOS / Catalyst 额外提供书签读写，供跨启动保留授权
- `FileSizeFormatter`：跟随 locale 的字节格式化（`.file` 1000 进制 / `.memory` 1024 进制），空文件显示 `0 bytes`
- `RelativeTimeFormatter`：本地化相对时间；未来时间不再被误显示成「刚刚」
- `Array.chunked(into:)`：按块切分，`size <= 0` 返回空
- `ResumeOnceGate`：线程安全的「只放行一次」，供 continuation 桥接与成功/超时竞速使用
- `withTimeout`、`AsyncDebouncer`、`RetryPolicy`、`TimeoutError`：超时、防抖、指数退避
- `Scripts/check-platforms.sh`：macOS 构建 + iOS / watchOS 交叉编译

### 修复

- `AuthUtil` 在 watchOS 上**编译不过**：`LAError` 的 `biometryNotAvailable` / `biometryNotEnrolled` / `biometryLockout` 在 watchOS 上是 unavailable，`mapError` 里的 `case` 需要条件编译。此前只跑 macOS 构建，一直没发现

### 其它

- `AGENTS.md` 增加平台矩阵（哪些 API 在 watchOS / macOS 12 不可用）与三平台编译命令
- `NetworkUtil` 的私有 `CallbackGate` 换成公共 `ResumeOnceGate`

## [0.0.29] - 2026-11-05

### 修复

- `PermissionUtil` 的 `.photoLibraryAddOnly` 只要求 `NSPhotoLibraryAddUsageDescription`：此前把读权限的 key 也算数，只配读权限的宿主会被误判为「相册可用」，真正请求时被系统终止
- `String.isUrl` 要求带 scheme（`http`/`https`/`ftp` 还要求 host）：修掉 `"hello"`、`"123"`、`"not a url"` 都被判定成链接的问题
- `NetworkUtil.getNetworkType` 增加 5 秒超时并真正调用 `fail`，`NWPathMonitor` 不回调时不再让调用方无限等待；`is5G`/`is4G`/`is3G`/`is2G` 的回调改为异步，与 `isWifi` 统一
- `Date.pastTimeString` 补齐 `Asia/Shanghai` 时区，与同文件其它格式化方法一致（此前同一时间戳在列表与详情会显示成不同日期）
- `AuthUtil` 每次新建 `LAContext`，新增 `AuthResult` 区分取消 / 失败 / 不可用；修掉验证成功也打「验证失败」error 日志的问题（旧接口行为不变）
- `NotificationUtil` 发送通知的成功 / 失败回调回到主队列
- `QrcodeUtil` macOS 分支补上 `inputCorrectionLevel = H`，与 iOS 输出一致
- `Bundle.appIconName` 改为读取当前 Bundle，而不是固定 `Bundle.main`
- `ShareUtil` macOS 分支对 `NSApp` 判空，避免非 GUI 进程直接崩

### 新增

- `AGENTS.md`：仓库命令、约定与已知坑
- `CHANGELOG.md`：本文件

### 其它

- `TODO.md` 补充权限、剪贴板、日志等已知问题

## [0.0.28] - 2026-10-24

### 新增

- `PermissionUtil`：`PermissionStatus` / `PermissionKind`，覆盖相机、麦克风、相册（只写 / 读写）、通知、定位、通讯录、日历；回调统一主队列，`request` 只在 `.notDetermined` 时弹框
- `openSettings(for:)`：iOS 打开 App 设置页，macOS 打开对应隐私面板
- 请求前校验 Info.plist usage description，缺 key 时返回 `.unavailable`，而不是让系统终止 App

### 修复

- `NotificationUtil`：授权回调回主队列、`provisional` 计入已授权、不再在 init 时取 `UNUserNotificationCenter`（无 bundle 的进程会崩）
- `CameraUtil` 改为 `PermissionUtil` 的薄封装

## [0.0.27] - 2026-10-23

### 变更

- `KeychainUtil` 改用数据保护钥匙串（`kSecUseDataProtectionKeychain` + 统一 service），兼容并静默迁移旧记录；宿主缺 entitlement 时回退旧钥匙串并记录错误

### 修复

- `getString` 区分 `errSecItemNotFound` 与其它错误码；`remove` 同时清理旧记录，避免退出登录后旧 token 被重新迁移回来

## [0.0.26] - 2026-10-19

### 变更

- `HttpUtil` 完成剥离 Alamofire：只保留纯 Foundation 实现，参数编码保持旧线上格式，回调固定主队列
