import XCTest
@testable import SwiftUtils

/// 命名空间、日志与平台判定的基础测试。
final class SwiftUtilsTests: XCTestCase {
    override func tearDown() {
        // 恢复默认日志级别，避免污染后续用例
        SU.configureLogger()
        super.tearDown()
    }

    func testConfigureLoggerAndLogAllLevels() {
        SU.configureLogger(label: "github.zhihaofans.swiftutils.tests")
        // 只要求不崩溃：各层级 + String/Int/Float 重载都要能被解析
        SU.log.d("debug")
        SU.log.i("info")
        SU.log.e("error")
        SU.log.debug("debug-string")
        SU.log.info("info-string")
        SU.log.warning("warning-string")
        SU.log.error("error-string")
        SU.log.debug(1)
        SU.log.info(2)
        SU.log.warning(3)
        SU.log.error(4)
        SU.log.debug(1.5)
        SU.log.info(2.5)
        SU.log.warning(3.5)
        SU.log.error(4.5)
    }

    func testConfigureLoggerAcceptsNilArguments() {
        SU.configureLogger(label: nil, logLevel: nil)
        SU.configureLogger(label: "自定义标签", logLevel: nil)
    }

    func testDeviceUtilPlatformFlags() {
        let util = DeviceUtil()

        #if os(macOS)
        XCTAssertTrue(util.isMac())
        #else
        XCTAssertFalse(util.isMac())
        #endif

        #if os(watchOS)
        XCTAssertTrue(util.isWatch())
        #else
        XCTAssertFalse(util.isWatch())
        #endif
    }

    func testDeviceUtilWatchAndMacFlagsAreMutuallyExclusive() {
        let util = DeviceUtil()
        XCTAssertFalse(util.isMac() && util.isWatch())
    }
}
