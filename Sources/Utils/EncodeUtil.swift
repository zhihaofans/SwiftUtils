//
//  EncodeUtil.swift
//
//
//  Created by zzh on 2024/6/17.
//

import Foundation

public class EncodeUtil {
    public init() {}

    public func UrlEncode(oldString: String) -> String {
        return oldString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? oldString
    }

    public func UrlDecode(oldString: String) -> String {
        return oldString.removingPercentEncoding ?? oldString
    }
    public func base64Encode(oldString: String) -> String {
    let data = oldString.data(using: .utf8)
    return data?.base64EncodedString() ?? oldString
    }
  public func base64Decode(_ base64String: String) -> String {
    guard let data = Data(base64Encoded: base64String) else {
        return base64String
    }
    return String(data: data, encoding: .utf8) ?? base64String
    }
}
