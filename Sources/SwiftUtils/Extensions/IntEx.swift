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

    func setUserDefaults(_ key: String) {
        UserDefaultUtil().setInt(key: key, value: self)
    }
}
