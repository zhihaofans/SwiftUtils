//
//  LogLevel.swift
//  SwiftUtils
//
//  Created by zzh on 2026/11/13.
//

import Foundation

/// 日志等级，按严重程度递增。
///
/// 去掉 swift-log 之后自己定义的等级：名字与 swift-log 的 `Logger.Level` 一致
/// （`.trace` … `.critical`），宿主从 `Logger.Level` 迁过来时 `.debug` / `.info`
/// 这些写法不用改，只有类型名变了。
public enum LogLevel: Int, Comparable, CaseIterable, Sendable {
    case trace
    case debug
    case info
    case notice
    case warning
    case error
    case critical

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// 上报给 OSLog / 控制台时显示的名字。
    public var name: String {
        switch self {
        case .trace: return "trace"
        case .debug: return "debug"
        case .info: return "info"
        case .notice: return "notice"
        case .warning: return "warning"
        case .error: return "error"
        case .critical: return "critical"
        }
    }
}
