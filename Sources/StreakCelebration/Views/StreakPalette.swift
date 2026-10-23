import SwiftUI

/// Colours for the celebration. It always plays on a dark, warm stage so the gold reads like metal.
struct StreakPalette {
    var background: Color
    var dotGrid: Color
    var ink: Color
    var secondaryInk: Color
    var tertiaryInk: Color
    var track: Color

    /// Light to deep gold, for the week dots.
    var gold: [Color]
    var number: [Color]
    var dormantNumber: [Color]
    var glow: Color

    /// The token's satin black face, top-left to bottom-right.
    var metal: [Color]
    /// The token's edge, left to right.
    var edge: [Color]
    /// Lettering stamped into the black metal.
    var engraving: Color
    /// The inlaid numeral, top to bottom, unlit and lit.
    var inlayDull: [RGB]
    var inlayLit: [RGB]
    /// Gold leaf: two tones, then the glint of a flake caught face-on.
    var flakes: [Color]

    static let night = StreakPalette(
        background: Color(hex: 0x0D0C0B),
        dotGrid: Color(hex: 0xF7F3EC).opacity(0.09),
        ink: Color(hex: 0xF7F3EC),
        secondaryInk: Color(hex: 0xF7F3EC).opacity(0.6),
        tertiaryInk: Color(hex: 0xF7F3EC).opacity(0.3),
        track: Color(hex: 0xF7F3EC).opacity(0.09),
        gold: [Color(hex: 0xFBE3A1), Color(hex: 0xF0B952), Color(hex: 0xC27F22)],
        number: [Color(hex: 0xFDE7AE), Color(hex: 0xE9A944)],
        dormantNumber: [Color(hex: 0x4A4743), Color(hex: 0x3A3734)],
        glow: Color(hex: 0xFFB547),
        metal: [Color(hex: 0x2C2B2E), Color(hex: 0x161618), Color(hex: 0x1F1E21)],
        edge: [Color(hex: 0x3A393D), Color(hex: 0x141416), Color(hex: 0x29282B)],
        engraving: Color(hex: 0x403F43),
        inlayDull: [RGB(hex: 0x8C6A3A), RGB(hex: 0x6E4E24), RGB(hex: 0x4E3416)],
        inlayLit: [RGB(hex: 0xFFEAA8), RGB(hex: 0xF2B544), RGB(hex: 0xB06E1E)],
        flakes: [Color(hex: 0xD9A441), Color(hex: 0xB8822E), Color(hex: 0xFFE7A3)]
    )

    /// The numeral's gradient at a given brightness: 0 dull bronze, 1 lit gold, past 1 flaring towards white.
    func inlay(brightness: Double) -> [Color] {
        let white = RGB(hex: 0xFFFFFF)
        return zip(inlayDull, inlayLit).map { dull, lit in
            if brightness <= 1 {
                return dull.mixed(with: lit, by: max(brightness, 0)).color
            }
            return lit.mixed(with: white, by: min(brightness - 1, 1) * 0.6).color
        }
    }
}

/// A plain sRGB triple that can be interpolated, unlike `Color`.
struct RGB {
    var red: Double
    var green: Double
    var blue: Double

    init(hex: UInt32) {
        red = Double((hex >> 16) & 0xFF) / 255
        green = Double((hex >> 8) & 0xFF) / 255
        blue = Double(hex & 0xFF) / 255
    }

    private init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    func mixed(with other: RGB, by amount: Double) -> RGB {
        RGB(
            red: red + (other.red - red) * amount,
            green: green + (other.green - green) * amount,
            blue: blue + (other.blue - blue) * amount
        )
    }

    var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue)
    }
}

extension Color {
    init(hex: UInt32) {
        self = RGB(hex: hex).color
    }
}
