// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

/// SwiftUtils 命名空间入口
public let SU = SwiftUtils.self
public enum SwiftUtils {
    /// 日志门面，等价于 `LogUtil.self`。
    public static let log = LogUtil.self

    /// 配置日志等级与后端。
    ///
    /// ```swift
    /// // 写系统日志（推荐 App 用）
    /// SU.configureLogging(level: .info, backend: OSLogBackend(subsystem: "me.zzhhoo.OhMyFile", category: "swiftutils"))
    /// // 只改等级，后端保持默认的 stderr
    /// SU.configureLogging(level: .debug)
    /// ```
    public static func configureLogging(level: LogLevel? = nil, backend: LogBackend? = nil) {
        LogUtil.configure(level: level, backend: backend)
    }

    /// 旧名字，保留以免宿主升级后编译不过。
    ///
    /// 0.0.31 及以前取自 swift-log：`label` 是 `Logger` 的标识，`logLevel` 是 `Logger.Level`。
    /// 现在 `logLevel` 换成 SwiftUtils 自己的 `LogLevel`（`.debug` / `.info` 等写法不变）；
    /// `label` 只在控制台输出里当前缀，传了 `label` 会切回 `ConsoleBackend`。
    /// 要用 OSLog 请用 `configureLogging(backend:)`。
    public static func configureLogger(label: String? = nil, logLevel: LogLevel? = nil) {
        if let label {
            LogUtil.configure(level: logLevel, backend: ConsoleBackend(label: label))
        } else {
            LogUtil.configure(level: logLevel)
        }
    }
}
