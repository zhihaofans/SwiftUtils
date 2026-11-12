//
//  PDFUtil.swift
//  SwiftUtils
//
//  Created by zzh on 2026/11/12.
//

#if os(iOS) || os(macOS)

import CoreGraphics
import Foundation

/// PDF：页数、单页渲染、由图片生成。
///
/// 为什么整个文件包在 `#if os(iOS) || os(macOS)` 里：
/// PDFKit 在 watchOS SDK 中**不存在**，而这套实现用的是 CoreGraphics（`CGPDFDocument`），
/// 手表上也没有 PDF 的展示场景，直接不提供比返回一个假结果好。
///
/// 为什么不用 PDFKit：`PDFDocument` 只能在 iOS / macOS 用，且渲染要包一层 UIImage / NSImage，
/// 两端类型不一致。`CGPDFDocument` 返回 `CGImage`，三端统一，也方便跨平台测试。
public enum PDFUtil {
    public enum PDFError: Error, Equatable {
        case cannotOpenDocument
        case pageOutOfRange(Int)
        case cannotCreateContext
        case emptyImages
    }

    /// 页数。
    public static func pageCount(_ url: URL) throws -> Int {
        guard let document = CGPDFDocument(url as CFURL) else {
            throw PDFError.cannotOpenDocument
        }
        return document.numberOfPages
    }

    /// 渲染单页为 `CGImage`。
    ///
    /// - Parameters:
    ///   - index: 从 0 开始。
    ///   - maxPixelSize: 输出最大边的像素数。
    /// - Important: 只渲染**一页**。别提供「整本渲染成数组」的 API：
    ///   100 页 × scale 2 的位图是 GB 级内存，调用方一页页取、用完就放，才不会爆。
    public static func pageImage(_ url: URL, page index: Int, maxPixelSize: Int) throws -> CGImage? {
        guard maxPixelSize > 0 else { return nil }
        guard let document = CGPDFDocument(url as CFURL) else {
            throw PDFError.cannotOpenDocument
        }
        guard index >= 0, index < document.numberOfPages, let page = document.page(at: index + 1) else {
            throw PDFError.pageOutOfRange(index)
        }

        // 用 mediaBox 而不是 cropBox：与系统预览看到的范围一致
        let box = page.getBoxRect(.mediaBox)
        guard box.width > 0, box.height > 0 else { return nil }

        let scale = CGFloat(maxPixelSize) / max(box.width, box.height)
        let width = max(1, Int((box.width * scale).rounded()))
        let height = max(1, Int((box.height * scale).rounded()))

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw PDFError.cannotCreateContext
        }

        // PDF 页面默认透明：不铺白底，导出 PNG 在深色背景上会变成黑/透明底
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        let target = CGRect(x: 0, y: 0, width: width, height: height)
        context.concatenate(
            page.getDrawingTransform(.mediaBox, rect: target, rotate: 0, preserveAspectRatio: true)
        )
        context.drawPDFPage(page)
        return context.makeImage()
    }

    /// 用图片生成 PDF，一图一页。
    ///
    /// - Note: 页面尺寸固定为**第一张图**的像素尺寸，其余图片等比缩放后居中（letterbox），
    ///   不裁切。想要每页各自尺寸，得用 `kCGPDFContextMediaBox` 逐页设置，
    ///   那需要在 `beginPDFPage` 里传 CFData，复杂且收益不大。
    public static func makePDF(from images: [CGImage], to url: URL) throws {
        guard let first = images.first else { throw PDFError.emptyImages }
        guard let consumer = CGDataConsumer(url: url as CFURL) else {
            throw PDFError.cannotCreateContext
        }

        var mediaBox = CGRect(
            x: 0,
            y: 0,
            width: CGFloat(first.width),
            height: CGFloat(first.height)
        )
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw PDFError.cannotCreateContext
        }
        defer { context.closePDF() }

        for image in images {
            context.beginPDFPage(nil)

            let imageSize = CGSize(width: image.width, height: image.height)
            let scale = min(mediaBox.width / imageSize.width, mediaBox.height / imageSize.height)
            let drawSize = CGSize(
                width: imageSize.width * scale,
                height: imageSize.height * scale
            )
            let drawRect = CGRect(
                x: (mediaBox.width - drawSize.width) / 2,
                y: (mediaBox.height - drawSize.height) / 2,
                width: drawSize.width,
                height: drawSize.height
            )
            context.draw(image, in: drawRect)

            context.endPDFPage()
        }
    }
}

#endif
