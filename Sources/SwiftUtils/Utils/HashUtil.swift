//
//  File.swift
//
//
//  Created by zzh on 2024/6/22.
//

import CommonCrypto // 引入你的 C 包装模块
import Foundation

class HashUtil {
    public init() {}
    public func sha256(_ string: String) -> String {
        guard let data = string.data(using: .utf8) else { return "" }
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))

        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }

        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
