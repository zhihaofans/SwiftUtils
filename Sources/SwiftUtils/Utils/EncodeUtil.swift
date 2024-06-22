//
//  EncodeUtil.swift
//
//
//  Created by zzh on 2024/6/17.
//

import Foundation

public class EncodeUtil {
    public init() {}

    public func urlEncode(oldString: String) -> String {
        return oldString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? oldString
    }

    public func urlDecode(oldString: String) -> String {
        return oldString.removingPercentEncoding ?? oldString
    }

    public func base64Encode(oldString: String) -> String {
        let data = oldString.data(using: .utf8)
        return data?.base64EncodedString() ?? oldString
    }

    public func base64Decode(oldString: String) -> String {
        guard let data = Data(base64Encoded: oldString) else {
            return oldString
        }
        return String(data: data, encoding: .utf8) ?? oldString
    }
}
