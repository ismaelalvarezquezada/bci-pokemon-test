import Foundation

enum PokemonSortOption: String, CaseIterable, Identifiable, Sendable {
    case number
    case hp
    case attack
    case defense
    case specialAttack
    case specialDefense
    case speed

    var id: String { rawValue }

    var label: String {
        switch self {
        case .number: return "Número"
        case .hp: return "Mayor HP"
        case .attack: return "Mayor ataque"
        case .defense: return "Mayor defensa"
        case .specialAttack: return "Mayor ataque especial"
        case .specialDefense: return "Mayor defensa especial"
        case .speed: return "Mayor velocidad"
        }
    }

    private var statName: String? {
        switch self {
        case .number: return nil
        case .hp: return "hp"
        case .attack: return "attack"
        case .defense: return "defense"
        case .specialAttack: return "special-attack"
        case .specialDefense: return "special-defense"
        case .speed: return "speed"
        }
    }

    func apply(to pokemon: [PokemonDetail]) -> [PokemonDetail] {
        guard let statName else {
            return pokemon.sorted { $0.id < $1.id }
        }
        return pokemon.sorted { $0.statValue(named: statName) > $1.statValue(named: statName) }
    }
}
