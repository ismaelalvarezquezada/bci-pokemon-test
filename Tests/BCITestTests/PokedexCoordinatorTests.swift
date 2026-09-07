import XCTest
@testable import BCITest

@MainActor
final class PokedexCoordinatorTests: XCTestCase {
    func test_showDetail_appendsRouteToPath() {
        let coordinator = PokedexCoordinator(repository: MockPokemonRepository(cached: []))

        coordinator.showDetail(for: PokemonFixture.make())

        XCTAssertEqual(coordinator.path.count, 1)
    }

    func test_showDetail_pushesOneRoutePerCall() {
        let coordinator = PokedexCoordinator(repository: MockPokemonRepository(cached: []))

        coordinator.showDetail(for: PokemonFixture.make(id: 1))
        coordinator.showDetail(for: PokemonFixture.make(id: 2))

        XCTAssertEqual(coordinator.path.count, 2)
    }

    func test_pop_removesLastRoute() {
        let coordinator = PokedexCoordinator(repository: MockPokemonRepository(cached: []))
        coordinator.showDetail(for: PokemonFixture.make())

        coordinator.pop()

        XCTAssertEqual(coordinator.path.count, 0)
    }

    func test_pop_doesNothing_whenPathIsEmpty() {
        let coordinator = PokedexCoordinator(repository: MockPokemonRepository(cached: []))

        coordinator.pop()

        XCTAssertEqual(coordinator.path.count, 0)
    }

    func test_popToRoot_clearsEveryRoute() {
        let coordinator = PokedexCoordinator(repository: MockPokemonRepository(cached: []))
        coordinator.showDetail(for: PokemonFixture.make(id: 1))
        coordinator.showDetail(for: PokemonFixture.make(id: 2))
        coordinator.showDetail(for: PokemonFixture.make(id: 3))

        coordinator.popToRoot()

        XCTAssertEqual(coordinator.path.count, 0)
    }
}
