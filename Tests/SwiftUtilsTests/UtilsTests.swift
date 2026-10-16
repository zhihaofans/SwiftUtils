import XCTest
@testable import SwiftUtils

// MARK: - Encode

final class EncodeUtilTests: XCTestCase {
    private let util = EncodeUtil()

    func testBase64Encode() {
        XCTAssertEqual(util.base64Encode("Hello"), "SGVsbG8=")
        XCTAssertEqual(util.base64Encode("你好"), "5L2g5aW9")
        XCTAssertEqual(util.base64Encode(""), "")
    }

    func testBase64Decode() {
        XCTAssertEqual(util.base64Decode("SGVsbG8="), "Hello")
        XCTAssertEqual(util.base64Decode("5L2g5aW9"), "你好")
        // 非法输入回落为原文
        XCTAssertEqual(util.base64Decode("!!!not-base64!!!"), "!!!not-base64!!!")
    }

    func testBase64ImageEncode() {
        XCTAssertEqual(util.base64ImageEncode(Data([0x01, 0x02, 0x03])), "AQID")
        XCTAssertEqual(util.base64ImageEncode(Data()), "")
    }

    func testUrlEncode() {
        XCTAssertEqual(util.urlEncode("abc"), "abc")
        XCTAssertEqual(util.urlEncode("a b/c"), "a%20b/c")
        XCTAssertEqual(util.urlEncode("中 文"), "%E4%B8%AD%20%E6%96%87")
    }

    /// 回归：参数值编码必须转义 query 分隔符，否则 `a&admin=true` 会拼出额外参数
    func testUrlEncodeEscapesQueryDelimiters() {
        XCTAssertEqual(util.urlEncode("a&admin=true"), "a%26admin%3Dtrue")
        XCTAssertEqual(util.urlEncode("k=v"), "k%3Dv")
        XCTAssertEqual(util.urlEncode("a?b"), "a%3Fb")
        XCTAssertEqual(util.urlEncode("a+b"), "a%2Bb")
        // 编码后不应再出现裸分隔符
        let encoded = util.urlEncode("x&y=z?w+v")
        XCTAssertFalse(encoded.contains("&"))
        XCTAssertFalse(encoded.contains("="))
        XCTAssertFalse(encoded.contains("?"))
        XCTAssertFalse(encoded.contains("+"))
        // 编解码可往返
        XCTAssertEqual(util.urlDecode(encoded), "x&y=z?w+v")
    }

    func testUrlDecode() {
        XCTAssertEqual(util.urlDecode("abc"), "abc")
        XCTAssertEqual(util.urlDecode("a%20b/c"), "a b/c")
        XCTAssertEqual(util.urlDecode("%E4%B8%AD%E6%96%87"), "中文")
        // 非法百分号转义回落为原文
        XCTAssertEqual(util.urlDecode("%zz"), "%zz")
    }
}

// MARK: - Hash

final class HashUtilTests: XCTestCase {
    private let util = HashUtil()

    func testSha1() {
        XCTAssertEqual(util.sha1("abc"), "a9993e364706816aba3e25717850c26c9cd0d89d")
    }

    func testSha256() {
        XCTAssertEqual(util.sha256("abc"), "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
        XCTAssertEqual(util.sha256(""), "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
    }

    func testSha384() {
        XCTAssertEqual(util.sha384("abc"), "cb00753f45a35e8bb5a03d699ac65007272c32ab0eded1631a8b605a43ff5bed8086072ba1e7cc2358baeca134c825a7")
    }

    func testSha512() {
        XCTAssertEqual(util.sha512("abc"), "ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f")
    }

    func testDigestLengths() {
        XCTAssertEqual(util.sha1("任意内容").count, 40)
        XCTAssertEqual(util.sha256("任意内容").count, 64)
        XCTAssertEqual(util.sha384("任意内容").count, 96)
        XCTAssertEqual(util.sha512("任意内容").count, 128)
    }
}

// MARK: - Date

final class DateUtilTests: XCTestCase {
    private let util = DateUtil()

    func testGetTimestampAndGetDate() {
        XCTAssertGreaterThan(util.getTimestamp(), 1_500_000_000)
        XCTAssertEqual(util.getDate(0), Date(timeIntervalSince1970: 0))
        XCTAssertEqual(util.getDate(1_600_000_000), Date(timeIntervalSince1970: 1_600_000_000))
    }

    /// 日期格式化固定为北京时间（UTC+8），与设备时区无关。
    func testTimestampToTimeStrHonoursFormat() {
        XCTAssertEqual(util.timestampToTimeStr(0, format: "yyyy-MM-dd"), "1970-01-01")
        XCTAssertEqual(util.timestampToTimeStr(0, format: "yyyy-MM-dd HH:mm:ss"), "1970-01-01 08:00:00")
        // 空 format 回落为默认格式
        XCTAssertEqual(util.timestampToTimeStr(0, format: ""), "1970-01-01 08:00:00")
        XCTAssertEqual(
            util.timestampToTimeStr(1_600_000_000, format: "yyyy-MM-dd HH:mm:ss"),
            "2020-09-13 20:26:40"
        )
    }

    func testTimestampToTimeStrOverloads() {
        XCTAssertEqual(util.timestampToTimeStr(0), "1970-01-01 08:00:00")
        XCTAssertEqual(util.timestampToTimeStr(1_600_000_000), "2020-09-13 20:26:40")
    }

    func testNowTimeStrShape() {
        let now = util.getNowTimeStr()
        XCTAssertEqual(now.count, 19)
        XCTAssertTrue(now.contains("-"))
        XCTAssertTrue(now.contains(":"))
    }
}

/// 回归测试：日期格式化必须固定为北京时间，不能随设备时区漂移。
/// （历史缺陷：`TimeZone(abbreviation: "Asia/Shanghai")` 对 IANA 标识返回 nil，
///  给 `DateFormatter.timeZone` 赋 nil 会回退到设备时区。）
final class DateBeijingTimeZoneTests: XCTestCase {
    func testAbbreviationInitializerCannotExpressIANAIdentifier() {
        XCTAssertNil(TimeZone(abbreviation: "Asia/Shanghai"))
        XCTAssertNotNil(TimeZone(identifier: "Asia/Shanghai"))
    }

    func testEpochZeroIsRenderedAsBeijingTime() {
        XCTAssertEqual(DateUtil().timestampToTimeStr(0), "1970-01-01 08:00:00")

        let epoch = Date(timeIntervalSince1970: 0)
        XCTAssertEqual(epoch.timestampToTimeStr, "1970-01-01 08:00:00")
        XCTAssertEqual(epoch.timestampToTimeStrMinute, "1970-01-01 08:00")
        XCTAssertEqual(epoch.timestampToTimeStrHour, "1970-01-01 08")
        XCTAssertEqual(epoch.timestampToTimeStrDay, "1970-01-01")
        XCTAssertEqual(epoch.timestampToTimeChinese, "1970年01月01日08时00分00秒")
    }
}

// MARK: - Fenci

final class FenciUtilTests: XCTestCase {
    private let util = FenciUtil()

    func testEmptyInput() {
        XCTAssertEqual(util.fenci(""), [])
        XCTAssertTrue(util.fenciWithRanges("").isEmpty)
    }

    func testWordSegmentation() {
        XCTAssertEqual(util.fenci("Hello world"), ["Hello", "world"])
        XCTAssertEqual(util.fenciByWord("Hello world"), ["Hello", "world"])
        XCTAssertEqual(util.fenciOld("Hello world"), ["Hello", "world"])
    }

    func testOmitPunctuationFiltersPunctuationOnlyTokens() {
        XCTAssertEqual(util.fenci("Hello, world!"), ["Hello", "world"])

        let unfiltered = util.fenci("Hello, world!", options: .init(omitPunctuation: false))
        XCTAssertTrue(unfiltered.contains("Hello"))
        XCTAssertTrue(unfiltered.contains("world"))
        XCTAssertGreaterThanOrEqual(unfiltered.count, 2)
    }

    func testLowercaseAndMinLengthOptions() {
        XCTAssertEqual(util.fenci("Hello World", options: .init(lowercase: true)), ["hello", "world"])
        XCTAssertEqual(util.fenci("a bb ccc", options: .init(minLength: 2)), ["bb", "ccc"])
    }

    func testTokenRangesPointBackToSource() {
        let source = "Hello world"
        let result = util.fenciWithRanges(source)
        XCTAssertEqual(result.map { $0.0 }, ["Hello", "world"])
        XCTAssertEqual(result.first.map { String(source[$0.1]) }, "Hello")
        XCTAssertEqual(result.last.map { String(source[$0.1]) }, "world")
    }

    func testJoinTokens() {
        XCTAssertEqual(FenciUtil.joinTokens(["a", "b"]), "a b")
        XCTAssertEqual(FenciUtil.joinTokens(["a", "b"], separator: "-"), "a-b")
        XCTAssertEqual(FenciUtil.joinTokens([]), "")
    }

    func testStringExtensions() {
        XCTAssertEqual("Hello world".fenciByWord(), ["Hello", "world"])
        XCTAssertFalse("Hello. World.".fenciBySentence().isEmpty)
        XCTAssertFalse("第一段\n第二段".fenciByParagraph().isEmpty)
        XCTAssertFalse("Hello".fenciByDocument().isEmpty)
    }
}

// MARK: - UserDefaults

final class UserDefaultUtilTests: XCTestCase {
    private let util = UserDefaultUtil()
    private let prefix = "github.zhihaofans.swiftutils.tests."
    private var usedKeys: [String] = []

    private func key(_ name: String) -> String {
        let value = prefix + name
        usedKeys.append(value)
        return value
    }

    override func tearDown() {
        usedKeys.forEach { util.remove($0) }
        usedKeys.removeAll()
        super.tearDown()
    }

    func testRoundTripForEveryType() {
        let stringKey = key("string")
        let intKey = key("int")
        let floatKey = key("float")
        let boolKey = key("bool")
        let arrayKey = key("array")

        XCTAssertFalse(util.hasValue(stringKey))

        util.setString(key: stringKey, value: "值")
        util.setInt(key: intKey, value: 7)
        util.setFloat(key: floatKey, value: 1.5)
        util.setBool(key: boolKey, value: true)
        util.setArrayString(key: arrayKey, value: ["x", "y"])

        XCTAssertTrue(util.hasValue(stringKey))
        XCTAssertEqual(util.getString(stringKey), "值")
        XCTAssertEqual(util.getString(key: stringKey, defaultValue: "默认"), "值")
        XCTAssertEqual(util.getInt(intKey), 7)
        XCTAssertEqual(util.getFloat(floatKey), 1.5)
        XCTAssertEqual(util.getBool(boolKey), true)
        XCTAssertEqual(util.getArrayString(arrayKey), ["x", "y"])
        XCTAssertEqual(util.getArrayLength(arrayKey), 2)
    }

    func testMissingKeyBehaviour() {
        let missing = key("missing")
        XCTAssertFalse(util.hasValue(missing))
        XCTAssertNil(util.getString(missing))
        XCTAssertNil(util.getInt(missing))
        XCTAssertNil(util.getFloat(missing))
        XCTAssertNil(util.getBool(missing))
        XCTAssertEqual(util.getString(key: missing, defaultValue: "兜底"), "兜底")
        XCTAssertEqual(util.getArrayString(missing), [])
        XCTAssertEqual(util.getArrayLength(missing), 0)
    }

    func testRemove() {
        let target = key("remove")
        util.setString(key: target, value: "v")
        XCTAssertTrue(util.hasValue(target))
        util.remove(target)
        XCTAssertFalse(util.hasValue(target))
    }

    func testExtensionHelpersWriteThrough() {
        let stringKey = key("ext.string")
        let intKey = key("ext.int")
        let floatKey = key("ext.float")
        let boolKey = key("ext.bool")
        let arrayKey = key("ext.array")

        "扩展值".setUserDefaults(stringKey)
        Int(9).setUserDefaults(intKey)
        Float(2.5).setUserDefaults(floatKey)
        Bool(true).setUserDefaults(boolKey)
        ["a", "b"].setUserDefaults(arrayKey)

        XCTAssertEqual(util.getString(stringKey), "扩展值")
        XCTAssertEqual(util.getInt(intKey), 9)
        XCTAssertEqual(util.getFloat(floatKey), 2.5)
        XCTAssertEqual(util.getBool(boolKey), true)
        XCTAssertEqual(util.getArrayString(arrayKey), ["a", "b"])
    }
}

// MARK: - Keychain

final class KeychainUtilTests: XCTestCase {
    private let util = KeychainUtil()
    private let key = "github.zhihaofans.swiftutils.tests.keychain"

    override func tearDown() {
        _ = util.remove(forKey: key)
        super.tearDown()
    }

    func testSaveReadUpdateRemove() throws {
        _ = util.remove(forKey: key)
        XCTAssertNil(util.getString(forKey: key))

        // 受限环境（沙箱 / 未签名测试进程）下 Keychain 不可写，此时跳过而不是误报失败
        guard util.saveString(forKey: key, value: "v1") else {
            throw XCTSkip("当前环境不允许访问 Keychain，跳过该用例")
        }
        XCTAssertEqual(util.getString(forKey: key), "v1")

        // 重复 save 命中 errSecDuplicateItem，应自动走 update
        XCTAssertTrue(util.saveString(forKey: key, value: "v2"))
        XCTAssertEqual(util.getString(forKey: key), "v2")

        XCTAssertTrue(util.update(forKey: key, value: "v3"))
        XCTAssertEqual(util.getString(forKey: key), "v3")

        XCTAssertTrue(util.remove(forKey: key))
        XCTAssertNil(util.getString(forKey: key))
    }
}

// MARK: - Network

final class NetworkTypeTests: XCTestCase {
    func testCasesAndRawValues() {
        XCTAssertEqual(NetworkUtil.NetworkType.allCases.count, 7)
        XCTAssertEqual(NetworkUtil.NetworkType.is5G.rawValue, "is5G")
        XCTAssertEqual(NetworkUtil.NetworkType.is4G.rawValue, "is4G")
        XCTAssertEqual(NetworkUtil.NetworkType.is3G.rawValue, "is3G")
        XCTAssertEqual(NetworkUtil.NetworkType.is2G.rawValue, "is2G")
        XCTAssertEqual(NetworkUtil.NetworkType.wifi.rawValue, "wifi")
        XCTAssertEqual(NetworkUtil.NetworkType.wiredEthernet.rawValue, "wiredEthernet")
        XCTAssertEqual(NetworkUtil.NetworkType.other.rawValue, "other")
    }

    func testIdentifiableConformance() {
        XCTAssertEqual(NetworkUtil.NetworkType.wifi.id, NetworkUtil.NetworkType.wifi)
        XCTAssertNotEqual(NetworkUtil.NetworkType.wifi.id, NetworkUtil.NetworkType.is5G.id)
    }
}

// MARK: - Qrcode（watchOS 上整个类型不存在）

#if !os(watchOS)
final class QrcodeUtilTests: XCTestCase {
    func testGenerateQRCodeForUrl() {
        let image = QrcodeUtil().generateQRCode(from: "https://example.com")
        XCTAssertNotNil(image)
        XCTAssertGreaterThan(image?.size.width ?? 0, 0)
        XCTAssertGreaterThan(image?.size.height ?? 0, 0)
    }

    func testGenerateQRCodeForChineseText() {
        XCTAssertNotNil(QrcodeUtil().generateQRCode(from: "你好，世界"))
    }
}
#endif

// MARK: - Notification
//
// 说明：`NotificationUtil` 无法在 SwiftPM 测试进程里实例化 ——
// 其存储属性 `UNUserNotificationCenter.current()` 在无 App Bundle 的进程里会直接抛
// `NSInternalInconsistencyException: bundleProxyForCurrentProcess is nil`（实测）。
// 因此 `timeInterval <= 0` 的入参校验只能靠代码审查保证，这里不做单元测试。
