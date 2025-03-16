//
//  ErrorEx.swift
//  SwiftUtils
//
//  Created by zzh on 2025/3/17.
//

import Foundation

extension Error {
    var message: String {
        return (self as? LocalizedError)?.errorDescription ?? ""
    }
}

extension Error? {
    var message: String {
        return (self as? LocalizedError)?.errorDescription ?? ""
    }

    var isError: Bool {
        return self != nil
    }
}
