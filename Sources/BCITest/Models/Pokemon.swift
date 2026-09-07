import Foundation

struct PokemonListEntry: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: Int
    let name: String
}

struct PokemonType: Codable, Equatable, Hashable, Identifiable, Sendable {
    var id: String { name }
    let name: String

    var displayName: String { name.capitalized }
}

struct PokemonStat: Codable, Equatable, Hashable, Identifiable, Sendable {
    var id: String { name }
    let name: String
    let baseValue: Int

    var displayName: String { name.replacingOccurrences(of: "-", with: " ").capitalized }
}

struct PokemonAbility: Codable, Equatable, Hashable, Identifiable, Sendable {
    var id: String { name }
    let name: String
    let isHidden: Bool

    var displayName: String { name.replacingOccurrences(of: "-", with: " ").capitalized }
}

struct PokemonMove: Codable, Equatable, Hashable, Identifiable, Sendable {
    var id: String { name }
    let name: String

    var displayName: String { name.replacingOccurrences(of: "-", with: " ").capitalized }
}

struct PokemonEvolutionStage: Codable, Equatable, Hashable, Identifiable, Sendable {
    let id: Int
    let name: String

    var displayName: String { name.capitalized }
}

struct PokemonDetail: Identifiable, Codable, Equatable, Hashable, Sendable {
    let id: Int
    let name: String
    let height: Int
    let weight: Int
    let types: [PokemonType]
    let abilities: [PokemonAbility]
    let stats: [PokemonStat]
    let moves: [PokemonMove]
    var flavorText: String?
    var evolutionChain: [PokemonEvolutionStage]?

    var displayName: String { name.capitalized }

    /// Built per the challenge spec from the sprites-repo URL pattern, not from PokeAPI's own sprite field.
    var spriteURL: URL { Self.spriteURL(forID: id) }

    static func spriteURL(forID id: Int) -> URL {
        URL(string: "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/\(id).png")!
    }

    var hasExtras: Bool {
        evolutionChain != nil && flavorText != nil
    }

    func statValue(named statName: String) -> Int {
        stats.first { $0.name == statName }?.baseValue ?? 0
    }
}
