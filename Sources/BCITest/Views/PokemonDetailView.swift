import SwiftUI

struct PokemonDetailView: View {
    @State var viewModel: PokemonDetailViewModel
    let repository: PokemonRepositoryProviding
    let coordinator: PokedexCoordinator

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                descriptionSection
                statsSection
                abilitiesSection
                movesSection
                evolutionSection
                if let infoMessage = viewModel.infoMessage {
                    Label(infoMessage, systemImage: "wifi.slash")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .animation(.easeInOut(duration: 0.25), value: viewModel.pokemon)
            .animation(.easeInOut(duration: 0.25), value: viewModel.isLoadingExtras)
        }
        .navigationTitle(viewModel.pokemon.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadSprite()
        }
        .task {
            await viewModel.loadExtrasIfNeeded()
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            ZStack {
                if let sprite = viewModel.spriteImage {
                    Image(uiImage: sprite)
                        .resizable()
                        .scaledToFit()
                } else if viewModel.isLoadingSprite {
                    ProgressView()
                } else {
                    Image("PokemonPlaceholder")
                        .resizable()
                        .scaledToFit()
                        .opacity(0.6)
                }
            }
            .frame(width: 160, height: 160)

            Text(String(format: "#%03d", viewModel.pokemon.id))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                ForEach(viewModel.pokemon.types) { type in
                    TypeBadge(type: type)
                }
            }

            HStack(spacing: 24) {
                labeledValue("Altura", "\(Double(viewModel.pokemon.height) / 10) m")
                labeledValue("Peso", "\(Double(viewModel.pokemon.weight) / 10) kg")
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var descriptionSection: some View {
        if let flavorText = viewModel.pokemon.flavorText {
            Text(flavorText)
                .font(.body)
                .foregroundStyle(.secondary)
        } else if viewModel.isLoadingExtras {
            HStack(spacing: 8) {
                ProgressView()
                Text("Cargando descripción…")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func labeledValue(_ label: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.headline)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }

    private var statsSection: some View {
        sectionContainer(title: "Estadísticas base") {
            VStack(spacing: 8) {
                ForEach(viewModel.pokemon.stats) { stat in
                    HStack {
                        Text(stat.displayName)
                            .frame(width: 110, alignment: .leading)
                            .font(.caption)
                        ProgressView(value: Double(stat.baseValue), total: 200)
                        Text("\(stat.baseValue)")
                            .font(.caption.monospacedDigit())
                            .frame(width: 30, alignment: .trailing)
                    }
                }
            }
        }
    }

    private var abilitiesSection: some View {
        sectionContainer(title: "Habilidades") {
            FlowText(items: viewModel.pokemon.abilities.map {
                $0.isHidden ? "\($0.displayName) (oculta)" : $0.displayName
            })
        }
    }

    private var movesSection: some View {
        sectionContainer(title: "Ataques") {
            FlowText(items: viewModel.pokemon.moves.prefix(15).map(\.displayName))
        }
    }

    @ViewBuilder
    private var evolutionSection: some View {
        if viewModel.isLoadingExtras {
            sectionContainer(title: "Evoluciones") {
                ProgressView()
            }
        } else if let chain = viewModel.pokemon.evolutionChain, !chain.isEmpty {
            sectionContainer(title: "Evoluciones") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(chain) { stage in
                            PokemonEvolutionCardView(
                                stage: stage,
                                isCurrent: stage.id == viewModel.pokemon.id,
                                repository: repository,
                                coordinator: coordinator
                            )
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private func sectionContainer<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.title3.weight(.semibold))
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct FlowText: View {
    let items: [String]

    var body: some View {
        Text(items.joined(separator: " · "))
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }
}
