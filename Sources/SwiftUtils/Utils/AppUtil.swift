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

    public func openUrl(urlString: String) async -> Bool {
        if let url = URL(string: urlString) {
#if canImport(UIKit)
            return await UIApplication.shared.open(url, options: [:])
#else
            return NSWorkspace.shared.open(url)
#endif
        }
        return false
    }

    public func openUrl(url: URL) async -> Bool {
#if canImport(UIKit)
        return await UIApplication.shared.open(url, options: [:])
#else
        return NSWorkspace.shared.open(url)
#endif
    }

    public func canOpenUrl(urlString: String) -> Bool {
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

    public func canOpenUrl(url: URL) -> Bool {
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

    public func getAppVersionAndBuild() -> String {
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
           let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        {
            return "Version \(version) (\(build))"
        }
        return "Unknown version"
    }
}
