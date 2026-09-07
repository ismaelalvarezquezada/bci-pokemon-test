import SwiftUI

struct PokemonRowView: View {
    let pokemon: PokemonDetail
    let repository: PokemonRepositoryProviding

    var body: some View {
        HStack(spacing: 12) {
            PokemonSpriteView(pokemonID: pokemon.id, repository: repository)
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: "#%03d", pokemon.id))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(pokemon.displayName)
                    .font(.headline)
                HStack(spacing: 6) {
                    ForEach(pokemon.types) { type in
                        TypeBadge(type: type)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
