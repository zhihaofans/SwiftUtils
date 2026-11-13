//
//  LogExporter.swift
//  SwiftUtils
//
//  Created by zzh on 2026/11/13.
//

#if canImport(OSLog)

import Foundation
import OSLog

/// 从系统日志里导出当前进程最近的日志。
///
/// 对应「设置页 → 导出日志」这类功能：用户不用连 Xcode 也能把现场发出来。
///
/// - Important: 只能读**当前进程**的日志（`scope: .currentProcessIdentifier`），
///   这是公开 API 允许的范围；读全系统日志需要专用 entitlement。
/// - Note: `OSLogStore` 与 `getEntries` 都是同步阻塞调用，可能耗时几百毫秒到几秒，
///   所以这里包成 `async` 并放到后台队列，不占调用方线程。
/// - Note: 导出的内容受写入时的隐私标记影响：用 `OSLogBackend(isPublic: false)`（默认）
///   打的日志，在导出里同样是 `<private>`。要可读就显式公开。
public enum LogExporter {
    public enum ExportError: Error, Equatable {
        case storeUnavailable
    }

    /// 导出 `subsystem` 下最近 `seconds` 秒的日志，按时间升序，一行一条。
    ///
    /// - Parameters:
    ///   - subsystem: 与 `OSLogBackend(subsystem:)` 的取值一致。
    ///   - seconds: 回溯时长；负数按 0 处理。
    ///   - categories: 只导出这些分类；`nil` 表示全部。
    /// - Returns: 没有匹配日志时返回空字符串。
    public static func export(
        subsystem: String,
        last seconds: TimeInterval,
        categories: Set<String>? = nil
    ) async throws -> String {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            DispatchQueue.global(qos: .utility).async {
                do {
                    let text = try readBlocking(
                        subsystem: subsystem,
                        seconds: seconds,
                        categories: categories
                    )
                    continuation.resume(returning: text)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - 私有

    private static func readBlocking(
        subsystem: String,
        seconds: TimeInterval,
        categories: Set<String>?
    ) throws -> String {
        let store: OSLogStore
        do {
            store = try OSLogStore(scope: .currentProcessIdentifier)
        } catch {
            throw ExportError.storeUnavailable
        }

        let start = store.position(date: Date().addingTimeInterval(-max(0, seconds)))

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var lines: [String] = []
        // 不要 compactMap 成数组：日志多时会把所有 entry 一次性物化，内存峰值很高
        for case let entry as OSLogEntryLog in try store.getEntries(at: start) {
            guard entry.subsystem == subsystem else { continue }
            if let categories, !categories.contains(entry.category) { continue }
            lines.append("\(formatter.string(from: entry.date)) [\(entry.category)] \(entry.composedMessage)")
        }
        return lines.joined(separator: "\n")
    }
}

#endif
