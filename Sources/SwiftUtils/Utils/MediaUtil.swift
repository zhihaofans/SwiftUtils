//
//  MediaUtil.swift
//  SwiftUtils
//
//  Created by zzh on 2026/11/12.
//

#if os(iOS) || os(macOS)

import AVFoundation
import Foundation

/// 音视频：导出、基本信息。
///
/// 为什么整个文件包在 `#if os(iOS) || os(macOS)` 里：
/// `AVAssetExportSession` 在 watchOS SDK 里是 `API_UNAVAILABLE(watchos)`，
/// 手表上也没有「另存为视频」的场景。
public enum MediaUtil {
    public enum MediaError: Error, Equatable {
        case cannotCreateSession
        case unsupportedFileType(String)
        case exportFailed(String)
        case cancelled
    }

    /// 导出预设。用枚举而不是裸 `String`：
    /// `AVAssetExportSession(asset:presetName:)` 在 preset 名字拼错时返回 `nil`，
    /// 静默失败，排查起来比编译错误贵得多。
    public enum Preset: Sendable {
        case highestQuality
        case mediumQuality
        case lowQuality
        case passthrough

        var name: String {
            switch self {
            case .highestQuality: return AVAssetExportPresetHighestQuality
            case .mediumQuality: return AVAssetExportPresetMediumQuality
            case .lowQuality: return AVAssetExportPresetLowQuality
            case .passthrough: return AVAssetExportPresetPassthrough
            }
        }
    }

    public struct MediaInfo: Sendable, Equatable {
        /// 时长（秒）。无法读取时为 0。
        public let duration: TimeInterval
        /// 视频显示尺寸：已按 `preferredTransform` 把旋转算进去（竖拍视频不会是 1920×1080 的横图）。
        public let naturalSize: CGSize
        public let hasVideo: Bool
        public let hasAudio: Bool
    }

    /// 读取时长 / 分辨率 / 有无音视频轨。
    ///
    /// - Note: 用 `try await asset.load(...)` 而不是同步的 `asset.duration`：
    ///   `AVAsset` 的属性在读取前要先加载，同步访问在未加载时会得到默认值
    ///   （时长 0、尺寸 .zero），并且已经在 iOS 16 起被标记 deprecated。
    public static func info(_ asset: AVAsset) async throws -> MediaInfo {
        let duration = try await asset.load(.duration)
        let videoTracks = try await asset.loadTracks(withMediaType: .video)
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)

        var size = CGSize.zero
        if let track = videoTracks.first {
            let naturalSize = try await track.load(.naturalSize)
            let transform = try await track.load(.preferredTransform)
            // 竖拍视频的 naturalSize 是横的，preferredTransform 里带 90° 旋转
            let transformed = naturalSize.applying(transform)
            size = CGSize(width: abs(transformed.width), height: abs(transformed.height))
        }

        return MediaInfo(
            duration: duration.isValid ? duration.seconds : 0,
            naturalSize: size,
            hasVideo: !videoTracks.isEmpty,
            hasAudio: !audioTracks.isEmpty
        )
    }

    /// 导出到 `outputURL`。
    ///
    /// - Important: 会先删掉已存在的 `outputURL`。`AVAssetExportSession` 在目标已存在时
    ///   直接失败（错误信息还不明显），这是最常见的「导出莫名其妙失败」。
    /// - Important: 结束时检查 `status`。只看 completion 回调会漏掉失败：
    ///   `exportAsynchronously` 无论成功失败都会回调。
    /// - Note: 进度只能轮询 `session.progress`（这个 API 没有进度回调）。
    ///   本方法不轮询：在异步上下文里加 Timer 会拖住调用方，需要进度的调用方自己封装。
    public static func export(
        _ asset: AVAsset,
        to outputURL: URL,
        preset: Preset = .highestQuality,
        fileType: AVFileType = .mp4
    ) async throws {
        try? FileManager.default.removeItem(at: outputURL)

        guard let session = AVAssetExportSession(asset: asset, presetName: preset.name) else {
            throw MediaError.cannotCreateSession
        }
        guard session.supportedFileTypes.contains(fileType) else {
            throw MediaError.unsupportedFileType(fileType.rawValue)
        }

        session.outputURL = outputURL
        session.outputFileType = fileType

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            session.exportAsynchronously { continuation.resume() }
        }

        switch session.status {
        case .completed:
            return
        case .cancelled:
            throw MediaError.cancelled
        case .failed:
            throw MediaError.exportFailed(session.error?.localizedDescription ?? "未知错误")
        default:
            throw MediaError.exportFailed("导出结束但状态异常 (\(session.status.rawValue))")
        }
    }
}

#endif
