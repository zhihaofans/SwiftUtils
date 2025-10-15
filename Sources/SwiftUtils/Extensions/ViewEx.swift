//
//  ViewEx.swift
//  SwiftUtils
//
//  Created by zzh on 2024/11/10.
//

import Foundation
import SwiftUI

#if canImport(UIKit)
import SafariServices
import UIKit
#endif

#if canImport(AppKit)
import AppKit
import WebKit
#endif

public extension View {
    func onClick(callback: @escaping () -> Void) -> some View {
        contentShape(Rectangle()) // 加这行才实现可点击
            .onTapGesture {
                callback()
            }
    }

    func setNavigationTitle(_ title: String) -> some View {
        #if os(iOS)
        // 兼容旧项目：inline 展示
        return navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        #else
        return navigationTitle(title)
        #endif
    }

    #if canImport(UIKit)
    /// iOS 分享文本
    func showShareTextView(_ text: String, isPresented: Binding<Bool>) -> some View {
        sheet(isPresented: isPresented) {
            ShareActivityView(activityItems: [text])
        }
    }
    #endif

    // Share Sheet
    #if canImport(AppKit)
    /// macOS 分享文本（保持同一接口）
    func showShareTextView(_ text: String, isPresented: Binding<Bool>) -> some View {
        sheet(isPresented: isPresented) {
            MacShareView(items: [text])
        }
    }
    #endif

    // Safari / Web 预览

    #if canImport(UIKit)
    /// iOS Safari 预览
    func showSafariWebPreviewView(_ safariUrlString: String, isPresented: Binding<Bool>) -> some View {
        sheet(isPresented: isPresented) {
            if let url = URL(string: safariUrlString) {
                SafariWebPreviewView(url: url)
            } else {
                Text("Invalid URL")
            }
        }
    }
    #endif

    #if canImport(AppKit)
    /// macOS Web 预览（WKWebView）
    func showSafariWebPreviewView(_ safariUrlString: String, isPresented: Binding<Bool>) -> some View {
        sheet(isPresented: isPresented) {
            if let url = URL(string: safariUrlString) {
                MacWebPreviewView(url: url)
            } else {
                Text("Invalid URL")
            }
        }
    }
    #endif
    func inputAlert(
        _ title: String,
        placeholder: String = "",
        text: Binding<String>,
        isPresented: Binding<Bool>,
        onConfirm: @escaping (String) -> Void
    ) -> some View {
        self.background(
            InputAlertView(
                title: title,
                placeholder: placeholder,
                inputText: text,
                isPresented: isPresented,
                callback: onConfirm
            )
        )
    }
}

// MARK: - TextField helpers

#if canImport(UIKit)
public extension TextField {
    /// 小数键盘（iOS）
    func setDecimalType() -> some View {
        keyboardType(.decimalPad)
    }

    /// 数字键盘（iOS）
    func setNumberType() -> some View {
        keyboardType(.numberPad)
    }
}
#endif

#if canImport(AppKit)
public extension TextField {
    /// macOS 无键盘类型概念，保持 API 一致，直接返回 self
    func setDecimalType() -> some View { self }
    func setNumberType() -> some View { self }
}
#endif

// MARK: - iOS 实现

#if canImport(UIKit)
struct ShareActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems,
                                 applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct SafariWebPreviewView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
#endif

// MARK: - macOS 实现

#if canImport(AppKit)
/// macOS 分享：使用 NSSharingServicePicker
struct MacShareView: NSViewRepresentable {
    let items: [Any]

    func makeNSView(context: Context) -> NSButton {
        let button = NSButton(title: "Share", target: context.coordinator, action: #selector(Coordinator.share))
        button.bezelStyle = .rounded
        context.coordinator.items = items
        context.coordinator.anchorButton = button
        return button
    }

    func updateNSView(_ nsView: NSButton, context: Context) {
        context.coordinator.items = items
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject {
        var items: [Any] = []
        weak var anchorButton: NSButton?

        @objc func share() {
            guard let view = anchorButton else { return }
            let picker = NSSharingServicePicker(items: items)
            picker.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
        }
    }
}

/// macOS 网页预览：WKWebView
struct MacWebPreviewView: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> WKWebView {
        let web = WKWebView()
        web.allowsBackForwardNavigationGestures = true
        web.customUserAgent = "SwiftUtils-MacWebPreview"
        let request = URLRequest(url: url)
        web.load(request)
        return web
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // 可根据需要刷新
    }
}
#endif
