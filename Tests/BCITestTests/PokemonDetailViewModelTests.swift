import XCTest
import UIKit
@testable import BCITest

@MainActor
final class PokemonDetailViewModelTests: XCTestCase {
    func test_loadExtrasIfNeeded_skipsNetworkCall_whenAlreadyHasExtras() async {
        let pokemon = PokemonFixture.make(flavorText: "desc", evolutionChain: [PokemonEvolutionStage(id: 1, name: "a")])
        let repository = MockPokemonRepository(cached: [])
        repository.loadEvolutionDetailsHandler = { _ in
            XCTFail("should not fetch when extras already present")
            return pokemon
        }
        let viewModel = PokemonDetailViewModel(pokemon: pokemon, repository: repository)

        await viewModel.loadExtrasIfNeeded()

        XCTAssertEqual(viewModel.pokemon, pokemon)
    }

    func test_loadExtrasIfNeeded_updatesPokemon_onSuccess() async {
        let pokemon = PokemonFixture.make()
        let updated = PokemonFixture.make(flavorText: "desc", evolutionChain: [
            PokemonEvolutionStage(id: 1, name: "a"),
            PokemonEvolutionStage(id: 2, name: "b")
        ])
        let repository = MockPokemonRepository(cached: [])
        repository.loadEvolutionDetailsHandler = { _ in updated }
        let viewModel = PokemonDetailViewModel(pokemon: pokemon, repository: repository)

        await viewModel.loadExtrasIfNeeded()

        XCTAssertEqual(viewModel.pokemon.flavorText, "desc")
        XCTAssertEqual(viewModel.pokemon.evolutionChain, [
            PokemonEvolutionStage(id: 1, name: "a"),
            PokemonEvolutionStage(id: 2, name: "b")
        ])
        XCTAssertNil(viewModel.infoMessage)
    }

    func test_loadExtrasIfNeeded_setsInfoMessage_onFailure() async {
        let pokemon = PokemonFixture.make()
        let repository = MockPokemonRepository(cached: [])
        repository.loadEvolutionDetailsHandler = { _ in throw URLError(.notConnectedToInternet) }
        let viewModel = PokemonDetailViewModel(pokemon: pokemon, repository: repository)

        await viewModel.loadExtrasIfNeeded()

        XCTAssertNotNil(viewModel.infoMessage)
        XCTAssertEqual(viewModel.pokemon, pokemon)
    }

    func test_loadSprite_setsImage_fromRepositoryData() async throws {
        let pokemon = PokemonFixture.make()
        let imageData = try XCTUnwrap(Self.samplePNGData())
        let repository = MockPokemonRepository(cached: [])
        repository.spriteDataHandler = { _ in imageData }
        let viewModel = PokemonDetailViewModel(pokemon: pokemon, repository: repository)

        await viewModel.loadSprite()

        XCTAssertNotNil(viewModel.spriteImage)
        XCTAssertFalse(viewModel.isLoadingSprite)
    }

    func test_loadSprite_leavesImageNil_whenRepositoryFails() async {
        let pokemon = PokemonFixture.make()
        let repository = MockPokemonRepository(cached: [])
        repository.spriteDataHandler = { _ in throw URLError(.notConnectedToInternet) }
        let viewModel = PokemonDetailViewModel(pokemon: pokemon, repository: repository)

        await viewModel.loadSprite()

        XCTAssertNil(viewModel.spriteImage)
        XCTAssertFalse(viewModel.isLoadingSprite)
    }

    private static func samplePNGData() -> Data? {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
        let image = renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        return image.pngData()
    }
}
