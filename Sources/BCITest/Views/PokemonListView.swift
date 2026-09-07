import SwiftUI

struct PokemonListView: View {
    @State private var viewModel: PokemonListViewModel
    private let repository: PokemonRepositoryProviding
    private let coordinator: PokedexCoordinator

    init(repository: PokemonRepositoryProviding, coordinator: PokedexCoordinator) {
        self.repository = repository
        self.coordinator = coordinator
        _viewModel = State(initialValue: PokemonListViewModel(repository: repository))
    }

    var body: some View {
        content
            .navigationTitle("Pokédex")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $viewModel.searchText, prompt: "Buscar Pokémon")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    sortMenu
                }
            }
            .task { await viewModel.loadIfNeeded() }
            .refreshable { await viewModel.refresh() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.allPokemon.isEmpty {
            emptyStateContent
        } else {
            list
        }
    }

    @ViewBuilder
    private var emptyStateContent: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView("Cargando Pokédex…")
        case .failed(let message):
            ContentUnavailableView(
                "Sin conexión",
                systemImage: "wifi.slash",
                description: Text(message)
            )
        case .loaded:
            ContentUnavailableView("Sin datos", systemImage: "questionmark.circle")
        }
    }

    private var list: some View {
        List(viewModel.filteredPokemon) { pokemon in
            NavigationLink(value: PokedexRoute.detail(pokemon)) {
                PokemonRowView(pokemon: pokemon, repository: repository)
            }
        }
        .listStyle(.plain)
        .safeAreaInset(edge: .top, spacing: 0) {
            if !viewModel.availableTypes.isEmpty {
                typeFilterBar
            }
        }
        .overlay {
            if viewModel.filteredPokemon.isEmpty {
                if viewModel.searchText.isEmpty {
                    ContentUnavailableView("Sin resultados", systemImage: "line.3.horizontal.decrease.circle")
                } else {
                    ContentUnavailableView.search
                }
            }
        }
    }

    private var typeFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                PokemonTypeFilterChip(
                    title: "Todos",
                    color: .secondary,
                    isSelected: !viewModel.isFilteringByType,
                    action: { viewModel.clearTypeFilter() }
                )
                ForEach(viewModel.availableTypes, id: \.self) { type in
                    PokemonTypeFilterChip(
                        title: type.capitalized,
                        color: PokemonTypeColor.color(for: type),
                        isSelected: viewModel.selectedTypes.contains(type),
                        action: { viewModel.toggleType(type) }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.bar)
    }

    private var sortMenu: some View {
        Menu {
            Picker("Ordenar por", selection: $viewModel.sortOption) {
                ForEach(PokemonSortOption.allCases) { option in
                    Text(option.label).tag(option)
                }
            }
        } label: {
            Image(systemName: viewModel.isSorting ? "arrow.up.arrow.down.circle.fill" : "arrow.up.arrow.down.circle")
        }
    }
}
