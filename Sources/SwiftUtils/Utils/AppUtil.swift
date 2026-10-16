//
//  AppUtil.swift
//
//
//  Created by zzh on 2024/7/17.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif
#if os(watchOS)
import WatchKit
#endif
public class AppUtil {
    public init() {}

    public func openUrl(_ urlString: String) {
        if let url = URL(string: urlString) {
#if os(watchOS)
            openUrl(url)
#elseif canImport(UIKit)
            Task {
                DispatchQueue.main.async {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
#else
            NSWorkspace.shared.open(url)
#endif
        }
    }

    public func openUrl(_ url: URL) {
#if os(watchOS)
        // watchOS：只能用 WKApplication.openSystemURL
        Task {
            DispatchQueue.main.async {
                WKApplication.shared().openSystemURL(url)
            }
        }
#elseif canImport(UIKit)
        Task {
            DispatchQueue.main.async {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
#else
        NSWorkspace.shared.open(url)
#endif
    }

    public func canOpenUrl(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return canOpenUrl(url)
    }

    public func canOpenUrl(_ url: URL) -> Bool {
#if os(watchOS)
        // watchOS 没有 canOpenURL 等价 API，仅做基本 scheme 校验
        return url.scheme?.isEmpty == false
#elseif canImport(UIKit)
        return UIApplication.shared.canOpenURL(url)
#else
        // 只检查能否打开，不真正打开
        return NSWorkspace.shared.urlForApplication(toOpen: url) != nil
#endif
    }

    public func getAppVersion() -> String {
        return Bundle.main.versionString ?? "Unknown"
    }

    public func getAppName() -> String {
        return self.getAppDisplayName() ?? self.getAppBundleName() ?? "Unknown App Name"
    }

    public func getAppDisplayName() -> String? {
        return Bundle.main.displayName
    }

    public func getAppBundleName() -> String? {
        return Bundle.main.bundleName
    }

    public func getAppBuild() -> String {
        return Bundle.main.buildString ?? "Unknown"
    }

    public func getAppIconName() -> String? {
        return Bundle.main.appIconName
    }

#if os(macOS)
    public func getAppIconImage() -> NSImage? {
        if let iconName = self.getAppIconName() {
            return NSImage(named: iconName)
        }
        return nil
    }
#else
    public func getAppIconImage() -> UIImage? {
        if let iconName = self.getAppIconName() {
            return UIImage(named: iconName)
        }
        return nil
    }
#endif

    public func getAppVersionAndBuild() -> String {
        if let version = Bundle.main.versionString,
           let build = Bundle.main.buildString
        {
            return "Version \(version) (\(build))"
        }
        return "Unknown version"
    }

    public func getAppMinimumOSVersion() -> String? {
        Bundle.main.appMinimumOSVersion
    }

    public func openAppSettings() {
#if os(iOS)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
#endif
    }

    public func isDarkColorMode() -> Bool {
#if os(watchOS)
        // watchOS 无 UITraitCollection，界面恒为深色
        return true
#elseif os(macOS)
        // 读真实外观：深色模式下应是 darkAqua
        return NSApp?.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
#else
        return UITraitCollection.current.userInterfaceStyle == .dark
#endif
    }

    public func checkBackgroundRefreshPermission() -> Bool {
#if os(iOS)

        // Info.plist 需要 UIBackgroundModes 才能后台运行
        let status = UIApplication.shared.backgroundRefreshStatus
        switch status {
        case .available:
            SU.log.info("✅ 后台 App 刷新已启用")
            return true
        case .denied:
            SU.log.error("❌ 后台 App 刷新被用户关闭")
            return false
        case .restricted:
            SU.log.error("⛔ 后台 App 刷新受限制（如家长控制）")
            return false
        @unknown default:
            SU.log.error("❓ 未知的后台刷新状态")
            return false
        }
#else
        return false
#endif
    }
}
