import XCTest
@testable import SwiftUtils

// MARK: - 请求拦截桩
//
// 用 URLProtocol 拦下注入的 URLSession，测试真实发出的请求，
// 无需启动本地服务器，也不依赖网络。
final class StubURLProtocol: URLProtocol {
    enum Stub {
        case success(status: Int, headers: [String: String], body: Data)
        case failure(Error)
    }

    struct Captured {
        let url: String
        let method: String
        let contentType: String?
        let userAgent: String?
        let cookie: String?
        let body: String?
    }

    static var handler: ((URLRequest) -> Stub)?
    static var captured: [Captured] = []

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        StubURLProtocol.captured.append(
            Captured(url: request.url?.absoluteString ?? "",
                     method: request.httpMethod ?? "",
                     contentType: request.value(forHTTPHeaderField: "Content-Type"),
                     userAgent: request.value(forHTTPHeaderField: "User-Agent"),
                     cookie: request.value(forHTTPHeaderField: "Cookie"),
                     body: Self.readBody(request).flatMap { String(data: $0, encoding: .utf8) })
        )

        switch StubURLProtocol.handler?(request) ?? .success(status: 200, headers: [:], body: Data()) {
        case let .success(status, headers, body):
            let response = HTTPURLResponse(url: request.url!,
                                           statusCode: status,
                                           httpVersion: "HTTP/1.1",
                                           headerFields: headers)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: body)
            client?.urlProtocolDidFinishLoading(self)
        case let .failure(error):
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}

    /// URLProtocol 有时会把 httpBody 转成 httpBodyStream，两种都要能读到
    private static func readBody(_ request: URLRequest) -> Data? {
        if let body = request.httpBody { return body }
        guard let stream = request.httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var data = Data()
        let bufferSize = 4096
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufferSize)
            if read <= 0 { break }
            data.append(buffer, count: read)
        }
        return data
    }
}

// MARK: - HttpUtil 测试

final class HttpUtilTests: XCTestCase {
    private var util: HttpUtil!
    private var session: URLSession!

    override func setUp() {
        super.setUp()
        StubURLProtocol.captured = []
        StubURLProtocol.handler = nil
        // 注入挂载了桩的 session：
        // 全局 URLProtocol.registerClass 对从 SwiftUtils 模块内部发起的请求不生效
        // （实测 hits=0，请求会打到真实网络），因此走注入路径。
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        session = URLSession(configuration: configuration)
        util = HttpUtil(session: session)
    }

    override func tearDown() {
        session.invalidateAndCancel()
        session = nil
        StubURLProtocol.handler = nil
        StubURLProtocol.captured = []
        util = nil
        super.tearDown()
    }

    /// 发起请求并等待回调，避免断言早于 URLProtocol 记录请求，也避免留下在途请求
    @discardableResult
    private func perform(_ start: (@escaping (String) -> Void, @escaping (String) -> Void) -> Void)
        -> (value: String?, error: String?)
    {
        var value: String?
        var error: String?
        let done = expectation(description: "request")
        start({ value = $0; done.fulfill() }, { error = $0; done.fulfill() })
        wait(for: [done], timeout: 10)
        return (value, error)
    }

    // MARK: 参数编码
    //
    // 下面几条钉的是「迁移前后服务端实际收到的字节」：剥离 Alamofire 后必须保持原样，
    // 否则调用方一行都没改也可能坏。

    func testEncodeFormMatchesLegacyWireFormat() {
        let params: [String: Any] = ["q": "a b", "n": 1, "amp": "a&b", "plus": "x+y"]
        XCTAssertEqual(HttpUtil.encodeForm(params), "amp=a%26b&n=1&plus=x%2By&q=a%20b")
        XCTAssertEqual(HttpUtil.encodeForm(["b": "x", "a": 1]), "a=1&b=x")
        XCTAssertEqual(HttpUtil.encodeForm([:]), "")
    }

    func testEncodeFormEscapesDelimitersLikeLegacy() {
        // ? 与 / 保留（RFC 3986 查询串规则），其余保留字转义
        XCTAssertEqual(HttpUtil.encodeForm(["k": "a&b=c?d+e/f"]), "k=a%26b%3Dc?d%2Be/f")
        XCTAssertEqual(HttpUtil.encodeForm(["k": "a:b@c"]), "k=a%3Ab%40c")
    }

    func testEncodeFormEncodesArraysAsBrackets() {
        // 方括号本身会被转义（Alamofire URLEncoding 的实际输出，见 ParameterEncodingTests）
        XCTAssertEqual(HttpUtil.encodeForm(["ids": [1, 2]]), "ids%5B%5D=1&ids%5B%5D=2")
        XCTAssertEqual(HttpUtil.encodeForm(["tags": ["a", "b"]]), "tags%5B%5D=a&tags%5B%5D=b")
    }

    func testEncodeFormEncodesNestedDictionary() {
        XCTAssertEqual(HttpUtil.encodeForm(["user": ["name": "zzh", "age": 18]]),
                       "user%5Bage%5D=18&user%5Bname%5D=zzh")
    }

    func testEncodeFormEncodesBoolAsNumber() {
        XCTAssertEqual(HttpUtil.encodeForm(["ok": true, "no": false]), "no=0&ok=1")
    }

    // MARK: GET

    func testGetAppendsSortedQuery() {
        perform { cb, fb in
            util.get("http://stub.local/echo", query: ["q": "a b", "n": 1], callback: cb, fail: fb)
        }
        XCTAssertEqual(StubURLProtocol.captured.first?.url, "http://stub.local/echo?n=1&q=a%20b")
        XCTAssertEqual(StubURLProtocol.captured.first?.method, "GET")
        XCTAssertNil(StubURLProtocol.captured.first?.contentType)
    }

    func testGetWithoutQueryDoesNotAppendQuestionMark() {
        perform { cb, fb in util.get("http://stub.local/echo", query: nil, callback: cb, fail: fb) }
        XCTAssertEqual(StubURLProtocol.captured.first?.url, "http://stub.local/echo")
    }

    /// 默认参数回归：删除 Alamofire 重载后，`get(url, callback:fail:)` 必须仍然可用
    func testGetWithOmittedQueryStillSendsRequest() {
        perform { cb, fb in util.get("http://stub.local/echo", callback: cb, fail: fb) }
        XCTAssertEqual(StubURLProtocol.captured.first?.url, "http://stub.local/echo")
        XCTAssertEqual(StubURLProtocol.captured.first?.method, "GET")
    }

    func testGetAppendsWithAmpersandWhenUrlAlreadyHasQuery() {
        perform { cb, fb in
            util.get("http://stub.local/echo?existing=1", query: ["a": 2], callback: cb, fail: fb)
        }
        XCTAssertEqual(StubURLProtocol.captured.first?.url, "http://stub.local/echo?existing=1&a=2")
    }

    func testGetKeepsFragmentAfterQuery() {
        perform { cb, fb in
            util.get("http://stub.local/echo#frag", query: ["a": 1], callback: cb, fail: fb)
        }
        XCTAssertEqual(StubURLProtocol.captured.first?.url, "http://stub.local/echo?a=1#frag")
    }

    // MARK: POST

    func testPostFormEncodingAndContentType() {
        perform { cb, fb in
            util.post("http://stub.local/echo", form: ["q": "a b", "n": 1], callback: cb, fail: fb)
        }
        let captured = StubURLProtocol.captured.first
        XCTAssertEqual(captured?.method, "POST")
        XCTAssertEqual(captured?.contentType, "application/x-www-form-urlencoded; charset=utf-8")
        XCTAssertEqual(captured?.body, "n=1&q=a%20b")
    }

    func testPostWithoutFormSendsNoBodyAndNoContentType() {
        perform { cb, fb in util.post("http://stub.local/echo", callback: cb, fail: fb) }
        XCTAssertNil(StubURLProtocol.captured.first?.body)
        XCTAssertNil(StubURLProtocol.captured.first?.contentType)
    }

    func testPostJSONContentTypeAndBody() {
        perform { cb, fb in
            util.postJSON("http://stub.local/echo", json: ["b": "x", "a": 1], callback: cb, fail: fb)
        }
        let captured = StubURLProtocol.captured.first
        XCTAssertEqual(captured?.method, "POST")
        XCTAssertEqual(captured?.contentType, "application/json")
        let parsed = captured?.body
            .flatMap { $0.data(using: .utf8) }
            .flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
        XCTAssertEqual(parsed?["a"] as? Int, 1)
        XCTAssertEqual(parsed?["b"] as? String, "x")
    }

    func testPostJSONRejectsNonJSONValue() {
        let done = expectation(description: "fail")
        var failMessage: String?
        var succeeded = false
        util.postJSON("http://stub.local/echo", json: ["bad": Date()]) { _ in
            succeeded = true
            done.fulfill()
        } fail: { message in
            failMessage = message
            done.fulfill()
        }
        wait(for: [done], timeout: 10)
        XCTAssertFalse(succeeded)
        XCTAssertNotNil(failMessage)
        XCTAssertTrue(StubURLProtocol.captured.isEmpty, "序列化失败不应发出请求")
    }

    // MARK: 请求头

    func testDefaultUserAgentIsSent() {
        perform { cb, fb in util.get("http://stub.local/echo", callback: cb, fail: fb) }
        XCTAssertTrue(StubURLProtocol.captured.first?.userAgent?.hasPrefix("Mozilla/5.0") == true)
    }

    func testSetHeaderDictionaryReplacesHeaders() {
        util.setHeader(["X-Custom": "1"])
        perform { cb, fb in util.get("http://stub.local/echo", callback: cb, fail: fb) }
        // 旧 UA 被整体替换
        XCTAssertNil(StubURLProtocol.captured.first?.userAgent)
    }

    func testSetUAOverride() {
        util.setUA("MyUA/1.0")
        perform { cb, fb in util.get("http://stub.local/echo", callback: cb, fail: fb) }
        XCTAssertEqual(StubURLProtocol.captured.first?.userAgent, "MyUA/1.0")
    }

    func testSetCookieOverride() {
        util.setCookie("sid=abc")
        perform { cb, fb in util.get("http://stub.local/echo", callback: cb, fail: fb) }
        XCTAssertEqual(StubURLProtocol.captured.first?.cookie, "sid=abc")
        // 设 Cookie 不应影响默认 UA
        XCTAssertTrue(StubURLProtocol.captured.first?.userAgent?.hasPrefix("Mozilla/5.0") == true)
    }

    // MARK: 回调契约

    /// 回归：回调必须在主队列执行。剥离前 Alamofire 的 `responseString` 默认就是 main，
    /// 后台队列回调会让「回调里直接刷 UI」的调用方在 Swift 6 下 trap。
    func testCallbacksRunOnMainQueue() {
        StubURLProtocol.handler = { _ in .success(status: 200, headers: [:], body: Data("ok".utf8)) }
        let done = expectation(description: "callback")
        var isMain = false
        util.get("http://stub.local/echo") { _ in
            isMain = Thread.isMainThread
            done.fulfill()
        } fail: { _ in
            done.fulfill()
        }
        wait(for: [done], timeout: 10)
        XCTAssertTrue(isMain, "成功回调不在主队列")
    }

    /// 失败回调同样在主队列，且是异步的（不会在 `get` 返回前就执行）
    func testFailCallbackIsAsyncOnMainQueue() {
        var returned = false
        var isMainWhenCalled = false
        var calledBeforeReturn = false
        let done = expectation(description: "fail")
        util.get("http://[invalid") { _ in
            done.fulfill()
        } fail: { _ in
            if !returned { calledBeforeReturn = true }
            isMainWhenCalled = Thread.isMainThread
            done.fulfill()
        }
        returned = true
        wait(for: [done], timeout: 10)
        XCTAssertTrue(isMainWhenCalled)
        XCTAssertFalse(calledBeforeReturn, "失败回调不应同步触发")
    }

    // MARK: 响应处理

    func testBodyIsDeliveredToCallback() {
        StubURLProtocol.handler = { _ in
            .success(status: 200, headers: ["Content-Type": "application/json"], body: Data("{\"ok\":true}".utf8))
        }
        let result = perform { cb, fb in util.get("http://stub.local/echo", callback: cb, fail: fb) }
        XCTAssertEqual(result.value, "{\"ok\":true}")
        XCTAssertNil(result.error)
    }

    /// 回归：不调用 validate()，非 2xx 仍走成功回调（旧 Alamofire 行为）
    func testNon2xxGoesToSuccessCallback() {
        StubURLProtocol.handler = { _ in
            .success(status: 404, headers: [:], body: Data("{\"error\":\"not found\"}".utf8))
        }
        let result = perform { cb, fb in util.get("http://stub.local/notfound", callback: cb, fail: fb) }
        XCTAssertNil(result.error, "4xx 不应走失败回调")
        XCTAssertEqual(result.value, "{\"error\":\"not found\"}")
    }

    func testServerErrorAlsoGoesToSuccessCallback() {
        StubURLProtocol.handler = { _ in .success(status: 500, headers: [:], body: Data("boom".utf8)) }
        let result = perform { cb, fb in util.get("http://stub.local/boom", callback: cb, fail: fb) }
        XCTAssertNil(result.error)
        XCTAssertEqual(result.value, "boom")
    }

    func testNetworkErrorGoesToFailCallback() {
        StubURLProtocol.handler = { _ in .failure(URLError(.notConnectedToInternet)) }
        let result = perform { cb, fb in util.get("http://stub.local/echo", callback: cb, fail: fb) }
        XCTAssertNil(result.value)
        XCTAssertTrue(result.error?.hasPrefix("http.get:") == true)
    }

    func testInvalidUTF8ResponseGoesToFailCallback() {
        StubURLProtocol.handler = { _ in
            .success(status: 200, headers: [:], body: Data([0xFF, 0xFE, 0xFD]))
        }
        let result = perform { cb, fb in util.post("http://stub.local/echo", callback: cb, fail: fb) }
        XCTAssertNil(result.value)
        XCTAssertNotNil(result.error)
    }

    func testInvalidUrlGoesToFailCallback() {
        let result = perform { cb, fb in util.get("http://[invalid", callback: cb, fail: fb) }
        XCTAssertNil(result.value)
        XCTAssertTrue(result.error?.hasPrefix("http.get:") == true)
        XCTAssertTrue(StubURLProtocol.captured.isEmpty)
    }
}
