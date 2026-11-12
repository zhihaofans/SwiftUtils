import CoreGraphics
import XCTest
@testable import SwiftUtils

final class PDFUtilTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("SwiftUtilsPDFTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
    }

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
        context.setFillColor(CGColor(red: 0.9, green: 0.3, blue: 0.1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()!
    }

    func testMakePDFThenRenderPage() throws {
        let pdf = directory.appendingPathComponent("out.pdf")
        try PDFUtil.makePDF(
            from: [makeImage(width: 100, height: 100), makeImage(width: 100, height: 50)],
            to: pdf
        )

        XCTAssertEqual(try PDFUtil.pageCount(pdf), 2)

        let first = try XCTUnwrap(try PDFUtil.pageImage(pdf, page: 0, maxPixelSize: 50))
        XCTAssertEqual(first.width, 50)
        XCTAssertEqual(first.height, 50)

        // 第二页内容比例不同，但页面尺寸跟着第一页，渲染结果仍是 50×50
        let second = try XCTUnwrap(try PDFUtil.pageImage(pdf, page: 1, maxPixelSize: 50))
        XCTAssertEqual(second.width, 50)
        XCTAssertEqual(second.height, 50)
    }

    func testPageOutOfRange() throws {
        let pdf = directory.appendingPathComponent("single.pdf")
        try PDFUtil.makePDF(from: [makeImage(width: 20, height: 20)], to: pdf)

        XCTAssertThrowsError(try PDFUtil.pageImage(pdf, page: 1, maxPixelSize: 10)) { error in
            XCTAssertEqual(error as? PDFUtil.PDFError, .pageOutOfRange(1))
        }
        XCTAssertThrowsError(try PDFUtil.pageImage(pdf, page: -1, maxPixelSize: 10)) { error in
            XCTAssertEqual(error as? PDFUtil.PDFError, .pageOutOfRange(-1))
        }
    }

    func testPageCountFailsForNonPDF() throws {
        let text = directory.appendingPathComponent("note.txt")
        try Data("hello".utf8).write(to: text)

        XCTAssertThrowsError(try PDFUtil.pageCount(text)) { error in
            XCTAssertEqual(error as? PDFUtil.PDFError, .cannotOpenDocument)
        }
    }

    func testMakePDFWithNoImagesThrows() {
        let pdf = directory.appendingPathComponent("empty.pdf")
        XCTAssertThrowsError(try PDFUtil.makePDF(from: [], to: pdf)) { error in
            XCTAssertEqual(error as? PDFUtil.PDFError, .emptyImages)
        }
    }

    func testPageImageRejectsNonPositivePixelSize() throws {
        let pdf = directory.appendingPathComponent("size.pdf")
        try PDFUtil.makePDF(from: [makeImage(width: 20, height: 20)], to: pdf)
        XCTAssertNil(try PDFUtil.pageImage(pdf, page: 0, maxPixelSize: 0))
    }
}
