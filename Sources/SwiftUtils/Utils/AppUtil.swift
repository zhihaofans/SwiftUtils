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
    public func openUrl(urlString: String) ->Bool {
        if let url = URL(string: urlString) {
#if canImport(UIKit)
            return UIApplication.shared.open(url, options: [:])
#else
            return NSWorkspace.shared.open(url)
#endif
        }
        return false
    }

    public func openUrl(url: URL) ->Bool {
#if canImport(UIKit)
        return UIApplication.shared.open(url, options: [:])
#else
        return NSWorkspace.shared.open(url)
#endif
    }

    public func canOpenUrl(urlString: String)->Bool {
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

    public func canOpenUrl(url: URL)->Bool {
#if canImport(UIKit)
        return UIApplication.shared.canOpenURL(url)
#else
        return false
#endif
    }
}
