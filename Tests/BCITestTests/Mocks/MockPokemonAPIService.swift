import Foundation
@testable import BCITest

enum MockAPIError: Error {
    case notConfigured
}

final class MockPokemonAPIService: PokemonAPIServicing, @unchecked Sendable {
    var listHandler: (@Sendable (Int, Int) throws -> [PokemonListEntry])?
    var detailHandler: (@Sendable (Int) throws -> PokemonDetail)?
    var evolutionHandler: (@Sendable (Int) throws -> (description: String?, evolutionChain: [PokemonEvolutionStage]))?

    private let lock = NSLock()
    private var _detailCallCount = 0
    var detailCallCount: Int {
        lock.lock(); defer { lock.unlock() }
        return _detailCallCount
    }

    func fetchPokemonList(limit: Int, offset: Int) async throws -> [PokemonListEntry] {
        guard let handler = listHandler else { throw MockAPIError.notConfigured }
        return try handler(limit, offset)
    }

    func fetchPokemonDetail(id: Int) async throws -> PokemonDetail {
        incrementDetailCallCount()
        guard let handler = detailHandler else { throw MockAPIError.notConfigured }
        return try handler(id)
    }

    private func incrementDetailCallCount() {
        lock.lock(); defer { lock.unlock() }
        _detailCallCount += 1
    }

    func fetchEvolutionAndDescription(forSpeciesID id: Int) async throws -> (description: String?, evolutionChain: [PokemonEvolutionStage]) {
        guard let handler = evolutionHandler else { throw MockAPIError.notConfigured }
        return try handler(id)
    }
}
