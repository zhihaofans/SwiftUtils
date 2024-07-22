//
//  DeviceUtil.swift
//
//
//  Created by zzh on 2024/7/22.
//

import Foundation

public class DeviceUtil {
    public init() {}

    
    public func isMac() -> Bool {
        #if os(macOS)
        return true
        #else
        return false
        #endif
    }
    public func isWatch() -> Bool {
        #if os(watchOS)
        return true
        #else
        return false
        #endif
    }
}
