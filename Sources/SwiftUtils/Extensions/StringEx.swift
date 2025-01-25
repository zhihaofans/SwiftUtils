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
    
    func fenci(_ fenciUnit: NLTokenUnit = .word): [String] {
        return FenciUtil().fenci(self)
    }

    var urlEncode: String {
        return EncodeUtil().urlEncode(self)
    }

    var urlDecode: String {
        return EncodeUtil().urlDecode(self)
    }
    
    var base64Encode: String {
        return EncodeUtil().base64Encode(self)
    }

    var base64Decode: String {
        return EncodeUtil().base64Decode(self)
    }
    
    var sha256: String {
        return HashUtil().sha256(self)
    }
    
    var sha384: String {
        return HashUtil().sha384(self)
    }
    
    var sha512: String {
        return HashUtil().sha512(self)
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
