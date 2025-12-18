//
//  IntEX.swift
//
//
//  Created by zzh on 2024/6/18.
//

import Foundation

public extension Int {
    var toString: String {
        return String(self)
    }

    var toDouble: Double {
        return Double(self)
    }

    var toTimeInterval: TimeInterval {
        return TimeInterval(self)
    }

    var toShortNumberString: String {
        // 一万开始转换为xx万（整数）
        if self < 10000 {
            return "\(self)"
        } else {
            let value = Double(self) / 10000
            return String(format: "%.1f万", value)
                .replacingOccurrences(of: ".0", with: "")
        }
    }

    var pastTimeString: String {
        return Date(timeIntervalSince1970: self.toTimeInterval).pastTimeString
    }

    var secondsToTimeLongString: String {
        // 秒数转成文本时间（最大到小时如01:02:30）
        guard self > 0 else { return "0秒" }

        let hour = self / 3600
        let minute = (self % 3600) / 60
        let second = self % 60

        if hour > 0 {
            return String(format: "%d:%02d:%02d", hour, minute, second)
        } else {
            return String(format: "%d:%02d", minute, second)
        }
    }

    func setUserDefaults(_ key: String) {
        UserDefaultUtil().setInt(key: key, value: self)
    }
}
