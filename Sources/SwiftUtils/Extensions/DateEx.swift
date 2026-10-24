//
//  DateEx.swift
//
//
//  Created by zzh on 2024/9/4.
//

import Foundation

public extension Date {
    /// 统一的时间格式化器：固定 zh_CN + Asia/Shanghai。
    /// 之前 `pastTimeString` 漏了 timeZone，同一个时间戳在列表和详情里会显示成不同日期。
    static func timeFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        return formatter
    }

    /// 与上面的格式化器配套的日历，用于「今年/去年」这类判断。
    /// 用设备日历去比较、却用上海时区去格式化，跨年那几天会算错。
    static var shanghaiCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current
        return calendar
    }

    var year: Int {
        return Calendar.current.component(.year, from: self)
    }

    var month: Int {
        return Calendar.current.component(.month, from: self)
    }

    var day: Int {
        return Calendar.current.component(.day, from: self)
    }

    var hour: Int {
        return Calendar.current.component(.hour, from: self)
    }

    var minute: Int {
        return Calendar.current.component(.minute, from: self)
    }

    var second: Int {
        return Calendar.current.component(.second, from: self)
    }

    var timestamp: Int {
        return Int(self.timeIntervalSince1970)
    }

    var timestampToTimeChinese: String {
        Date.timeFormatter("yyyy年MM月dd日HH时mm分ss秒").string(from: self)
    }

    var timestampToTimeStr: String {
        Date.timeFormatter("yyyy-MM-dd HH:mm:ss").string(from: self)
    }

    var timestampToTimeStrMinute: String {
        Date.timeFormatter("yyyy-MM-dd HH:mm").string(from: self)
    }

    var timestampToTimeStrHour: String {
        Date.timeFormatter("yyyy-MM-dd HH").string(from: self)
    }

    var timestampToTimeStrDay: String {
        Date.timeFormatter("yyyy-MM-dd").string(from: self)
    }

    var pastTimeString: String {
        let now = Date()
        let diff = now.timeIntervalSince(self)

        // 1️⃣ 一小时内
        if diff < 3600 {
            return "刚刚"
        }

        // 2️⃣ 1 - 24 小时
        if diff < 86400 {
            let hours = Int(diff / 3600)
            return "\(hours)小时前"
        }

        // 3️⃣/4️⃣ 年份判断与格式化都必须用同一个时区，否则跨年那几天会算错
        let calendar = Date.shanghaiCalendar
        let dateYear = calendar.component(.year, from: self)
        let nowYear = calendar.component(.year, from: now)

        if dateYear == nowYear {
            return Date.timeFormatter("MM-dd").string(from: self)
        }
        return Date.timeFormatter("yy-MM-dd").string(from: self)
    }

    func isYesterday(date: Date) -> Bool {
        let calendar = Calendar.current
        if calendar.isDate(date, inSameDayAs: self) {
            return false
        }
        let startOfDay1 = calendar.startOfDay(for: self)
        let startOfDay2 = calendar.startOfDay(for: date)
        // 如果 date1 是 date2 的前一天
        return calendar.isDate(startOfDay1, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: startOfDay2)!)
    }
}
