import XCTest
@testable import BCITest

final class PokemonStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "PokemonStoreTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    func test_loadCachedPokemon_returnsEmpty_whenNothingStored() {
        let store = UserDefaultsPokemonStore(defaults: defaults)

        XCTAssertTrue(store.loadCachedPokemon().isEmpty)
    }

    func test_saveAndLoad_roundTrips() {
        let store = UserDefaultsPokemonStore(defaults: defaults)
        let pokemon = [PokemonFixture.make(id: 1), PokemonFixture.make(id: 2, name: "ivysaur")]

        store.saveCachedPokemon(pokemon)

        XCTAssertEqual(store.loadCachedPokemon(), pokemon)
    }

    func test_updatePokemon_insertsNewEntry() {
        let store = UserDefaultsPokemonStore(defaults: defaults)
        let pokemon = PokemonFixture.make(id: 1)

        store.updatePokemon(pokemon)

        XCTAssertEqual(store.loadCachedPokemon(), [pokemon])
    }

    func test_updatePokemon_replacesExistingEntry() {
        let store = UserDefaultsPokemonStore(defaults: defaults)
        store.saveCachedPokemon([PokemonFixture.make(id: 1, name: "bulbasaur")])
        let updated = PokemonFixture.make(id: 1, name: "bulbasaur", flavorText: "desc")

        store.updatePokemon(updated)

        XCTAssertEqual(store.loadCachedPokemon(), [updated])
    }
}
