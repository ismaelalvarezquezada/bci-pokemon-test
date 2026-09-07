import SwiftUI

struct PokedexRootView: View {
    @State private var coordinator: PokedexCoordinator
    private let repository: PokemonRepositoryProviding

    init(repository: PokemonRepositoryProviding) {
        self.repository = repository
        _coordinator = State(initialValue: PokedexCoordinator(repository: repository))
    }

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            PokemonListView(repository: repository, coordinator: coordinator)
                .navigationDestination(for: PokedexRoute.self) { route in
                    coordinator.destination(for: route)
                }
        }
    }
}
