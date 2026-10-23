import SwiftUI

/// Lettering set along a circle, like the inscription round the rim of a coin.
struct ArcText: View {
    var text: String
    /// Distance from the centre to the middle of the letters.
    var radius: Double
    var placement: ArcLayout.Placement
    var font: Font
    var degreesPerCharacter: Double

    var body: some View {
        let characters = Array(text)
        let positions = ArcLayout.positions(for: text, placement: placement, degreesPerCharacter: degreesPerCharacter)
        ZStack {
            ForEach(characters.indices, id: \.self) { index in
                // Push the letter out to the rim, then swing it round the centre into place.
                Text(String(characters[index]))
                    .font(font)
                    .offset(y: placement == .top ? -radius : radius)
                    .rotationEffect(.degrees(positions[index].rotation))
            }
        }
    }
}
