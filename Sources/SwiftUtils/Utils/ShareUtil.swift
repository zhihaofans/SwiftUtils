//
//  ShareUtil.swift
//
//
//  Created by zzh on 2024/7/24.
//

import Foundation

#if canImport(UIKit)
import SwiftUI
import UIKit

// 使用 UIViewControllerRepresentable 封装 UIActivityViewController
struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // 通常不需要更新
    }
}
#endif
#if canImport(AppKit)
import AppKit
#endif
public class ShareUtil {
    public init() {}

    public func share(item: Any) {
        #if os(macOS)
        let sharingPicker = NSSharingServicePicker(items: [item])
        sharingPicker.delegate = nil // 可以设置代理来进一步自定义行为

        // 使用 NSView 的窗口来展示分享界面
        sharingPicker.show(relativeTo: .zero, of: NSApp.keyWindow!.contentView!, preferredEdge: .minY)
        #else
        let iosShareResult = ShareSheet(activityItems: [item])
        debugPrint(iosShareResult)
        #endif
    }

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
