//
//  DeviceUtil.swift
//
//
//  Created by zzh on 2024/7/22.
//

import AVFoundation
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
        return UIDevice.current.model
        #endif
    }

    public func startToGetBatteryLevel() {
        #if os(iOS)
        // 当系统为ios时才有效
        UIDevice.current.isBatteryMonitoringEnabled = true
        #endif
    }

    public func stopToGetBatteryLevel() {
        #if os(iOS)
        // 当系统为ios时才有效
        UIDevice.current.isBatteryMonitoringEnabled = false
        #endif
    }

    public func getBatteryLevel() -> Int {
        // 获取成功为0-100的Int，获取失败则为-1
        #if os(macOS)
        let process = Process()
        let pipe = Pipe()

        // 设置要运行的命令，这里是 system_profiler，路径为 /usr/sbin/system_profiler
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        // 设置命令的参数，只获取电源相关的数据
        process.arguments = ["SPPowerDataType"]
        // 设置输出管道，将命令的输出重定向到这个管道
        process.standardOutput = pipe
        do {
            // 启动进程
            try process.run()
            // 等待进程完成
            process.waitUntilExit()

            // 从管道读取数据，转换为字符串
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                print(output)
                // 解析电池信息
                let lines = output.split(separator: "\n")
                var batteryFull = 0
                var batteryNow = 0
                var batteryLevel = 0
                for line in lines {
                    // 查找并打印剩余电量
                    if line.contains("Charge Remaining (mAh):") {
                        print(line.trimmingCharacters(in: .whitespaces))
                        batteryNow = Int(line.trimmingCharacters(in: .whitespaces)) ?? -1
                    }
                    // 查找并打印是否充满电
                    if line.contains("Fully Charged:") {
                        print(line.trimmingCharacters(in: .whitespaces))
                    }
                    // 查找并打印是否正在充电
                    if line.contains("Charging:") {
                        print(line.trimmingCharacters(in: .whitespaces))
                    }
                    // 查找并打印满充电量
                    if line.contains("Full Charge Capacity (mAh):") {
                        print(line.trimmingCharacters(in: .whitespaces))
                        batteryFull = Int(line.trimmingCharacters(in: .whitespaces)) ?? -1
                    }
                    // 查找并打印满充电量
                    if line.contains("State of Charge (%):") {
                        print(line.trimmingCharacters(in: .whitespaces))
                        batteryLevel = Int(line.trimmingCharacters(in: .whitespaces)) ?? -1
                    }
                }
//                if batteryNow <= 0 || batteryFull <= 0 {
//                    return -1
//                } else {
//                    return Int((batteryNow / batteryFull) * 100)
//                }
                return batteryLevel
            } else {
                return -1
            }
        } catch {
            // 如果命令执行失败，打印错误信息
            print("Failed to fetch battery info: \(error)")
            return -1
        }
        #else
        // 获取电池电量
        let batteryLevel: Float = UIDevice.current.batteryLevel
        if batteryLevel < 0 {
            print("无法读取电池电量")
            return -1
        } else {
            let batteryPercentage = batteryLevel * 100
            print("当前电池电量为：\(batteryPercentage)%")
            return Int(batteryPercentage)
        }
        #endif
    }
    public func isDeviceBatteryCharging() -> Bool {
    UIDevice.current.isBatteryMonitoringEnabled = true // 开启监测
    let charging = UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full
    UIDevice.current.isBatteryMonitoringEnabled = false // 关闭监测，避免不必要的监听
        return charging
    }
    public func getScreenBrightness() -> Double {
        #if os(iOS)
        return UIScreen.main.brightness
        #else
        // TODO: 支持macOS
        return 0
        #endif
    }

    public func setScreenBrightness(brightness: Double) {
        #if os(iOS)
        if brightness >= 0.0 || brightness <= 1.0 {
            UIScreen.main.brightness = brightness
        }
        #else
        // TODO: 支持macOS
        #endif
    }

    public func toggleFlashlight() -> Bool {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else {
            // 如果设备不支持闪光灯，返回 false
            return false
        }

        do {
            try device.lockForConfiguration()

            if device.torchMode == .on {
                // 如果闪光灯已经打开，关闭它
                device.torchMode = .off
                device.unlockForConfiguration()
                return true // 成功关闭
            } else {
                // 如果闪光灯没有打开，打开它
                try device.setTorchModeOn(level: 1.0) // 最大亮度
                device.unlockForConfiguration()
                return true // 成功打开
            }
        } catch {
            // 捕获错误，如果无法操作闪光灯，返回 false
            print("无法操作闪光灯: \(error)")
            return false
        }
    }
}
