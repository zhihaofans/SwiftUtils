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