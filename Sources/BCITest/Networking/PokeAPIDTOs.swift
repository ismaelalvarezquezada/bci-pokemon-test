import Foundation

enum PokeAPIIDExtractor {
    static func id(fromURL url: String) -> Int? {
        let trimmed = url.hasSuffix("/") ? String(url.dropLast()) : url
        guard let last = trimmed.split(separator: "/").last else { return nil }
        return Int(last)
    }
}

struct NamedResourceDTO: Decodable {
    let name: String
    let url: String
}

struct PokemonListResponseDTO: Decodable {
    let results: [PokemonListResultDTO]
}

struct PokemonListResultDTO: Decodable {
    let name: String
    let url: String

    func toDomain() -> PokemonListEntry? {
        guard let id = PokeAPIIDExtractor.id(fromURL: url) else { return nil }
        return PokemonListEntry(id: id, name: name)
    }
}

struct PokemonDetailDTO: Decodable {
    let id: Int
    let name: String
    let height: Int
    let weight: Int
    let types: [TypeSlotDTO]
    let abilities: [AbilitySlotDTO]
    let stats: [StatSlotDTO]
    let moves: [MoveSlotDTO]

    struct TypeSlotDTO: Decodable {
        let type: NamedResourceDTO
    }

    struct AbilitySlotDTO: Decodable {
        let ability: NamedResourceDTO
        let isHidden: Bool

        enum CodingKeys: String, CodingKey {
            case ability
            case isHidden = "is_hidden"
        }
    }

    struct StatSlotDTO: Decodable {
        let baseStat: Int
        let stat: NamedResourceDTO

        enum CodingKeys: String, CodingKey {
            case baseStat = "base_stat"
            case stat
        }
    }

    struct MoveSlotDTO: Decodable {
        let move: NamedResourceDTO
    }

    func toDomain() -> PokemonDetail {
        PokemonDetail(
            id: id,
            name: name,
            height: height,
            weight: weight,
            types: types.map { PokemonType(name: $0.type.name) },
            abilities: abilities.map { PokemonAbility(name: $0.ability.name, isHidden: $0.isHidden) },
            stats: stats.map { PokemonStat(name: $0.stat.name, baseValue: $0.baseStat) },
            moves: moves.map { PokemonMove(name: $0.move.name) },
            flavorText: nil,
            evolutionChain: nil
        )
    }
}

struct PokemonSpeciesDTO: Decodable {
    let evolutionChain: EvolutionChainReferenceDTO
    let flavorTextEntries: [FlavorTextEntryDTO]

    enum CodingKeys: String, CodingKey {
        case evolutionChain = "evolution_chain"
        case flavorTextEntries = "flavor_text_entries"
    }

    struct EvolutionChainReferenceDTO: Decodable {
        let url: String
    }

    struct FlavorTextEntryDTO: Decodable {
        let flavorText: String
        let language: NamedResourceDTO

        enum CodingKeys: String, CodingKey {
            case flavorText = "flavor_text"
            case language
        }
    }

    func preferredDescription() -> String? {
        let candidate = flavorTextEntries.first { $0.language.name == "es" }
            ?? flavorTextEntries.first { $0.language.name == "en" }
        return candidate?.flavorText.cleanedFlavorText
    }
}

struct EvolutionChainDTO: Decodable {
    let chain: ChainLinkDTO

    struct ChainLinkDTO: Decodable {
        let species: NamedResourceDTO
        let evolvesTo: [ChainLinkDTO]

        enum CodingKeys: String, CodingKey {
            case species
            case evolvesTo = "evolves_to"
        }
    }

    func flattenedStages() -> [PokemonEvolutionStage] {
        var stages: [PokemonEvolutionStage] = []
        func walk(_ link: ChainLinkDTO) {
            if let id = PokeAPIIDExtractor.id(fromURL: link.species.url) {
                stages.append(PokemonEvolutionStage(id: id, name: link.species.name))
            }
            for next in link.evolvesTo {
                walk(next)
            }
        }
        walk(chain)
        return stages
    }
}

private extension String {
    var cleanedFlavorText: String {
        replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\u{0C}", with: " ")
    }
}
