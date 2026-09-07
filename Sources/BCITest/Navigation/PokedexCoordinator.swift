import SwiftUI

/// Owns the navigation stack and is the single place that resolves a route into a
/// destination view. Views ask the coordinator to navigate (push/pop) instead of
/// constructing destinations themselves — that's what let a Button in an evolution
/// card push the same detail screen a list row pushes, without either view knowing
/// how `PokemonDetailView` is built or wired.
@MainActor
@Observable
final class PokedexCoordinator {
    var path = NavigationPath()

    private let repository: PokemonRepositoryProviding

    init(repository: PokemonRepositoryProviding) {
        self.repository = repository
    }

    func push(_ route: PokedexRoute) {
        path.append(route)
    }

    func showDetail(for pokemon: PokemonDetail) {
        push(.detail(pokemon))
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeLast(path.count)
    }

    @ViewBuilder
    func destination(for route: PokedexRoute) -> some View {
        switch route {
        case .detail(let pokemon):
            PokemonDetailView(
                viewModel: PokemonDetailViewModel(pokemon: pokemon, repository: repository),
                repository: repository,
                coordinator: self
            )
        }
    }
}
