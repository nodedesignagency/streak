import SwiftUI

/// Colours for the celebration: a charcoal stage with a gold-and-orange glow round the edges of the screen,
/// and the badge's chrome on top. The badge's enamel comes from its artwork.
struct StreakPalette {
    var background: Color
    var ink: Color
    var secondaryInk: Color
    var tertiaryInk: Color
    /// The glow round the edges of the screen, top to bottom: gold, then orange.
    var glow: [Color]
    /// The share button: a white pill with dark lettering.
    var button: Color
    var buttonInk: Color
    /// The close button's square: the grey a tenth of white makes on the charcoal, but solid, so the glow
    /// can't show through it.
    var closeButton: Color

    /// The badge's chrome edge, left to right, matched to the artwork's silver frame.
    var edgeChrome: [RGB]
    /// The white flash the edge takes on when it turns towards the light.
    var edgeGlint: [RGB]
    /// The pale highlight on the edge as it turns towards us.
    var reliefLight: Color

    static let night = StreakPalette(
        background: Color(hex: 0x131313),
        ink: Color(hex: 0xFFFFFF),
        secondaryInk: Color(hex: 0xFFFFFF).opacity(0.72),
        tertiaryInk: Color(hex: 0xFFFFFF).opacity(0.45),
        glow: [Color(hex: 0xFFC63F), Color(hex: 0xFF7A1A)],
        button: Color(hex: 0xFFFFFF),
        buttonInk: Color(hex: 0x131313),
        closeButton: Color(hex: 0x2B2B2B),
        edgeChrome: [RGB(hex: 0xDADCDF), RGB(hex: 0x6F7277), RGB(hex: 0xAAADB2)],
        edgeGlint: [RGB(hex: 0xF8F8F9), RGB(hex: 0xA0A3A8), RGB(hex: 0xD4D6D9)],
        reliefLight: Color(hex: 0xFFFFFF)
    )

    func edge(light: TokenLight) -> [Color] {
        (0..<edgeChrome.count).map { index in
            edgeChrome[index].mixed(with: edgeGlint[index], by: light.glint).color
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
