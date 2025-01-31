//
//  NetworkUtil.swift
//  SwiftUtils
//
//  Created by zzh on 2025/1/31.
//

import Foundation
import Network

public class NetworkUtil {
    public init() {}
    public func getNetworkType(callback: @escaping (InterfaceType?)->Void, fail: @escaping (String)->Void) {
        do {
            let monitor = NWPathMonitor()
            let queue = DispatchQueue.global(qos: .background)
        
            monitor.pathUpdateHandler = { path in
                if path.usesInterfaceType(.wifi) {
                    print("当前网络：Wi-Fi")
                    callback(.wifi)
                } else if path.usesInterfaceType(.cellular) {
                    print("当前网络：蜂窝数据")
                    callback(.cellular)
                } else if path.usesInterfaceType(.other) {
                    print("当前网络：其他")
                    callback(.other)
                } else {
                    print("无网络连接或未知网络")
                    callback(nil)
                }
            }
            monitor.start(queue: queue)
        } catch {
            print (error.localizedDescription)
            fail(error.localizedDescription)
        }
    }
    public func getCellularType(callback: @escaping (CellularNetworkType?)->Void, fail: @escaping (String)->Void) {
        let networkInfo = CTTelephonyNetworkInfo()
        if let currentRadioTech = networkInfo.serviceCurrentRadioAccessTechnology?.values.first {
            switch currentRadioTech {
            case CTRadioAccessTechnologyNR, CTRadioAccessTechnologyNRNSA:
                print("当前网络：5G")
                callback(.5G)
            case CTRadioAccessTechnologyLTE:
                print("当前网络：4G")
                callback(.4G)
            case CTRadioAccessTechnologyLTE:
                print("当前网络：3G")
                callback(.3G)
            case CTRadioAccessTechnologyEdge:
                print("当前网络：2G")
                callback(.2G)
            default:
                print("当前网络：未知蜂窝网络")
                callback(nil)
            }
        }
    }
    public enum CellularNetworkType: String, CaseIterable, Identifiable {
        case 5G,4G,3G,2G
        var id: Self { self }
    }
}
