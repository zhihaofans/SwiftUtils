import XCTest
@testable import SwiftUtils

#if os(iOS) || os(macOS)
import AVFoundation
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
#if canImport(UserNotifications)
import UserNotifications
#endif

final class PermissionUtilTests: XCTestCase {
    // MARK: 状态语义

    func testIsGrantedSemantics() {
        XCTAssertTrue(PermissionStatus.authorized.isGranted)
        // 部分授权（相册 limited / 通知 provisional）也是能用
        XCTAssertTrue(PermissionStatus.limited.isGranted)

        let notGranted: [PermissionStatus] = [.notDetermined, .denied, .restricted, .unavailable, .unknown]
        for status in notGranted {
            XCTAssertFalse(status.isGranted, "\(status) 不该被当成已授权")
        }
    }

    // MARK: 系统枚举 → PermissionStatus
    //
    // 这些映射是唯一能在单测里钉住的部分：真实 TCC 弹框只能在真机/模拟器手动验证。
    // 每个 case 都要覆盖，包括 .limited / .provisional——上一版就是把它们漏掉了。

    #if os(iOS) || os(macOS)
    func testMapCameraStatus() {
        XCTAssertEqual(PermissionUtil.map(AVAuthorizationStatus.authorized), .authorized)
        XCTAssertEqual(PermissionUtil.map(AVAuthorizationStatus.denied), .denied)
        XCTAssertEqual(PermissionUtil.map(AVAuthorizationStatus.restricted), .restricted)
        XCTAssertEqual(PermissionUtil.map(AVAuthorizationStatus.notDetermined), .notDetermined)
    }
    #endif

    #if canImport(Photos)
    func testMapPhotoLibraryStatus() {
        XCTAssertEqual(PermissionUtil.map(PHAuthorizationStatus.authorized), .authorized)
        XCTAssertEqual(PermissionUtil.map(PHAuthorizationStatus.limited), .limited)
        XCTAssertEqual(PermissionUtil.map(PHAuthorizationStatus.denied), .denied)
        XCTAssertEqual(PermissionUtil.map(PHAuthorizationStatus.restricted), .restricted)
        XCTAssertEqual(PermissionUtil.map(PHAuthorizationStatus.notDetermined), .notDetermined)
    }
    #endif

    #if canImport(UserNotifications)
    func testMapNotificationStatus() {
        XCTAssertEqual(PermissionUtil.map(UNAuthorizationStatus.authorized), .authorized)
        XCTAssertEqual(PermissionUtil.map(UNAuthorizationStatus.denied), .denied)
        XCTAssertEqual(PermissionUtil.map(UNAuthorizationStatus.notDetermined), .notDetermined)
        // 回归：这两种以前被当成「未授权」，用户明明收得到通知
        XCTAssertEqual(PermissionUtil.map(UNAuthorizationStatus.provisional), .limited)
        #if os(iOS)
        XCTAssertEqual(PermissionUtil.map(UNAuthorizationStatus.ephemeral), .limited)
        #endif
    }
    #endif

    #if canImport(CoreLocation)
    func testMapLocationStatus() {
        XCTAssertEqual(PermissionUtil.map(CLAuthorizationStatus.notDetermined), .notDetermined)
        #if !os(macOS)
        XCTAssertEqual(PermissionUtil.map(CLAuthorizationStatus.authorizedWhenInUse), .authorized)
        #endif
        XCTAssertEqual(PermissionUtil.map(CLAuthorizationStatus.authorizedAlways), .authorized)
        XCTAssertEqual(PermissionUtil.map(CLAuthorizationStatus.denied), .denied)
        XCTAssertEqual(PermissionUtil.map(CLAuthorizationStatus.restricted), .restricted)
    }
    #endif

    #if canImport(Contacts)
    func testMapContactsStatus() {
        XCTAssertEqual(PermissionUtil.map(CNAuthorizationStatus.notDetermined), .notDetermined)
        XCTAssertEqual(PermissionUtil.map(CNAuthorizationStatus.authorized), .authorized)
        XCTAssertEqual(PermissionUtil.map(CNAuthorizationStatus.denied), .denied)
        XCTAssertEqual(PermissionUtil.map(CNAuthorizationStatus.restricted), .restricted)
        #if os(iOS)
        if #available(iOS 18.0, *) {
            XCTAssertEqual(PermissionUtil.map(CNAuthorizationStatus.limited), .limited)
        }
        #endif
    }
    #endif

    #if canImport(EventKit)
    func testMapCalendarStatus() {
        // 0..4 是 EKAuthorizationStatus 的原始值：notDetermined / restricted / denied / fullAccess / writeOnly
        XCTAssertEqual(PermissionUtil.map(EKAuthorizationStatus(rawValue: 0)!), .notDetermined)
        XCTAssertEqual(PermissionUtil.map(EKAuthorizationStatus(rawValue: 1)!), .restricted)
        XCTAssertEqual(PermissionUtil.map(EKAuthorizationStatus(rawValue: 2)!), .denied)
        // 3 既是新的 fullAccess，也是 macOS 12/13 上的 authorized（两者原始值相同）
        XCTAssertEqual(PermissionUtil.map(EKAuthorizationStatus(rawValue: 3)!), .authorized)
        // 4 是只写权限，属于部分授权
        XCTAssertEqual(PermissionUtil.map(EKAuthorizationStatus(rawValue: 4)!), .limited)
        XCTAssertEqual(PermissionUtil.map(EKAuthorizationStatus(rawValue: 99)!), .unknown)
    }
    #endif

    #if canImport(UserNotifications)
    /// 回归：以前 NotificationUtil 在 init 里取 UNUserNotificationCenter.current()，
    /// 无 App bundle 的 SPM 测试进程会直接抛异常，导致这个类完全没有测试。
    func testNotificationUtilCanBeCreatedWithoutAppBundle() {
        XCTAssertNotNil(NotificationUtil())
    }
    #endif

    // MARK: 能力探测

    func testNotificationsAreAlwaysSupportedWhereFrameworkExists() {
        #if canImport(UserNotifications)
        XCTAssertTrue(PermissionUtil().isSupported(.notifications))
        #else
        XCTAssertFalse(PermissionUtil().isSupported(.notifications))
        #endif
    }

    #if os(watchOS)
    func testCameraAndPhotosUnavailableOnWatchOS() {
        XCTAssertFalse(PermissionUtil().isSupported(.camera))
        XCTAssertFalse(PermissionUtil().isSupported(.photoLibraryReadWrite))
    }
    #endif

    // MARK: Info.plist usage description

    func testRequiredInfoPlistKeys() {
        XCTAssertEqual(PermissionUtil.requiredInfoPlistKeys(for: .camera), ["NSCameraUsageDescription"])
        XCTAssertEqual(PermissionUtil.requiredInfoPlistKeys(for: .microphone), ["NSMicrophoneUsageDescription"])
        XCTAssertEqual(PermissionUtil.requiredInfoPlistKeys(for: .contacts), ["NSContactsUsageDescription"])
        XCTAssertEqual(PermissionUtil.requiredInfoPlistKeys(for: .photoLibraryReadWrite),
                       ["NSPhotoLibraryUsageDescription"])
        // 只写相册：两个 key 任一存在都算配好
        XCTAssertTrue(PermissionUtil.requiredInfoPlistKeys(for: .photoLibraryAddOnly)
            .contains("NSPhotoLibraryAddUsageDescription"))
        // 定位：iOS 用 WhenInUse，macOS 12 上还有旧的 NSLocationUsageDescription
        XCTAssertTrue(PermissionUtil.requiredInfoPlistKeys(for: .locationWhenInUse)
            .contains("NSLocationWhenInUseUsageDescription"))
        // 日历：iOS 17 换成 FullAccess 的 key，旧 key 作为兼容
        XCTAssertTrue(PermissionUtil.requiredInfoPlistKeys(for: .calendars)
            .contains("NSCalendarsFullAccessUsageDescription"))
        // 通知不需要 usage description
        XCTAssertTrue(PermissionUtil.requiredInfoPlistKeys(for: .notifications).isEmpty)
    }

    /// 缺 key 时 `request` 必须直接失败，不能去调系统 API（那会终止 App）
    func testUsageDescriptionGuardFailsClosed() {
        let util = PermissionUtil()
        let empty: [String: Any] = [:]
        XCTAssertFalse(util.hasUsageDescription(for: .camera, info: empty))
        XCTAssertFalse(util.hasUsageDescription(for: .contacts, info: empty))
        XCTAssertFalse(util.hasUsageDescription(for: .calendars, info: empty))
        // 通知不需要 key，守卫应放行
        XCTAssertTrue(util.hasUsageDescription(for: .notifications, info: empty))
        // 空白字符串也算没配
        XCTAssertFalse(util.hasUsageDescription(for: .camera, info: ["NSCameraUsageDescription": "  "]))
        XCTAssertTrue(util.hasUsageDescription(for: .camera, info: ["NSCameraUsageDescription": "拍照"]))
        // 相册只写：新旧 key 任一存在即可
        XCTAssertTrue(util.hasUsageDescription(for: .photoLibraryAddOnly,
                                               info: ["NSPhotoLibraryUsageDescription": "x"]))
        // 日历：旧 key 作为兼容
        XCTAssertTrue(util.hasUsageDescription(for: .calendars,
                                               info: ["NSCalendarsUsageDescription": "x"]))
    }
}
