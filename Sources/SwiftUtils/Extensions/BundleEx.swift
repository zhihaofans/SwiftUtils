//
//  BundleEx.swift
//
//
//  Created by zzh on 2025/10/16.
//

import Foundation

public extension Bundle {
    var versionString: String? {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
    var buildString: String? {
        object(forInfoDictionaryKey: "CFBundleVersion") as? String
    }
    var bundleName: String? {
        object(forInfoDictionaryKey: "CFBundleName") as? String
    }
}