//
//  AsyncUtil.swift
//  SwiftUtils
//
//  Created by zzh on 2026/11/12.
//

import Foundation

// MARK: - 超时

/// 超时错误。
public struct TimeoutError: Error, Equatable, Sendable {
    public init() {}
}

/// 给一个异步操作加超时。
///
/// 草案的签名用 `Duration`，**在 macOS 12 上不存在**（`Duration` 要求 macOS 13 / iOS 16 / watchOS 9，
/// 本包最低 macOS 12），所以这里用 `TimeInterval`。等最低版本升到 13 再加 `Duration` 重载。
///
/// 实现没有用 `withThrowingTaskGroup`：
/// group 在返回前会等**所有**子任务结束，而卡在非协作系统调用里的 `operation` 永远不会结束，
/// 超时于是永远不生效 —— 这正是「明明加了超时还是卡死」的经典原因。
/// 这里用非结构化 `Task` + `ResumeOnceGate`：谁先到谁 resume，另一条路径直接放弃。
///
/// - Important: 超时/取消之后，`operation` 只是被**请求**取消。它如果已经卡在
///   `read()`、Vision、Core ML 这类不检查取消的地方，会继续跑到自己结束（结果被丢弃）。
///   需要「超时后绝不能写入」的调用方，还得自己加 token 判断。
/// - Note: 调用方取消时，这里会以 `CancellationError` 结束，而不是 `TimeoutError`。
public func withTimeout<T: Sendable>(
    _ seconds: TimeInterval,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    let gate = ResumeOnceGate()
    let box = ContinuationBox<T>()

    let work = Task {
        do {
            let value = try await operation()
            if gate.tryResume() { box.resume(with: .success(value)) }
        } catch {
            if gate.tryResume() { box.resume(with: .failure(error)) }
        }
    }

    let timer = Task {
        do {
            try await Task.sleep(nanoseconds: sleepNanoseconds(seconds))
        } catch {
            // 被 defer 取消：说明已经有结果了，什么都不做
            return
        }
        if gate.tryResume() {
            work.cancel()
            box.resume(with: .failure(TimeoutError()))
        }
    }

    defer { timer.cancel() }

    return try await withTaskCancellationHandler {
        try await box.value()
    } onCancel: {
        if gate.tryResume() {
            work.cancel()
            timer.cancel()
            box.resume(with: .failure(CancellationError()))
        }
    }
}

/// 「结果」和「等待者」谁先到都能正确处理。
///
/// 这是 `withTimeout` 自己的内部件：如果把 continuation 先存进变量、等结果回来再 resume，
/// 结果是「结果先到」时会 resume 一个还不存在的 continuation（崩溃或丢结果）。
private final class ContinuationBox<T: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<T, Error>?
    private var result: Result<T, Error>?

    func value() async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            lock.lock()
            if let result {
                self.result = nil
                lock.unlock()
                continuation.resume(with: result)
            } else if self.continuation == nil {
                self.continuation = continuation
                lock.unlock()
            } else {
                // 只支持一个等待者；第二个直接报错，避免继续堆积
                lock.unlock()
                continuation.resume(throwing: TimeoutError())
            }
        }
    }

    func resume(with result: Result<T, Error>) {
        lock.lock()
        if let continuation {
            self.continuation = nil
            lock.unlock()
            continuation.resume(with: result)
        } else if self.result == nil {
            self.result = result
            lock.unlock()
        } else {
            lock.unlock()
        }
    }
}

/// `TimeInterval` → `Task.sleep` 需要的纳秒数；负数/NaN 视为 0，无穷大视为「最长」。
func sleepNanoseconds(_ seconds: TimeInterval) -> UInt64 {
    // NaN 与负数都在这里被挡掉（`NaN > 0` 为 false）
    guard seconds > 0 else { return 0 }
    if seconds.isInfinite { return UInt64.max }
    let value = seconds * 1_000_000_000
    return value >= Double(UInt64.max) ? UInt64.max : UInt64(value)
}

// MARK: - 防抖

/// 高频事件合并：延迟窗口内多次 `schedule` 只执行最后一次。
///
/// 典型场景：`photoLibraryDidChange` 一次新增触发多条通知、滚动/输入触发的重建。
///
/// - Note: 取消是「请求」。如果上一次 `operation` 已经**开始执行**，这里拦不住它，
///   也不会等它结束——需要互斥的副作用，自己在 `operation` 里判断 `Task.isCancelled`。
/// - Note: 刻意没有 `deinit` 取消：actor 的 `deinit` 里碰隔离状态在 Swift 5 模式下受限。
///   长期存活的 debouncer 请在合适的时机显式 `cancel()`。
public actor AsyncDebouncer {
    private var pending: Task<Void, Never>?

    public init() {}

    /// 延迟 `delay` 秒执行；期间再次调用会取消上一次。
    public func schedule(delay: TimeInterval = 0.4, operation: @escaping @Sendable () async -> Void) {
        pending?.cancel()
        pending = Task {
            do {
                try await Task.sleep(nanoseconds: sleepNanoseconds(delay))
            } catch {
                // 被后来的 schedule 或 cancel 取消：静默退出。
                // 这里不要打日志——高频事件会把日志刷满，而且「取消」是正常路径。
                return
            }
            guard !Task.isCancelled else { return }
            await operation()
        }
    }

    /// 取消挂起的执行（已经开始的 `operation` 不受影响）。
    public func cancel() {
        pending?.cancel()
        pending = nil
    }

    /// 等当前挂起的任务结束；主要给测试用。没有挂起任务时立即返回。
    public func waitForPending() async {
        await pending?.value
    }
}

// MARK: - 重试

/// 重试策略：次数 + 指数退避。纯值类型，不碰存储和网络。
public struct RetryPolicy: Sendable, Equatable {
    /// 总尝试次数（含第一次）。
    public let maxAttempts: Int
    /// 第一次重试前的等待秒数。
    public let baseDelay: TimeInterval
    /// 每次失败后延迟的倍数。
    public let multiplier: Double
    /// 单次延迟上限，防止指数增长到几小时。
    public let maxDelay: TimeInterval

    public init(
        maxAttempts: Int = 3,
        baseDelay: TimeInterval = 0.5,
        multiplier: Double = 2,
        maxDelay: TimeInterval = 60
    ) {
        self.maxAttempts = maxAttempts
        self.baseDelay = baseDelay
        self.multiplier = multiplier
        self.maxDelay = maxDelay
    }

    /// 第 `attempt` 次失败后该等多久再试；`nil` 表示不再重试。
    ///
    /// - Parameter attempt: 已经失败的次数，从 1 开始。
    /// - Note: 保留 optional 返回，而不是草案里的非 optional `Duration`：
    ///   1. `Duration` 在 macOS 12 上不可用（同 `withTimeout` 的说明）；
    ///   2. 「该不该重试」和「等多久」是两件事，合成一个值会让调用方再判断一次 attempt。
    public func delay(forAttempt attempt: Int) -> TimeInterval? {
        guard attempt >= 1, attempt < maxAttempts else { return nil }

        // 指数在 attempt 很大时会溢出成 inf，直接退到上限
        let raw = baseDelay * pow(multiplier, Double(attempt - 1))
        guard raw.isFinite else { return maxDelay }
        return min(raw, maxDelay)
    }
}
