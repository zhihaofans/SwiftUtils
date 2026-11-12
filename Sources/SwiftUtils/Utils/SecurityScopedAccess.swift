//
//  SecurityScopedAccess.swift
//  SwiftUtils
//
//  Created by zzh on 2026/11/12.
//

import Foundation

/// 安全作用域资源访问。
///
/// App 沙箱里，用户在文件 App / 打开面板里选中的目录，拿到的是「安全作用域 URL」：
/// 只有 `startAccessingSecurityScopedResource()` 之后才能 IO，用完必须 `stop`。
/// 最常见的 bug 是「打开时能用，下次启动就拒绝访问」——因为只存了 URL，没存书签。
public enum SecurityScopedAccess {
    /// 在安全作用域内执行 `body`，退出时（含抛错）一定 `stop`。
    ///
    /// - Note: 对普通 URL，`startAccessingSecurityScopedResource()` 会返回 `false`，
    ///   这是正常情况（表示不需要 stop），不要因此当成错误。
    /// - Important: 作用域只在闭包内有效。跨启动要保留访问权，得存书签
    ///   （仅 macOS / Catalyst 可用，见下面的重载）；别把 `url` 存下来下次直接用。
    @discardableResult
    public static func withAccess<T>(to url: URL, _ body: () throws -> T) rethrows -> T {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        return try body()
    }

    /// 异步版本，语义同 `withAccess(to:_:)`。
    @discardableResult
    public static func withAccess<T>(to url: URL, _ body: () async throws -> T) async rethrows -> T {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        return try await body()
    }

    #if os(macOS) || targetEnvironment(macCatalyst)
    /// 生成安全作用域书签，用于跨启动保留用户选中的目录/文件。
    ///
    /// - Note: 安全作用域书签只有 macOS / Catalyst 有
    ///   （`NSURLBookmarkCreationWithSecurityScope` 在 iOS / watchOS / tvOS 上是 unavailable），
    ///   所以这段用条件编译包起来。
    public static func bookmark(for url: URL) throws -> Data {
        try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }

    /// 解析书签。`isStale == true` 时应重新生成并覆盖旧数据。
    ///
    /// - Important: 解析出来的 URL 仍然要包在 `withAccess` 里才能读写。
    public static func resolve(_ bookmark: Data) throws -> (url: URL, isStale: Bool) {
        var isStale = false
        let url = try URL(
            resolvingBookmarkData: bookmark,
            options: [.withSecurityScope],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        return (url, isStale)
    }
    #endif
}
