//  StringEx.swift
//
//
//  Created by zzh on 2024/6/17.
//

import Foundation

public extension String {
    var array: [String] {
        return [self]
    }

    var isNotEmpty: Bool {
        return !self.isEmpty
    }

    var isInt: Bool {
        return Int(self) != nil
    }

    var isUrl: Bool {
        return URL(string: self) != nil
    }

    var isFloat: Bool {
        return Float(self) != nil
    }

    var toSubstring: Substring {
        return self[...]
    }

    func has(_ keyword: String) -> Bool {
        return self.contains(keyword)
    }

    func replace(of: String, with: String) -> String {
        return self.replacingOccurrences(of: of, with: with)
    }

    func getString(_ defaultValue: String) -> String {
        return self.isEmpty ? defaultValue : self
    }

    func removeLeftSpaceAndNewLine() -> String {
        return String(self.drop(while: { $0 == " " || $0 == "\n" }))
    }

    func fenciByWord() -> [String] {
        return FenciUtil().fenciByWord(self)
    }

    func fenciBySentence() -> [String] {
        return FenciUtil().fenciBySentence(self)
    }

    func fenciByParagraph() -> [String] {
        return FenciUtil().fenciByParagraph(self)
    }

    func fenciByDocument() -> [String] {
        return FenciUtil().fenciByDocument(self)
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

    func uppercasedFirst() -> String {
        guard !isEmpty else { return self }
        let firstLetter = self.prefix(1).uppercased()
        let remainingLetters = self.dropFirst()
        return firstLetter + remainingLetters
    }

    func lowercasedFirst() -> String {
        guard !isEmpty else { return self }
        let firstLetter = self.prefix(1).lowercased()
        let remainingLetters = self.dropFirst()
        return firstLetter + remainingLetters
    }

    func setUserDefaults(_ key: String) {
        UserDefaultUtil().setString(key: key, value: self)
    }

    var httpToHttps: String {
        return self.replace(of: "http://", with: "https://")
    }
}

public extension String? {
    var isNotEmpty: Bool {
        return self?.isEmpty == false
    }

    var isInt: Bool {
        return Int(self ?? "") != nil
    }

    func getString(_ defaultValue: String) -> String {
        return self ?? defaultValue
    }
}
