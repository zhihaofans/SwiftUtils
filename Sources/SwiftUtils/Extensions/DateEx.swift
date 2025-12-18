//
//  DateEx.swift
//
//
//  Created by zzh on 2024/9/4.
//

import Foundation

public extension Date {
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
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日HH时mm分ss秒"
        formatter.locale = Locale(identifier: "zh_CN") // 设置为中国地区格式
        formatter.timeZone = TimeZone(abbreviation: "Asia/Shanghai") // 中央标准时间
        let dateString = formatter.string(from: self)
        return dateString // 输出 "2020-05-23 19:47:52"
    }

    var timestampToTimeStr: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "zh_CN") // 设置为中国地区格式
        formatter.timeZone = TimeZone(abbreviation: "Asia/Shanghai") // 中央标准时间
        let dateString = formatter.string(from: self)
        return dateString // 输出 "2020-05-23 19:47:52"
    }

    var timestampToTimeStrMinute: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        formatter.locale = Locale(identifier: "zh_CN") // 设置为中国地区格式
        formatter.timeZone = TimeZone(abbreviation: "Asia/Shanghai") // 中央标准时间
        let dateString = formatter.string(from: self)
        return dateString // 输出 "2020-05-23 19:47:52"
    }

    var timestampToTimeStrHour: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH"
        formatter.locale = Locale(identifier: "zh_CN") // 设置为中国地区格式
        formatter.timeZone = TimeZone(abbreviation: "Asia/Shanghai") // 中央标准时间
        let dateString = formatter.string(from: self)
        return dateString // 输出 "2020-05-23 19"
    }

    var timestampToTimeStrDay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "zh_CN") // 设置为中国地区格式
        formatter.timeZone = TimeZone(abbreviation: "Asia/Shanghai") // 中央标准时间
        let dateString = formatter.string(from: self)
        return dateString // 输出 "2020-05-23"
    }

    var pastTimeString: String {
        let date = self
        let now = Date()

        let calendar = Calendar.current
        let diff = now.timeIntervalSince(date)

        // 1️⃣ 一小时内
        if diff < 3600 {
            return "刚刚"
        }

        // 2️⃣ 1 - 24 小时
        if diff < 86400 {
            let hours = Int(diff / 3600)
            return "\(hours)小时前"
        }

        let dateYear = calendar.component(.year, from: date)
        let nowYear = calendar.component(.year, from: now)

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")

        // 3️⃣ 今年
        if dateYear == nowYear {
            formatter.dateFormat = "MM-dd"
            return formatter.string(from: date)
        }

        // 4️⃣ 去年及以前
        formatter.dateFormat = "yy-MM-dd"
        return formatter.string(from: date)
    }

    func isYesterday(date: Date) -> Bool {
        let calendar = Calendar.current
        if calendar.isDate(date, inSameDayAs: self) {
            return false
        }
        let startOfDay1 = calendar.startOfDay(for: self)
        let startOfDay2 = calendar.startOfDay(for: date)
        // 如果 date1 是 date2 的前一天
        return calendar.isDate(startOfDay1, inSameDayAs: calendar.date(byAdding: .day, value: 1, to: startOfDay2)!)
    }
}
