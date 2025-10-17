//
//  BundleEx.swift
//
//  Created by zzh on 2025/10/16.
//

import Foundation

public extension Bundle {
    var versionString: String? {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }

    var buildString: String? {
        object(forInfoDictionaryKey: "CFBundleVersion") as? String
    }

    var bundleName: String? {
        object(forInfoDictionaryKey: "CFBundleName") as? String
    }

    var displayName: String? {
        object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
    }

    var appIconName: String? {
        if let iconsDictionary = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primaryIconsDictionary = iconsDictionary["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIconsDictionary["CFBundleIconFiles"] as? [String],
           let lastIcon = iconFiles.last
        {
            return lastIcon
        }
        return nil
    }

    var appMinimumOSVersion: String? {
        object(forInfoDictionaryKey: "MinimumOSVersion") as? String
    }
}
