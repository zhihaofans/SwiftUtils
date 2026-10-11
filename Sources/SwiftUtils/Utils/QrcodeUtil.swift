#if !os(watchOS)
//
//  QrcodeUtil.swift
//
//
//  Created by zzh on 2024/7/19.
//

import CoreImage.CIFilterBuiltins
import Foundation
import SwiftUI

public class QrcodeUtil {
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()
    public init() {}

    #if os(macOS)
    public func generateQRCode(from string: String, scale: CGFloat = 10) -> NSImage? {
        // scale放大倍数
        filter.message = Data(string.utf8)
        if let outputImage = filter.outputImage {
            let transform = CGAffineTransform(scaleX: scale, y: scale)
            let scaledImage = outputImage.transformed(by: transform)
            let size = NSSize(width: outputImage.extent.width, height: outputImage.extent.height)
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return NSImage(cgImage: cgImage, size: size)
            }
        }
        return nil
    }
    #else
    public func generateQRCode(from string: String, scale: CGFloat = 5.0) -> UIImage? {
        let data = Data(string.utf8)
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel") // 高纠错级别

        if let qrCodeImage = filter.outputImage {
            let transformedImage = qrCodeImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            if let qrCodeCGImage = context.createCGImage(transformedImage, from: transformedImage.extent) {
                return UIImage(cgImage: qrCodeCGImage)
            }
        }
        return nil
    }
    #endif
}
#endif
