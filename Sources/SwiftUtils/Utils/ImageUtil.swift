//
//  ImageUtil.swift
//  SwiftUtils
//
//  Created by zzh on 2026/11/12.
//

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// 图片处理：缩放、转码、读元数据。
///
/// 全部走 ImageIO，**不用** `UIImage` / `UIGraphicsImageRenderer`：
/// 那两个在 watchOS 上是 unavailable（`UIImage` 本身有，但渲染器没有），
/// 用 ImageIO 才有可能一套代码覆盖三个平台。
public enum ImageUtil {
    /// 生成缩略图（等比缩放到最大边 `maxPixelSize`）。
    ///
    /// - Important: 必须带 `kCGImageSourceCreateThumbnailWithTransform`。
    ///   少了它，`orientation = 6` 的竖拍照片缩略图会躺倒 —— 而且只在部分照片上出现，
    ///   测试里没有 fixture 根本发现不了。
    /// - Note: `kCGImageSourceShouldCacheImmediately` 让解码在这里完成，
    ///   而不是等到第一次绘制时在主线程上做。
    public static func downsample(_ data: Data, maxPixelSize: Int) -> CGImage? {
        guard maxPixelSize > 0,
              let source = CGImageSourceCreateWithData(data as CFData, nil)
        else { return nil }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }

    /// 转码（可选先缩放），保留除方向外的元数据。
    ///
    /// - Parameters:
    ///   - type: 目标格式，默认 JPEG。PNG 会忽略 `quality`。
    ///   - quality: 有损压缩质量 0…1，只对 JPEG / HEIC 生效。
    ///   - maxPixelSize: 传了就先按 `downsample` 缩放再写。
    /// - Important: 传了 `maxPixelSize` 时，输出会把 EXIF 方向**归一到 1**。
    ///   因为缩略图已经按方向转正，原方向再留着就会转两次（竖拍变横）。
    ///   这也是「重编码后照片躺倒」的根因。
    /// - Returns: 编码失败 / 数据无法解码时返回 `nil`。
    public static func reencode(
        _ data: Data,
        to type: UTType = .jpeg,
        quality: CGFloat = 0.9,
        maxPixelSize: Int? = nil
    ) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }

        let resized = maxPixelSize != nil
        let image: CGImage?
        if let maxPixelSize {
            image = downsample(data, maxPixelSize: maxPixelSize)
        } else {
            image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        }
        guard let image else { return nil }

        var properties = metadata(data)
        if resized {
            properties = normalizedProperties(
                properties,
                pixelWidth: image.width,
                pixelHeight: image.height
            )
        }
        properties[kCGImageDestinationLossyCompressionQuality as String] = quality

        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            output,
            type.identifier as CFString,
            1,
            nil
        ) else { return nil }

        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return output as Data
    }

    /// 原始元数据（Exif / TIFF / GPS 等），结构同 `CGImageSourceCopyPropertiesAtIndex`。
    ///
    /// - Note: 不是 Sendable。要跨 actor 传，用 `flatMetadata` 或只取需要的字符串值。
    public static func metadata(_ data: Data) -> [String: Any] {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any]
        else { return [:] }
        return properties
    }

    /// 扁平化后的元数据：`Exif.DateTimeOriginal` → `"2026:11:12 10:00:00"`。
    ///
    /// 给 UI 展示用。数组/字典值会被 `"\(value)"` 描述成字符串，需要精确结构时用 `metadata`。
    public static func flatMetadata(_ data: Data) -> [String: String] {
        var result: [String: String] = [:]

        func flatten(_ value: Any, prefix: String) {
            if let dictionary = value as? [String: Any] {
                for (key, nested) in dictionary {
                    flatten(nested, prefix: prefix.isEmpty ? key : "\(prefix).\(key)")
                }
            } else {
                result[prefix] = "\(value)"
            }
        }

        for (key, value) in metadata(data) {
            flatten(value, prefix: key)
        }
        return result
    }

    // MARK: - 私有

    /// 缩放之后要写的属性：方向归一到 1，像素尺寸改成新尺寸。
    ///
    /// 这里踩过一个很隐蔽的坑：只把顶层 `Orientation` 改成 1、保留其余原属性时，
    /// 写出来的图**用图像查看器看是正的**，但再用 `CGImageSourceCreateThumbnailAtIndex`
    /// 取缩略图会转 90° —— 旧的 `{Exif}.PixelXDimension` / `{TIFF}.Orientation = 6`
    /// 还在描述缩放前的旧像素。必须一起清掉，并写入新尺寸。
    private static func normalizedProperties(
        _ properties: [String: Any],
        pixelWidth: Int,
        pixelHeight: Int
    ) -> [String: Any] {
        var result = properties
        result[kCGImagePropertyOrientation as String] = 1
        result[kCGImagePropertyPixelWidth as String] = pixelWidth
        result[kCGImagePropertyPixelHeight as String] = pixelHeight

        if var exif = result[kCGImagePropertyExifDictionary as String] as? [String: Any] {
            exif[kCGImagePropertyOrientation as String] = 1
            exif.removeValue(forKey: kCGImagePropertyExifPixelXDimension as String)
            exif.removeValue(forKey: kCGImagePropertyExifPixelYDimension as String)
            result[kCGImagePropertyExifDictionary as String] = exif
        }

        if var tiff = result[kCGImagePropertyTIFFDictionary as String] as? [String: Any] {
            tiff[kCGImagePropertyOrientation as String] = 1
            result[kCGImagePropertyTIFFDictionary as String] = tiff
        }

        return result
    }
}
