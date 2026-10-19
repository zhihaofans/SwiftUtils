//
//  HttpUtil.swift
//
//
//  Created by zzh on 2024/7/23.
//

import Foundation

/// HTTP 工具（纯 Foundation 实现，`URLSession` + `URLComponents`，不依赖第三方网络库）。
///
/// 行为契约（与剥离 Alamofire 之前保持一致）：
/// - **回调一律在主队列异步执行**：`callback`/`fail` 不会在 URLSession 的后台队列上被调用，
///   调用方可以直接更新 UI。过渡版本曾把回调投递到 URLSession 的后台队列（与旧版不一致），
///   这里已改回主队列；同时也意味着回调**一定晚于**发起请求的语句返回（即使失败原因是
///   非法 URL / 参数无法序列化这类同步就能发现的问题）。
/// - **不校验 HTTP 状态码**：4xx/5xx 依然走成功回调，响应体原样交给 `callback`。
/// - **参数编码与旧版 Alamofire `URLEncoding` 逐字节一致**：
///   顶层 key 升序；空格 `%20`；`:` `#` `[` `]` `@` `!` `$` `&` `'` `(` `)` `*` `+` `,` `;` `=`
///   转义（`?` 与 `/` 保留，同 RFC 3986 查询串规则）；
///   数组编码为 `key[]=v`、嵌套字典编码为 `key[sub]=v`（方括号在最终串里会被转义成
///   `%5B`/`%5D`，即 `ids%5B%5D=1`，与旧实现一致），`Bool` 编码为 `1`/`0`。
///   唯一的差异：嵌套字典的 key 也做了升序（旧实现按字典遍历顺序，顺序不保证）。
/// - 请求头默认带 UA，由 `init` 注入，可用 `setHeader`/`setUA` 覆盖。
public class HttpUtil {
    private static let defaultHeaders: [String: String] = [
        "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 14_5 like Mac OS X) AppleWebKit/630.3 (KHTML, like Gecko) Version/14.5.21 Mobile/4QKLI4 Safari/630.3",
    ]

    private var headers: [String: String]
    private let session: URLSession

    /// 使用 `URLSession.shared`
    public init() {
        self.session = .shared
        self.headers = Self.defaultHeaders
    }

    /// 注入自定义 `URLSession`。
    /// 内部可见，供测试挂载 `URLProtocol` 桩；也为后续需要自定义超时/缓存策略留出入口。
    init(session: URLSession) {
        self.session = session
        self.headers = Self.defaultHeaders
    }

    // MARK: - Headers

    /// 设置全部请求头（会整体替换，如需保留 UA 请一并传入）
    public func setHeader(_ newHeaders: [String: String]) {
        self.headers = newHeaders
    }

    public func setUA(_ newValue: String) {
        self.headers["User-Agent"] = newValue
    }

    public func setCookie(_ newValue: String) {
        self.headers["Cookie"] = newValue
    }

    // MARK: - 请求

    /// GET，参数拼接到 query。
    /// - Parameters:
    ///   - query: 查询参数；传 `nil` 或空字典时 URL 不变
    ///   - callback: 成功回调，参数为响应体按 UTF-8 解码后的文本，主队列执行
    ///   - fail: 失败回调，参数形如 `http.get:<原因>`，主队列执行
    public func get(_ url: String,
                    query: [String: Any]? = nil,
                    callback: @escaping (String) -> Void, fail: @escaping (String) -> Void)
    {
        var finalUrl = url
        if let query, !query.isEmpty {
            guard var components = URLComponents(string: url) else {
                Self.reportFailure(prefix: "http.get:", message: "非法 URL: \(url)", fail: fail)
                return
            }
            let encoded = Self.encodeForm(query)
            let existingQuery = components.percentEncodedQuery ?? ""
            components.percentEncodedQuery = existingQuery.isEmpty ? encoded : existingQuery + "&" + encoded
            guard let mergedUrl = components.url else {
                Self.reportFailure(prefix: "http.get:", message: "非法 URL: \(url)", fail: fail)
                return
            }
            finalUrl = mergedUrl.absoluteString
        }
        request(method: "GET", url: finalUrl, body: nil, contentType: nil,
                errorPrefix: "http.get:", callback: callback, fail: fail)
    }

    /// POST，参数以 `application/x-www-form-urlencoded` 放在 body。
    /// - Parameters:
    ///   - form: 表单参数；传 `nil` 时不发 body 也不带 Content-Type（空字典会发空 body）
    public func post(_ url: String,
                     form: [String: Any]? = nil,
                     callback: @escaping (String) -> Void, fail: @escaping (String) -> Void)
    {
        var body: Data?
        if let form {
            body = Data(Self.encodeForm(form).utf8)
        }
        request(method: "POST", url: url, body: body,
                contentType: body == nil ? nil : "application/x-www-form-urlencoded; charset=utf-8",
                errorPrefix: "http.post:", callback: callback, fail: fail)
    }

    /// POST，参数序列化为 JSON 放在 body。
    /// - Parameters:
    ///   - json: JSON 参数；传 `nil` 时不发 body 也不带 Content-Type。非法对象（如 `Date`）
    ///     会走 `fail` 且不发出请求，不会崩溃
    public func postJSON(_ url: String,
                         json: [String: Any]? = nil,
                         callback: @escaping (String) -> Void, fail: @escaping (String) -> Void)
    {
        var body: Data?
        if let json {
            // 注意：JSONSerialization 对不合法的对象（如 Date）会抛 ObjC 异常而非返回 nil，
            // 必须先 isValidJSONObject 校验，否则会直接崩溃
            guard JSONSerialization.isValidJSONObject(json),
                  let data = try? JSONSerialization.data(withJSONObject: json) else {
                Self.reportFailure(prefix: "http.postJSON:", message: "参数无法序列化为 JSON", fail: fail)
                return
            }
            body = data
        }
        request(method: "POST", url: url, body: body,
                contentType: body == nil ? nil : "application/json",
                errorPrefix: "http.postJSON:", callback: callback, fail: fail)
    }

    // MARK: - 私有实现

    private func request(method: String, url: String, body: Data?, contentType: String?,
                         errorPrefix: String,
                         callback: @escaping (String) -> Void, fail: @escaping (String) -> Void)
    {
        guard let requestUrl = URL(string: url) else {
            Self.reportFailure(prefix: errorPrefix, message: "非法 URL: \(url)", fail: fail)
            return
        }

        var request = URLRequest(url: requestUrl)
        request.httpMethod = method
        for (name, value) in headers {
            request.setValue(value, forHTTPHeaderField: name)
        }
        if let contentType {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        request.httpBody = body

        session.dataTask(with: request) { data, _, error in
            if let error {
                Self.reportFailure(prefix: errorPrefix, message: error.localizedDescription, fail: fail)
                return
            }
            // 与旧行为保持一致：不校验状态码，4xx/5xx 同样走成功回调
            let data = data ?? Data()
            guard let text = String(data: data, encoding: .utf8) else {
                Self.reportFailure(prefix: errorPrefix, message: "响应无法按 UTF-8 解码", fail: fail)
                return
            }
            Self.deliver { callback(text) }
        }.resume()
    }

    /// 统一的失败出口：日志 + 主队列异步回调。
    private static func reportFailure(prefix: String, message: String, fail: @escaping (String) -> Void) {
        SU.log.error("\(prefix)\(message)")
        deliver { fail(prefix + message) }
    }

    /// 所有回调都从主队列异步投递，保证「不会在后台队列更新 UI」，
    /// 也保证回调不会早于发起请求的代码执行。
    private static func deliver(_ block: @escaping () -> Void) {
        DispatchQueue.main.async(execute: block)
    }

    // MARK: - 参数编码

    /// 与旧版 Alamofire `URLEncoding` 的输出对齐：
    /// 顶层 key 升序，数组 `key[]`，嵌套字典 `key[sub]`，Bool 转 `1`/`0`；
    /// 方括号随 key 一起转义（`ids%5B%5D=1`），与旧实现的线上格式一致。
    static func encodeForm(_ params: [String: Any]) -> String {
        var components: [(String, String)] = []
        for key in params.keys.sorted() {
            guard let value = params[key] else { continue }
            components += queryComponents(fromKey: key, value: value)
        }
        return components.map { "\(escape($0.0))=\(escape($0.1))" }.joined(separator: "&")
    }

    /// 递归展开参数，key 在这一层还没有做百分号转义（转义在拼装时统一做）
    private static func queryComponents(fromKey key: String, value: Any) -> [(String, String)] {
        switch value {
        case let dictionary as [String: Any]:
            return dictionary.keys.sorted().flatMap { nestedKey in
                guard let nestedValue = dictionary[nestedKey] else { return [(String, String)]() }
                return queryComponents(fromKey: "\(key)[\(nestedKey)]", value: nestedValue)
            }
        case let array as [Any]:
            return array.flatMap { queryComponents(fromKey: "\(key)[]", value: $0) }
        case let bool as Bool:
            return [(key, bool ? "1" : "0")]
        case let number as NSNumber:
            // Bool 在部分场景会以 NSNumber(CFBoolean) 形式进来，先按 Bool 处理
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return [(key, number.boolValue ? "1" : "0")]
            }
            return [(key, "\(number)")]
        default:
            return [(key, "\(value)")]
        }
    }

    /// RFC 3986 查询串转义：`?` 与 `/` 保留，其余保留字转义，空格转 `%20`。
    private static func escape(_ string: String) -> String {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: ":#[]@" + "!$&'()*+,;=")
        return string.addingPercentEncoding(withAllowedCharacters: allowed) ?? string
    }
}
