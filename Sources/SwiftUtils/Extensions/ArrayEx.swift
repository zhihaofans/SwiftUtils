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

    /// 按固定大小切块。
    ///
    /// 用于批量写入/删除（SwiftData、`IN` 查询都有参数个数上限），一次 500/1000 条。
    ///
    /// 边界行为（测试钉住）：
    /// - `size <= 0` 返回 `[]`，不是死循环，也不是 `[self]`
    /// - 空数组返回 `[]`
    /// - `size >= count` 返回 `[self]`（一个块，不是拆成 count 个）
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0, !isEmpty else { return [] }
        return stride(from: 0, to: count, by: size).map { offset in
            Array(self[offset..<Swift.min(offset + size, count)])
        }
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
