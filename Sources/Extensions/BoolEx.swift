//
//  BoolEx.swift
//
//
//  Created by zzh on 2024/6/18.
//

import Foundation

public extension Bool {
    func string(trueStr: String, falseStr: String) -> String {
        return if self {
            trueStr
        } else {
            falseStr
        }
    }
}
