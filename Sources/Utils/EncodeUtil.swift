//
//  EncodeUtil.swift
//
//
//  Created by zzh on 2024/6/17.
//

import Foundation

public class EncodeUtil {
    func UrlEncode(oldString: String) -> String {
        return oldString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? oldString
    }

    func UrlDecode(oldString: String) -> String {
        return oldString.removingPercentEncoding ?? oldString
    }
}
