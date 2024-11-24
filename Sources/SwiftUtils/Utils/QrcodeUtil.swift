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
        public func generateQRCode(from string: String) -> NSImage? {
            filter.message = Data(string.utf8)
            if let outputImage = filter.outputImage {
                if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                    let size = NSSize(width: outputImage.extent.width, height: outputImage.extent.height)
                    let nsImage = NSImage(cgImage: cgimg, size: size)
                    return nsImage
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
