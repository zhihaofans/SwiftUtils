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

    public func base64ImageEncode(imageData: Data) -> String {
        // 将图片转换为 JPEG 格式的 Data (也可以选择转换为 PNG 格式)
        /* guard let imageData = image.jpegData(compressionQuality: 1.0) else {
             return nil
         } */
        // 将 Data 转换为 base64 编码的字符串
        return imageData.base64EncodedString()
    }
}
