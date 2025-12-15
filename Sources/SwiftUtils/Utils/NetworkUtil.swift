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

        // ✅ 优先使用 iOS 12.1+ 的多卡 API
        let radioTech: String? = {
            if #available(iOS 12.1, *) {
                // 优先取当前蜂窝数据服务对应的制式
                if let dataId = networkInfo.dataServiceIdentifier,
                   let tech = networkInfo.serviceCurrentRadioAccessTechnology?[dataId]
                {
                    return tech
                }
                // 若未获取到 dataServiceIdentifier，则退回任意可用制式
                if let any = networkInfo.serviceCurrentRadioAccessTechnology?.values.first {
                    return any
                }
                return nil
            } else {
                // If the code reaches here, it means the OS is less than iOS 12.1.
                // Given the warning "enclosing scope ensures guard will always be true" for iOS 12.0,
                // this implies the deployment target is iOS 12.0.
                // Therefore, if not iOS 12.1+, it must be iOS 12.0.
                // iOS 12.0：无 dataServiceIdentifier，使用 serviceCurrentRadioAccessTechnology?.values.first
                return networkInfo.serviceCurrentRadioAccessTechnology?.values.first
            }
        }()

        guard let tech = radioTech else { return nil }

        // ✅ 分类映射
        switch tech {
        // 5G
        case CTRadioAccessTechnologyNR, CTRadioAccessTechnologyNRNSA:
            print("当前网络：5G")
            return .is5G

        // 4G
        case CTRadioAccessTechnologyLTE:
            print("当前网络：4G")
            return .is4G

        // 3G
        case CTRadioAccessTechnologyWCDMA,
             CTRadioAccessTechnologyHSDPA,
             CTRadioAccessTechnologyHSUPA,
             CTRadioAccessTechnologyCDMAEVDORev0,
             CTRadioAccessTechnologyCDMAEVDORevA,
             CTRadioAccessTechnologyCDMAEVDORevB,
             CTRadioAccessTechnologyeHRPD:
            print("当前网络：3G")
            return .is3G

        // 2G
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
        // ✅ macOS 没有蜂窝网络
        return nil
        #endif
    }
}

