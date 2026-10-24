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

public final class NetworkUtil: Sendable {
    /// 网络类型探测的超时时间：NWPathMonitor 可能永远不回调
    private static let timeout: TimeInterval = 5

    public init() {}

    // MARK: - Types

    public enum NetworkType: String, CaseIterable, Identifiable {
        case is5G, is4G, is3G, is2G, wifi, wiredEthernet, other
        public var id: Self { self }
    }

    // MARK: - Public API

    /// 异步获取当前网络类型；无网络/未知时回调 `nil`。
    ///
    /// `NWPathMonitor` 偶尔不会给出任何路径更新（比如刚启动就断网、网络状态一直抖动），
    /// 所以超过 `timeout` 秒没有结果会走 `fail`，避免调用方一直等一个永远不会来的回调。
    ///
    /// - Note: 回调在 Network 框架的后台队列上执行，因此闭包标记为 `@Sendable`。
    ///   若调用方开启了 `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`，未标注的闭包会隐式
    ///   继承主线程隔离，而这里是在后台队列调用，Swift 6 运行时隔离检查会直接 trap
    ///   （`dispatch_assert_queue_fail`）—— 这是运行时崩溃，编译期不会报错。
    public func getNetworkType(
        callback: @escaping @Sendable (NetworkType?) -> Void,
        fail: @escaping @Sendable (String) -> Void
    ) {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "github.zhihaofans.swiftutils.network", qos: .background)
        // 成功回调和超时只能有一个生效，否则调用方会收到两次结果
        let gate = CallbackGate()

        let timeout = DispatchWorkItem {
            guard gate.fire() else { return }
            monitor.cancel()
            SU.log.error("获取网络类型超时")
            fail("获取网络类型超时")
        }
        queue.asyncAfter(deadline: .now() + Self.timeout, execute: timeout)

        // 仅回调一次后停止
        monitor.pathUpdateHandler = { [weak self] path in
            guard gate.fire() else { return }
            timeout.cancel()
            monitor.cancel()

            guard path.status == .satisfied else {
                SU.log.info("无网络连接或未知网络")
                callback(nil)
                return
            }

            if path.usesInterfaceType(.wifi) {
                SU.log.info("当前网络：Wi-Fi")
                callback(.wifi)
                return
            }

            if path.usesInterfaceType(.wiredEthernet) {
                SU.log.info("当前网络：以太网")
                callback(.wiredEthernet)
                return
            }

            if path.usesInterfaceType(.cellular) {
                #if os(iOS) || targetEnvironment(macCatalyst)
                SU.log.info("当前网络：蜂窝数据")
                callback(self?.getCellularType())
                #else
                // 纯 macOS 基本不会出现 cellular；兜底为 other
                SU.log.error("当前网络：其他（macOS 无蜂窝）")
                callback(.other)
                #endif
                return
            }

            if path.usesInterfaceType(.other) {
                SU.log.info("当前网络：其他")
                callback(.other)
                return
            }

            // 正常不会到这里，保险兜底
            SU.log.error("无网络连接或未知网络")
            callback(nil)
        }

        monitor.start(queue: queue)
    }

    // MARK: - Convenience checks (跨平台一致接口)

    public func isWifi(callback: @escaping @Sendable (Bool) -> Void) {
        getNetworkType(callback: { @Sendable value in callback(value == .wifi) },
                       fail: { @Sendable _ in callback(false) })
    }

    // 这四个以前是同步回调，`isWifi` 却是异步的——同一个类型里两套时序，
    // 调用方按同步写就会在回调用不到的地方读到旧值。这里统一改成异步，
    // 顺便把 CTTelephonyNetworkInfo 的查询挪出调用方线程。
    public func is5G(callback: @escaping @Sendable (Bool) -> Void) {
        DispatchQueue.global(qos: .background).async { callback(self.is5G()) }
    }

    public func is4G(callback: @escaping @Sendable (Bool) -> Void) {
        DispatchQueue.global(qos: .background).async { callback(self.is4G()) }
    }

    public func is3G(callback: @escaping @Sendable (Bool) -> Void) {
        DispatchQueue.global(qos: .background).async { callback(self.is3G()) }
    }

    public func is2G(callback: @escaping @Sendable (Bool) -> Void) {
        DispatchQueue.global(qos: .background).async { callback(self.is2G()) }
    }

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
            SU.log.info("当前网络：5G")
            return .is5G

        // 4G
        case CTRadioAccessTechnologyLTE:
            SU.log.info("当前网络：4G")
            return .is4G

        // 3G
        case CTRadioAccessTechnologyWCDMA,
             CTRadioAccessTechnologyHSDPA,
             CTRadioAccessTechnologyHSUPA,
             CTRadioAccessTechnologyCDMAEVDORev0,
             CTRadioAccessTechnologyCDMAEVDORevA,
             CTRadioAccessTechnologyCDMAEVDORevB,
             CTRadioAccessTechnologyeHRPD:
            SU.log.info("当前网络：3G")
            return .is3G

        // 2G
        case CTRadioAccessTechnologyGPRS,
             CTRadioAccessTechnologyEdge,
             CTRadioAccessTechnologyCDMA1x:
            SU.log.info("当前网络：2G")
            return .is2G

        default:
            SU.log.info("当前网络：未知蜂窝网络(\(tech))")
            return nil
        }
        #else
        // ✅ macOS 没有蜂窝网络
        return nil
        #endif
    }
}

/// 保证「成功」和「超时」只有一条路径能真正回调
private final class CallbackGate: @unchecked Sendable {
    private let lock = NSLock()
    private var fired = false

    /// - Returns: 第一次调用返回 `true`，之后的调用都返回 `false`
    func fire() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !fired else { return false }
        fired = true
        return true
    }
}
