import Foundation
@testable import BCITest

actor MockImageCaching: ImageCaching {
    private var storage: [Int: Data] = [:]
    private(set) var storeCallCount = 0

    func image(forID id: Int) -> Data? {
        storage[id]
    }

    func store(_ data: Data, forID id: Int) {
        storage[id] = data
        storeCallCount += 1
    }

    func seed(_ data: Data, forID id: Int) {
        storage[id] = data
    }
}
