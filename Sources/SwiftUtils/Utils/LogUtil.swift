//
//  LogUtil.swift
//  SwiftUtils
//
//  Created by zzh on 2026/1/18.
//
import Foundation

/// 日志门面。
///
/// 0.0.32 起不再依赖 swift-log：等级过滤、后端分发都在这里，后端只有
/// `ConsoleBackend`（默认，stderr）和 `OSLogBackend`（写系统日志）两种。
/// 方法名保持原样（`d/i/e` 与 `debug/info/warning/error`），宿主已有的调用不用改。
public enum LogUtil {
    // MARK: - 配置

    /// - Parameters:
    ///   - level: 最低输出等级，`nil` 表示保持当前值。
    ///   - backend: 输出后端，`nil` 表示保持当前值。
    public static func configure(level: LogLevel? = nil, backend: LogBackend? = nil) {
        state.configure(level: level, backend: backend)
    }

    /// 当前最低输出等级。
    public static var level: LogLevel {
        state.snapshot().level
    }

    // MARK: - 写入

    public static func trace(
        _ message: @autoclosure () -> String,
        metadata: [String: String]? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        guard isEnabled(.trace) else { return }
        write(.trace, message(), metadata: metadata ?? [:], file: file, function: function, line: line)
    }

    public static func debug(
        _ message: @autoclosure () -> String,
        metadata: [String: String]? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        guard isEnabled(.debug) else { return }
        write(.debug, message(), metadata: metadata ?? [:], file: file, function: function, line: line)
    }

    public static func info(
        _ message: @autoclosure () -> String,
        metadata: [String: String]? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        guard isEnabled(.info) else { return }
        write(.info, message(), metadata: metadata ?? [:], file: file, function: function, line: line)
    }

    public static func notice(
        _ message: @autoclosure () -> String,
        metadata: [String: String]? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        guard isEnabled(.notice) else { return }
        write(.notice, message(), metadata: metadata ?? [:], file: file, function: function, line: line)
    }

    public static func warning(
        _ message: @autoclosure () -> String,
        metadata: [String: String]? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        guard isEnabled(.warning) else { return }
        write(.warning, message(), metadata: metadata ?? [:], file: file, function: function, line: line)
    }

    public static func error(
        _ message: @autoclosure () -> String,
        metadata: [String: String]? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        guard isEnabled(.error) else { return }
        write(.error, message(), metadata: metadata ?? [:], file: file, function: function, line: line)
    }

    public static func critical(
        _ message: @autoclosure () -> String,
        metadata: [String: String]? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        guard isEnabled(.critical) else { return }
        write(.critical, message(), metadata: metadata ?? [:], file: file, function: function, line: line)
    }

    // MARK: - 短别名

    public static func d(
        _ message: @autoclosure () -> String,
        metadata: [String: String]? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        guard isEnabled(.debug) else { return }
        write(.debug, message(), metadata: metadata ?? [:], file: file, function: function, line: line)
    }

    public static func i(
        _ message: @autoclosure () -> String,
        metadata: [String: String]? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        guard isEnabled(.info) else { return }
        write(.info, message(), metadata: metadata ?? [:], file: file, function: function, line: line)
    }

    public static func e(
        _ message: @autoclosure () -> String,
        metadata: [String: String]? = nil,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        guard isEnabled(.error) else { return }
        write(.error, message(), metadata: metadata ?? [:], file: file, function: function, line: line)
    }

    // MARK: - 数值重载
    //
    // 保留原来的 Int / Float 重载：仓库里有 `SU.log.info(count)` 这类调用，
    // 字符串插值会在调用点发生，这里只负责包成 String。

    public static func debug(_ message: Int) {
        guard isEnabled(.debug) else { return }
        write(.debug, String(message), metadata: [:], file: #fileID, function: #function, line: #line)
    }
    public static func info(_ message: Int) {
        guard isEnabled(.info) else { return }
        write(.info, String(message), metadata: [:], file: #fileID, function: #function, line: #line)
    }
    public static func warning(_ message: Int) {
        guard isEnabled(.warning) else { return }
        write(.warning, String(message), metadata: [:], file: #fileID, function: #function, line: #line)
    }
    public static func error(_ message: Int) {
        guard isEnabled(.error) else { return }
        write(.error, String(message), metadata: [:], file: #fileID, function: #function, line: #line)
    }

    public static func debug(_ message: Float) {
        guard isEnabled(.debug) else { return }
        write(.debug, String(message), metadata: [:], file: #fileID, function: #function, line: #line)
    }
    public static func info(_ message: Float) {
        guard isEnabled(.info) else { return }
        write(.info, String(message), metadata: [:], file: #fileID, function: #function, line: #line)
    }
    public static func warning(_ message: Float) {
        guard isEnabled(.warning) else { return }
        write(.warning, String(message), metadata: [:], file: #fileID, function: #function, line: #line)
    }
    public static func error(_ message: Float) {
        guard isEnabled(.error) else { return }
        write(.error, String(message), metadata: [:], file: #fileID, function: #function, line: #line)
    }

    // MARK: - 内部

    private static let state = State(level: defaultLevel, backend: ConsoleBackend())

    private static var defaultLevel: LogLevel {
        #if DEBUG
        return .debug
        #else
        return .info
        #endif
    }

    /// 等级是否够。公共方法先问这个，被过滤掉的日志连插值都不做。
    private static func isEnabled(_ level: LogLevel) -> Bool {
        level >= state.snapshot().level
    }

    private static func write(
        _ level: LogLevel,
        _ message: String,
        metadata: [String: String],
        file: String,
        function: String,
        line: UInt
    ) {
        state.snapshot().backend.log(
            level,
            message: message,
            metadata: metadata,
            file: file,
            function: function,
            line: line
        )
    }

    /// 全局状态。配置和输出可能来自任意线程，统一用锁保护。
    private final class State: @unchecked Sendable {
        private let lock = NSLock()
        private var level: LogLevel
        private var backend: LogBackend

        init(level: LogLevel, backend: LogBackend) {
            self.level = level
            self.backend = backend
        }

        func configure(level: LogLevel?, backend: LogBackend?) {
            lock.lock()
            if let level { self.level = level }
            if let backend { self.backend = backend }
            lock.unlock()
        }

        func snapshot() -> (level: LogLevel, backend: LogBackend) {
            lock.lock()
            defer { lock.unlock() }
            return (level, backend)
        }
    }
}
