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
        public func generateQRCode(from string: String) -> UIImage? {
            let data = Data(string.utf8)
            filter.setValue(data, forKey: "inputMessage")

            if let qrCodeImage = filter.outputImage {
                if let qrCodeCGImage = context.createCGImage(qrCodeImage, from: qrCodeImage.extent) {
                    return UIImage(cgImage: qrCodeCGImage)
                }
            }
            return nil
        }
    #endif
}
