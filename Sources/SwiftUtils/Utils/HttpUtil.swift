//
//  HttpUtil.swift
//
//
//  Created by zzh on 2024/7/23.
//

import Alamofire
import Foundation

public class HttpUtil {
    private var headers: HTTPHeaders
    public init() {
        self.headers = ["User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 14_5 like Mac OS X) AppleWebKit/630.3 (KHTML, like Gecko) Version/14.5.21 Mobile/4QKLI4 Safari/630.3"]
    }

    public func setHeader(_ newHeaders: HTTPHeaders) {
        self.headers = newHeaders
    }

    public func setUA(_ newValue: String) {
        self.headers.update(name: "User-Agent", value: newValue)
    }

    public func setCookie(_ newValue: String) {
        self.headers.update(name: "Cookie", value: newValue)
    }

    public func get(_ url: String, callback: @escaping (String)->Void, fail: @escaping (String)->Void) {
        AF.request(url, headers: self.headers).responseString { response in
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
        AF.request(url, method: .post, parameters: body, headers: self.headers).responseString { response in
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
