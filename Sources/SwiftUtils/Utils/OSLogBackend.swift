//
//  OSLogBackend.swift
//  SwiftUtils
//
//  Created by zzh on 2026/11/13.
//

#if canImport(OSLog)

import Foundation
import OSLog

/// 用 `os.Logger` 输出的后端。
///
/// 收益：日志进系统日志（Console.app / `log stream` / sysdiagnose），
/// 和宿主自己用 `Logger(subsystem:category:)` 打的日志在同一条流里；
/// 也不需要宿主再 `LoggingSystem.bootstrap`。
///
/// - Important: 默认 `isPublic == false`，整条消息按 `.private` 处理，在 Console 里显示成
///   `<private>`。这是故意的：日志里经常带文件路径、用户名、Token，默认公开等于把它们
///   写进 sysdiagnose。要公开的字段请单独构造消息，或者明确传 `isPublic: true`。
public final class OSLogBackend: LogBackend, @unchecked Sendable {
    private let logger: Logger
    private let isPublic: Bool

    /// - Parameters:
    ///   - subsystem: 一般是宿主 bundle id，例如 `me.zzhhoo.OhMyFile`。
    ///   - category: 分类，例如 `swiftutils`；用同一个 subsystem 时，
    ///     `LogExporter.export(subsystem:last:)` 能把两边日志一起导出。
    ///   - isPublic: 是否把消息内容标记为公开。
    public init(subsystem: String, category: String, isPublic: Bool = false) {
        self.logger = Logger(subsystem: subsystem, category: category)
        self.isPublic = isPublic
    }

    public func log(
        _ level: LogLevel,
        message: String,
        metadata: [String: String],
        file: String,
        function: String,
        line: UInt
    ) {
        var text = message
        if !metadata.isEmpty {
            let pairs = metadata.sorted { $0.key < $1.key }
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: ", ")
            text += " {\(pairs)}"
        }

        // 隐私修饰符必须是字面量 `.public` / `.private`，不能传变量（编译器只接受静态成员），
        // 所以这里分成两条路径。
        if isPublic {
            logger.log(level: osLevel(level), "\(text, privacy: .public)")
        } else {
            logger.log(level: osLevel(level), "\(text, privacy: .private)")
        }
    }

    private func osLevel(_ level: LogLevel) -> OSLogType {
        switch level {
        case .trace, .debug:
            return .debug
        case .info:
            return .info
        case .notice, .warning:
            // OSLog 没有 warning 档，warning 归到 default（会被持久化，Console 里可见）
            return .default
        case .error:
            return .error
        case .critical:
            return .fault
        }
    }
}

#endif
