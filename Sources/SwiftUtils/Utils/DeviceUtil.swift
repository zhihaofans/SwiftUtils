//
//  DeviceUtil.swift
//
//
//  Created by zzh on 2024/7/22.
//
import AVFoundation
import Foundation
import LocalAuthentication

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

#if os(macOS)
import Darwin
import IOKit
import IOKit.ps
#endif

public class DeviceUtil {
    public init() {}

    // MARK: - Platform checks

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

    // MARK: - System / Device

    public func getSystemVersion() -> String {
        #if os(macOS)
        let v = ProcessInfo.processInfo.operatingSystemVersion
        return "macOS \(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
        #else
        #if canImport(UIKit)
        return UIDevice.current.systemVersion
        #else
        return "Unknown"
        #endif
        #endif
    }

    public func getDeviceName() -> String {
        #if os(macOS)
        return Host.current().localizedName ?? "Mac"
        #else
        #if canImport(UIKit)
        return UIDevice.current.name
        #else
        return "Unknown"
        #endif
        #endif
    }

    public func getDeviceModel() -> String {
        #if os(macOS)
        // e.g. "MacBookPro18,3"
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var buf = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &buf, &size, nil, 0)
        return String(cString: buf)
        #else
        #if canImport(UIKit)
        return UIDevice.current.model
        #else
        return "Unknown"
        #endif
        #endif
    }

    // MARK: - Battery (start/stop for iOS)

    public func startToGetBatteryLevel() {
        #if canImport(UIKit)
        UIDevice.current.isBatteryMonitoringEnabled = true
        #endif
    }

    public func stopToGetBatteryLevel() {
        #if canImport(UIKit)
        UIDevice.current.isBatteryMonitoringEnabled = false
        #endif
    }

    /// 获取电池电量（0-100）；获取失败返回 -1
    public func getBatteryLevel() -> Int {
        #if os(macOS)
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let list = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef],
              !list.isEmpty
        else { return -1 }

        for ps in list {
            if let desc = IOPSGetPowerSourceDescription(info, ps)?.takeUnretainedValue() as? [String: Any],
               let type = desc[kIOPSTypeKey as String] as? String,
               type == (kIOPSInternalBatteryType as String),
               let cur = desc[kIOPSCurrentCapacityKey as String] as? Int,
               let maxCap = desc[kIOPSMaxCapacityKey as String] as? Int,
               maxCap > 0
            {
                let pct = Int(round(Double(cur) / Double(maxCap) * 100.0))
                return Swift.min(Swift.max(pct, 0), 100)
            }
        }
        return -1
        #else
        #if canImport(UIKit)
        let level = UIDevice.current.batteryLevel
        guard level >= 0 else { return -1 }
        return Int(level * 100.0)
        #else
        return -1
        #endif
        #endif
    }

    /// 是否正在充电（或已充满）
    public func isDeviceBatteryCharging() -> Bool {
        #if os(macOS)
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let list = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef]
        else { return false }

        for ps in list {
            if let desc = IOPSGetPowerSourceDescription(info, ps)?.takeUnretainedValue() as? [String: Any],
               let type = desc[kIOPSTypeKey as String] as? String,
               type == (kIOPSInternalBatteryType as String)
            {
                // 优先使用 kIOPSIsChargingKey；如果没有，再根据状态判断
                if let charging = desc[kIOPSIsChargingKey as String] as? Bool {
                    return charging
                }
                if let state = desc[kIOPSPowerSourceStateKey as String] as? String {
                    // "AC Power" 通常表示连电，可能在充电或已充满
                    return state == (kIOPSACPowerValue as String)
                }
            }
        }
        return false
        #else
        #if canImport(UIKit)
        UIDevice.current.isBatteryMonitoringEnabled = true
        defer { UIDevice.current.isBatteryMonitoringEnabled = false }
        let s = UIDevice.current.batteryState
        return s == .charging || s == .full
        #else
        return false
        #endif
        #endif
    }

    // MARK: - Screen brightness

    /// 获取屏幕亮度（0~1）。macOS 出于公开 API 限制返回 0。
    public func getScreenBrightness() -> Double {
        #if canImport(UIKit)
        return Double(UIScreen.main.brightness)
        #else
        // macOS 没有公开可上架的全局亮度 API
        return 0
        #endif
    }

    /// 设置屏幕亮度。macOS 保持 no-op（避免使用私有 API）。
    public func setScreenBrightness(brightness: Double) {
        #if canImport(UIKit)
        guard brightness >= 0.0, brightness <= 1.0 else { return }
        UIScreen.main.brightness = CGFloat(brightness)
        #else
        // macOS: 不做处理（避免私有 API）
        #endif
    }

    // MARK: - Torch (iOS only)

    public func toggleFlashlight() -> Bool {
        #if canImport(UIKit)
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else {
            return false
        }
        do {
            try device.lockForConfiguration()
            if device.torchMode == .on {
                device.torchMode = .off
            } else {
                try device.setTorchModeOn(level: 1.0)
            }
            device.unlockForConfiguration()
            return true
        } catch {
            print("无法操作闪光灯: \(error)")
            return false
        }
        #else
        // macOS 无手电筒
        return false
        #endif
    }

    // MARK: - Biometric

    public func hasFaceID() -> Bool {
        return AuthUtil().hasFaceID()
    }

    public func hasTouchID() -> Bool {
        return AuthUtil().hasTouchID()
    }
}
