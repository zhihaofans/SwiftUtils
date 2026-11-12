//
//  ResumeOnceGate.swift
//  SwiftUtils
//
//  Created by zzh on 2026/11/12.
//

import Foundation

/// 保证一段逻辑只执行一次（线程安全）。
///
/// 用在你控制不了回调次数、又必须让后续流程只走一遍的地方：
/// - `withCheckedContinuation` 被系统 API 调了两次 —— 第二次 resume 在 Swift 5 里直接崩
/// - 成功回调和超时回调赛跑 —— 调用方会收到两次结果
///
/// 和 `NetworkUtil` 里原来的私有 `CallbackGate` 是同一个东西，公开后两处共用，
/// 不再让每个调用方自己复制一份 `NSLock`。
///
/// - Note: 用锁而不是 `actor`。这些回调发生在任意队列（`NWPathMonitor` 的后台队列、
///   PhotoKit 的回调队列），而且中间没有 `await` 可以让出；做成 actor 反而要
///   在每个回调里包一层 `Task`，回调顺序就不再可信了。
public final class ResumeOnceGate: @unchecked Sendable {
    private let lock = NSLock()
    private var resumed = false

    public init() {}

    /// 第一次调用返回 `true`，之后（含并发）都返回 `false`。
    ///
    /// - Important: 只负责「占位」，不负责 resume。拿到 `true` 的一方才去 resume continuation，
    ///   不要把 `tryResume()` 放在 `await` 之后 —— 让出期间别人可能已经抢走了。
    @discardableResult
    public func tryResume() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !resumed else { return false }
        resumed = true
        return true
    }

    /// 只读查询，不占名额。用于诊断「是不是已经被别人抢走了」。
    public var isResumed: Bool {
        lock.lock()
        defer { lock.unlock() }
        return resumed
    }
}
