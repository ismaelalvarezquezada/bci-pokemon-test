import XCTest
@testable import BCITest

final class ImageDiskCacheTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
        directory = nil
        try super.tearDownWithError()
    }

    func test_image_returnsNil_whenNotStored() async {
        let cache = ImageDiskCache(directory: directory)

        let result = await cache.image(forID: 1)

        XCTAssertNil(result)
    }

    func test_storeAndRetrieve_roundTrips() async {
        let cache = ImageDiskCache(directory: directory)
        let data = Data([0x01, 0x02, 0x03])

        await cache.store(data, forID: 1)
        let result = await cache.image(forID: 1)

        XCTAssertEqual(result, data)
    }

    func test_differentIDs_areStoredIndependently() async {
        let cache = ImageDiskCache(directory: directory)

        await cache.store(Data([0x01]), forID: 1)
        await cache.store(Data([0x02]), forID: 2)

        let first = await cache.image(forID: 1)
        let second = await cache.image(forID: 2)

        XCTAssertEqual(first, Data([0x01]))
        XCTAssertEqual(second, Data([0x02]))
    }
}
