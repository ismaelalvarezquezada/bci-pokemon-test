import Foundation
import Observation

enum PokedexLoadState: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)
}

@MainActor
@Observable
final class PokemonListViewModel {
    private(set) var allPokemon: [PokemonDetail]
    private(set) var state: PokedexLoadState
    var searchText: String = ""
    var selectedTypes: Set<String> = []
    var sortOption: PokemonSortOption = .number

    private let repository: PokemonRepositoryProviding

    init(repository: PokemonRepositoryProviding) {
        self.repository = repository
        let cached = repository.cachedPokemon()
        self.allPokemon = cached
        self.state = cached.isEmpty ? .idle : .loaded
    }

    var availableTypes: [String] {
        Set(allPokemon.flatMap { $0.types.map(\.name) }).sorted()
    }

    var isFilteringByType: Bool {
        !selectedTypes.isEmpty
    }

    var isSorting: Bool {
        sortOption != .number
    }

    var filteredPokemon: [PokemonDetail] {
        var result = allPokemon
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            result = result.filter { $0.name.lowercased().contains(query) }
        }
        if !selectedTypes.isEmpty {
            result = result.filter { pokemon in pokemon.types.contains { selectedTypes.contains($0.name) } }
        }
        return sortOption.apply(to: result)
    }

    func toggleType(_ type: String) {
        if selectedTypes.contains(type) {
            selectedTypes.remove(type)
        } else {
            selectedTypes.insert(type)
        }
    }

    func clearTypeFilter() {
        selectedTypes.removeAll()
    }

    func loadIfNeeded() async {
        guard allPokemon.isEmpty else { return }
        await load()
    }

    func refresh() async {
        await load()
    }

    private func load() async {
        state = .loading
        do {
            allPokemon = try await repository.loadInitialData()
            state = .loaded
        } catch {
            state = allPokemon.isEmpty ? .failed(Self.message(for: error)) : .loaded
        }
    }

    private static func message(for error: Error) -> String {
        if let apiError = error as? PokemonAPIError {
            switch apiError {
            case .invalidURL:
                return "URL inválida al construir la petición."
            case .invalidResponse:
                return "No se pudo conectar a la red. Revisa tu conexión e intenta nuevamente."
            case .decodingFailed:
                return "La respuesta del servidor no pudo ser interpretada."
            }
        }
        return "No se pudo conectar a la red. Revisa tu conexión e intenta nuevamente."
    }
}
