//
//  ClipboardUtil.swift
//
//
//  Created by zzh on 2024/7/11.
//

import Foundation


public class ClipboardUtil {
    public init() {}

    public func getString() -> String {
       return UIPasteboard.general.string ?? ""
    }
    public func setString(str:String) {
        UIPasteboard.general.string = str
    }
    public func hasString() -> Bool {
        return UIPasteboard.general.hasStrings()
    }
    public func getImage() -> UIImage?
 {
       return UIPasteboard.general.image
    }
    public func setImage(img:UIImage) {
        UIPasteboard.general.image = img
    }
    public func hasString() -> Bool {
        return UIPasteboard.general.hasImages()
    }
    public func getUrl() -> URL?
 {
       return UIPasteboard.general.url
    }
    public func setUrl(url:URL) {
        UIPasteboard.general.url = url
    }
    public func hasUrl() -> Bool {
        return UIPasteboard.general.hasURLs()
    }
    public func getColor() -> UIColor?
 {
       return UIPasteboard.general.color
    }
    public func setColor(color:UIColor) {
        UIPasteboard.general.color = color
    }
    public func hasColor() -> Bool {
        return UIPasteboard.general.hasColors()
    }
}
