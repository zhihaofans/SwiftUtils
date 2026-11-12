import XCTest
@testable import SwiftUtils

final class FormatterTests: XCTestCase {
    // MARK: 文件体积

    func testFileSizeUsesLocaleDecimalSeparator() {
        // 用 1.5 MB：kB 这一档系统会取整（1500 → "2 kB"），测试小数点得挑会带小数的量级
        let english = FileSizeFormatter.string(1_500_000, style: .file, locale: Locale(identifier: "en_US"))
        let french = FileSizeFormatter.string(1_500_000, style: .file, locale: Locale(identifier: "fr_FR"))

        // 手写 String(format: "%.1f") 的版本在 fr_FR 下会输出 "1.5"，这里必须是逗号
        XCTAssertTrue(english.contains("1.5"), english)
        XCTAssertTrue(french.contains("1,5"), french)
    }

    func testFileSizeStyleChangesBase() {
        let bytes: Int64 = 2_000_000
        let file = FileSizeFormatter.string(bytes, style: .file, locale: Locale(identifier: "en_US"))
        let memory = FileSizeFormatter.string(bytes, style: .memory, locale: Locale(identifier: "en_US"))

        // 1000 进制 → 2 MB；1024 进制 → 1.9 MB
        XCTAssertTrue(file.hasPrefix("2"), file)
        XCTAssertTrue(memory.hasPrefix("1.9"), memory)
    }

    func testFileSizeZeroIsNumericNotSpelledOut() {
        // 默认配置会输出 "Zero kB"，空文件显示成一句话很怪
        let zero = FileSizeFormatter.string(0, locale: Locale(identifier: "en_US"))
        XCTAssertTrue(zero.contains("0"), zero)
        XCTAssertFalse(zero.lowercased().contains("zero"), zero)
    }

    // MARK: 相对时间

    private let chinese = Locale(identifier: "zh_CN")
    private let english = Locale(identifier: "en_US")
    private let shanghai = TimeZone(identifier: "Asia/Shanghai")!

    func testRelativeTimePast() {
        let now = Date()
        let text = RelativeTimeFormatter.string(
            from: now.addingTimeInterval(-180),
            now: now,
            style: .numeric,
            locale: chinese,
            timeZone: shanghai
        )
        XCTAssertTrue(text.contains("3"), text)
        XCTAssertTrue(text.contains("前"), text)
    }

    func testRelativeTimeFutureIsNotJustNow() {
        let now = Date()
        let text = RelativeTimeFormatter.string(
            from: now.addingTimeInterval(3600),
            now: now,
            style: .numeric,
            locale: chinese,
            timeZone: shanghai
        )
        // 草案的 `interval < 60` 对负数也成立，未来时间会显示成「刚刚」
        XCTAssertFalse(text.contains("刚刚"), text)
        XCTAssertTrue(text.contains("后"), text)
    }

    func testRelativeTimeFollowsLocale() {
        let now = Date()
        let past = RelativeTimeFormatter.string(
            from: now.addingTimeInterval(-3600),
            now: now,
            style: .numeric,
            locale: english,
            timeZone: shanghai
        )
        XCTAssertTrue(past.contains("ago"), past)

        let future = RelativeTimeFormatter.string(
            from: now.addingTimeInterval(3600),
            now: now,
            style: .numeric,
            locale: english,
            timeZone: shanghai
        )
        XCTAssertTrue(future.contains("in"), future)
    }
}

final class ChunkedTests: XCTestCase {
    func testEmptyArrayReturnsNoChunks() {
        XCTAssertTrue([Int]().chunked(into: 3).isEmpty)
    }

    func testNonPositiveSizeReturnsNoChunks() {
        // 不能让 size = 0 变成死循环，也别自作主张返回 [self]
        XCTAssertTrue([1, 2, 3].chunked(into: 0).isEmpty)
        XCTAssertTrue([1, 2, 3].chunked(into: -5).isEmpty)
    }

    func testExactDivision() {
        XCTAssertEqual([1, 2, 3, 4].chunked(into: 2), [[1, 2], [3, 4]])
    }

    func testRemainderGoesToLastChunk() {
        XCTAssertEqual([1, 2, 3, 4, 5].chunked(into: 2), [[1, 2], [3, 4], [5]])
    }

    func testSizeLargerThanCountKeepsSingleChunk() {
        XCTAssertEqual([1, 2, 3].chunked(into: 10), [[1, 2, 3]])
        XCTAssertEqual([1].chunked(into: 10), [[1]])
    }

    func testChunksPreserveOrderAndCount() {
        let source = Array(0..<1000)
        let chunks = source.chunked(into: 300)

        XCTAssertEqual(chunks.map(\.count), [300, 300, 300, 100])
        XCTAssertEqual(chunks.flatMap { $0 }, source)
    }
}
