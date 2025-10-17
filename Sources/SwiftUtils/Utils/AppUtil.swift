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
public class AppUtil {
    public init() {}

    public func openUrl(_ urlString: String) {
        if let url = URL(string: urlString) {
#if canImport(UIKit)
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
#if canImport(UIKit)
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
        if let url = URL(string: urlString) {
#if canImport(UIKit)
            return UIApplication.shared.canOpenURL(url)
#else
            return NSWorkspace.shared.open(url)
#endif
        } else {
            return false
        }
    }

    public func canOpenUrl(_ url: URL) -> Bool {
#if canImport(UIKit)
        return UIApplication.shared.canOpenURL(url)
#else
        return false
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
#if os(macOS)
        return false
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
            print("✅ 后台 App 刷新已启用")
            return true
        case .denied:
            print("❌ 后台 App 刷新被用户关闭")
            return false
        case .restricted:
            print("⛔ 后台 App 刷新受限制（如家长控制）")
            return false
        @unknown default:
            print("❓ 未知的后台刷新状态")
            return false
        }
#else
        return false
#endif
    }
}
