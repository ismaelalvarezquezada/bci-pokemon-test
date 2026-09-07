import SwiftUI

struct PokemonTypeFilterChip: View {
    let title: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? color : color.opacity(0.15), in: Capsule())
                .foregroundStyle(isSelected ? .white : color)
                .overlay {
                    Capsule().strokeBorder(color, lineWidth: isSelected ? 0 : 1)
                }
        }
        .buttonStyle(.plain)
    }
}
