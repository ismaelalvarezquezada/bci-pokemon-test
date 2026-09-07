import Foundation

protocol PokemonRepositoryProviding: Sendable {
    /// Returns the cached snapshot immediately; empty on first launch before any sync.
    func cachedPokemon() -> [PokemonDetail]

    /// Loads the full 151-entry Pokedex: returns the cache if already complete, otherwise
    /// fetches from the network and persists the result. Throws only when the cache is
    /// empty and the network call fails.
    func loadInitialData() async throws -> [PokemonDetail]

    /// Fetches evolution chain + flavor text for a single Pokemon and persists it into the
    /// cached record, so it's available offline on the next visit. No-op if already present.
    func loadEvolutionDetails(for pokemon: PokemonDetail) async throws -> PokemonDetail

    /// Returns sprite PNG data, preferring the on-disk cache before hitting the network.
    func spriteData(forID id: Int) async throws -> Data

    /// Cache-first lookup of a single Pokemon by id, falling back to the network. Used to
    /// resolve evolution-chain stages that may fall outside the cached 151 (e.g. Pichu).
    func pokemon(forID id: Int) async throws -> PokemonDetail
}

final class PokemonRepository: PokemonRepositoryProviding {
    private let api: PokemonAPIServicing
    private let store: PokemonPersisting
    private let imageCache: ImageCaching
    private let session: URLSession
    private let pokemonCount: Int
    private let maxConcurrentDetailRequests: Int

    init(
        api: PokemonAPIServicing,
        store: PokemonPersisting,
        imageCache: ImageCaching,
        session: URLSession = .shared,
        pokemonCount: Int = 151,
        maxConcurrentDetailRequests: Int = 20
    ) {
        self.api = api
        self.store = store
        self.imageCache = imageCache
        self.session = session
        self.pokemonCount = pokemonCount
        self.maxConcurrentDetailRequests = maxConcurrentDetailRequests
    }

    func cachedPokemon() -> [PokemonDetail] {
        store.loadCachedPokemon().sorted { $0.id < $1.id }
    }

    func loadInitialData() async throws -> [PokemonDetail] {
        let cached = store.loadCachedPokemon()
        if cached.count >= pokemonCount {
            return cached.sorted { $0.id < $1.id }
        }

        let entries = try await api.fetchPokemonList(limit: pokemonCount, offset: 0)
        let details = try await fetchDetailsConcurrently(entries: entries)
        let sorted = details.sorted { $0.id < $1.id }
        store.saveCachedPokemon(sorted)
        return sorted
    }

    func loadEvolutionDetails(for pokemon: PokemonDetail) async throws -> PokemonDetail {
        guard !pokemon.hasExtras else { return pokemon }
        let (description, chain) = try await api.fetchEvolutionAndDescription(forSpeciesID: pokemon.id)
        var updated = pokemon
        updated.flavorText = description
        updated.evolutionChain = chain
        store.updatePokemon(updated)
        return updated
    }

    func spriteData(forID id: Int) async throws -> Data {
        if let cached = await imageCache.image(forID: id) {
            return cached
        }
        let (data, _) = try await session.data(from: PokemonDetail.spriteURL(forID: id))
        await imageCache.store(data, forID: id)
        return data
    }

    func pokemon(forID id: Int) async throws -> PokemonDetail {
        if let cached = store.loadCachedPokemon().first(where: { $0.id == id }) {
            return cached
        }
        let detail = try await api.fetchPokemonDetail(id: id)
        store.updatePokemon(detail)
        return detail
    }

    /// PokeAPI has no bulk-detail endpoint, so the 151 detail calls run concurrently in
    /// bounded chunks rather than one unbounded task group, to stay reasonably polite to the API.
    private func fetchDetailsConcurrently(entries: [PokemonListEntry]) async throws -> [PokemonDetail] {
        var results: [PokemonDetail] = []
        results.reserveCapacity(entries.count)
        var index = 0
        while index < entries.count {
            let end = min(index + maxConcurrentDetailRequests, entries.count)
            let chunk = entries[index..<end]
            let chunkResults = try await withThrowingTaskGroup(of: PokemonDetail.self) { group -> [PokemonDetail] in
                for entry in chunk {
                    group.addTask { [api] in
                        try await api.fetchPokemonDetail(id: entry.id)
                    }
                }
                var collected: [PokemonDetail] = []
                for try await detail in group {
                    collected.append(detail)
                }
                return collected
            }
            results.append(contentsOf: chunkResults)
            index = end
        }
        return results
    }
}
