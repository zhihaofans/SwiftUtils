//
//  EncodeUtil.swift
//
//
//  Created by zzh on 2024/6/17.
//

import Foundation

public class EncodeUtil {
    init() {}

    public func UrlEncode(oldString: String) -> String {
        return oldString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? oldString
    }

    public func UrlDecode(oldString: String) -> String {
        return oldString.removingPercentEncoding ?? oldString
    }
}
