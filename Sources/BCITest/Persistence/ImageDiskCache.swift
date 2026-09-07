import Foundation

protocol ImageCaching: Sendable {
    func image(forID id: Int) async -> Data?
    func store(_ data: Data, forID id: Int) async
}

/// Sprites are binary blobs and don't belong in UserDefaults; they're cached on disk
/// under Caches/ so the OS can reclaim the space and offline detail views still render.
actor ImageDiskCache: ImageCaching {
    private let directory: URL
    private let fileManager: FileManager

    init(fileManager: FileManager = .default, directory: URL? = nil) {
        self.fileManager = fileManager
        if let directory {
            self.directory = directory
        } else {
            let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            self.directory = caches.appendingPathComponent("PokemonSprites", isDirectory: true)
        }
        try? self.fileManager.createDirectory(at: self.directory, withIntermediateDirectories: true)
    }

    func image(forID id: Int) -> Data? {
        fileManager.contents(atPath: fileURL(for: id).path)
    }

    func store(_ data: Data, forID id: Int) {
        fileManager.createFile(atPath: fileURL(for: id).path, contents: data)
    }

    private func fileURL(for id: Int) -> URL {
        directory.appendingPathComponent("\(id).png")
    }
}
