import SwiftUI

/// Tappable evolution card: resolves the full detail for `stage` (cache-first, falling
/// back to network for stages outside the cached 151, e.g. Pichu in Pikachu's chain)
/// and pushes it via the coordinator.
struct PokemonEvolutionCardView: View {
    let stage: PokemonEvolutionStage
    let isCurrent: Bool
    let repository: PokemonRepositoryProviding
    let coordinator: PokedexCoordinator

    @State private var isResolving = false

    var body: some View {
        Button {
            Task { await selectStage() }
        } label: {
            cardContent
        }
        .buttonStyle(.plain)
        .disabled(isCurrent || isResolving)
    }

    private var cardContent: some View {
        VStack(spacing: 8) {
            PokemonSpriteView(pokemonID: stage.id, repository: repository)
                .frame(width: 72, height: 72)
            Text(stage.displayName)
                .font(.caption.weight(.medium))
                .lineLimit(1)
        }
        .padding(12)
        .frame(width: 104)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(isCurrent ? Color.accentColor : .clear, lineWidth: 2)
        }
    }

    private func selectStage() async {
        guard !isCurrent else { return }
        isResolving = true
        defer { isResolving = false }
        if let pokemon = try? await repository.pokemon(forID: stage.id) {
            coordinator.showDetail(for: pokemon)
        }
    }
}
