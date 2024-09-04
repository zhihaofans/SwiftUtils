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
}
