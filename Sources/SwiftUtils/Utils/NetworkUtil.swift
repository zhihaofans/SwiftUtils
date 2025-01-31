//
//  NetworkUtil.swift
//  SwiftUtils
//
//  Created by zzh on 2025/1/31.
//

import CoreTelephony
import Foundation
import Network

public class NetworkUtil {
    public init() {}
    public func getNetworkType(callback: @escaping (NetworkType?)->Void, fail: @escaping (String)->Void) {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue.global(qos: .background)
        monitor.pathUpdateHandler = { path in
            if path.usesInterfaceType(.wifi) {
                print("当前网络：Wi-Fi")
                callback(.wifi)
            } else if path.usesInterfaceType(.cellular) {
                print("当前网络：蜂窝数据")
                callback(self.getCellularType())
            } else if path.usesInterfaceType(.other) {
                print("当前网络：其他")
                callback(.other)
            } else if path.usesInterfaceType(.wiredEthernet) {
                print("当前网络：以太网")
                callback(.wiredEthernet)
            } else {
                print("无网络连接或未知网络")
                callback(nil)
            }
            monitor.cancel() // **获取一次后立即停止监听**
        }
        monitor.start(queue: queue)
    }

    public func getCellularType()->NetworkType? {
        let networkInfo = CTTelephonyNetworkInfo()
        if let currentRadioTech = networkInfo.serviceCurrentRadioAccessTechnology?.values.first {
            switch currentRadioTech {
            case CTRadioAccessTechnologyNR, CTRadioAccessTechnologyNRNSA:
                print("当前网络：5G")
                return .is5G
            case CTRadioAccessTechnologyLTE:
                print("当前网络：4G")
                return .is4G
            case CTRadioAccessTechnologyLTE:
                print("当前网络：3G")
                return .is3G
            case CTRadioAccessTechnologyEdge:
                print("当前网络：2G")
                return .is2G
            default:
                print("当前网络：未知蜂窝网络")
                return nil
            }
        } else {
            return nil
        }
    }

    public enum NetworkType: String, CaseIterable, Identifiable {
        case is5G, is4G, is3G, is2G, wifi, wiredEthernet, other
        public var id: Self { self }
    }

    public func isWifi(callback: @escaping (Bool)->Void) {
        self.getNetworkType(callback: { networkType in callback(networkType == .wifi) }) { _ in
            callback(false)
        }
    }

    public func is5G(callback: @escaping (Bool)->Void) {
        callback(self.getCellularType() == .is5G)
    }

    public func is4G(callback: @escaping (Bool)->Void) {
        callback(self.getCellularType() == .is4G)
    }

    public func is3G(callback: @escaping (Bool)->Void) {
        callback(self.getCellularType() == .is3G)
    }

    public func is2G(callback: @escaping (Bool)->Void) {
        callback(self.getCellularType() == .is2G)
    }

    public func is5G()->Bool {
        return self.getCellularType() == .is5G
    }

    public func is4G()->Bool {
        return self.getCellularType() == .is4G
    }

    public func is3G()->Bool {
        return self.getCellularType() == .is3G
    }

    public func is2G()->Bool {
        return self.getCellularType() == .is2G
    }
}
