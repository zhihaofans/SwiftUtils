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
        return pasteboard.string(forType: .string) ?? ""
        #else
        return pasteboard.string ?? ""
        #endif
    }

    public func setString(_ str: String) {
        #if os(macOS)
        pasteboard.clearContents() // 清除剪贴板当前内容
        pasteboard.setString(str, forType: .string)
        #else
        pasteboard.string = str
        #endif
    }

    public func hasString() -> Bool {
        #if os(macOS)
        // 与原语义一致：剪贴板中存在非空字符串
        return pasteboard.string(forType: .string)?.isEmpty == false
        #else
        return pasteboard.hasStrings
        #endif
    }

    #if os(macOS)
    public func getImage() -> NSImage? {
        // readObjects 覆盖 TIFF/PNG/JPEG/HEIC 等所有系统可识别的图像类型
        return pasteboard.readObjects(forClasses: [NSImage.self], options: nil)?.first as? NSImage
    }
    #else
    public func getImage() -> UIImage? {
        return pasteboard.image
    }
    #endif

    #if os(macOS)
    public func setImage(_ img: NSImage) {
        pasteboard.clearContents() // 清除剪贴板上的内容
        pasteboard.writeObjects([img]) // 写入图像
    }
    #else
    public func setImage(_ img: UIImage) {
        pasteboard.image = img
    }
    #endif

    public func hasImage() -> Bool {
        #if os(macOS)
        // 只检查可读性，不实际解码图片
        return pasteboard.canReadObject(forClasses: [NSImage.self])
        #else
        return pasteboard.hasImages
        #endif
    }

    public func getUrl() -> URL? {
        #if os(macOS)
        // 优先读 URL 类型；没有则退化为字符串解析
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil),
           let url = urls.first as? URL
        {
            return url
        }

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

    public func setUrl(_ url: URL) {
        #if os(macOS)
        pasteboard.clearContents() // 首先清除剪贴板上的内容
        pasteboard.writeObjects([url as NSURL]) // 将 URL 写入剪贴板
        #else
        pasteboard.url = url
        #endif
    }

    public func hasUrl() -> Bool {
        #if os(macOS)
        // 与 getUrl() 口径一致：URL 类型，或可解析为 URL 的字符串
        // 注：canReadObject(forClasses: [NSURL.self]) 不覆盖纯字符串，故需额外判断字符串
        if pasteboard.types?.contains(.URL) == true { return true }
        return pasteboard.string(forType: .string).flatMap(URL.init(string:)) != nil
        #else
        return pasteboard.hasURLs
        #endif
    }

    #if os(macOS)
    public func getColor() -> NSColor? {
        // 尝试从剪贴板获取颜色类型数据
        if let colorData = pasteboard.data(forType: .color) {
            do {
                let unarchiver = try NSKeyedUnarchiver(forReadingFrom: colorData)
                unarchiver.requiresSecureCoding = false // 与 setColor 的归档方式配对
                let color = unarchiver.decodeObject(of: NSColor.self, forKey: NSKeyedArchiveRootObjectKey)
                unarchiver.finishDecoding()
                return color
            } catch {
                SU.log.error("Error unarchiving color from pasteboard: \(error)")
            }
        }
        return nil
    }
    #else
    public func getColor() -> UIColor? {
        return pasteboard.color
    }
    #endif

    #if os(macOS)
    public func setColor(_ color: NSColor) {
        pasteboard.clearContents() // 清除剪贴板上的内容

        // 使用新 API 归档 NSColor 对象
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false) {
            pasteboard.setData(data, forType: .color)
        }
    }
    #else
    public func setColor(_ color: UIColor) {
        pasteboard.color = color
    }
    #endif

    public func hasColor() -> Bool {
        #if os(macOS)
        return pasteboard.types?.contains(.color) ?? false
        #else
        return pasteboard.hasColors
        #endif
    }
}
