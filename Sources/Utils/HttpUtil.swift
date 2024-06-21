//
//  HttpUtil.swift
//
//
//  Created by zzh on 2024/6/21.
//
import Foundation
import Alamofire

public class HttpUtil {
    public init() {}

    public func getString(url:String) {
      AF.request(url).responseString { response in
            do {
                switch response.result {
                case let .success(value):
                   callback(value)
                    
                case let .failure(error):
                    print(error)
                    fail(error.localizedDescription)
                }
            } catch {
                print("HttpUtil.getString.error")
                fail("网络请求错误")
            }
        }
    }
}
