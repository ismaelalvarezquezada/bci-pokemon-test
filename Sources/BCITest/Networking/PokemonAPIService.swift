import Foundation

enum PokemonAPIError: Error, Equatable {
    case invalidURL
    case invalidResponse(statusCode: Int)
    case decodingFailed
}

protocol PokemonAPIServicing: Sendable {
    func fetchPokemonList(limit: Int, offset: Int) async throws -> [PokemonListEntry]
    func fetchPokemonDetail(id: Int) async throws -> PokemonDetail
    func fetchEvolutionAndDescription(forSpeciesID id: Int) async throws -> (description: String?, evolutionChain: [PokemonEvolutionStage])
}

struct PokemonAPIService: PokemonAPIServicing {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder

    init(baseURL: URL = URL(string: "https://pokeapi.co/api/v2")!, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = JSONDecoder()
    }

    func fetchPokemonList(limit: Int, offset: Int) async throws -> [PokemonListEntry] {
        let url = baseURL.appendingPathComponent("pokemon")
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw PokemonAPIError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]
        let dto: PokemonListResponseDTO = try await get(components.url)
        return dto.results.compactMap { $0.toDomain() }
    }

    func fetchPokemonDetail(id: Int) async throws -> PokemonDetail {
        let url = baseURL.appendingPathComponent("pokemon/\(id)")
        let dto: PokemonDetailDTO = try await get(url)
        return dto.toDomain()
    }

    func fetchEvolutionAndDescription(forSpeciesID id: Int) async throws -> (description: String?, evolutionChain: [PokemonEvolutionStage]) {
        let speciesURL = baseURL.appendingPathComponent("pokemon-species/\(id)")
        let species: PokemonSpeciesDTO = try await get(speciesURL)
        let description = species.preferredDescription()

        guard let chainID = PokeAPIIDExtractor.id(fromURL: species.evolutionChain.url) else {
            return (description, [])
        }
        let chainURL = baseURL.appendingPathComponent("evolution-chain/\(chainID)")
        let chain: EvolutionChainDTO = try await get(chainURL)
        return (description, chain.flattenedStages())
    }

    private func get<T: Decodable>(_ url: URL?) async throws -> T {
        guard let url else { throw PokemonAPIError.invalidURL }
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw PokemonAPIError.invalidResponse(statusCode: code)
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw PokemonAPIError.decodingFailed
        }
    }
}
