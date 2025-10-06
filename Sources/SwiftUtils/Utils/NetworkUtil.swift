//
//  NetworkUtil.swift
//  SwiftUtils
//
//  Created by zzh on 2025/1/31.
//
import Foundation
import Network

#if os(iOS) || targetEnvironment(macCatalyst)
import CoreTelephony
#endif

public final class NetworkUtil {
    public init() {}

    // MARK: - Types

    public enum NetworkType: String, CaseIterable, Identifiable {
        case is5G, is4G, is3G, is2G, wifi, wiredEthernet, other
        public var id: Self { self }
    }

    // MARK: - Public API

    /// 异步获取当前网络类型；无网络/未知时回调 `nil`
    public func getNetworkType(
        callback: @escaping (NetworkType?) -> Void,
        fail: @escaping (String) -> Void
    ) {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue.global(qos: .background)

        // 仅回调一次后停止
        monitor.pathUpdateHandler = { [weak self] path in
            defer { monitor.cancel() }

            guard path.status == .satisfied else {
                print("无网络连接或未知网络")
                callback(nil)
                return
            }

            if path.usesInterfaceType(.wifi) {
                print("当前网络：Wi-Fi")
                callback(.wifi)
                return
            }

            if path.usesInterfaceType(.wiredEthernet) {
                print("当前网络：以太网")
                callback(.wiredEthernet)
                return
            }

            if path.usesInterfaceType(.cellular) {
                #if os(iOS) || targetEnvironment(macCatalyst)
                print("当前网络：蜂窝数据")
                callback(self?.getCellularType())
                #else
                // 纯 macOS 基本不会出现 cellular；兜底为 other
                print("当前网络：其他（macOS 无蜂窝）")
                callback(.other)
                #endif
                return
            }

            if path.usesInterfaceType(.other) {
                print("当前网络：其他")
                callback(.other)
                return
            }

            // 正常不会到这里，保险兜底
            print("无网络连接或未知网络")
            callback(nil)
        }

        monitor.start(queue: queue)
    }

    // MARK: - Convenience checks (跨平台一致接口)

    public func isWifi(callback: @escaping (Bool) -> Void) {
        getNetworkType(callback: { callback($0 == .wifi) }, fail: { _ in callback(false) })
    }

    public func is5G(callback: @escaping (Bool) -> Void) { callback(is5G()) }
    public func is4G(callback: @escaping (Bool) -> Void) { callback(is4G()) }
    public func is3G(callback: @escaping (Bool) -> Void) { callback(is3G()) }
    public func is2G(callback: @escaping (Bool) -> Void) { callback(is2G()) }

    public func is5G() -> Bool {
        #if os(iOS) || targetEnvironment(macCatalyst)
        return getCellularType() == .is5G
        #else
        return false
        #endif
    }

    public func is4G() -> Bool {
        #if os(iOS) || targetEnvironment(macCatalyst)
        return getCellularType() == .is4G
        #else
        return false
        #endif
    }

    public func is3G() -> Bool {
        #if os(iOS) || targetEnvironment(macCatalyst)
        return getCellularType() == .is3G
        #else
        return false
        #endif
    }

    public func is2G() -> Bool {
        #if os(iOS) || targetEnvironment(macCatalyst)
        return getCellularType() == .is2G
        #else
        return false
        #endif
    }

    // MARK: - Cellular (iOS/Catalyst only)

    /// 返回当前蜂窝网络类型；在 macOS 下恒为 `nil`
    public func getCellularType() -> NetworkType? {
        #if os(iOS) || targetEnvironment(macCatalyst)
        let networkInfo = CTTelephonyNetworkInfo()

        // iOS 12+ 使用 service* API 支持多 SIM
        let radioTech: String? = {
            if let values = networkInfo.serviceCurrentRadioAccessTechnology?.values, let first = values.first {
                return first
            }
            // 兜底（老系统）：
            return networkInfo.currentRadioAccessTechnology
        }()

        guard let tech = radioTech else { return nil }

        switch tech {
        // 5G
        case CTRadioAccessTechnologyNR, CTRadioAccessTechnologyNRNSA:
            print("当前网络：5G")
            return .is5G

        // 4G
        case CTRadioAccessTechnologyLTE:
            print("当前网络：4G")
            return .is4G

        // 3G（含 WCDMA/H/HSDPA/HSUPA/CDMAEVDO）
        case CTRadioAccessTechnologyWCDMA,
             CTRadioAccessTechnologyHSDPA,
             CTRadioAccessTechnologyHSUPA,
             CTRadioAccessTechnologyCDMAEVDORev0,
             CTRadioAccessTechnologyCDMAEVDORevA,
             CTRadioAccessTechnologyCDMAEVDORevB,
             CTRadioAccessTechnologyeHRPD:
            print("当前网络：3G")
            return .is3G

        // 2G（GPRS/EDGE/CDMA1x）
        case CTRadioAccessTechnologyGPRS,
             CTRadioAccessTechnologyEdge,
             CTRadioAccessTechnologyCDMA1x:
            print("当前网络：2G")
            return .is2G

        default:
            print("当前网络：未知蜂窝网络(\(tech))")
            return nil
        }
        #else
        return nil
        #endif
    }
}
