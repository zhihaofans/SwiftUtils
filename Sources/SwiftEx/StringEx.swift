//
//  StringEx.swift
//
//
//  Created by zzh on 2024/6/17.
//

import Foundation

extension String {
    var isNotEmpty: Bool {
        return !self.isEmpty
    }

    var isInt: Bool {
        return Int(self) != nil
    }
}
