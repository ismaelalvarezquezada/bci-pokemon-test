import Foundation

protocol PokemonPersisting: Sendable {
    func loadCachedPokemon() -> [PokemonDetail]
    func saveCachedPokemon(_ pokemon: [PokemonDetail])
    func updatePokemon(_ pokemon: PokemonDetail)
}

/// Persists the full Pokedex snapshot as a single JSON blob in UserDefaults.
/// 151 records with trimmed move lists stay well within a reasonable UserDefaults payload size,
/// keeping the whole dataset available for offline search without a database dependency.
final class UserDefaultsPokemonStore: PokemonPersisting, @unchecked Sendable {
    private let defaults: UserDefaults
    private let key: String
    private let lock = NSLock()
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard, key: String = "com.ismaelalvarez.bcitest.pokemonCache") {
        self.defaults = defaults
        self.key = key
    }

    func loadCachedPokemon() -> [PokemonDetail] {
        lock.lock()
        defer { lock.unlock() }
        return decodeLocked()
    }

    func saveCachedPokemon(_ pokemon: [PokemonDetail]) {
        lock.lock()
        defer { lock.unlock() }
        guard let data = try? encoder.encode(pokemon) else { return }
        defaults.set(data, forKey: key)
    }

    func updatePokemon(_ pokemon: PokemonDetail) {
        lock.lock()
        var current = decodeLocked()
        if let index = current.firstIndex(where: { $0.id == pokemon.id }) {
            current[index] = pokemon
        } else {
            current.append(pokemon)
        }
        guard let data = try? encoder.encode(current) else {
            lock.unlock()
            return
        }
        defaults.set(data, forKey: key)
        lock.unlock()
    }

    private func decodeLocked() -> [PokemonDetail] {
        guard let data = defaults.data(forKey: key),
              let pokemon = try? decoder.decode([PokemonDetail].self, from: data) else {
            return []
        }
        return pokemon
    }
}
