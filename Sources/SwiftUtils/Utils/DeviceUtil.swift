//
//  DeviceUtil.swift
//
//
//  Created by zzh on 2024/7/22.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif
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

    public func getSystemVersion() -> String {
        #if os(macOS)
        let processInfo = ProcessInfo.processInfo
        let osVersion = processInfo.operatingSystemVersion
        let versionString = "macOS \(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
        return versionString
        #else
        return UIDevice.current.systemVersion
        #endif
    }

//    let device = UIDevice.current
//    print("Device name: \(device.name)")
//    print("Device model: \(device.model)") // 如 "iPhone", "iPod touch"
//    print("System name: \(device.systemName)")
//    print("System version: \(device.systemVersion)")
    public func getDeviceName() -> String {
        #if os(macOS)
        return "macOS"
        #else
        return UIDevice.current.name
        #endif
    }
    public func getDeviceModel() -> String {
        #if os(macOS)
        return "macOS"
        #else
        return UIDevice.current.isBatteryMonitoringEnabled
        #endif
    }
}
