//
//  HttpUtil.swift
//
//
//  Created by zzh on 2024/7/23.
//

import Alamofire
import Foundation

/// HTTP 工具。
///
/// 目前同时提供两套等价的公开 API（剥离 Alamofire 的第一步）：
///
/// - **纯 Foundation 版（推荐）**：`setHeader([String: String])`、
///   `get(_:query:)`、`post(_:form:)`、`postJSON(_:json:)`，内部只用 `URLSession`，
///   不依赖 Alamofire。调用方应逐步迁移到这套。
/// - **Alamofire 版（兼容保留）**：`setHeader(HTTPHeaders)`、
///   `get(_:params:)`、`post(_:body:)`、`postJSON(_:body:)`。
///   待所有调用方迁移完成后，第二步会删除这一套并从 Package.swift 移除 Alamofire。
///
/// 两套实现的行为经过对齐验证，保持一致：
/// - **不校验 HTTP 状态码**：4xx/5xx 依然走成功回调（与既有 Alamofire 行为一致，
///   Alamofire 未调用 `validate()` 时即为此行为）；
/// - GET 参数与 form body 的编码与 Alamofire 的 `URLEncodedFormEncoder` 一致：
///   key 升序排序，空格编码为 `%20`，`&`/`+`/`=` 分别转义为 `%26`/`%2B`/`%3D`；
/// - 请求头默认带 UA，由 `init` 注入，可用 `setHeader`/`setUA` 覆盖。
public class HttpUtil {
    /// 请求头以纯 Foundation 字典存储，便于第二步剥离 Alamofire 时无需改动存储结构
    private var headers: [String: String]
    private let session: URLSession

    public convenience init() {
        self.init(session: .shared)
    }

    /// 注入自定义 `URLSession`。
    /// 内部可见，供测试挂载 `URLProtocol` 桩；也为后续需要自定义超时/缓存策略留出入口。
    init(session: URLSession) {
        self.session = session
        self.headers = ["User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 14_5 like Mac OS X) AppleWebKit/630.3 (KHTML, like Gecko) Version/14.5.21 Mobile/4QKLI4 Safari/630.3"]
    }

    // MARK: - Headers

    /// 设置全部请求头（纯 Foundation 版，推荐）
    public func setHeader(_ newHeaders: [String: String]) {
        self.headers = newHeaders
    }

    /// 设置全部请求头（Alamofire 版，保留至第二步剥离）
    public func setHeader(_ newHeaders: HTTPHeaders) {
        self.headers = Dictionary(newHeaders.map { ($0.name, $0.value) }, uniquingKeysWith: { _, last in last })
    }

    public func setUA(_ newValue: String) {
        self.headers["User-Agent"] = newValue
    }

    public func setCookie(_ newValue: String) {
        self.headers["Cookie"] = newValue
    }

    // MARK: - 纯 Foundation 实现（新增，推荐迁移）
    //
    // 注意：这一套的参数都**故意不给默认值**。
    // 原因是与上面/下面的 Alamofire 重载并存期间，若 `query`/`form`/`json` 带默认值，
    // 那么 `get(url, callback:fail:)` 这类不带参数的调用会被解析到 Alamofire 重载
    // （实测已确认），调用方以为迁移了、实际仍在走 Alamofire。
    // 去掉默认值后：不带参数 → 旧的重载；带 `query:`/`form:`/`json:`（哪怕是 nil）→ 新实现，
    // 迁移到哪一套从调用点一眼可见。等第二步删除旧重载后，再给新实现补默认值。

    /// GET，参数拼接到 query。不依赖 Alamofire。
    /// - Parameters:
    ///   - query: 查询参数，没有就传 `nil`（必传，见上面的说明）
    public func get(_ url: String,
                    query: [String: Any]?,
                    callback: @escaping (String) -> Void, fail: @escaping (String) -> Void)
    {
        var finalUrl = url
        if let query, !query.isEmpty {
            finalUrl += (url.contains("?") ? "&" : "?") + Self.encodeForm(query)
        }
        request(method: "GET", url: finalUrl, body: nil, contentType: nil,
                errorPrefix: "http.get:", callback: callback, fail: fail)
    }

    /// POST，参数以 `application/x-www-form-urlencoded` 放在 body。不依赖 Alamofire。
    /// - Parameters:
    ///   - form: 表单参数，没有就传 `nil`（必传）
    public func post(_ url: String,
                     form: [String: Any]?,
                     callback: @escaping (String) -> Void, fail: @escaping (String) -> Void)
    {
        let body = form.flatMap { Self.encodeForm($0).data(using: .utf8) }
        request(method: "POST", url: url, body: body,
                contentType: "application/x-www-form-urlencoded; charset=utf-8",
                errorPrefix: "http.post:", callback: callback, fail: fail)
    }

    /// POST，参数序列化为 JSON 放在 body。不依赖 Alamofire。
    /// - Parameters:
    ///   - json: JSON 参数，没有就传 `nil`（必传）
    public func postJSON(_ url: String,
                         json: [String: Any]?,
                         callback: @escaping (String) -> Void, fail: @escaping (String) -> Void)
    {
        var body: Data?
        if let json {
            // 注意：JSONSerialization 对不合法的对象（如 Date）会抛 ObjC 异常而非返回 nil，
            // 必须先 isValidJSONObject 校验，否则会直接崩溃
            guard JSONSerialization.isValidJSONObject(json),
                  let data = try? JSONSerialization.data(withJSONObject: json) else {
                SU.log.error("http.postJSON: 参数无法序列化为 JSON")
                fail("http.postJSON: 参数无法序列化为 JSON")
                return
            }
            body = data
        }
        request(method: "POST", url: url, body: body, contentType: "application/json",
                errorPrefix: "http.postJSON:", callback: callback, fail: fail)
    }

    // MARK: - 纯 Foundation 私有实现

    private func request(method: String, url: String, body: Data?, contentType: String?,
                         errorPrefix: String,
                         callback: @escaping (String) -> Void, fail: @escaping (String) -> Void)
    {
        guard let requestUrl = URL(string: url) else {
            SU.log.error("\(errorPrefix) 非法 URL: \(url)")
            fail("\(errorPrefix) 非法 URL")
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
                SU.log.error("\(errorPrefix)\(error.localizedDescription)")
                fail(errorPrefix + error.localizedDescription)
                return
            }
            // 与既有 Alamofire 行为保持一致：不校验状态码，4xx/5xx 同样走成功回调
            let data = data ?? Data()
            guard let text = String(data: data, encoding: .utf8) else {
                SU.log.error("\(errorPrefix)响应无法按 UTF-8 解码")
                fail(errorPrefix + "响应无法按 UTF-8 解码")
                return
            }
            callback(text)
        }.resume()
    }

    /// 与 Alamofire 的 `URLEncodedFormEncoder` 行为对齐：
    /// key 升序排序，空格 `%20`，`&`/`+`/`=` 转义。
    static func encodeForm(_ params: [String: Any]) -> String {
        params.keys.sorted().map { key in
            "\(encode(key))=\(encode(stringValue(params[key])))"
        }.joined(separator: "&")
    }

    private static func stringValue(_ value: Any?) -> String {
        guard let value else { return "" }
        if let string = value as? String { return string }
        return String(describing: value)
    }

    private static func encode(_ value: String) -> String {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&=?+")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }

    // MARK: - Alamofire 实现（兼容保留，第二步删除）

    public func get(_ url: String,
                    params: Parameters? = nil, callback: @escaping (String)->Void, fail: @escaping (String)->Void)
    {
        AF.request(url, method: .get, parameters: params, headers: HTTPHeaders(headers)).responseString { response in
            switch response.result {
            case let .success(value):
                callback(value)
            case let .failure(error):
                print(error)
                fail("http.get:" + error.localizedDescription)
            }
        }
    }

    public func get(_ url: String, callback: @escaping (String)->Void, fail: @escaping (String)->Void) {
        AF.request(url, method: .get, headers: HTTPHeaders(headers)).responseString { response in
            switch response.result {
            case let .success(value):
                callback(value)
            case let .failure(error):
                print(error)
                fail("http.get:" + error.localizedDescription)
            }
        }
    }

    public func post(_ url: String, body: Parameters? = nil, callback: @escaping (String)->Void, fail: @escaping (String)->Void) {
        AF.request(url, method: .post, parameters: body, headers: HTTPHeaders(headers)).responseString { response in
            switch response.result {
            case let .success(value):
                callback(value)
            case let .failure(error):
                print(error)
                fail(error.localizedDescription)
            }
        }
    }

    public func postJSON(_ url: String, body: Parameters? = nil, callback: @escaping (String)->Void, fail: @escaping (String)->Void) {
        AF.request(url, method: .post, parameters: body,
                   encoding: JSONEncoding.default, headers: HTTPHeaders(headers)).responseString { response in
            switch response.result {
            case let .success(value):
                callback(value)
            case let .failure(error):
                print(error)
                fail(error.localizedDescription)
            }
        }
    }
}
