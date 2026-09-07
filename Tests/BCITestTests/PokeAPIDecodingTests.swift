import XCTest
@testable import BCITest

final class PokeAPIDecodingTests: XCTestCase {
    func test_idExtractor_parsesTrailingSegment() {
        XCTAssertEqual(PokeAPIIDExtractor.id(fromURL: "https://pokeapi.co/api/v2/pokemon/25/"), 25)
        XCTAssertEqual(PokeAPIIDExtractor.id(fromURL: "https://pokeapi.co/api/v2/pokemon-species/1"), 1)
        XCTAssertNil(PokeAPIIDExtractor.id(fromURL: "not-a-url"))
    }

    func test_pokemonListResponse_decodesAndMapsEntries() throws {
        let json = """
        {
          "results": [
            { "name": "bulbasaur", "url": "https://pokeapi.co/api/v2/pokemon/1/" },
            { "name": "ivysaur", "url": "https://pokeapi.co/api/v2/pokemon/2/" }
          ]
        }
        """.data(using: .utf8)!

        let dto = try JSONDecoder().decode(PokemonListResponseDTO.self, from: json)
        let entries = dto.results.compactMap { $0.toDomain() }

        XCTAssertEqual(entries, [
            PokemonListEntry(id: 1, name: "bulbasaur"),
            PokemonListEntry(id: 2, name: "ivysaur")
        ])
    }

    func test_pokemonDetail_decodesAndMapsToDomain() throws {
        let json = """
        {
          "id": 1,
          "name": "bulbasaur",
          "height": 7,
          "weight": 69,
          "types": [
            { "type": { "name": "grass", "url": "" } },
            { "type": { "name": "poison", "url": "" } }
          ],
          "abilities": [
            { "ability": { "name": "overgrow", "url": "" }, "is_hidden": false, "slot": 1 }
          ],
          "stats": [
            { "base_stat": 45, "stat": { "name": "hp", "url": "" } }
          ],
          "moves": [
            { "move": { "name": "tackle", "url": "" } }
          ]
        }
        """.data(using: .utf8)!

        let detail = try JSONDecoder().decode(PokemonDetailDTO.self, from: json).toDomain()

        XCTAssertEqual(detail.id, 1)
        XCTAssertEqual(detail.types.map(\.name), ["grass", "poison"])
        XCTAssertEqual(detail.abilities.first?.isHidden, false)
        XCTAssertEqual(detail.stats.first?.baseValue, 45)
        XCTAssertEqual(detail.moves.first?.name, "tackle")
        XCTAssertEqual(
            detail.spriteURL.absoluteString,
            "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/1.png"
        )
    }

    func test_evolutionChain_flattensBranching() throws {
        let json = """
        {
          "chain": {
            "species": { "name": "eevee", "url": "https://pokeapi.co/api/v2/pokemon-species/133/" },
            "evolves_to": [
              { "species": { "name": "vaporeon", "url": "https://pokeapi.co/api/v2/pokemon-species/134/" }, "evolves_to": [] },
              { "species": { "name": "jolteon", "url": "https://pokeapi.co/api/v2/pokemon-species/135/" }, "evolves_to": [] }
            ]
          }
        }
        """.data(using: .utf8)!

        let chain = try JSONDecoder().decode(EvolutionChainDTO.self, from: json)

        XCTAssertEqual(chain.flattenedStages(), [
            PokemonEvolutionStage(id: 133, name: "eevee"),
            PokemonEvolutionStage(id: 134, name: "vaporeon"),
            PokemonEvolutionStage(id: 135, name: "jolteon")
        ])
    }

    func test_species_prefersSpanishFlavorText_thenEnglish() throws {
        let json = """
        {
          "evolution_chain": { "url": "https://pokeapi.co/api/v2/evolution-chain/1/" },
          "flavor_text_entries": [
            { "flavor_text": "A cute pokemon.", "language": { "name": "en", "url": "" } },
            { "flavor_text": "Un pokemon lindo.", "language": { "name": "es", "url": "" } }
          ]
        }
        """.data(using: .utf8)!

        let species = try JSONDecoder().decode(PokemonSpeciesDTO.self, from: json)

        XCTAssertEqual(species.preferredDescription(), "Un pokemon lindo.")
    }
}
