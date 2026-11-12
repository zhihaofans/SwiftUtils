import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import XCTest
@testable import SwiftUtils

final class ImageUtilTests: XCTestCase {
    // MARK: 造数据

    private func makeImage(width: Int, height: Int) -> CGImage {
        let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.setFillColor(CGColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()!
    }

    /// 写一张带 EXIF orientation 的 JPEG。
    /// orientation 6 = 右转 90°：显示时宽高互换，竖拍照片拿到的就是它。
    private func makeJPEG(_ image: CGImage, orientation: Int) throws -> Data {
        let output = NSMutableData()
        let destination = try XCTUnwrap(
            CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil)
        )
        let properties: [CFString: Any] = [kCGImagePropertyOrientation: orientation]
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
        return output as Data
    }

    // MARK: 元数据

    func testMetadataReadsOrientationAndSize() throws {
        let data = try makeJPEG(makeImage(width: 40, height: 20), orientation: 6)
        let metadata = ImageUtil.metadata(data)

        XCTAssertEqual(metadata[kCGImagePropertyOrientation as String] as? Int, 6)
        XCTAssertEqual(metadata[kCGImagePropertyPixelWidth as String] as? Int, 40)
        XCTAssertEqual(metadata[kCGImagePropertyPixelHeight as String] as? Int, 20)
    }

    func testFlatMetadataFlattensNestedDictionaries() throws {
        let data = try makeJPEG(makeImage(width: 10, height: 10), orientation: 1)
        let flat = ImageUtil.flatMetadata(data)

        XCTAssertEqual(flat["PixelWidth"], "10")
        XCTAssertEqual(flat["Orientation"], "1")
        // ImageIO 的字典 key 带花括号：{Exif}.PixelXDimension
        XCTAssertTrue(flat.keys.contains { $0.hasPrefix("{Exif}.") }, "\(flat.keys)")
    }

    func testInvalidDataDoesNotCrash() {
        let garbage = Data([0x00, 0x01, 0x02, 0x03])

        XCTAssertNil(ImageUtil.downsample(garbage, maxPixelSize: 10))
        XCTAssertNil(ImageUtil.reencode(garbage))
        XCTAssertTrue(ImageUtil.metadata(garbage).isEmpty)
        XCTAssertTrue(ImageUtil.flatMetadata(garbage).isEmpty)
    }

    // MARK: 缩放

    func testDownsampleAppliesExifOrientation() throws {
        let data = try makeJPEG(makeImage(width: 40, height: 20), orientation: 6)

        let thumbnail = try XCTUnwrap(ImageUtil.downsample(data, maxPixelSize: 10))

        // 不带 kCGImageSourceCreateThumbnailWithTransform 时，这里会是 10×5（横的）
        XCTAssertGreaterThan(thumbnail.height, thumbnail.width, "orientation=6 的竖图缩略图应当是竖的")
        XCTAssertEqual(max(thumbnail.width, thumbnail.height), 10)
    }

    func testDownsampleRejectsNonPositiveSize() throws {
        let data = try makeJPEG(makeImage(width: 10, height: 10), orientation: 1)
        XCTAssertNil(ImageUtil.downsample(data, maxPixelSize: 0))
        XCTAssertNil(ImageUtil.downsample(data, maxPixelSize: -10))
    }

    // MARK: 转码

    func testReencodeNormalizesOrientationWhenResized() throws {
        let data = try makeJPEG(makeImage(width: 40, height: 20), orientation: 6)
        let png = try XCTUnwrap(ImageUtil.reencode(data, to: .png, maxPixelSize: 20))

        let source = try XCTUnwrap(CGImageSourceCreateWithData(png as CFData, nil))
        XCTAssertEqual(CGImageSourceGetType(source) as String?, UTType.png.identifier)

        // 缩放后已经按方向转正，方向必须归一为 1，否则查看器再转一次 → 躺倒
        let flat = ImageUtil.flatMetadata(png)
        XCTAssertEqual(flat["Orientation"] ?? "1", "1")

        let decoded = try XCTUnwrap(ImageUtil.downsample(png, maxPixelSize: 100))
        XCTAssertGreaterThan(decoded.height, decoded.width)
    }

    func testReencodeKeepsOrientationWhenNotResized() throws {
        let data = try makeJPEG(makeImage(width: 40, height: 20), orientation: 6)
        let output = try XCTUnwrap(ImageUtil.reencode(data, to: .jpeg, quality: 0.5))

        // 不缩放时像素没动，方向要原样保留，否则照片会翻过来
        XCTAssertEqual(ImageUtil.flatMetadata(output)["Orientation"], "6")
    }
}
