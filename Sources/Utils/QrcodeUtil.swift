//
//  QrcodeUtil.swift
//
//
//  Created by zzh on 2024/6/17.
//

import CoreImage.CIFilterBuiltins
import Foundation
import SwiftUI

@available(macOS 10.15, *)
public class QrcodeUtil {
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()
    init() {}

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
}
