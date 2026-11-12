import XCTest
@testable import SwiftUtils

final class FileUtilTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("SwiftUtilsTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
    }

    // MARK: 读写

    func testWriteAndReadRoundTrip() throws {
        let url = directory.appendingPathComponent("round.txt")
        let payload = Data("你好, SwiftUtils".utf8)

        try FileUtil.write(payload, to: url)

        XCTAssertEqual(try FileUtil.read(url), payload)
        // 原子写不能留下临时文件
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path), ["round.txt"])
    }

    func testAtomicWriteOverwritesOldContent() throws {
        let url = directory.appendingPathComponent("overwrite.txt")
        try FileUtil.write(Data("old".utf8), to: url)
        try FileUtil.write(Data("new".utf8), to: url)

        XCTAssertEqual(try FileUtil.read(url), Data("new".utf8))
    }

    func testCoordinatedWriteAndRead() throws {
        let url = directory.appendingPathComponent("coordinated.txt")
        try FileUtil.write(Data("coordinated".utf8), to: url, coordinated: true)

        XCTAssertEqual(try FileUtil.read(url, coordinated: true), Data("coordinated".utf8))
    }

    func testWriteFailsWhenParentMissing() {
        let url = directory.appendingPathComponent("missing/child.txt")
        // 故意不建父目录：不能静默创建，否则拼错的路径会悄悄写到别处
        XCTAssertThrowsError(try FileUtil.write(Data("x".utf8), to: url))
    }

    // MARK: 唯一文件名

    func testUniqueURLSuggestsIncrementingNames() throws {
        let name = "photo.jpg"
        XCTAssertEqual(FileUtil.uniqueURL(in: directory, preferredName: name).lastPathComponent, name)

        try Data().write(to: directory.appendingPathComponent(name))
        XCTAssertEqual(FileUtil.uniqueURL(in: directory, preferredName: name).lastPathComponent, "photo-1.jpg")

        try Data().write(to: directory.appendingPathComponent("photo-1.jpg"))
        XCTAssertEqual(FileUtil.uniqueURL(in: directory, preferredName: name).lastPathComponent, "photo-2.jpg")
    }

    func testUniqueURLKeepsEmptyExtensionReadable() {
        let suggested = FileUtil.uniqueURL(in: directory, preferredName: "README")
        XCTAssertEqual(suggested.lastPathComponent, "README")
    }

    func testCreateUniqueFileRenamesOnCollision() throws {
        let first = try FileUtil.createUniqueFile(in: directory, preferredName: "a.txt", contents: Data("1".utf8))
        let second = try FileUtil.createUniqueFile(in: directory, preferredName: "a.txt", contents: Data("2".utf8))

        XCTAssertEqual(first.lastPathComponent, "a.txt")
        XCTAssertEqual(second.lastPathComponent, "a-1.txt")
        XCTAssertEqual(try Data(contentsOf: first), Data("1".utf8))
        XCTAssertEqual(try Data(contentsOf: second), Data("2".utf8))
    }

    func testCreateUniqueFileIsAtomicUnderConcurrency() throws {
        // 只做 fileExists 判断的版本在这里会互相覆盖：并发保存同名文件时名字必须都不同
        let lock = NSLock()
        var urls: [URL] = []

        DispatchQueue.concurrentPerform(iterations: 20) { index in
            let url = try? FileUtil.createUniqueFile(
                in: directory,
                preferredName: "concurrent.txt",
                contents: Data("\(index)".utf8)
            )
            lock.lock()
            urls.append(url ?? directory.appendingPathComponent("failed-\(index)"))
            lock.unlock()
        }

        XCTAssertEqual(urls.count, 20)
        XCTAssertEqual(Set(urls.map(\.lastPathComponent)).count, 20, "20 个并发创建拿到了重复文件名")
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: directory.path).count, 20)
    }

    // MARK: 目录

    func testCreateDirectoryIfNeeded() throws {
        let nested = directory.appendingPathComponent("a/b/c", isDirectory: true)
        try FileUtil.createDirectoryIfNeeded(nested)
        XCTAssertTrue(FileManager.default.fileExists(atPath: nested.path))

        // 已存在时重复调用不能抛错
        XCTAssertNoThrow(try FileUtil.createDirectoryIfNeeded(nested))
    }

    func testRemoveIfExistsIsIdempotent() throws {
        let url = directory.appendingPathComponent("remove-me.txt")
        try Data().write(to: url)

        XCTAssertNoThrow(try FileUtil.removeIfExists(url))
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
        XCTAssertNoThrow(try FileUtil.removeIfExists(url))
    }

    func testTemporaryDirectoryIsRemovedOnDeinit() throws {
        var temp: TemporaryDirectory?
        var url: URL?
        do {
            let created = try FileUtil.makeTemporaryDirectory(prefix: "unit")
            temp = created
            url = created.url
            XCTAssertTrue(FileManager.default.fileExists(atPath: created.url.path))
            XCTAssertFalse(created.isRemoved)
        }

        weak var weakTemp = temp
        temp = nil
        XCTAssertNil(weakTemp, "TemporaryDirectory 必须能被释放")
        XCTAssertFalse(FileManager.default.fileExists(atPath: try XCTUnwrap(url).path), "deinit 没有删掉临时目录")
    }

    // MARK: 体积

    func testDirectorySizeCountsNestedFiles() async throws {
        let deep = directory.appendingPathComponent("deep", isDirectory: true)
        try FileManager.default.createDirectory(at: deep, withIntermediateDirectories: true)
        try Data(repeating: 0, count: 100).write(to: directory.appendingPathComponent("a.bin"))
        try Data(repeating: 0, count: 200).write(to: deep.appendingPathComponent("b.bin"))

        let size = await FileUtil.directorySize(directory)
        XCTAssertEqual(size, 300)
    }

    func testDirectorySizeSkipsHiddenByDefault() async throws {
        try Data(repeating: 0, count: 10).write(to: directory.appendingPathComponent(".hidden"))
        try Data(repeating: 0, count: 20).write(to: directory.appendingPathComponent("visible"))

        let withoutHidden = await FileUtil.directorySize(directory)
        let withHidden = await FileUtil.directorySize(directory, includingHidden: true)

        XCTAssertEqual(withoutHidden, 20)
        XCTAssertEqual(withHidden, 30)
    }

    func testDirectorySizeOfMissingDirectoryIsZero() async {
        let missing = directory.appendingPathComponent("nope", isDirectory: true)
        let size = await FileUtil.directorySize(missing)
        XCTAssertEqual(size, 0)
    }
}
