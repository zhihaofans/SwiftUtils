//
//  ClipboardUtil.swift
//
//
//  Created by zzh on 2024/7/18.
//

import Foundation

#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif
public class ClipboardUtil {
    #if os(macOS)
    private let pasteboard = NSPasteboard.general
    #else
    private let pasteboard = UIPasteboard.general
    #endif
    public init() {}
    public func getString() -> String {
        #if os(macOS)
        return NSPasteboard.general.string(forType: .string) ?? ""
        #else
        return UIPasteboard.general.string ?? ""
        #endif
    }

    public func setString(str: String) {
        #if os(macOS)
        pasteboard.clearContents() // 清除剪贴板当前内容
        pasteboard.setString(str, forType: .string)
        #else
        UIPasteboard.general.string = str
        #endif
    }

    public func hasString() -> Bool {
        #if os(macOS)
        return getString().isEmpty
        #else
        return pasteboard.hasStrings
        #endif
    }

    #if os(macOS)
    public func getImage() -> NSImage? {
        // 尝试从剪贴板获取 TIFF 数据
        if let tiffData = pasteboard.data(forType: .tiff),
           let image = NSImage(data: tiffData)
        {
            return image
        }

        // 如果 TIFF 数据未找到，尝试 PNG
        if let pngData = pasteboard.data(forType: .png),
           let image = NSImage(data: pngData)
        {
            return image
        }

        return nil
    }
    #else
    public func getImage() -> UIImage? {
        return pasteboard.image
    }
    #endif

    #if os(macOS)
    public func setImage(img: NSImage) {
        pasteboard.clearContents() // 清除剪贴板上的内容
        pasteboard.writeObjects([img]) // 写入图像
    }
    #else
    public func setImage(img: UIImage) {
        pasteboard.image = img
    }
    #endif

    public func hasImage() -> Bool {
        return getImage() != nil
    }

    public func getUrl() -> URL? {
        #if os(macOS)
        // 尝试从剪贴板获取 URL 类型数据
        if let urlString = pasteboard.string(forType: .URL),
           let url = URL(string: urlString)
        {
            return url
        }

        // 如果没有找到 URL 类型数据，尝试以字符串类型获取
        if let urlString = pasteboard.string(forType: .string),
           let url = URL(string: urlString)
        {
            return url
        }
        return nil
        #else
        return pasteboard.url
        #endif
    }

    public func setUrl(url: URL) {
        #if os(macOS)
        pasteboard.clearContents() // 首先清除剪贴板上的内容
        pasteboard.writeObjects([url as NSURL]) // 将 URL 写入剪贴板
        #else
        pasteboard.url = url
        #endif
    }

    public func hasUrl() -> Bool {
        #if os(macOS)
        return getUrl() != nil
        #else
        return pasteboard.hasURLs()
        #endif
    }

    #if os(macOS)
    public func getColor() -> NSColor? {
        // 尝试从剪贴板获取颜色类型数据
        if let colorData = pasteboard.data(forType: .color) {
            do {
                let color = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: colorData)
                return color
            } catch {
                print("Error unarchiving color from pasteboard: \(error)")
            }
        }
        return nil
    }
    #else
    public func getColor() -> UIColor? {
        return UIPasteboard.general.color
    }
    #endif
    #if os(macOS)
    public func setColor(color: NSColor) {
        pasteboard.clearContents() // 清除剪贴板上的内容

        // 使用新 API 归档 NSColor 对象
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false) {
            pasteboard.setData(data, forType: .color)
        }
    }
    #else
    public func setColor(color: UIColor) {
        UIPasteboard.general.color = color
    }
    #endif

    public func hasColor() -> Bool {
        #if os(macOS)
        return getColor() != nil
        #else
        return UIPasteboard.general.hasColors()
        #endif
    }
}
