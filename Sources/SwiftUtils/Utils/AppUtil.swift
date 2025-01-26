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
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            return version
        }
        return "Unknown"
    }

    public func getAppName() -> String {
        return self.getAppDisplayName() ?? self.getAppBundleName() ?? "Unknown App Name"
    }

    public func getAppDisplayName() -> String? {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
    }

    public func getAppBundleName() -> String? {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
    }

    public func getAppBuild() -> String {
        if let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
            return build
        }
        return "Unknown"
    }

    public func getAppIconName() -> String? {
        if let iconsDictionary = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primaryIconsDictionary = iconsDictionary["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIconsDictionary["CFBundleIconFiles"] as? [String],
           let lastIcon = iconFiles.last
        {
            return lastIcon
        }
        return nil
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
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
           let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        {
            return "Version \(version) (\(build))"
        }
        return "Unknown version"
    }

    public func getAppMinimumOSVersion() -> String? {
        if let version = Bundle.main.object(forInfoDictionaryKey: "MinimumOSVersion") as? String {
            return version
        }
        return nil
    }
}
