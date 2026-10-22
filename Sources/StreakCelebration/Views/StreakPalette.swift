import SwiftUI

/// Colours for the celebration. It always plays on a dark, warm stage so the gold reads like metal.
struct StreakPalette {
    var background: Color
    var dotGrid: Color
    var ink: Color
    var secondaryInk: Color
    var tertiaryInk: Color
    var track: Color

    /// Light to deep, top to bottom of the gold face.
    var gold: [Color]
    var goldHighlight: Color
    var goldDeep: Color
    var graphite: [Color]
    var graphiteDeep: Color

    var number: [Color]
    var dormantNumber: [Color]
    var glow: Color
    var particles: [Color]

    static let night = StreakPalette(
        background: Color(hex: 0x0D0C0B),
        dotGrid: Color(hex: 0xF7F3EC).opacity(0.09),
        ink: Color(hex: 0xF7F3EC),
        secondaryInk: Color(hex: 0xF7F3EC).opacity(0.6),
        tertiaryInk: Color(hex: 0xF7F3EC).opacity(0.3),
        track: Color(hex: 0xF7F3EC).opacity(0.09),
        gold: [Color(hex: 0xFBE3A1), Color(hex: 0xF0B952), Color(hex: 0xC27F22)],
        goldHighlight: Color(hex: 0xFFF3D1),
        goldDeep: Color(hex: 0x9A6216),
        graphite: [Color(hex: 0x46423E), Color(hex: 0x312E2B), Color(hex: 0x211F1D)],
        graphiteDeep: Color(hex: 0x181715),
        number: [Color(hex: 0xFDE7AE), Color(hex: 0xE9A944)],
        dormantNumber: [Color(hex: 0x4A4743), Color(hex: 0x3A3734)],
        glow: Color(hex: 0xFFB547),
        particles: [Color(hex: 0xFFE6A6), Color(hex: 0xF4C25E), Color(hex: 0xFFFFFF)]
    )
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
