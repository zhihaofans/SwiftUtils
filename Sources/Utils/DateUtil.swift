//
//  DateUtil.swift
//  
//
//  Created by zzh on 2024/6/17.
//

import Foundation
class DateUtil {
    func getTimestamp() -> Int {
        return Int(Date().timeIntervalSince1970)
    }

    func timestampToTimeStr(timestampInt: Int) -> String {
        // 转换为 Date 对象
        let date = Date(timeIntervalSince1970: Double(timestampInt))
        // 创建 DateFormatter
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "zh_CN") // 设置为中国地区格式
        //formatter.timeZone = TimeZone(abbreviation: "CST") // 中央标准时间
        formatter.timeZone = TimeZone(abbreviation: "Asia/Shanghai") // 中央标准时间
        
        //formatter.timeZone = TimeZone(secondsFromGMT: 8 * 3600)  // 设置时区为 UTC+8
        // 格式化日期
        let dateString = formatter.string(from: date)
        return dateString // 输出 "2020-05-23 19:47:52"
    }

    func timestampToTimeStr(timestamp: Double) -> String {
        // 转换为 Date 对象
        let date = Date(timeIntervalSince1970: Double(timestamp))
        // 创建 DateFormatter
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "zh_CN") // 设置为中国地区格式
        //formatter.timeZone = TimeZone(abbreviation: "CST") // 中央标准时间
        formatter.timeZone = TimeZone(abbreviation: "Asia/Shanghai") // 中央标准时间
        
        //formatter.timeZone = TimeZone(secondsFromGMT: 8 * 3600)  // 设置时区为 UTC+8
        // 格式化日期
        let dateString = formatter.string(from: date)
        return dateString // 输出 "2020-05-23 19:47:52"
    }

    func getNowTimeStr() -> String {
        // 转换为 Date 对象
        return self.timestampToTimeStr(timestamp: Date().timeIntervalSince1970) // 输出 "2020-05-23 19:47:52"
    }
}
