//
//  LogBackend.swift
//  SwiftUtils
//
//  Created by zzh on 2026/11/13.
//

import Foundation

/// 日志输出后端。
///
/// 只负责「把已经决定要打的一条日志写出去」：等级过滤、字符串拼接都在 `LogUtil` 里做完，
/// 后端不需要重复判断。这样以后加文件后端、上报后端时不用再抄一遍过滤逻辑。
///
/// - Important: 约定 `Sendable`。实现如果持有可变状态（文件句柄、缓冲区），
///   自己加锁并标 `@unchecked Sendable`，或者在注释里写清线程约束。
public protocol LogBackend: Sendable {
    func log(
        _ level: LogLevel,
        message: String,
        metadata: [String: String],
        file: String,
        function: String,
        line: UInt
    )
}

/// 写到 stderr 的后端，也是默认后端。
///
/// 为什么是 stderr 不是 stdout：stdout 常被调用方重定向（管道、`2>&1` 之外的用法），
/// stderr 才是「诊断信息」该去的地方；Xcode 控制台两个都会显示。
public final class ConsoleBackend: LogBackend, @unchecked Sendable {
    private let label: String?
    private let lock = NSLock()
    private let formatter: DateFormatter

    /// - Parameter label: 可选前缀，例如模块名，输出成 `[IMPORT] ...`。
    public init(label: String? = nil) {
        self.label = label
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        self.formatter = formatter
    }

    public func log(
        _ level: LogLevel,
        message: String,
        metadata: [String: String],
        file: String,
        function: String,
        line: UInt
    ) {
        // DateFormatter 不是线程安全的，整行拼装放进锁里
        lock.lock()
        let text = format(level: level, message: message, metadata: metadata, file: file, line: line)
        lock.unlock()
        try? FileHandle.standardError.write(contentsOf: Data(text.utf8))
    }

    /// 拼一行日志；`internal` 是为了测试能直接断言格式。
    func format(
        level: LogLevel,
        message: String,
        metadata: [String: String],
        file: String,
        line: UInt
    ) -> String {
        let time = formatter.string(from: Date())
        let levelName = level.name.uppercased()
        let labelPart = label.map { " [\($0)]" } ?? ""

        // 固定顺序，避免同一份日志两次导出顺序不同、diff 看起来一直在变
        let metadataPart = metadata.isEmpty
            ? ""
            : " {" + metadata.sorted { $0.key < $1.key }
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: ", ") + "}"

        let fileName = (file as NSString).lastPathComponent
        return "[\(time)] [\(levelName)]\(labelPart) \(message)\(metadataPart) (\(fileName):\(line))\n"
    }
}
