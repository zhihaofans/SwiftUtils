//
//  StringEx.swift
//
//
//  Created by zzh on 2024/6/17.
//

import Foundation

public extension String {
    var isNotEmpty: Bool {
        return !self.isEmpty
    }

    var isInt: Bool {
        return Int(self) != nil
    }

    func has(keyword: String) -> Bool {
        return self.contains(keyword)
    }

    func replace(of: String, with: String) -> String {
        return self.replacingOccurrences(of: of, with: with)
    }

    func getString(defaultValue: String) -> String {
        if self.count == 0 {
            return defaultValue
        } else {
            return self
        }
    }
}

public extension String? {
    var isNotEmpty: Bool {
        return (self ?? "").isEmpty == false
    }

    var isInt: Bool {
        return Int(self ?? "") != nil
    }

    func getString(defaultValue: String) -> String {
        return self ?? defaultValue
    }
}
