//
//  FileUtil.swift
//  SwiftUtils
//
//  Created by zzh on 2026/11/12.
//

import Foundation

/// 文件基础操作。
///
/// 设计原则：**只做 Foundation 已经能做、但容易被写错的那一层**。
/// 尤其不要在这里重新发明「原子写」「唯一文件名」——写错不会报错，只会偶发丢文件。
public enum FileUtil {
    // MARK: - 读写

    /// 原子写入。
    ///
    /// 实现就是 `Data.write(options: .atomic)`，**没有**再套一层 `replaceItemAt`。
    /// 草案里的双层原子写有两个问题：
    /// 1. 系统写临时文件失败时，`.tmp-UUID` 会残留在用户目录里（草案没有清理路径）；
    /// 2. `replaceItemAt` 跨卷直接抛 `EXDEV`，而 `Data.write` 自己会处理跨卷。
    ///
    /// - Parameter coordinated: 目标可能被 iCloud Drive / 文件 App 的其它进程同时读写时传 `true`。
    ///   `NSFileCoordinator` 三平台都有（watchOS 2+），但手表上没有文件 App，一般只在 macOS / iOS 用。
    /// - Important: 父目录必须已经存在；这里不替你建目录（建目录该由调用方决定，静默创建经常是 bug）。
    public static func write(_ data: Data, to url: URL, coordinated: Bool = false) throws {
        guard coordinated else {
            try data.write(to: url, options: .atomic)
            return
        }
        var coordinationError: NSError?
        var writeError: Error?
        NSFileCoordinator().coordinate(writingItemAt: url, options: .forReplacing, error: &coordinationError) { target in
            do {
                try data.write(to: target, options: .atomic)
            } catch {
                writeError = error
            }
        }
        if let coordinationError { throw coordinationError }
        if let writeError { throw writeError }
    }

    /// 读取整个文件；`coordinated` 含义同 `write`。
    public static func read(_ url: URL, coordinated: Bool = false) throws -> Data {
        guard coordinated else {
            return try Data(contentsOf: url)
        }
        var coordinationError: NSError?
        var result: Result<Data, Error>?
        NSFileCoordinator().coordinate(readingItemAt: url, options: [], error: &coordinationError) { target in
            result = Result { try Data(contentsOf: target) }
        }
        if let coordinationError { throw coordinationError }
        guard let result else { throw CocoaError(.fileReadUnknown) }
        return try result.get()
    }

    // MARK: - 目录

    /// 确保目录存在（含中间层级）；已存在时什么都不做。
    public static func createDirectoryIfNeeded(_ url: URL) throws {
        guard !FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    /// 删除文件或目录；不存在时静默返回。
    ///
    /// - Note: 这里**不**用 `try?` 把失败吞掉——删除失败通常要告诉用户（权限、被占用）。
    ///   只有「本来就不存在」算成功。
    public static func removeIfExists(_ url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        try FileManager.default.removeItem(at: url)
    }

    // MARK: - 临时目录

    /// 建一个临时目录，删除由返回的 `TemporaryDirectory` 负责（`deinit` 自动清理）。
    ///
    /// 草案是「返回 URL + 调用方记得 remove」：异常路径一多就忘，tmp 目录只增不减。
    /// 改成 RAII 后，无论是正常返回、抛错还是提前 `return`，都能清掉。
    ///
    /// - Note: 没有用 `.itemReplacementDirectory`：那个是给「同卷原子替换」找目录用的，
    ///   语义不是通用临时目录，而且要求传一个「将被替换的文件」URL。
    public static func makeTemporaryDirectory(prefix: String = "SwiftUtils") throws -> TemporaryDirectory {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(prefix)-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return TemporaryDirectory(url: url)
    }

    // MARK: - 唯一文件名

    /// 在 `directory` 里按 `preferredName` 找一个当前不存在的名字，返回**建议值**。
    ///
    /// - Important: 这不是「预留」。从返回，到调用方真正创建文件之间，别的进程/任务
    ///   可能已经占用了同一个名字（check-then-create 的 TOCTOU）。
    ///   要让名字真的唯一，用 `createUniqueFile`。
    ///   保留这个 API 是因为 UI 需要先展示「将保存为 xxx-1.jpg」。
    /// - Note: APFS 默认大小写不敏感，`IMG.PNG` 和 `img.png` 会撞；判重交给 `FileManager` 即可。
    public static func uniqueURL(in directory: URL, preferredName: String, maxAttempts: Int = 10_000) -> URL {
        let name = preferredName as NSString
        let base = name.deletingPathExtension
        let ext = name.pathExtension
        var candidate = directory.appendingPathComponent(preferredName)
        var index = 1
        while FileManager.default.fileExists(atPath: candidate.path), index < maxAttempts {
            let fileName = ext.isEmpty ? "\(base)-\(index)" : "\(base)-\(index).\(ext)"
            candidate = directory.appendingPathComponent(fileName)
            index += 1
        }
        return candidate
    }

    /// 原子地占住一个唯一文件名，并写入 `contents`（默认空）。
    ///
    /// 和 `uniqueURL` 的区别：这里用 `.withoutOverwriting` 让内核判重，
    /// 两个并发调用不可能拿到同一个名字。批量拖入文件、并发导出时会用到——
    /// 只做 `fileExists` 判断的版本在这种情况下会互相覆盖。
    ///
    /// - Returns: 真正创建成功的 URL；重名时依次变成 `name-1.ext`、`name-2.ext`。
    @discardableResult
    public static func createUniqueFile(
        in directory: URL,
        preferredName: String,
        contents: Data = Data(),
        maxAttempts: Int = 10_000
    ) throws -> URL {
        guard maxAttempts > 0 else { throw CocoaError(.fileWriteFileExists) }

        let name = preferredName as NSString
        let base = name.deletingPathExtension
        let ext = name.pathExtension

        for index in 1...maxAttempts {
            // index 1 用原名，之后从 -1 开始，和 `uniqueURL` 的建议名保持一致
            let fileName: String
            if index == 1 {
                fileName = preferredName
            } else {
                let suffix = index - 1
                fileName = ext.isEmpty ? "\(base)-\(suffix)" : "\(base)-\(suffix).\(ext)"
            }
            let candidate = directory.appendingPathComponent(fileName)
            do {
                try contents.write(to: candidate, options: .withoutOverwriting)
                return candidate
            } catch let error as CocoaError where error.code == .fileWriteFileExists {
                continue
            }
        }
        throw CocoaError(.fileWriteFileExists)
    }

    // MARK: - 体积统计

    /// 目录体积的计量口径。
    public enum SizeMetric: Sendable {
        /// 内容大小：文件里实际有多少字节。
        case content
        /// 占用磁盘：按块对齐后的实际占用，通常比内容大（小文件尤其明显）。
        case allocated
    }

    /// 递归统计目录体积（字节）。
    ///
    /// 草案是同步实现：枚举大目录（几万个文件、iCloud 未下载占位符）会把调用方线程堵住几秒，
    /// 在主线程上就是白屏/掉帧。这里改成 `async`，并在每个条目上响应取消。
    ///
    /// - Returns: 读不到权限、目录不存在时返回 `0`，不抛错（统计类调用的惯例）。
    /// - Important: `0` 既可能是空目录，也可能是读不到。需要区分时自己用 `FileManager` 枚举。
    public static func directorySize(
        _ url: URL,
        metric: SizeMetric = .content,
        includingHidden: Bool = false
    ) async -> Int64 {
        let keys: Set<URLResourceKey> = metric == .content
            ? [.fileSizeKey, .isDirectoryKey]
            : [.totalFileAllocatedSizeKey, .isDirectoryKey]

        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: Array(keys),
            options: includingHidden ? [] : [.skipsHiddenFiles]
        ) else { return 0 }

        var total: Int64 = 0
        // 用 nextObject() 而不是 for-in：NSEnumerator 的 Sequence 迭代在 async 上下文里
        // 被标成 noasync（Swift 6 直接报错），这里逐个取下一个就没事。
        while let item = enumerator.nextObject() {
            if Task.isCancelled { return total }
            guard let fileURL = item as? URL,
                  let values = try? fileURL.resourceValues(forKeys: keys),
                  values.isDirectory != true
            else { continue }

            let size = metric == .content
                ? values.fileSize ?? 0
                : values.totalFileAllocatedSize ?? 0
            let (sum, overflow) = total.addingReportingOverflow(Int64(size))
            total = overflow ? Int64.max : sum
        }
        return total
    }
}

/// 临时目录句柄：`deinit` 时自动删除。
///
/// 显式 `remove()` 可以提前删除；重复调用是安全的。
public final class TemporaryDirectory: @unchecked Sendable {
    public let url: URL

    private let lock = NSLock()
    private var removed = false

    init(url: URL) {
        self.url = url
    }

    deinit {
        remove()
    }

    /// 立即删除目录（可重复调用）。
    public func remove() {
        lock.lock()
        guard !removed else {
            lock.unlock()
            return
        }
        removed = true
        lock.unlock()
        // 已经被别人删掉/系统清理，不算错误
        try? FileManager.default.removeItem(at: url)
    }

    /// 是否已经删除。
    public var isRemoved: Bool {
        lock.lock()
        defer { lock.unlock() }
        return removed
    }
}
