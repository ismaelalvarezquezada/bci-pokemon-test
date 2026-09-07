import XCTest
@testable import BCITest

@MainActor
final class PokemonListViewModelTests: XCTestCase {
    func test_init_loadsCachedPokemonImmediately() {
        let cached = [PokemonFixture.make(id: 1, name: "bulbasaur")]
        let repository = MockPokemonRepository(cached: cached)

        let viewModel = PokemonListViewModel(repository: repository)

        XCTAssertEqual(viewModel.allPokemon, cached)
        XCTAssertEqual(viewModel.state, .loaded)
    }

    func test_init_withEmptyCache_startsIdle() {
        let repository = MockPokemonRepository(cached: [])

        let viewModel = PokemonListViewModel(repository: repository)

        XCTAssertEqual(viewModel.state, .idle)
    }

    func test_loadIfNeeded_doesNothing_whenAlreadyHasData() async {
        let repository = MockPokemonRepository(cached: [PokemonFixture.make()])
        repository.loadInitialDataHandler = {
            XCTFail("should not fetch when data already present")
            return []
        }
        let viewModel = PokemonListViewModel(repository: repository)

        await viewModel.loadIfNeeded()

        XCTAssertEqual(repository.loadInitialDataCallCount, 0)
    }

    func test_loadIfNeeded_fetchesAndSetsLoaded_whenCacheEmpty() async {
        let fetched = [PokemonFixture.make(id: 1), PokemonFixture.make(id: 2)]
        let repository = MockPokemonRepository(cached: [])
        repository.loadInitialDataHandler = { fetched }
        let viewModel = PokemonListViewModel(repository: repository)

        await viewModel.loadIfNeeded()

        XCTAssertEqual(viewModel.allPokemon, fetched)
        XCTAssertEqual(viewModel.state, .loaded)
    }

    func test_loadIfNeeded_setsFailed_whenCacheEmptyAndNetworkFails() async {
        let repository = MockPokemonRepository(cached: [])
        repository.loadInitialDataHandler = { throw URLError(.notConnectedToInternet) }
        let viewModel = PokemonListViewModel(repository: repository)

        await viewModel.loadIfNeeded()

        guard case .failed = viewModel.state else {
            return XCTFail("expected failed state, got \(viewModel.state)")
        }
    }

    func test_refresh_keepsLoaded_whenCacheNonEmptyButNetworkFails() async {
        let existing = [PokemonFixture.make(id: 1)]
        let repository = MockPokemonRepository(cached: existing)
        repository.loadInitialDataHandler = { throw URLError(.notConnectedToInternet) }
        let viewModel = PokemonListViewModel(repository: repository)

        await viewModel.refresh()

        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertEqual(viewModel.allPokemon, existing)
    }

    func test_filteredPokemon_filtersCaseInsensitivelyBySubstring() {
        let repository = MockPokemonRepository(cached: [
            PokemonFixture.make(id: 1, name: "bulbasaur"),
            PokemonFixture.make(id: 2, name: "charmander"),
            PokemonFixture.make(id: 25, name: "pikachu")
        ])
        let viewModel = PokemonListViewModel(repository: repository)

        viewModel.searchText = "CHAR"

        XCTAssertEqual(viewModel.filteredPokemon.map(\.name), ["charmander"])
    }

    func test_filteredPokemon_returnsAll_whenSearchTextIsBlank() {
        let cached = [
            PokemonFixture.make(id: 1, name: "bulbasaur"),
            PokemonFixture.make(id: 2, name: "charmander")
        ]
        let repository = MockPokemonRepository(cached: cached)
        let viewModel = PokemonListViewModel(repository: repository)

        viewModel.searchText = "   "

        XCTAssertEqual(viewModel.filteredPokemon, cached)
    }

    func test_filteredPokemon_filtersBySelectedType() {
        let repository = MockPokemonRepository(cached: [
            PokemonFixture.make(id: 1, name: "bulbasaur", types: ["grass", "poison"]),
            PokemonFixture.make(id: 4, name: "charmander", types: ["fire"]),
            PokemonFixture.make(id: 7, name: "squirtle", types: ["water"])
        ])
        let viewModel = PokemonListViewModel(repository: repository)

        viewModel.toggleType("fire")

        XCTAssertEqual(viewModel.filteredPokemon.map(\.name), ["charmander"])
    }

    func test_filteredPokemon_withMultipleSelectedTypes_matchesAny() {
        let repository = MockPokemonRepository(cached: [
            PokemonFixture.make(id: 1, name: "bulbasaur", types: ["grass", "poison"]),
            PokemonFixture.make(id: 4, name: "charmander", types: ["fire"]),
            PokemonFixture.make(id: 7, name: "squirtle", types: ["water"])
        ])
        let viewModel = PokemonListViewModel(repository: repository)

        viewModel.toggleType("fire")
        viewModel.toggleType("water")

        XCTAssertEqual(viewModel.filteredPokemon.map(\.name).sorted(), ["charmander", "squirtle"])
    }

    func test_toggleType_deselectsWhenTappedAgain() {
        let repository = MockPokemonRepository(cached: [
            PokemonFixture.make(id: 4, name: "charmander", types: ["fire"])
        ])
        let viewModel = PokemonListViewModel(repository: repository)

        viewModel.toggleType("fire")
        XCTAssertEqual(viewModel.selectedTypes, ["fire"])

        viewModel.toggleType("fire")
        XCTAssertTrue(viewModel.selectedTypes.isEmpty)
    }

    func test_filteredPokemon_combinesTypeFilterAndSearch() {
        let repository = MockPokemonRepository(cached: [
            PokemonFixture.make(id: 1, name: "bulbasaur", types: ["grass", "poison"]),
            PokemonFixture.make(id: 13, name: "weedle", types: ["poison"])
        ])
        let viewModel = PokemonListViewModel(repository: repository)

        viewModel.toggleType("poison")
        viewModel.searchText = "bulba"

        XCTAssertEqual(viewModel.filteredPokemon.map(\.name), ["bulbasaur"])
    }

    func test_filteredPokemon_sortsByHighestAttack() {
        let repository = MockPokemonRepository(cached: [
            PokemonFixture.make(id: 1, name: "low", stats: [PokemonStat(name: "attack", baseValue: 10)]),
            PokemonFixture.make(id: 2, name: "high", stats: [PokemonStat(name: "attack", baseValue: 90)]),
            PokemonFixture.make(id: 3, name: "mid", stats: [PokemonStat(name: "attack", baseValue: 50)])
        ])
        let viewModel = PokemonListViewModel(repository: repository)

        viewModel.sortOption = .attack

        XCTAssertEqual(viewModel.filteredPokemon.map(\.name), ["high", "mid", "low"])
    }

    func test_filteredPokemon_sortsByNumber_byDefault() {
        let repository = MockPokemonRepository(cached: [
            PokemonFixture.make(id: 3, name: "venusaur"),
            PokemonFixture.make(id: 1, name: "bulbasaur"),
            PokemonFixture.make(id: 2, name: "ivysaur")
        ])
        let viewModel = PokemonListViewModel(repository: repository)

        XCTAssertEqual(viewModel.filteredPokemon.map(\.id), [1, 2, 3])
    }

    func test_availableTypes_returnsSortedUniqueTypesFromLoadedPokemon() {
        let repository = MockPokemonRepository(cached: [
            PokemonFixture.make(id: 1, types: ["grass", "poison"]),
            PokemonFixture.make(id: 4, types: ["fire"])
        ])
        let viewModel = PokemonListViewModel(repository: repository)

        XCTAssertEqual(viewModel.availableTypes, ["fire", "grass", "poison"])
    }

    func test_isFilteringByType_reflectsSelectedTypesState() {
        let viewModel = PokemonListViewModel(repository: MockPokemonRepository(cached: []))

        XCTAssertFalse(viewModel.isFilteringByType)

        viewModel.toggleType("fire")
        XCTAssertTrue(viewModel.isFilteringByType)

        viewModel.clearTypeFilter()
        XCTAssertFalse(viewModel.isFilteringByType)
    }

    func test_isSorting_reflectsSortOptionState() {
        let viewModel = PokemonListViewModel(repository: MockPokemonRepository(cached: []))

        XCTAssertFalse(viewModel.isSorting)

        viewModel.sortOption = .hp
        XCTAssertTrue(viewModel.isSorting)

        viewModel.sortOption = .number
        XCTAssertFalse(viewModel.isSorting)
    }

    func test_clearTypeFilter_removesAllSelectedTypes() {
        let viewModel = PokemonListViewModel(repository: MockPokemonRepository(cached: []))
        viewModel.toggleType("water")
        viewModel.toggleType("fire")

        viewModel.clearTypeFilter()

        XCTAssertTrue(viewModel.selectedTypes.isEmpty)
    }
}
