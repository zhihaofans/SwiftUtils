import AVFoundation
import XCTest
@testable import SwiftUtils

final class MediaUtilTests: XCTestCase {
    func testPresetMapping() {
        // 枚举存在的意义就是不要手写 preset 字符串
        XCTAssertEqual(MediaUtil.Preset.highestQuality.name, AVAssetExportPresetHighestQuality)
        XCTAssertEqual(MediaUtil.Preset.mediumQuality.name, AVAssetExportPresetMediumQuality)
        XCTAssertEqual(MediaUtil.Preset.lowQuality.name, AVAssetExportPresetLowQuality)
        XCTAssertEqual(MediaUtil.Preset.passthrough.name, AVAssetExportPresetPassthrough)
    }

    func testInfoThrowsOnCorruptFile() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).mp4")
        try Data().write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        do {
            _ = try await MediaUtil.info(AVURLAsset(url: url))
            XCTFail("损坏的媒体应当抛错，而不是返回「0 秒空视频」")
        } catch {
            // 期望把底层 AVError 传出来；这里不吞成 0，调用方才分得出「空」和「坏了」
        }
    }

    func testExportProducesPlayableFile() async throws {
        let source = try await makeTestVideo()
        defer { try? FileManager.default.removeItem(at: source) }

        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString)-out.mp4")
        defer { try? FileManager.default.removeItem(at: output) }

        try await MediaUtil.export(AVURLAsset(url: source), to: output)

        XCTAssertTrue(FileManager.default.fileExists(atPath: output.path))

        let info = try await MediaUtil.info(AVURLAsset(url: output))
        XCTAssertGreaterThan(info.duration, 0)
        XCTAssertTrue(info.hasVideo)
    }

    func testExportDeletesExistingOutputBeforeWriting() async throws {
        let source = try await makeTestVideo()
        defer { try? FileManager.default.removeItem(at: source) }

        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString)-overwrite.mp4")
        defer { try? FileManager.default.removeItem(at: output) }

        // 目标已存在时 AVAssetExportSession 会直接失败，这里必须先删
        try Data("stale".utf8).write(to: output)
        try await MediaUtil.export(AVURLAsset(url: source), to: output)

        XCTAssertGreaterThan(try FileManager.default.attributesOfItem(atPath: output.path)[.size] as? Int ?? 0, 4)
    }

    func testExportFailsOnAssetWithoutTracks() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString).mp4")
        try Data().write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString)-fail.mp4")
        defer { try? FileManager.default.removeItem(at: output) }

        do {
            try await MediaUtil.export(AVURLAsset(url: url), to: output)
            XCTFail("没有音视频轨的资产不该导出成功")
        } catch {
            // cannotCreateSession / exportFailed 都可以，关键是不要静默成功
        }
    }

    // MARK: - 测试视频

    /// 用 AVAssetWriter 现造一个 0.4 秒、32×32 的 H.264 视频。
    /// 编码器在无 GUI 的测试进程里也可能不可用，此时跳过而不是假绿。
    private func makeTestVideo() async throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString)-source.mp4")

        let writer: AVAssetWriter
        do {
            writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
        } catch {
            throw XCTSkip("无法创建 AVAssetWriter: \(error.localizedDescription)")
        }

        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 32,
            AVVideoHeightKey: 32,
        ])
        input.expectsMediaDataInRealTime = false

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: 32,
                kCVPixelBufferHeightKey as String: 32,
            ]
        )

        guard writer.canAdd(input) else {
            throw XCTSkip("无法添加视频轨")
        }
        writer.add(input)

        guard writer.startWriting() else {
            throw XCTSkip("无法开始写入: \(writer.error?.localizedDescription ?? "未知")")
        }
        writer.startSession(atSourceTime: .zero)

        for frame in 0..<4 {
            var pixelBuffer: CVPixelBuffer?
            guard let pool = adaptor.pixelBufferPool,
                  CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer) == kCVReturnSuccess,
                  let pixelBuffer
            else {
                throw XCTSkip("无法创建像素缓冲")
            }

            CVPixelBufferLockBaseAddress(pixelBuffer, [])
            if let base = CVPixelBufferGetBaseAddress(pixelBuffer) {
                memset(base, 0x7F, CVPixelBufferGetDataSize(pixelBuffer))
            }
            CVPixelBufferUnlockBaseAddress(pixelBuffer, [])

            while !input.isReadyForMoreMediaData {
                try await Task.sleep(nanoseconds: 1_000_000)
            }

            guard adaptor.append(pixelBuffer, withPresentationTime: CMTime(value: Int64(frame), timescale: 10)) else {
                throw XCTSkip("append 帧失败: \(writer.error?.localizedDescription ?? "未知")")
            }
        }

        input.markAsFinished()
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            writer.finishWriting { continuation.resume() }
        }

        guard writer.status == .completed else {
            throw XCTSkip("写入测试视频失败: \(writer.error?.localizedDescription ?? "未知")")
        }
        return url
    }
}
