import XCTest
@testable import SwiftUtils

final class ResumeOnceGateTests: XCTestCase {
    func testOnlyOneCallerWins() {
        let gate = ResumeOnceGate()
        let lock = NSLock()
        var winners = 0

        DispatchQueue.concurrentPerform(iterations: 100) { _ in
            if gate.tryResume() {
                lock.lock()
                winners += 1
                lock.unlock()
            }
        }

        XCTAssertEqual(winners, 1, "并发 100 次必须只有一个拿到 true")
        XCTAssertTrue(gate.isResumed)
    }

    func testIsResumedDoesNotConsume() {
        let gate = ResumeOnceGate()
        XCTAssertFalse(gate.isResumed)
        XCTAssertTrue(gate.tryResume())
        XCTAssertTrue(gate.isResumed)
        XCTAssertFalse(gate.tryResume())
    }
}

final class TimeoutTests: XCTestCase {
    private struct SampleError: Error {}

    func testFinishesBeforeTimeout() async throws {
        let value = try await withTimeout(1) {
            try await Task.sleep(nanoseconds: 10_000_000)
            return 42
        }
        XCTAssertEqual(value, 42)
    }

    func testTimeoutFires() async {
        let start = Date()
        do {
            _ = try await withTimeout(0.05) {
                try await Task.sleep(nanoseconds: 2_000_000_000)
                return 1
            }
            XCTFail("应当超时")
        } catch {
            XCTAssertTrue(error is TimeoutError, "期望 TimeoutError，实际 \(error)")
        }
        XCTAssertLessThan(Date().timeIntervalSince(start), 0.5)
    }

    func testOperationErrorPropagates() async {
        do {
            _ = try await withTimeout(1) {
                throw SampleError()
            }
            XCTFail("应当抛错")
        } catch {
            XCTAssertTrue(error is SampleError)
        }
    }

    /// 回归：用 `withThrowingTaskGroup` 写的版本会在这里卡到 0.5 秒。
    /// group 返回前要等所有子任务结束，而 CheckedContinuation 不响应取消。
    func testTimeoutDoesNotWaitForNonCooperativeOperation() async {
        let start = Date()
        do {
            _ = try await withTimeout(0.05) {
                await withCheckedContinuation { (continuation: CheckedContinuation<Int, Never>) in
                    DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                        continuation.resume(returning: 1)
                    }
                }
            }
            XCTFail("应当超时")
        } catch {
            XCTAssertTrue(error is TimeoutError)
        }
        XCTAssertLessThan(Date().timeIntervalSince(start), 0.3, "超时后不能等 operation 自己结束")
    }

    func testCallerCancellationFinishesWithCancellationError() async {
        let task = Task { () -> Int in
            try await withTimeout(5) {
                try await Task.sleep(nanoseconds: 1_000_000_000)
                return 1
            }
        }
        try? await Task.sleep(nanoseconds: 50_000_000)
        task.cancel()

        do {
            _ = try await task.value
            XCTFail("应当抛错")
        } catch is CancellationError {
            // 期望：调用方取消 → CancellationError，而不是等满 5 秒
        } catch {
            XCTFail("期望 CancellationError，实际 \(error)")
        }
    }

    func testSleepNanosecondsClampsInvalidValues() {
        XCTAssertEqual(sleepNanoseconds(-1), 0)
        XCTAssertEqual(sleepNanoseconds(0), 0)
        XCTAssertEqual(sleepNanoseconds(.nan), 0)
        XCTAssertEqual(sleepNanoseconds(.infinity), UInt64.max)
        XCTAssertEqual(sleepNanoseconds(1), 1_000_000_000)
    }
}

final class AsyncDebouncerTests: XCTestCase {
    private final class LockedCounter: @unchecked Sendable {
        private let lock = NSLock()
        private var count = 0

        func increment() {
            lock.lock()
            count += 1
            lock.unlock()
        }

        var value: Int {
            lock.lock()
            defer { lock.unlock() }
            return count
        }
    }

    func testOnlyLastScheduleRuns() async {
        let debouncer = AsyncDebouncer()
        let counter = LockedCounter()

        for _ in 0..<5 {
            await debouncer.schedule(delay: 0.05) { counter.increment() }
        }
        await debouncer.waitForPending()

        XCTAssertEqual(counter.value, 1)
    }

    func testCancelPreventsExecution() async {
        let debouncer = AsyncDebouncer()
        let counter = LockedCounter()

        await debouncer.schedule(delay: 0.05) { counter.increment() }
        await debouncer.cancel()
        try? await Task.sleep(nanoseconds: 150_000_000)

        XCTAssertEqual(counter.value, 0)
    }

    func testWaitForPendingWithoutScheduleReturnsImmediately() async {
        let debouncer = AsyncDebouncer()
        await debouncer.waitForPending()
    }
}

final class RetryPolicyTests: XCTestCase {
    func testExponentialBackoff() {
        let policy = RetryPolicy(maxAttempts: 3, baseDelay: 0.5, multiplier: 2, maxDelay: 60)

        XCTAssertEqual(policy.delay(forAttempt: 1), 0.5)
        XCTAssertEqual(policy.delay(forAttempt: 2), 1.0)
        XCTAssertNil(policy.delay(forAttempt: 3), "最后一次失败后不该再来一轮")
    }

    func testInvalidAttemptsDoNotRetry() {
        let policy = RetryPolicy(maxAttempts: 3)

        XCTAssertNil(policy.delay(forAttempt: 0))
        XCTAssertNil(policy.delay(forAttempt: -1))
        XCTAssertNil(policy.delay(forAttempt: Int.max))
    }

    func testMaxDelayClampsGrowth() {
        let policy = RetryPolicy(maxAttempts: 10, baseDelay: 1, multiplier: 10, maxDelay: 5)
        XCTAssertEqual(policy.delay(forAttempt: 2), 5)
        XCTAssertEqual(policy.delay(forAttempt: 9), 5)
    }

    func testSingleAttemptNeverRetries() {
        let policy = RetryPolicy(maxAttempts: 1)
        XCTAssertNil(policy.delay(forAttempt: 1))
    }
}
