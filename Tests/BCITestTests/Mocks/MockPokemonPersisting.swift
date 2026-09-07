import Foundation
@testable import BCITest

final class MockPokemonPersisting: PokemonPersisting, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [PokemonDetail]

    init(initial: [PokemonDetail] = []) {
        storage = initial
    }

    func loadCachedPokemon() -> [PokemonDetail] {
        lock.lock(); defer { lock.unlock() }
        return storage
    }

    func saveCachedPokemon(_ pokemon: [PokemonDetail]) {
        lock.lock()
        storage = pokemon
        lock.unlock()
    }

    func updatePokemon(_ pokemon: PokemonDetail) {
        lock.lock()
        if let index = storage.firstIndex(where: { $0.id == pokemon.id }) {
            storage[index] = pokemon
        } else {
            storage.append(pokemon)
        }
        lock.unlock()
    }
}
