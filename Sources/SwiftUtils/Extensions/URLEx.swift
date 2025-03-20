//
//  URLEx.swift
//  SwiftUtils
//
//  Created by zzh on 2025/3/17.
//

import Foundation

extension URL {
    var isHTTPS: Bool {
      return self.scheme?.lowercased() == "https"
    }
    var isHTTP: Bool {
      return self.scheme?.lowercased() == "http"
    }
}