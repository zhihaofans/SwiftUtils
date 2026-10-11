#if !os(watchOS)
//
//  ShareUtil.swift
//
//
//  Created by zzh on 2024/7/24.
//

import Foundation

#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

public class ShareUtil {
    public init() {}

    public func share(item: Any) {
        #if os(macOS)
        guard let keyWindow = NSApp.keyWindow, let contentView = keyWindow.contentView else {
            SU.log.error("分享失败：找不到主窗口")
            return
        }
        let sharingPicker = NSSharingServicePicker(items: [item])
        sharingPicker.show(relativeTo: .zero, of: contentView, preferredEdge: .minY)
        #else
        DispatchQueue.main.async {
            guard let topVC = Self.topViewController() else {
                SU.log.error("分享失败：找不到可展示的视图控制器")
                return
            }
            let controller = UIActivityViewController(activityItems: [item], applicationActivities: nil)
            // iPad 上 UIActivityViewController 必须用 popover 展示，否则会崩溃
            if let popover = controller.popoverPresentationController {
                popover.sourceView = topVC.view
                popover.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            topVC.present(controller, animated: true, completion: nil)
        }
        #endif
    }

    #if canImport(UIKit)
    /// 找到当前最顶层的视图控制器
    private static func topViewController(from root: UIViewController? = nil) -> UIViewController? {
        let root = root ?? UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first?.rootViewController
        if let presented = root?.presentedViewController {
            return topViewController(from: presented)
        }
        if let nav = root as? UINavigationController {
            return topViewController(from: nav.visibleViewController)
        }
        if let tab = root as? UITabBarController {
            return topViewController(from: tab.selectedViewController)
        }
        return root
    }
    #endif

    #if os(macOS)
    public func shareImage(img: NSImage) {
        self.share(item: img)
    }
    #else
    public func shareImage(img: UIImage) {
        self.share(item: img)
    }
    #endif

    public func shareText(text: String) {
        self.share(item: text)
    }
}
#endif
