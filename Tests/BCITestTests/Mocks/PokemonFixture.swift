@testable import BCITest

enum PokemonFixture {
    static func make(
        id: Int = 1,
        name: String = "bulbasaur",
        types: [String] = ["grass", "poison"],
        stats: [PokemonStat] = [PokemonStat(name: "hp", baseValue: 45)],
        flavorText: String? = nil,
        evolutionChain: [PokemonEvolutionStage]? = nil
    ) -> PokemonDetail {
        PokemonDetail(
            id: id,
            name: name,
            height: 7,
            weight: 69,
            types: types.map { PokemonType(name: $0) },
            abilities: [PokemonAbility(name: "overgrow", isHidden: false)],
            stats: stats,
            moves: [PokemonMove(name: "tackle")],
            flavorText: flavorText,
            evolutionChain: evolutionChain
        )
    }
}
