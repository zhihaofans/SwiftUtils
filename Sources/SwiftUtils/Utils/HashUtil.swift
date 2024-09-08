//
//  HashUtil.swift
//
//
//  Created by zzh on 2024/6/22.
//

import CryptoKit // 引入你的 C 包装模块
import Foundation

public class HashUtil {
    public init() {}
    public func sha256(input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }

    public func sha512(input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA512.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }

    public func sha384(input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA384.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}
