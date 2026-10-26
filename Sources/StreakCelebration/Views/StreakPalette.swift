import SwiftUI

/// Colours for the celebration: a charcoal stage that warms into gold towards the bottom, as in the
/// reference, with the badge's chrome on top. The badge's enamel comes from its artwork.
struct StreakPalette {
    var background: Color
    var ink: Color
    var secondaryInk: Color
    var tertiaryInk: Color
    /// The warm wash rising from the bottom of the screen: deep amber, orange gold, bright gold.
    var warmth: [Color]
    /// The share button, sitting dark on the gold.
    var button: Color

    // The badge's chrome, matched to the artwork's silver frame. Plate lists (the back) run top-left to
    // bottom-right, edge lists left to right.
    var plateDull: [RGB]
    var platePolished: [RGB]
    /// The white flash chrome takes on when it turns towards the light.
    var plateGlint: [RGB]
    /// The grey it falls to when it turns the other way.
    var plateShade: [RGB]
    var edgeDull: [RGB]
    var edgePolished: [RGB]
    var edgeGlint: [RGB]
    /// Catch-light and shadow that make the frame stand off the back and sink the engraving into it.
    var reliefLight: Color
    var reliefShadow: Color

    static let night = StreakPalette(
        background: Color(hex: 0x131313),
        ink: Color(hex: 0xFFFFFF),
        secondaryInk: Color(hex: 0xFFFFFF).opacity(0.72),
        tertiaryInk: Color(hex: 0xFFFFFF).opacity(0.45),
        warmth: [Color(hex: 0x5A3A0E), Color(hex: 0xE0982C), Color(hex: 0xFFC63F)],
        button: Color(hex: 0x161616),
        plateDull: [RGB(hex: 0x8D8F94), RGB(hex: 0x66686D), RGB(hex: 0x46484C)],
        platePolished: [RGB(hex: 0xF2F2F3), RGB(hex: 0xC3C5C9), RGB(hex: 0x8A8D93)],
        plateGlint: [RGB(hex: 0xFFFFFF), RGB(hex: 0xE6E7EA), RGB(hex: 0xB0B3B8)],
        plateShade: [RGB(hex: 0xCDCFD3), RGB(hex: 0x9A9DA2), RGB(hex: 0x65686E)],
        edgeDull: [RGB(hex: 0x6C6E72), RGB(hex: 0x303236), RGB(hex: 0x525458)],
        edgePolished: [RGB(hex: 0xDADCDF), RGB(hex: 0x6F7277), RGB(hex: 0xAAADB2)],
        edgeGlint: [RGB(hex: 0xF8F8F9), RGB(hex: 0xA0A3A8), RGB(hex: 0xD4D6D9)],
        reliefLight: Color(hex: 0xFFFFFF),
        reliefShadow: Color(hex: 0x2A2C30)
    )

    /// - Parameter ignition: 0 dull, 1 polished, past 1 flaring towards white.
    func plate(ignition: Double, light: TokenLight) -> [Color] {
        let lit = (0..<platePolished.count).map { index in
            platePolished[index]
                .mixed(with: plateGlint[index], by: light.glint)
                .mixed(with: plateShade[index], by: light.shade)
        }
        return shade(dull: plateDull, lit: lit, ignition: ignition)
    }

    func edge(ignition: Double, light: TokenLight) -> [Color] {
        let lit = (0..<edgePolished.count).map { index in
            edgePolished[index].mixed(with: edgeGlint[index], by: light.glint)
        }
        return shade(dull: edgeDull, lit: lit, ignition: ignition)
    }

    private func shade(dull: [RGB], lit: [RGB], ignition: Double) -> [Color] {
        let flare = RGB(hex: 0xFFFAF2)
        return (0..<lit.count).map { index in
            let polished = dull[index].mixed(with: lit[index], by: min(max(ignition, 0), 1))
            return polished.mixed(with: flare, by: min(max(ignition - 1, 0), 1) * 0.6).color
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
