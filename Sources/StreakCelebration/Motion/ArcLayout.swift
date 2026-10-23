import Foundation

/// Lays lettering out along a circle, the way text runs round the rim of a coin.
enum ArcLayout {
    enum Placement: Sendable {
        /// Across the top, reading left to right with the letters' tops pointing outwards.
        case top
        /// Across the bottom, reading left to right with the letters upright.
        case bottom
    }

    struct Position: Equatable, Sendable {
        /// Where the character's centre sits, in degrees clockwise from three o'clock (y grows downwards).
        var angle: Double
        /// How far to turn the character so it stands square to the circle.
        var rotation: Double
    }

    /// One position per character, centred on twelve o'clock (top) or six o'clock (bottom).
    /// - Parameter degreesPerCharacter: The arc an average capital takes up, spacing included.
    static func positions(for text: String, placement: Placement, degreesPerCharacter: Double) -> [Position] {
        let widths = text.map(relativeWidth)
        let total = widths.reduce(0, +)
        var used = 0.0
        return widths.map { width in
            let offset = (used + width / 2 - total / 2) * degreesPerCharacter
            used += width
            switch placement {
            case .top: return Position(angle: -90 + offset, rotation: offset)
            case .bottom: return Position(angle: 90 - offset, rotation: -offset)
            }
        }
    }

    /// Rough advance of a character relative to an average capital, so narrow ones don't leave gaps.
    static func relativeWidth(_ character: Character) -> Double {
        switch character {
        case " ", "•", "·", "I", "1", "J": 0.55
        case "M", "W": 1.3
        default: 1
        }
    }
}
