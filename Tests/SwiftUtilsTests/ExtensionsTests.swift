import XCTest
@testable import SwiftUtils

// MARK: - String

final class StringExtensionTests: XCTestCase {
    func testPredicates() {
        XCTAssertTrue("123".isInt)
        XCTAssertTrue("-12".isInt)
        XCTAssertFalse("12.3".isInt)
        XCTAssertFalse("abc".isInt)
        XCTAssertFalse("".isInt)

        XCTAssertTrue("1.5".isFloat)
        XCTAssertFalse("abc".isFloat)

        XCTAssertTrue("https://example.com".isUrl)
        XCTAssertFalse("".isNotEmpty)
        XCTAssertTrue("a".isNotEmpty)
    }

    func testOptionalPredicates() {
        let some: String? = "12"
        let none: String? = nil

        XCTAssertTrue(some.isInt)
        XCTAssertFalse(none.isInt)
        XCTAssertTrue(some.isNotEmpty)
        XCTAssertFalse(none.isNotEmpty)
        XCTAssertEqual(none.getString("默认值"), "默认值")
        XCTAssertEqual(some.getString("默认值"), "12")
    }

    func testTransformHelpers() {
        XCTAssertEqual("abc".array, ["abc"])
        XCTAssertEqual("Hello".toSubstring, "Hello")
        XCTAssertTrue("abcdef".has("cd"))
        XCTAssertFalse("abcdef".has("xy"))
        XCTAssertEqual("a-b-c".replace(of: "-", with: "+"), "a+b+c")
        XCTAssertEqual("".getString("默认"), "默认")
        XCTAssertEqual("值".getString("默认"), "值")
        XCTAssertEqual("  \nabc".removeLeftSpaceAndNewLine(), "abc")
        XCTAssertEqual("abc".removeLeftSpaceAndNewLine(), "abc")
    }

    func testCaseHelpers() {
        XCTAssertEqual("abc".uppercasedFirst(), "Abc")
        XCTAssertEqual("ABC".lowercasedFirst(), "aBC")
        XCTAssertEqual("".uppercasedFirst(), "")
        XCTAssertEqual("".lowercasedFirst(), "")
        XCTAssertEqual("中".uppercasedFirst(), "中")
    }

    func testHttpToHttps() {
        XCTAssertEqual("http://example.com".httpToHttps, "https://example.com")
        XCTAssertEqual("https://example.com".httpToHttps, "https://example.com")
        XCTAssertEqual("http://a.com/http://b.com".httpToHttps, "https://a.com/https://b.com")
    }

    func testEncodeAndHashExtensions() {
        XCTAssertEqual("Hello".base64Encode, "SGVsbG8=")
        XCTAssertEqual("SGVsbG8=".base64Decode, "Hello")
        XCTAssertEqual("a b/c".urlEncode, "a%20b/c")
        XCTAssertEqual("a%20b/c".urlDecode, "a b/c")
        XCTAssertEqual("abc".sha256, "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
        XCTAssertEqual("abc".sha384, "cb00753f45a35e8bb5a03d699ac65007272c32ab0eded1631a8b605a43ff5bed8086072ba1e7cc2358baeca134c825a7")
        XCTAssertEqual("abc".sha512, "ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f")
    }
}

// MARK: - Int / Double / Float

final class NumberExtensionTests: XCTestCase {
    func testIntConversions() {
        XCTAssertEqual(42.toString, "42")
        XCTAssertEqual((-42).toString, "-42")
        XCTAssertEqual(42.toDouble, 42.0)
        XCTAssertEqual(42.toTimeInterval, 42.0)
    }

    func testShortNumberString() {
        XCTAssertEqual(0.toShortNumberString, "0")
        XCTAssertEqual(9999.toShortNumberString, "9999")
        XCTAssertEqual(10000.toShortNumberString, "1万")
        XCTAssertEqual(12345.toShortNumberString, "1.2万")
        XCTAssertEqual(100000000.toShortNumberString, "10000万")
    }

    func testSecondsToTimeLongString() {
        XCTAssertEqual(0.secondsToTimeLongString, "0秒")
        XCTAssertEqual((-1).secondsToTimeLongString, "0秒")
        XCTAssertEqual(1.secondsToTimeLongString, "0:01")
        XCTAssertEqual(59.secondsToTimeLongString, "0:59")
        XCTAssertEqual(60.secondsToTimeLongString, "1:00")
        XCTAssertEqual(3599.secondsToTimeLongString, "59:59")
        XCTAssertEqual(3661.secondsToTimeLongString, "1:01:01")
    }

    func testFloatRounding() {
        XCTAssertEqual(Float(1.2345).roundedDecimal(2), 1.23)
        XCTAssertEqual(Float(1.2345).roundedDecimalUp(2), 1.24)
        XCTAssertEqual(Float(1.235).roundedDecimalDown(2), 1.23)

        XCTAssertEqual(Float(1.5).roundedDecimal(), 2.0)
        XCTAssertEqual(Float(1.4).roundedDecimal(), 1.0)
        XCTAssertEqual(Float(2.9).roundedDecimalDown(), 2.0)
        XCTAssertEqual(Float(2.1).roundedDecimalUp(), 3.0)

        // 0 位小数与多位小数都要覆盖
        XCTAssertEqual(Float(-1.5).roundedDecimal(), -2.0)
        XCTAssertEqual(Float(2.5).roundedDecimal(), 3.0)
        XCTAssertEqual(Float(3.14159).roundedDecimal(3), 3.142)
        XCTAssertEqual(Float(3.14159).roundedDecimalUp(3), 3.142)
        XCTAssertEqual(Float(3.14159).roundedDecimalDown(3), 3.141)
    }

    func testDoubleConversion() {
        XCTAssertEqual(Double(1.5).toString, "1.5")
        XCTAssertEqual(Double(0).toString, "0.0")
    }
}

// MARK: - Bool / Array / URL / Error

final class MiscExtensionTests: XCTestCase {
    func testBoolString() {
        XCTAssertEqual(true.string("是", "否"), "是")
        XCTAssertEqual(false.string("是", "否"), "否")
    }

    func testArrayHelpers() {
        XCTAssertEqual([1, 2, 3].length, 3)
        XCTAssertEqual([1, 2, 3].size, 3)
        XCTAssertEqual([1, 2, 3].count, 3)
        XCTAssertTrue([1, 2, 3].isNotEmpty)
        XCTAssertFalse([Int]().isNotEmpty)
        XCTAssertTrue(["a", "b"].has("a"))
        XCTAssertFalse(["a", "b"].has("c"))
    }

    func testUrlSchemeHelpers() {
        XCTAssertTrue(URL(string: "https://example.com")!.isHTTPS)
        XCTAssertFalse(URL(string: "https://example.com")!.isHTTP)
        XCTAssertTrue(URL(string: "http://example.com")!.isHTTP)
        XCTAssertFalse(URL(string: "http://example.com")!.isHTTPS)
        XCTAssertFalse(URL(string: "ftp://example.com")!.isHTTPS)
        XCTAssertFalse(URL(string: "ftp://example.com")!.isHTTP)
    }

    private struct SampleLocalizedError: LocalizedError {
        var errorDescription: String? { "示例错误" }
    }

    private struct SamplePlainError: Error {}

    func testErrorHelpers() {
        XCTAssertEqual(SampleLocalizedError().message, "示例错误")
        XCTAssertEqual(SamplePlainError().message, "")

        let none: Error? = nil
        XCTAssertFalse(none.isError)
        XCTAssertEqual(none.message, "")

        let some: Error? = SampleLocalizedError()
        XCTAssertTrue(some.isError)
        XCTAssertEqual(some.message, "示例错误")

        let plain: Error? = SamplePlainError()
        XCTAssertTrue(plain.isError)
        XCTAssertEqual(plain.message, "")
    }
}

// MARK: - Date

final class DateExtensionTests: XCTestCase {
    private let epoch: Int = 1_600_000_000 // 2020-09-13T12:26:40Z

    func testComponentsMatchCalendar() {
        let date = Date(timeIntervalSince1970: TimeInterval(epoch))
        let calendar = Calendar.current

        XCTAssertEqual(date.timestamp, epoch)
        XCTAssertEqual(date.year, calendar.component(.year, from: date))
        XCTAssertEqual(date.month, calendar.component(.month, from: date))
        XCTAssertEqual(date.day, calendar.component(.day, from: date))
        XCTAssertEqual(date.hour, calendar.component(.hour, from: date))
        XCTAssertEqual(date.minute, calendar.component(.minute, from: date))
        XCTAssertEqual(date.second, calendar.component(.second, from: date))
    }

    func testTimestampIsTruncating() {
        let date = Date(timeIntervalSince1970: 1_600_000_000.75)
        XCTAssertEqual(date.timestamp, 1_600_000_000)
    }

    func testPastTimeStringForNow() {
        XCTAssertEqual(Date().pastTimeString, "刚刚")
    }

    func testPastTimeStringForHoursAgo() {
        let twoHoursAgo = Date().addingTimeInterval(-2 * 3600 - 1)
        XCTAssertEqual(twoHoursAgo.pastTimeString, "2小时前")
    }

    func testIsYesterdaySameDayIsAlwaysFalse() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        XCTAssertFalse(today.isYesterday(date: today))
        XCTAssertFalse(tomorrow.isYesterday(date: tomorrow))
    }

    /// `x.isYesterday(date: y)` 的语义是「x 是 y 的前一天」。
    func testIsYesterdayReturnsTrueWhenSelfIsTheDayBeforeDate() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let dayBeforeYesterday = calendar.date(byAdding: .day, value: -2, to: today)!

        XCTAssertTrue(yesterday.isYesterday(date: today))
        XCTAssertTrue(dayBeforeYesterday.isYesterday(date: yesterday))
        XCTAssertFalse(today.isYesterday(date: yesterday))
        XCTAssertFalse(yesterday.isYesterday(date: dayBeforeYesterday))
        XCTAssertFalse(dayBeforeYesterday.isYesterday(date: today))
    }

    func testIntPastTimeStringMatchesDateVariant() {
        let twoHoursAgo = Date().addingTimeInterval(-2 * 3600 - 1)
        XCTAssertEqual(twoHoursAgo.timestamp.pastTimeString, twoHoursAgo.pastTimeString)
    }
}
