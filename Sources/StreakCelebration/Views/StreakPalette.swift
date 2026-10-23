import SwiftUI

/// Colours for the celebration. It always plays on a dark, warm stage so the fire reads as light.
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
    /// Embers thrown off the token as it ignites, likewise.
    var embers: [Color]

    // The flame token, cold and lit. Each list runs from the tips at the top to the base.
    var ashBody: [RGB]
    var fireBody: [RGB]
    /// The hottest part of the flame, glowing up from the base.
    var core: Color
    var ashEdge: [RGB]
    var fireEdge: [RGB]
    var ashNumeral: [RGB]
    var fireNumeral: [RGB]
    var ashStamp: RGB
    var fireStamp: RGB

    static let night = StreakPalette(
        background: Color(hex: 0x0D0C0B),
        dotGrid: Color(hex: 0xF7F3EC).opacity(0.09),
        ink: Color(hex: 0xF7F3EC),
        secondaryInk: Color(hex: 0xF7F3EC).opacity(0.6),
        tertiaryInk: Color(hex: 0xF7F3EC).opacity(0.3),
        track: Color(hex: 0xF7F3EC).opacity(0.09),
        gold: [Color(hex: 0xFBE3A1), Color(hex: 0xF0B952), Color(hex: 0xC27F22)],
        glow: Color(hex: 0xFF8A2A),
        flakes: [Color(hex: 0xD9A441), Color(hex: 0xB8822E), Color(hex: 0xFFE7A3)],
        embers: [Color(hex: 0xFF9A2E), Color(hex: 0xF2541C), Color(hex: 0xFFE07A)],
        ashBody: [RGB(hex: 0x45413D), RGB(hex: 0x34312E), RGB(hex: 0x24221F)],
        fireBody: [RGB(hex: 0xF0441C), RGB(hex: 0xFF7A1A), RGB(hex: 0xFFB627)],
        core: Color(hex: 0xFFE07A),
        ashEdge: [RGB(hex: 0x2E2C2A), RGB(hex: 0x181716), RGB(hex: 0x242220)],
        fireEdge: [RGB(hex: 0xB8380F), RGB(hex: 0x6E1C06), RGB(hex: 0x932C0B)],
        ashNumeral: [RGB(hex: 0x6A6560), RGB(hex: 0x55514C)],
        fireNumeral: [RGB(hex: 0xFFFDF4), RGB(hex: 0xFFE9B8)],
        ashStamp: RGB(hex: 0x5A5652),
        fireStamp: RGB(hex: 0x8A2A0E)
    )

    func body(ignition: Double) -> [Color] {
        blend(ashBody, fireBody, ignition: ignition, flareTo: RGB(hex: 0xFFE9A0))
    }

    func edge(ignition: Double) -> [Color] {
        blend(ashEdge, fireEdge, ignition: ignition, flareTo: RGB(hex: 0xFF7A1A))
    }

    func numeral(ignition: Double) -> [Color] {
        blend(ashNumeral, fireNumeral, ignition: ignition, flareTo: RGB(hex: 0xFFFFFF))
    }

    func stamp(ignition: Double) -> Color {
        ashStamp.mixed(with: fireStamp, by: min(max(ignition, 0), 1)).color
    }

    /// Ash at 0, lit at 1; past 1 the flare pushes the colours towards `flareTo`.
    private func blend(_ cold: [RGB], _ lit: [RGB], ignition: Double, flareTo flare: RGB) -> [Color] {
        zip(cold, lit).map { ash, fire in
            if ignition <= 1 {
                return ash.mixed(with: fire, by: max(ignition, 0)).color
            }
            return fire.mixed(with: flare, by: min(ignition - 1, 1) * 0.6).color
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
