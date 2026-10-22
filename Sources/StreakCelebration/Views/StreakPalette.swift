import SwiftUI

/// Colours for the celebration, tuned separately for light and dark appearance.
struct StreakPalette {
    var background: Color
    var ink: Color
    var secondaryInk: Color
    var track: Color

    var flame: [Color]
    var flameCore: [Color]
    var dormant: [Color]
    var dormantCore: Color

    var number: [Color]
    var dormantNumber: [Color]
    var accent: Color
    var glow: Color
    var particles: [Color]

    /// Orb colour stops for heat 0 (ash), 1 (ember) and 2 (gold).
    var orbStops: [RGB]

    static func standard(for scheme: ColorScheme) -> StreakPalette {
        let isDark = scheme == .dark
        return StreakPalette(
            background: isDark ? Color(hex: 0x121214) : Color(hex: 0xFFFDF8),
            ink: isDark ? .white : Color(hex: 0x1F1F24),
            secondaryInk: isDark ? Color(hex: 0x9A9AA3) : Color(hex: 0x86868F),
            track: isDark ? Color(hex: 0x2A2A30) : Color(hex: 0xEEEEF2),
            flame: [Color(hex: 0xFFE36E), Color(hex: 0xFFC727), Color(hex: 0xFFA412)],
            flameCore: [Color(hex: 0xFFFDF0), Color(hex: 0xFFF1B8)],
            dormant: isDark
                ? [Color(hex: 0x4A4B52), Color(hex: 0x3A3B41)]
                : [Color(hex: 0xDDDFE4), Color(hex: 0xCDD0D6)],
            dormantCore: isDark ? Color(hex: 0x5E6068) : Color(hex: 0xF4F5F7),
            number: [Color(hex: 0xFFB21E), Color(hex: 0xFF8A00)],
            dormantNumber: isDark
                ? [Color(hex: 0x55565D), Color(hex: 0x46474D)]
                : [Color(hex: 0xD9DBE0), Color(hex: 0xC9CCD2)],
            accent: Color(hex: 0xFF9500),
            glow: Color(hex: 0xFFC83D).opacity(isDark ? 0.55 : 1),
            particles: [Color(hex: 0xFFC400), Color(hex: 0xFF9F0A), Color(hex: 0xFFE15A)],
            orbStops: [
                isDark ? RGB(hex: 0x4A4B52) : RGB(hex: 0xCDD0D6),
                RGB(hex: 0xFF9F0A),
                RGB(hex: 0xFFC727),
            ]
        )
    }

    func orbColor(heat: Double) -> Color {
        let clamped = min(max(heat, 0), Double(orbStops.count - 1))
        let lower = Int(clamped.rounded(.down))
        let upper = min(lower + 1, orbStops.count - 1)
        return orbStops[lower].mixed(with: orbStops[upper], by: clamped - Double(lower)).color
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
