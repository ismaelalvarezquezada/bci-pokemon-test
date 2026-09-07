import SwiftUI

@main
struct BCITestApp: App {
    private let repository: PokemonRepositoryProviding = PokemonRepository(
        api: PokemonAPIService(),
        store: UserDefaultsPokemonStore(),
        imageCache: ImageDiskCache()
    )

    var body: some Scene {
        WindowGroup {
            PokedexRootView(repository: repository)
        }
    }
}
