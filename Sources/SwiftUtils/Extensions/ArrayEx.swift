//
//  ArrayEx.swift
//
//
//  Created by zzh on 2024/9/2.
//

import Foundation

public extension Array {
    var isNotEmpty: Bool {
        return !self.isEmpty
    }

    var length: Int {
        return self.count
    }

    var size: Int {
        return self.count
    }
}

public extension Array where Element: Equatable {
    func has(_ item: Element) -> Bool {
        return self.contains(item)
    }
}

public extension Array where Element == String {
    func setUserDefaults(_ key: String) {
        UserDefaultUtil().setArrayString(key: key, value: self)
    }
}
