import Foundation
import UIKit
import Observation

@MainActor
@Observable
final class PokemonDetailViewModel {
    private(set) var pokemon: PokemonDetail
    private(set) var isLoadingExtras = false
    private(set) var isLoadingSprite = true
    private(set) var spriteImage: UIImage?
    private(set) var infoMessage: String?

    private let repository: PokemonRepositoryProviding

    init(pokemon: PokemonDetail, repository: PokemonRepositoryProviding) {
        self.pokemon = pokemon
        self.repository = repository
    }

    func loadExtrasIfNeeded() async {
        guard !pokemon.hasExtras else { return }
        isLoadingExtras = true
        defer { isLoadingExtras = false }
        do {
            pokemon = try await repository.loadEvolutionDetails(for: pokemon)
        } catch {
            infoMessage = "Sin conexión: mostrando solo la información guardada localmente."
        }
    }

    func loadSprite() async {
        isLoadingSprite = true
        defer { isLoadingSprite = false }
        do {
            let data = try await repository.spriteData(forID: pokemon.id)
            spriteImage = UIImage(data: data)
        } catch {
            spriteImage = nil
        }
    }
}
