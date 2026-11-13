# SwiftUtils TODO

> 原则：只收**平台无关、无业务语义**的小工具；每条配测试。
> 通用库不引 SwiftData / Core ML / AppKit；`Photos` 只出现在 `PermissionUtil` 的权限映射里。
> 新增工具类之前先看 `AGENTS.md` 的平台矩阵，watchOS 上不可用的 API 必须条件编译。

## 已知问题（不急着改）

- `DateUtil` 硬编码 `Asia/Shanghai`，跨时区项目会静默错。建议默认 `TimeZone.current`，需要固定时区的调用方显式传。
- `Date.pastTimeString` 未来时间也会显示「刚刚」（`diff < 3600` 对负数成立）；新代码用 `RelativeTimeFormatter`。
- `UserDefaultUtil` 用默认值吞掉「没数据 vs 数据坏了」。建议区分 optional 读取与默认值。
- `QrcodeUtil` 实例内的 `CIFilter` 非线程安全，多线程同时生成会串数据；可改为每次调用新建 filter，或加锁。
- `ClipboardUtil.getString` 在 iOS 16+ 会触发系统粘贴授权弹窗；`hasString` 也可能触发，启动路径不要调。
- `AlertUtil` / 部分 `ViewEx` 文案写死在库里（“取消/确定/请输入内容”），无法被宿主 String Catalog 本地化。

## 明确不做

- `ZIPUtil`：不引入 ZIPFoundation（宿主零依赖原则）；要压缩由宿主自己决定依赖。
- `DownloadUtil`：后台 `URLSession` 需要宿主实现 `handleEventsForBackgroundURLSession`，库接管不了生命周期；`persistedTasks()` 还得自存元数据，接近半套数据库。需要时在宿主做。
- 回收站 / 目录树 / 文件夹模型、Share Extension 文件交接协议、预览路由、具体格式预览器：业务相关。
- 照片、Vision、向量、SwiftData 相关：留在 App 或宿主共享模块。
- 任何默认开启网络的能力。
