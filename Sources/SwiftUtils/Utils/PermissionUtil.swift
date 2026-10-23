//
//  PermissionUtil.swift
//  SwiftUtils
//
//  Created by zzh on 2025/1/28.
//

import Foundation

#if os(iOS) || os(macOS)
import AVFoundation
#endif

#if canImport(AppKit)
import AppKit
#endif

#if canImport(Contacts)
import Contacts
#endif

#if canImport(CoreLocation)
import CoreLocation
#endif

#if canImport(EventKit)
import EventKit
#endif

#if canImport(Photos)
import Photos
#endif

#if canImport(UIKit)
import UIKit
#endif

#if canImport(UserNotifications)
import UserNotifications
#endif

/// 权限状态。
///
/// 刻意不用 `Bool`：`没问过`、`用户拒绝`、`系统限制`、`部分授权`、`设备没有这个能力`
/// 在处理方式上完全不同（引导去设置 / 安静降级 / 不打扰），压成一个布尔值之后就分不出来了。
public enum PermissionStatus: Equatable {
    /// 还没弹过系统授权框
    case notDetermined
    /// 完整授权
    case authorized
    /// 部分授权：相册 `.limited`、通知 `.provisional`/`.ephemeral`
    case limited
    /// 用户明确拒绝（应该引导去设置页）
    case denied
    /// 系统限制，用户自己也改不了（MDM、家长控制）
    case restricted
    /// 当前平台/设备没有这个能力（不是拒绝，别引导去开权限）。
    /// 另外：Info.plist 缺 usage description 时 `request` 也会返回这个值（不调系统 API，避免崩溃）
    case unavailable
    /// 未知状态（系统新增的枚举值），不当作拒绝处理
    case unknown

    /// 用户现在能用这项能力吗（部分授权也算能用）
    public var isGranted: Bool {
        self == .authorized || self == .limited
    }
}

/// 需要查询/申请的权限种类。
public enum PermissionKind: Equatable {
    case camera
    case microphone
    /// 只往相册里加，不读（`NSPhotoLibraryAddUsageDescription`）
    case photoLibraryAddOnly
    /// 读写相册，可能是 `.limited`（`NSPhotoLibraryUsageDescription`）
    case photoLibraryReadWrite
    case notifications
    /// 使用 App 期间定位（`NSLocationWhenInUseUsageDescription`）
    case locationWhenInUse
    /// 通讯录（`NSContactsUsageDescription`）
    case contacts
    /// 日历（`NSCalendarsFullAccessUsageDescription` / 旧系统 `NSCalendarsUsageDescription`）
    case calendars
}

/// 权限工具。
///
/// 约定：
/// - **所有回调都在主队列异步执行**，调用方可以直接更新 UI；
/// - `check` 只查询、不弹框；`request` 只在 `.notDetermined` 时才会弹框，
///   其它状态直接把当前结果回调回去；
/// - 平台/设备不支持时返回 `.unavailable`，不会伪装成 `.denied`；
/// - 调用系统 API 前需要 Info.plist 里对应的 usage description（见各 `PermissionKind` 注释），
///   缺 key 时系统会直接杀掉 App，这一步无法在代码里兜底。
public class PermissionUtil {
    public init() {}

    // MARK: - 查询

    /// 当前权限状态，只查询、不弹框。
    public func check(_ kind: PermissionKind, completion: @escaping (PermissionStatus) -> Void) {
        guard isSupported(kind) else {
            Self.deliver(.unavailable, to: completion)
            return
        }

        switch kind {
        case .camera:
            #if os(iOS) || os(macOS)
            Self.deliver(Self.map(AVCaptureDevice.authorizationStatus(for: .video)), to: completion)
            #else
            Self.deliver(.unavailable, to: completion)
            #endif

        case .microphone:
            #if os(iOS) || os(macOS)
            Self.deliver(Self.map(AVCaptureDevice.authorizationStatus(for: .audio)), to: completion)
            #else
            Self.deliver(.unavailable, to: completion)
            #endif

        case .photoLibraryAddOnly:
            #if canImport(Photos)
            Self.deliver(Self.map(PHPhotoLibrary.authorizationStatus(for: .addOnly)), to: completion)
            #else
            Self.deliver(.unavailable, to: completion)
            #endif

        case .photoLibraryReadWrite:
            #if canImport(Photos)
            Self.deliver(Self.map(PHPhotoLibrary.authorizationStatus(for: .readWrite)), to: completion)
            #else
            Self.deliver(.unavailable, to: completion)
            #endif

        case .notifications:
            #if canImport(UserNotifications)
            Self.notificationStatus(completion: completion)
            #else
            Self.deliver(.unavailable, to: completion)
            #endif

        case .locationWhenInUse:
            #if os(iOS) || os(macOS)
            Self.deliver(LocationAuthorizationProbe.shared.status, to: completion)
            #else
            Self.deliver(.unavailable, to: completion)
            #endif

        case .contacts:
            #if canImport(Contacts)
            Self.deliver(Self.map(CNContactStore.authorizationStatus(for: .contacts)), to: completion)
            #else
            Self.deliver(.unavailable, to: completion)
            #endif

        case .calendars:
            #if canImport(EventKit)
            Self.deliver(Self.map(EKEventStore.authorizationStatus(for: .event)), to: completion)
            #else
            Self.deliver(.unavailable, to: completion)
            #endif
        }
    }

    // MARK: - 申请

    /// 申请权限：只有 `.notDetermined` 会真的调用系统 API 弹框，其它状态直接回传当前结果。
    ///
    /// 宿主 Info.plist 缺少对应 usage description 时**不会**调用系统 API（那会直接终止 App），
    /// 而是打错误日志并回调 `.unavailable`。
    public func request(_ kind: PermissionKind, completion: @escaping (PermissionStatus) -> Void) {
        check(kind) { status in
            guard status == .notDetermined else {
                completion(status)
                return
            }
            guard self.hasUsageDescription(for: kind) else {
                let keys = Self.requiredInfoPlistKeys(for: kind).joined(separator: " / ")
                SU.log.error("permission: Info.plist 缺少 \(keys)，调用系统 API 会被直接终止，已跳过请求（kind: \(kind)）")
                Self.deliver(.unavailable, to: completion)
                return
            }
            self.performRequest(kind, completion: completion)
        }
    }

    // MARK: - 跳转设置

    /// 打开系统的权限设置页。
    /// - iOS：本 App 的设置页（系统没有按权限分类的公开深链）
    /// - macOS：系统设置里对应的隐私面板
    /// - watchOS：没有对应入口，返回 `false`
    /// - Returns: 是否成功发起跳转
    @discardableResult
    public func openSettings(for kind: PermissionKind) -> Bool {
        #if os(iOS)
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return false }
        UIApplication.shared.open(url)
        return true
        #elseif os(macOS)
        guard let url = URL(string: Self.macSettingsURL(for: kind)) else { return false }
        return NSWorkspace.shared.open(url)
        #else
        return false
        #endif
    }

    // MARK: - 能力探测

    /// 当前平台/设备是否具备这项能力（与「有没有权限」是两件事）。
    public func isSupported(_ kind: PermissionKind) -> Bool {
        switch kind {
        case .camera:
            #if os(iOS) || os(macOS)
            return AVCaptureDevice.default(for: .video) != nil
            #else
            return false
            #endif

        case .microphone:
            #if os(iOS) || os(macOS)
            return AVCaptureDevice.default(for: .audio) != nil
            #else
            return false
            #endif

        case .photoLibraryAddOnly, .photoLibraryReadWrite:
            #if canImport(Photos)
            return true
            #else
            return false
            #endif

        case .notifications:
            #if canImport(UserNotifications)
            return true
            #else
            return false
            #endif

        case .locationWhenInUse:
            #if os(iOS) || os(macOS)
            return true
            #else
            return false
            #endif

        case .contacts:
            #if canImport(Contacts)
            return true
            #else
            return false
            #endif

        case .calendars:
            #if canImport(EventKit)
            return true
            #else
            return false
            #endif
        }
    }

    // MARK: - Info.plist

    /// 各类权限在宿主 Info.plist 里需要的 usage description key。
    /// 返回多个表示「任一存在即可」（新旧 key 有替换关系）。
    public static func requiredInfoPlistKeys(for kind: PermissionKind) -> [String] {
        switch kind {
        case .camera:
            return ["NSCameraUsageDescription"]
        case .microphone:
            return ["NSMicrophoneUsageDescription"]
        case .photoLibraryAddOnly:
            return ["NSPhotoLibraryAddUsageDescription", "NSPhotoLibraryUsageDescription"]
        case .photoLibraryReadWrite:
            return ["NSPhotoLibraryUsageDescription"]
        case .notifications:
            // 通知不需要 usage description
            return []
        case .locationWhenInUse:
            return ["NSLocationWhenInUseUsageDescription", "NSLocationUsageDescription"]
        case .contacts:
            return ["NSContactsUsageDescription"]
        case .calendars:
            return ["NSCalendarsFullAccessUsageDescription", "NSCalendarsUsageDescription"]
        }
    }

    /// 判断 Info.plist 是否配了这个权限需要的 key。
    /// `info` 可注入，方便单测；默认读宿主的 `Bundle.main`。
    func hasUsageDescription(for kind: PermissionKind, info: [String: Any]? = Bundle.main.infoDictionary) -> Bool {
        let keys = Self.requiredInfoPlistKeys(for: kind)
        guard !keys.isEmpty else { return true }
        return keys.contains { key in
            guard let value = info?[key] as? String else { return false }
            return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    // MARK: - 私有实现

    private func performRequest(_ kind: PermissionKind, completion: @escaping (PermissionStatus) -> Void) {
        switch kind {
        case .camera:
            #if os(iOS) || os(macOS)
            AVCaptureDevice.requestAccess(for: .video) { _ in
                // 回调里只有 Bool，统一重新查一次状态，避免 restricted/unknown 被压平
                Self.deliver(Self.map(AVCaptureDevice.authorizationStatus(for: .video)), to: completion)
            }
            #else
            Self.deliver(.unavailable, to: completion)
            #endif

        case .microphone:
            #if os(iOS) || os(macOS)
            AVCaptureDevice.requestAccess(for: .audio) { _ in
                Self.deliver(Self.map(AVCaptureDevice.authorizationStatus(for: .audio)), to: completion)
            }
            #else
            Self.deliver(.unavailable, to: completion)
            #endif

        case .photoLibraryAddOnly:
            #if canImport(Photos)
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                Self.deliver(Self.map(status), to: completion)
            }
            #else
            Self.deliver(.unavailable, to: completion)
            #endif

        case .photoLibraryReadWrite:
            #if canImport(Photos)
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                Self.deliver(Self.map(status), to: completion)
            }
            #else
            Self.deliver(.unavailable, to: completion)
            #endif

        case .notifications:
            #if canImport(UserNotifications)
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
                // 用 getNotificationSettings 而不是 granted 布尔值，才能区分 provisional
                Self.notificationStatus(completion: completion)
            }
            #else
            Self.deliver(.unavailable, to: completion)
            #endif

        case .locationWhenInUse:
            #if os(iOS) || os(macOS)
            LocationAuthorizationProbe.shared.request { status in
                Self.deliver(status, to: completion)
            }
            #else
            Self.deliver(.unavailable, to: completion)
            #endif

        case .contacts:
            #if canImport(Contacts)
            CNContactStore().requestAccess(for: .contacts) { _, _ in
                Self.deliver(Self.map(CNContactStore.authorizationStatus(for: .contacts)), to: completion)
            }
            #else
            Self.deliver(.unavailable, to: completion)
            #endif

        case .calendars:
            #if canImport(EventKit)
            let store = EKEventStore()
            if #available(iOS 17.0, macOS 14.0, watchOS 10.0, *) {
                store.requestFullAccessToEvents { _, _ in
                    Self.deliver(Self.map(EKEventStore.authorizationStatus(for: .event)), to: completion)
                }
            } else {
                // macOS 12/13 上只有这个旧 API；走 #available 的 else 分支不会触发废弃警告
                store.requestAccess(to: .event) { _, _ in
                    Self.deliver(Self.map(EKEventStore.authorizationStatus(for: .event)), to: completion)
                }
            }
            #else
            Self.deliver(.unavailable, to: completion)
            #endif
        }
    }

    // MARK: - 设置页地址（macOS）

    /// macOS 系统设置里对应隐私面板的 anchor
    private static func macSettingsURL(for kind: PermissionKind) -> String {
        let anchor: String?
        switch kind {
        case .camera: anchor = "Privacy_Camera"
        case .microphone: anchor = "Privacy_Microphone"
        case .photoLibraryAddOnly, .photoLibraryReadWrite: anchor = "Privacy_Photos"
        case .locationWhenInUse: anchor = "Privacy_LocationServices"
        case .contacts: anchor = "Privacy_Contacts"
        case .calendars: anchor = "Privacy_Calendars"
        case .notifications: anchor = nil
        }

        guard let anchor else {
            // 通知没有隐私面板，在「通知」设置页里
            if #available(macOS 13.0, *) {
                return "x-apple.systempreferences:com.apple.Notifications-Settings.extension"
            }
            return "x-apple.systempreferences:com.apple.preference.notifications"
        }
        // macOS 13 起系统设置换了 bundle id，旧链接会重定向但直接给新的更稳
        if #available(macOS 13.0, *) {
            return "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?\(anchor)"
        }
        return "x-apple.systempreferences:com.apple.preference.security?\(anchor)"
    }

    /// 通知状态只能异步取；`UNUserNotificationCenter.current()` 在无 App bundle 的进程里会抛异常，
    /// 所以只在真正调用时取，不放在存储属性里。
    #if canImport(UserNotifications)
    private static func notificationStatus(completion: @escaping (PermissionStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            deliver(map(settings.authorizationStatus), to: completion)
        }
    }
    #endif

    /// 统一主队列异步回调
    private static func deliver(_ status: PermissionStatus, to completion: @escaping (PermissionStatus) -> Void) {
        DispatchQueue.main.async { completion(status) }
    }

    // MARK: - 状态映射（internal 供测试逐 case 钉住）

    #if os(iOS) || os(macOS)
    static func map(_ status: AVAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        @unknown default: return .unknown
        }
    }
    #endif

    #if canImport(Photos)
    static func map(_ status: PHAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized: return .authorized
        case .limited: return .limited
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        @unknown default: return .unknown
        }
    }
    #endif

    #if canImport(UserNotifications)
    static func map(_ status: UNAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized: return .authorized
        // provisional：不打扰用户的临时授权；ephemeral 是 App Clip 专用（仅 iOS），都算「部分可用」
        case .provisional: return .limited
        #if os(iOS)
        case .ephemeral: return .limited
        #endif
        case .denied: return .denied
        case .notDetermined: return .notDetermined
        @unknown default: return .unknown
        }
    }
    #endif

    #if canImport(CoreLocation)
    static func map(_ status: CLAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .denied
        // macOS 只有 authorizedAlways（没有 WhenInUse，请求 whenInUse 也会落到这里）
        case .authorizedAlways: return .authorized
        #if os(iOS) || os(watchOS)
        case .authorizedWhenInUse: return .authorized
        #endif
        @unknown default: return .unknown
        }
    }
    #endif

    #if canImport(Contacts)
    static func map(_ status: CNAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        default:
            // .limited（只允许访问用户挑选的联系人）从 iOS 18 才有，且 macOS 上没有
            #if os(iOS)
            if #available(iOS 18.0, *) {
                if status == .limited { return .limited }
            }
            #endif
            return .unknown
        }
    }
    #endif

    #if canImport(EventKit)
    static func map(_ status: EKAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        default:
            // 用 rawValue 比较：EKAuthorizationStatusAuthorized 在 iOS 17 / macOS 14 起已废弃，
            // 且它的值就等于 EKAuthorizationStatusFullAccess（3）；writeOnly 是 4
            switch status.rawValue {
            case 3: return .authorized
            case 4: return .limited
            default: return .unknown
            }
        }
    }
    #endif
}

#if os(iOS) || os(macOS)
/// 定位授权必须有活着的 `CLLocationManager` 和 delegate 才拿得到结果，
/// 用单例把它留住，避免请求发出后对象被释放、回调丢失。
///
/// 已知限制：如果用户把系统弹框一直挂在那里不选，`completion` 会一直不回调。
private final class LocationAuthorizationProbe: NSObject, CLLocationManagerDelegate {
    static let shared = LocationAuthorizationProbe()

    private let manager = CLLocationManager()
    /// 同时有多个请求方时不能只留最后一个，否则前一个调用方的回调永远不来
    private var completions: [(PermissionStatus) -> Void] = []

    private override init() {
        super.init()
        manager.delegate = self
    }

    /// 注意：读这个属性不会弹框，但创建过 manager 之后系统可能记一次「访问过定位」
    var status: PermissionStatus {
        PermissionUtil.map(manager.authorizationStatus)
    }

    func request(completion: @escaping (PermissionStatus) -> Void) {
        completions.append(completion)
        manager.requestWhenInUseAuthorization()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard !completions.isEmpty else { return }
        let status = PermissionUtil.map(manager.authorizationStatus)
        // 设置 delegate 时会先回调一次初始状态（notDetermined），那不代表用户选择，继续等
        guard status != .notDetermined else { return }
        let pending = completions
        completions.removeAll()
        pending.forEach { $0(status) }
    }
}
#endif
