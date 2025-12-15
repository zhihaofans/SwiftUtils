//
//  File.swift
//  SwiftUtils
//
//  Created by zzh on 2025/2/1.
//

import Foundation

public extension Float {
    func roundedDecimal(_ decimalPlaces: Int = 0) -> Float {
        if decimalPlaces == 0 {
            return self.rounded()
        }
        return (self * pow(10, Float(decimalPlaces))).rounded() / pow(10, Float(decimalPlaces))
    }

    func roundedDecimalUp(_ decimalPlaces: Int = 0) -> Float {
        if decimalPlaces == 0 {
            return self.rounded(.up)
        }
        return (self * pow(10, Float(decimalPlaces))).rounded(.up) / pow(10, Float(decimalPlaces))
    }

    func roundedDecimalDown(_ decimalPlaces: Int = 0) -> Float {
        if decimalPlaces == 0 {
            return self.rounded(.down)
        }
        return (self * pow(10, Float(decimalPlaces))).rounded(.down) / pow(10, Float(decimalPlaces))
    }
    
    func setUserDefaults(_ key: String) {
        UserDefaultUtil().setFloat(key: key, value: self)
    }
}
