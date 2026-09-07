import XCTest
@testable import BCITest

final class PokemonRepositoryTests: XCTestCase {
    func test_loadInitialData_returnsCacheWithoutNetworkCall_whenCacheIsComplete() async throws {
        let cached = (1...3).map { PokemonFixture.make(id: $0, name: "p\($0)") }
        let store = MockPokemonPersisting(initial: cached)
        let api = MockPokemonAPIService()
        api.listHandler = { _, _ in
            XCTFail("should not fetch list when cache is already complete")
            return []
        }
        let repository = PokemonRepository(api: api, store: store, imageCache: MockImageCaching(), pokemonCount: 3)

        let result = try await repository.loadInitialData()

        XCTAssertEqual(result.map(\.id), [1, 2, 3])
    }

    func test_loadInitialData_fetchesAndPersists_whenCacheEmpty() async throws {
        let store = MockPokemonPersisting()
        let api = MockPokemonAPIService()
        api.listHandler = { _, _ in
            [PokemonListEntry(id: 1, name: "bulbasaur"), PokemonListEntry(id: 2, name: "ivysaur")]
        }
        api.detailHandler = { id in PokemonFixture.make(id: id, name: "p\(id)") }
        let repository = PokemonRepository(api: api, store: store, imageCache: MockImageCaching(), pokemonCount: 2)

        let result = try await repository.loadInitialData()

        XCTAssertEqual(result.map(\.id).sorted(), [1, 2])
        XCTAssertEqual(store.loadCachedPokemon().count, 2)
        XCTAssertEqual(api.detailCallCount, 2)
    }

    func test_loadInitialData_throwsAndLeavesCacheEmpty_whenNetworkFails() async {
        let store = MockPokemonPersisting()
        let api = MockPokemonAPIService()
        api.listHandler = { _, _ in throw URLError(.notConnectedToInternet) }
        let repository = PokemonRepository(api: api, store: store, imageCache: MockImageCaching(), pokemonCount: 2)

        do {
            _ = try await repository.loadInitialData()
            XCTFail("expected loadInitialData to throw")
        } catch {
            XCTAssertTrue(store.loadCachedPokemon().isEmpty)
        }
    }

    func test_loadEvolutionDetails_skipsNetworkCall_whenAlreadyPresent() async throws {
        let pokemon = PokemonFixture.make(flavorText: "desc", evolutionChain: [
            PokemonEvolutionStage(id: 1, name: "bulbasaur"),
            PokemonEvolutionStage(id: 2, name: "ivysaur")
        ])
        let api = MockPokemonAPIService()
        api.evolutionHandler = { _ in
            XCTFail("should not fetch evolution data when already present")
            return (nil, [])
        }
        let repository = PokemonRepository(api: api, store: MockPokemonPersisting(), imageCache: MockImageCaching())

        let result = try await repository.loadEvolutionDetails(for: pokemon)

        XCTAssertEqual(result, pokemon)
    }

    func test_loadEvolutionDetails_fetchesAndPersists_whenMissing() async throws {
        let pokemon = PokemonFixture.make()
        let expectedChain = [
            PokemonEvolutionStage(id: 1, name: "bulbasaur"),
            PokemonEvolutionStage(id: 2, name: "ivysaur"),
            PokemonEvolutionStage(id: 3, name: "venusaur")
        ]
        let api = MockPokemonAPIService()
        api.evolutionHandler = { _ in ("A cute pokemon.", expectedChain) }
        let store = MockPokemonPersisting(initial: [pokemon])
        let repository = PokemonRepository(api: api, store: store, imageCache: MockImageCaching())

        let result = try await repository.loadEvolutionDetails(for: pokemon)

        XCTAssertEqual(result.flavorText, "A cute pokemon.")
        XCTAssertEqual(result.evolutionChain, expectedChain)
        XCTAssertEqual(store.loadCachedPokemon().first?.evolutionChain, result.evolutionChain)
    }

    func test_spriteData_returnsCachedData_withoutNetworkCall() async throws {
        let pokemon = PokemonFixture.make()
        let imageCache = MockImageCaching()
        let cachedData = Data([0x01, 0x02])
        await imageCache.seed(cachedData, forID: pokemon.id)
        let repository = PokemonRepository(
            api: MockPokemonAPIService(),
            store: MockPokemonPersisting(),
            imageCache: imageCache
        )

        let result = try await repository.spriteData(forID: pokemon.id)

        XCTAssertEqual(result, cachedData)
    }

    func test_pokemon_returnsCachedEntry_withoutNetworkCall() async throws {
        let cached = PokemonFixture.make(id: 1, name: "bulbasaur")
        let api = MockPokemonAPIService()
        api.detailHandler = { _ in
            XCTFail("should not fetch when the entry is already cached")
            return cached
        }
        let repository = PokemonRepository(
            api: api,
            store: MockPokemonPersisting(initial: [cached]),
            imageCache: MockImageCaching()
        )

        let result = try await repository.pokemon(forID: 1)

        XCTAssertEqual(result, cached)
    }

    func test_pokemon_fetchesAndPersists_whenNotCached() async throws {
        let fetched = PokemonFixture.make(id: 172, name: "pichu")
        let api = MockPokemonAPIService()
        api.detailHandler = { id in
            XCTAssertEqual(id, 172)
            return fetched
        }
        let store = MockPokemonPersisting()
        let repository = PokemonRepository(api: api, store: store, imageCache: MockImageCaching())

        let result = try await repository.pokemon(forID: 172)

        XCTAssertEqual(result, fetched)
        XCTAssertEqual(store.loadCachedPokemon(), [fetched])
    }
}
