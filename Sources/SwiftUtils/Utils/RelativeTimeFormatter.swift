//
//  RelativeTimeFormatter.swift
//  SwiftUtils
//
//  Created by zzh on 2026/11/12.
//

import Foundation

/// 相对时间（"3 分钟前" / "明天"）。
public enum RelativeTimeFormatter {
    /// 过去/未来的表达方式。
    public enum DateTimeStyle: Sendable {
        /// 能用名词就用名词：「昨天」「上周」。
        case named
        /// 一律用数字：「1 天前」「2 周后」。
        case numeric
    }

    /// 把 `date` 表示成相对于 `now` 的文字。
    ///
    /// 起草的纯函数版本有两个问题：
    /// 1. **未来时间会被说成「刚刚」**：`interval < 60` 对未来的负数也成立，
    ///    「明天」因此显示成「刚刚」；
    /// 2. 硬编码中文 —— 和 `AlertUtil` 文案写死在库里是同一类问题，宿主无法本地化。
    ///
    /// 改用系统的 `RelativeDateTimeFormatter`（watchOS 6+）：过去/未来、跨月跨年、夏令时都由它处理，
    /// 这里只负责注入 locale / 时区，并给测试一个固定的 `now`。
    ///
    /// - Note: 与 `Date.timeFormatter(_:)` 的约定**故意不同**。那个固定 `zh_CN + Asia/Shanghai`，
    ///   用于「把时间戳显示成某年某月」；相对时间应该跟**用户所在时区**走，
    ///   否则跨时区时「昨天」会算错，所以这里默认 `.current`，需要固定时区时显式传。
    /// - Note: `RelativeDateTimeFormatter` 不是线程安全的，每次调用新建。
    public static func string(
        from date: Date,
        now: Date = Date(),
        style: DateTimeStyle = .named,
        locale: Locale = .current,
        timeZone: TimeZone = .current
    ) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = locale
        formatter.dateTimeStyle = style == .named ? .named : .numeric
        formatter.unitsStyle = .full

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        formatter.calendar = calendar

        return formatter.localizedString(for: date, relativeTo: now)
    }
}
