import SwiftUI
import UIKit

/// Fetches and displays a Pokemon sprite by id, falling back to a placeholder
/// artwork when there's no image data available (network failure, nothing cached).
struct PokemonSpriteView: View {
    let pokemonID: Int
    let repository: PokemonRepositoryProviding

    @State private var image: UIImage?
    @State private var isLoading = true

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else if isLoading {
                ProgressView()
            } else {
                Image("PokemonPlaceholder")
                    .resizable()
                    .scaledToFit()
                    .opacity(0.6)
            }
        }
        .task(id: pokemonID) {
            isLoading = true
            image = nil
            if let data = try? await repository.spriteData(forID: pokemonID) {
                image = UIImage(data: data)
            }
            isLoading = false
        }
    }
}
