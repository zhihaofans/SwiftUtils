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

    /// 是否是「可打开的链接」。
    ///
    /// 以前只判断 `URL(string:) != nil`，而它对相对路径也返回非 nil，
    /// 于是 `"hello"`、`"123"`、`"not a url"` 全被当成 URL（实测）。
    /// 现在要求：
    /// - 不含空白字符；
    /// - 带 scheme（`http:` / `mailto:` / `file:` 等）；
    /// - `http`/`https`/`ftp` 还必须有 host，过滤掉 `https://` 这种残缺串。
    ///
    /// - Note: 不带 scheme 的 `www.example.com` 现在会返回 `false`，需要先补全 scheme。
    var isUrl: Bool {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              trimmed.rangeOfCharacter(from: .whitespacesAndNewlines) == nil,
              let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(), !scheme.isEmpty
        else {
            return false
        }

        if ["http", "https", "ftp", "ftps"].contains(scheme) {
            return url.host?.isEmpty == false
        }
        return true
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
