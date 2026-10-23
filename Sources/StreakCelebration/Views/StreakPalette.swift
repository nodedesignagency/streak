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
    var faceDull: [RGB]
    var facePolished: [RGB]
    /// The pale cast satin gold takes on when it turns towards the light.
    var faceChampagne: [RGB]
    /// The warm cast it takes on when it turns the other way.
    var facePeach: [RGB]
    var edgeDull: [RGB]
    var edgePolished: [RGB]
    var edgeChampagne: [RGB]
    /// Catch-light and shadow that make the rings, lettering and flame stand off the face.
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
        faceDull: [RGB(hex: 0xA08A55), RGB(hex: 0x7E6838), RGB(hex: 0x594622)],
        facePolished: [RGB(hex: 0xEBC766), RGB(hex: 0xD1A443), RGB(hex: 0xA97E2E)],
        faceChampagne: [RGB(hex: 0xF6EAB8), RGB(hex: 0xE4CE8A), RGB(hex: 0xC4A862)],
        facePeach: [RGB(hex: 0xF3C28C), RGB(hex: 0xDE9D62), RGB(hex: 0xB5763F)],
        edgeDull: [RGB(hex: 0x6E5A30), RGB(hex: 0x3E3118), RGB(hex: 0x574626)],
        edgePolished: [RGB(hex: 0xDDBB6E), RGB(hex: 0x86652A), RGB(hex: 0xB89048)],
        edgeChampagne: [RGB(hex: 0xF1E4B8), RGB(hex: 0xB59C5E), RGB(hex: 0xDCC688)],
        reliefLight: Color(hex: 0xFFF4D2),
        reliefShadow: Color(hex: 0x6A4812)
    )

    /// - Parameter ignition: 0 tarnished, 1 polished, past 1 flaring towards white gold.
    func face(ignition: Double, light: CoinLight) -> [Color] {
        let lit = (0..<facePolished.count).map { index in
            facePolished[index]
                .mixed(with: faceChampagne[index], by: light.champagne)
                .mixed(with: facePeach[index], by: light.peach)
        }
        return shade(dull: faceDull, lit: lit, ignition: ignition)
    }

    func edge(ignition: Double, light: CoinLight) -> [Color] {
        let lit = (0..<edgePolished.count).map { index in
            edgePolished[index].mixed(with: edgeChampagne[index], by: light.champagne)
        }
        return shade(dull: edgeDull, lit: lit, ignition: ignition)
    }

    private func shade(dull: [RGB], lit: [RGB], ignition: Double) -> [Color] {
        let flare = RGB(hex: 0xFFF6DA)
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
