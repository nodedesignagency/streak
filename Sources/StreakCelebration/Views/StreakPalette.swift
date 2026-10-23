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
    var glow: Color
    /// Gold leaf: two tones, then the glint of a flake caught face-on.
    var flakes: [Color]

    // The coin. Face lists run top-left to bottom-right, edge lists left to right.
    var faceLit: [RGB]
    var faceDull: [RGB]
    /// The olive cast brushed gold takes on when it turns away from the light.
    var faceAway: [RGB]
    var edgeLit: [RGB]
    var edgeDull: [RGB]
    var edgeAway: [RGB]
    /// Catch-light and shadow that make the raised rim, lettering and flame stand off the face.
    var reliefLight: Color
    var reliefShadow: Color

    static let night = StreakPalette(
        background: Color(hex: 0x0D0C0B),
        dotGrid: Color(hex: 0xF7F3EC).opacity(0.09),
        ink: Color(hex: 0xF7F3EC),
        secondaryInk: Color(hex: 0xF7F3EC).opacity(0.6),
        tertiaryInk: Color(hex: 0xF7F3EC).opacity(0.3),
        track: Color(hex: 0xF7F3EC).opacity(0.09),
        gold: [Color(hex: 0xFBE3A1), Color(hex: 0xF0B952), Color(hex: 0xC27F22)],
        glow: Color(hex: 0xFFB547),
        flakes: [Color(hex: 0xD9A441), Color(hex: 0xB8822E), Color(hex: 0xFFE7A3)],
        faceLit: [RGB(hex: 0xF6D48A), RGB(hex: 0xD9A548), RGB(hex: 0xA8742A)],
        faceDull: [RGB(hex: 0xA08A55), RGB(hex: 0x7E6838), RGB(hex: 0x594622)],
        faceAway: [RGB(hex: 0xB8A566), RGB(hex: 0x8D7A3C), RGB(hex: 0x625024)],
        edgeLit: [RGB(hex: 0xD1A048), RGB(hex: 0x7A5218), RGB(hex: 0xAD7F30)],
        edgeDull: [RGB(hex: 0x6E5A30), RGB(hex: 0x3E3118), RGB(hex: 0x574626)],
        edgeAway: [RGB(hex: 0x8F7E45), RGB(hex: 0x4E4220), RGB(hex: 0x6E5E30)],
        reliefLight: Color(hex: 0xFFF0C2),
        reliefShadow: Color(hex: 0x5E3E0E)
    )

    /// - Parameters:
    ///   - ignition: 0 tarnished, 1 polished, past 1 flaring towards white gold.
    ///   - light: 1 facing the light, 0 turned away from it.
    func face(ignition: Double, light: Double) -> [Color] {
        shade(dull: faceDull, lit: faceLit, away: faceAway, ignition: ignition, light: light)
    }

    func edge(ignition: Double, light: Double) -> [Color] {
        shade(dull: edgeDull, lit: edgeLit, away: edgeAway, ignition: ignition, light: light)
    }

    private func shade(dull: [RGB], lit: [RGB], away: [RGB], ignition: Double, light: Double) -> [Color] {
        let flare = RGB(hex: 0xFFF4D0)
        return (0..<lit.count).map { index in
            let base = ignition <= 1
                ? dull[index].mixed(with: lit[index], by: max(ignition, 0))
                : lit[index].mixed(with: flare, by: min(ignition - 1, 1) * 0.6)
            return base.mixed(with: away[index], by: (1 - min(max(light, 0), 1)) * 0.45).color
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
