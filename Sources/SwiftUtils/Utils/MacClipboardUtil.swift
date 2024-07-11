//
//  MacClipboardUtil.swift
//
//
//  Created by zzh on 2024/7/11.
//

import AppKit
import Foundation

@available(macOS 10.15, *)
public class MacClipboardUtil {
    public init() {}

    public func getString() -> String {
        return NSPasteboard.general.string ?? ""
    }

    public func setString(str: String) {
        NSPasteboard.general.string = str
    }

    public func hasString() -> Bool {
        return NSPasteboard.general.hasStrings
    }

    public func getImage() -> UIImage? {
        return NSPasteboard.general.image
    }

    public func setImage(img: UIImage) {
        NSPasteboard.general.image = img
    }

    public func hasImage() -> Bool {
        return NSPasteboard.general.hasImages
    }

    public func getUrl() -> URL? {
        return NSPasteboard.general.url
    }

    public func setUrl(url: URL) {
        NSPasteboard.general.url = url
    }

    public func hasUrl() -> Bool {
        return NSPasteboard.general.hasURLs
    }

    public func getColor() -> UIColor? {
        return NSPasteboard.general.color
    }

    public func setColor(color: UIColor) {
        NSPasteboard.general.color = color
    }

    public func hasColor() -> Bool {
        return NSPasteboard.general.hasColors
    }
}
