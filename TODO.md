# SwiftUtils TODO

> 原则：只收**平台无关、无业务语义**的小工具；每条配测试。
> 通用库不引 SwiftData / Core ML / AppKit；`Photos` 只出现在 `PermissionUtil` 的权限映射里。
> 新增工具类之前先看 `AGENTS.md` 的平台矩阵，watchOS 上不可用的 API 必须条件编译。

## 待实现

### 批次 2：图像 / PDF / 媒体（0.0.31）

1. `ImageUtil`（ImageIO 路线，三平台同名 API）
   - `downsample(_:maxPixelSize:) -> CGImage?`：必须带 `kCGImageSourceCreateThumbnailWithTransform`，否则竖拍缩略图是横的
   - `reencode(_:to:quality:maxPixelSize:) -> Data?`：重编码会丢 metadata，要显式搬 EXIF orientation
   - `metadata(_:) -> [String: Any]`：非 Sendable，文档写清只在主线程用；另给扁平 `[String: String]` 版本
   - 验证：带 `orientation = 6` 的 fixture，输出仍竖着
2. `PDFUtil`（`#if os(iOS) || os(macOS)`；watchOS 没有 PDFKit）
   - `pageCount`、`pageImage(_:page:maxPixelSize:) -> CGImage?`、`makePDF(from: [CGImage], to:)`
   - 不做整本渲染：100 页 × scale 2 是 GB 级内存
3. `MediaUtil`（`#if os(iOS) || os(macOS)`；`AVAssetExportSession` 在 watchOS 上 unavailable）
   - `export(_:to:preset:)`：导出前删目标文件、检查 `status == .failed`、进度轮询
   - `info(_:)`：用 `try await asset.load(.duration)`，不用已 deprecated 的同步 `.duration`
4. `AuthUtil.biometryInfo()`：返回 `(available, LABiometryType)`，每次新建 `LAContext`
5. 待定：`PermissionUtil` 增加 `.misconfigured`，区分「Info.plist 缺 key」与「设备没有这个能力」
   —— 公共枚举变更，先确认再动

### 批次 3：日志（0.0.32）

6. `OSLogHandler`：swift-log 的 OSLog 后端
   - 用 `final class` + 锁（`LogHandler.metadata` 可变，struct 值语义并发写会丢）
   - 默认 `.private`，避免把路径写进系统日志；库**不**调 `LoggingSystem.bootstrap`
7. `LogExporter`：用 `OSLogStore` 导出最近 N 秒日志（macOS 12 / iOS 15 / watchOS 8+）
   - `getEntries` 同步阻塞，要包 async；流式拼接，别一次 `compactMap` 成数组

## 已知问题（不急着改）

- `DateUtil` 硬编码 `Asia/Shanghai`，跨时区项目会静默错。建议默认 `TimeZone.current`，需要固定时区的调用方显式传。
- `Date.pastTimeString` 未来时间也会显示「刚刚」（`diff < 3600` 对负数成立）；新代码用 `RelativeTimeFormatter`。
- `UserDefaultUtil` 用默认值吞掉「没数据 vs 数据坏了」。建议区分 optional 读取与默认值。
- `PermissionUtil` 把「Info.plist 缺 key」和「设备没有这个能力」都映射成 `.unavailable`，调用方分不出是配置错还是硬件不支持；要区分得加 `.misconfigured`（公共 API 变更，见批次 2 第 5 条）。
- `QrcodeUtil` 实例内的 `CIFilter` 非线程安全，多线程同时生成会串数据；可改为每次调用新建 filter，或加锁。
- `ClipboardUtil.getString` 在 iOS 16+ 会触发系统粘贴授权弹窗；`hasString` 也可能触发，启动路径不要调。
- `LogUtil` 默认走 swift-log 的 stderr handler，宿主不 `LoggingSystem.bootstrap` 时真机 Release 看不到日志；批次 3 的 `OSLogHandler` 就是解这个。
- `AlertUtil` / 部分 `ViewEx` 文案写死在库里（“取消/确定/请输入内容”），无法被宿主 String Catalog 本地化。

## 明确不做

- `ZIPUtil`：不引入 ZIPFoundation（宿主零依赖原则）；要压缩由宿主自己决定依赖。
- `DownloadUtil`：后台 `URLSession` 需要宿主实现 `handleEventsForBackgroundURLSession`，库接管不了生命周期；`persistedTasks()` 还得自存元数据，接近半套数据库。需要时在宿主做。
- 回收站 / 目录树 / 文件夹模型、Share Extension 文件交接协议、预览路由、具体格式预览器：业务相关。
- 照片、Vision、向量、SwiftData 相关：留在 App 或宿主共享模块。
- 任何默认开启网络的能力。
