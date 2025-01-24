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

    var isUrl: Bool {
        return URL(string: self) != nil
    }

    var toSubstring: Substring {
        return self[self.startIndex...]
    }

    func has(_ keyword: String) -> Bool {
        return self.contains(keyword)
    }

    func replace(of: String, with: String) -> String {
        return self.replacingOccurrences(of: of, with: with)
    }

    func getString(_ defaultValue: String) -> String {
        if self.count == 0 {
            return defaultValue
        } else {
            return self
        }
    }

    func removeLeftSpaceAndNewLine() -> String {
        return String(self.toSubstring.drop(while: { $0 == " " || $0 == "\n" }))
    }

    var urlEncode: String {
        return EncodeUtil().urlEncode(self)
    }

    var urlDecode: String {
        return EncodeUtil().urlDecode(self)
    }
}

public extension String? {
    var isNotEmpty: Bool {
        return (self ?? "").isEmpty == false
    }

    var isInt: Bool {
        return Int(self ?? "") != nil
    }

    func getString(_ defaultValue: String) -> String {
        return self ?? defaultValue
    }
}
