//
//  EncodeUtil.swift
//
//
//  Created by zzh on 2024/6/17.
//

import Foundation

public class EncodeUtil {
    public init() {}

    /// 用于 URL **参数值** 的百分号编码。
    /// 注意不能直接用 `.urlQueryAllowed`：它包含 `& = ? +` 等分隔符，
    /// 会把 `a&admin=true` 原样输出，拼进 query 后等于凭空多出一个参数。
    public func urlEncode(_ oldString: String) -> String {
        return oldString.addingPercentEncoding(withAllowedCharacters: EncodeUtil.queryValueAllowed) ?? oldString
    }

    /// `.urlQueryAllowed` 去掉在 query 中具有分隔语义的字符
    private static let queryValueAllowed: CharacterSet = {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&=?+")
        return allowed
    }()

    public func urlDecode(_ oldString: String) -> String {
        return oldString.removingPercentEncoding ?? oldString
    }

    public func base64Encode(_ oldString: String) -> String {
        let data = oldString.data(using: .utf8)
        return data?.base64EncodedString() ?? oldString
    }

    public func base64Decode(_ oldString: String) -> String {
        guard let data = Data(base64Encoded: oldString) else {
            return oldString
        }
        return String(data: data, encoding: .utf8) ?? oldString
    }

    public func base64ImageEncode(_ imageData: Data) -> String {
        // 将图片转换为 JPEG 格式的 Data (也可以选择转换为 PNG 格式)
        /* guard let imageData = image.jpegData(compressionQuality: 1.0) else {
             return nil
         } */
        // 将 Data 转换为 base64 编码的字符串
        return imageData.base64EncodedString()
    }
}
