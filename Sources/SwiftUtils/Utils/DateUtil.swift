//
//  DateUtil.swift
//
//
//  Created by zzh on 2024/6/17.
//

import Foundation

public class DateUtil {
    public init() {}
    public func getTimestamp() -> Int {
        return Date().timestamp
    }

    public func timestampToTimeStr(_ timestampInt: Int, format: String = "yyyy-MM-dd HH:mm:ss") -> String {
        return self.timestampToTimeStr(Double(timestampInt))
    }

    public func timestampToTimeStr(_ timestamp: Double, format: String = "yyyy-MM-dd HH:mm:ss") -> String {
        // 转换为 Date 对象
        let date = Date(timeIntervalSince1970: timestamp)
        // 创建 DateFormatter
        let formatter = DateFormatter()
        formatter.dateFormat = format.isEmpty ? "yyyy-MM-dd HH:mm:ss" : format
        formatter.locale = Locale(identifier: "zh_CN") // 设置为中国地区格式
        // formatter.timeZone = TimeZone(abbreviation: "CST") // 中央标准时间
        formatter.timeZone = TimeZone(abbreviation: "Asia/Shanghai") // 中央标准时间

        // formatter.timeZone = TimeZone(secondsFromGMT: 8 * 3600)  // 设置时区为 UTC+8
        // 格式化日期
        let dateString = formatter.string(from: date)
        return dateString // 输出 "2020-05-23 19:47:52"
    }

    public func getNowTimeStr() -> String {
        // 转换为 Date 对象
        return self.timestampToTimeStr(Date().timeIntervalSince1970) // 输出 "2020-05-23 19:47:52"
    }

    public func isYesterday(_ timestampInt: Int) {
        // TODO:
        let date = Date(timeIntervalSince1970: Double(timestampInt))
    }
}
