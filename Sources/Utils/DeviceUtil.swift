//
//  DeviceUtil.swift
//
//
//  Created by zzh on 2024/6/18.
//

import Foundation

class DeviceUtil {
    func isMacOS() -> Bool {
        return os(macOS)
    }
    func isIOS() -> Bool {
        return os(iOS)
    }
    func isWatchOS() -> Bool {
        return os(watchOS)
    }
    func isTvOS() -> Bool {
        return os(tvOS)
    }
}
