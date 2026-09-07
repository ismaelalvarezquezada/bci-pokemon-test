import Foundation
@testable import BCITest

final class MockPokemonRepository: PokemonRepositoryProviding, @unchecked Sendable {
    private let lock = NSLock()
    private var cached: [PokemonDetail]

    var loadInitialDataHandler: (@Sendable () throws -> [PokemonDetail])?
    var loadEvolutionDetailsHandler: (@Sendable (PokemonDetail) throws -> PokemonDetail)?
    var spriteDataHandler: (@Sendable (Int) throws -> Data)?
    var pokemonHandler: (@Sendable (Int) throws -> PokemonDetail)?

    private var _loadInitialDataCallCount = 0
    var loadInitialDataCallCount: Int {
        lock.lock(); defer { lock.unlock() }
        return _loadInitialDataCallCount
    }

    init(cached: [PokemonDetail]) {
        self.cached = cached
    }

    func cachedPokemon() -> [PokemonDetail] {
        lock.lock(); defer { lock.unlock() }
        return cached
    }

    func loadInitialData() async throws -> [PokemonDetail] {
        incrementLoadInitialDataCallCount()
        guard let handler = loadInitialDataHandler else { return cached }
        return try handler()
    }

    private func incrementLoadInitialDataCallCount() {
        lock.lock(); defer { lock.unlock() }
        _loadInitialDataCallCount += 1
    }

    func loadEvolutionDetails(for pokemon: PokemonDetail) async throws -> PokemonDetail {
        guard let handler = loadEvolutionDetailsHandler else { return pokemon }
        return try handler(pokemon)
    }

    func spriteData(forID id: Int) async throws -> Data {
        guard let handler = spriteDataHandler else { return Data() }
        return try handler(id)
    }

    func pokemon(forID id: Int) async throws -> PokemonDetail {
        guard let handler = pokemonHandler else {
            if let match = cached.first(where: { $0.id == id }) {
                return match
            }
            throw MockAPIError.notConfigured
        }
        return try handler(id)
    }
}
