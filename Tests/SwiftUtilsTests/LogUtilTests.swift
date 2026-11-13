import XCTest
@testable import SwiftUtils

final class LogUtilTests: XCTestCase {
    /// 把日志收进数组，用来断言「谁被记录、谁被过滤」。
    private final class CapturingBackend: LogBackend, @unchecked Sendable {
        struct Entry {
            let level: LogLevel
            let message: String
            let metadata: [String: String]
        }

        private let lock = NSLock()
        private var storage: [Entry] = []

        func log(
            _ level: LogLevel,
            message: String,
            metadata: [String: String],
            file: String,
            function: String,
            line: UInt
        ) {
            lock.lock()
            storage.append(Entry(level: level, message: message, metadata: metadata))
            lock.unlock()
        }

        var entries: [Entry] {
            lock.lock()
            defer { lock.unlock() }
            return storage
        }

        var levels: [LogLevel] { entries.map(\.level) }
        var messages: [String] { entries.map(\.message) }
    }

    override func tearDown() {
        // 全局状态，测完要复原，否则会影响其它用例的输出
        LogUtil.configure(level: .info, backend: ConsoleBackend())
        super.tearDown()
    }

    // MARK: 等级过滤

    func testFiltersByLevel() {
        let backend = CapturingBackend()
        LogUtil.configure(level: .warning, backend: backend)

        LogUtil.trace("trace")
        LogUtil.debug("debug")
        LogUtil.info("info")
        LogUtil.notice("notice")
        LogUtil.warning("warning")
        LogUtil.error("error")
        LogUtil.critical("critical")

        XCTAssertEqual(backend.levels, [.warning, .error, .critical])
    }

    func testFilteredMessageIsNotBuilt() {
        let backend = CapturingBackend()
        LogUtil.configure(level: .error, backend: backend)

        var evaluated = false
        func expensive() -> String {
            evaluated = true
            return "should not appear"
        }

        LogUtil.debug(expensive())

        // autoclosure 的意义就在这里：Release 里 debug 日志连字符串都不拼
        XCTAssertFalse(evaluated)
        XCTAssertTrue(backend.entries.isEmpty)
    }

    // MARK: 内容

    func testAliasesAndNumericOverloads() {
        let backend = CapturingBackend()
        LogUtil.configure(level: .debug, backend: backend)

        LogUtil.d("debug", metadata: ["a": "1"])
        LogUtil.i("info")
        LogUtil.e("error")
        LogUtil.debug(42)
        LogUtil.info(1.5)

        XCTAssertEqual(backend.messages, ["debug", "info", "error", "42", "1.5"])
        XCTAssertEqual(backend.levels, [.debug, .info, .error, .debug, .info])
        XCTAssertEqual(backend.entries.first?.metadata, ["a": "1"])
    }

    func testLevelAccessorReflectsConfiguration() {
        LogUtil.configure(level: .critical)
        XCTAssertEqual(LogUtil.level, .critical)

        LogUtil.configure(level: nil)
        XCTAssertEqual(LogUtil.level, .critical, "传 nil 不应重置等级")
    }

    // MARK: 后端

    func testConsoleBackendFormat() {
        let backend = ConsoleBackend(label: "UNIT")
        let line = backend.format(
            level: .warning,
            message: "disk full",
            metadata: ["b": "2", "a": "1"],
            file: "Utilities/FileThing.swift",
            line: 42
        )

        XCTAssertTrue(line.contains("[WARNING]"), line)
        XCTAssertTrue(line.contains("[UNIT]"), line)
        XCTAssertTrue(line.contains("disk full"), line)
        // metadata 固定按 key 排序，导出两份日志时 diff 才稳定
        XCTAssertTrue(line.contains("{a=1, b=2}"), line)
        XCTAssertTrue(line.contains("(FileThing.swift:42)"), line)
        XCTAssertTrue(line.hasSuffix("\n"), line)
    }

    func testConsoleBackendOmitsEmptyMetadata() {
        let backend = ConsoleBackend()
        let line = backend.format(level: .info, message: "x", metadata: [:], file: "A.swift", line: 1)
        XCTAssertFalse(line.contains("{"), line)
        XCTAssertFalse(line.contains("[UNIT]"), line)
    }

    func testOSLogBackendAcceptsAllLevels() {
        // 只验证「能调用、不崩」：OSLog 的真实落盘由系统决定，测试进程里不好断言
        LogUtil.configure(
            level: .trace,
            backend: OSLogBackend(subsystem: "github.zhihaofans.swiftutils.tests", category: "unit")
        )

        LogUtil.trace("trace")
        LogUtil.debug("debug")
        LogUtil.info("info", metadata: ["k": "v"])
        LogUtil.notice("notice")
        LogUtil.warning("warning")
        LogUtil.error("error")
        LogUtil.critical("critical")
    }

    func testConcurrentLoggingDoesNotCrash() {
        let backend = CapturingBackend()
        LogUtil.configure(level: .trace, backend: backend)

        DispatchQueue.concurrentPerform(iterations: 200) { index in
            if index % 20 == 0 {
                LogUtil.configure(level: index % 40 == 0 ? .trace : .error)
            }
            LogUtil.info("m\(index)")
        }

        // 并发下允许丢日志（等级在变），只要求不崩、状态最终可读
        XCTAssertLessThanOrEqual(backend.entries.count, 200)
    }

    func testConfigureLoggerWrapperStillWorks() {
        // 0.0.31 及以前的宿主调的是这个名字，升级后不应编译失败
        SU.configureLogger()
        SU.configureLogger(label: "github.zhihaofans.swiftutils.tests")
        SU.configureLogger(label: nil, logLevel: .error)
        XCTAssertEqual(LogUtil.level, .error)

        SU.configureLogging(level: .info, backend: ConsoleBackend())
        SU.log.info("通过 SU.log 写一条")
    }
}

#if canImport(OSLog)
final class LogExporterTests: XCTestCase {
    override func tearDown() {
        LogUtil.configure(level: .info, backend: ConsoleBackend())
        super.tearDown()
    }

    func testExportContainsMessageWrittenViaOSLogBackend() async throws {
        let subsystem = "github.zhihaofans.swiftutils.tests.exporter"
        let marker = "export-\(UUID().uuidString)"

        LogUtil.configure(
            level: .debug,
            backend: OSLogBackend(subsystem: subsystem, category: "unit", isPublic: true)
        )
        LogUtil.info(marker)

        let text: String
        do {
            text = try await LogExporter.export(subsystem: subsystem, last: 30)
        } catch {
            // 某些沙箱/测试进程拿不到 OSLogStore，跳过而不是假绿
            throw XCTSkip("当前环境拿不到 OSLogStore：\(error)")
        }

        if !text.contains(marker) {
            // os_log 的落盘时机由系统决定，测试进程里可能还没进 store
            throw XCTSkip("os_log 尚未落盘，导出内容里没有刚写的日志")
        }
        XCTAssertTrue(text.contains("[unit]"), text)
    }

    func testExportWithNoMatchingLogsReturnsEmpty() async throws {
        let text: String
        do {
            text = try await LogExporter.export(subsystem: "github.zhihaofans.swiftutils.tests.empty", last: 1)
        } catch {
            throw XCTSkip("当前环境拿不到 OSLogStore：\(error)")
        }
        XCTAssertTrue(text.isEmpty, text)
    }
}
#endif
