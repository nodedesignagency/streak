import Foundation

/// How the light falls on the badge at a given turn.
///
/// The light sits a little to the left of the viewer. Turned towards it, the chrome flashes white and the
/// enamel brightens; turned the other way, both fall into shade. As the badge sways it moves between these,
/// the way polished metal and glossy enamel do.
struct TokenLight: Equatable, Sendable {
    /// 1 facing the light, falling to 0 as the face turns away; drives the hot spot.
    let facing: Double
    /// How far the chrome is pushed towards white (0...0.8).
    let glint: Double
    /// How far it falls into shade (0...0.5).
    let shade: Double

    /// - Parameter yaw: Degrees around the vertical axis. 0 shows the front.
    init(yaw: Double) {
        func towards(_ degrees: Double) -> Double {
            max(0, cos((yaw - degrees) * .pi / 180))
        }
        facing = pow(towards(25), 2)
        glint = pow(towards(25), 6) * 0.8
        shade = pow(towards(-30), 4) * 0.5
    }
}

/// How the badge's enamel looks at a given moment: muted while it spins, flaring as it lands, then its own
/// colours, brightening a touch as it sways towards the light and darkening as it sways away.
struct BadgeFinish: Equatable, Sendable {
    /// 1 shows the artwork's own colours; lower mutes them.
    let saturation: Double
    /// Added to the artwork's brightness: below 0 darkens, above 0 brightens.
    let brightness: Double

    /// - Parameter ignition: 0 dull, 1 polished, past 1 flaring (see `CelebrationFrame.ignition`).
    init(ignition: Double, light: TokenLight) {
        let polish = min(max(ignition, 0), 1)
        let flare = min(max(ignition - 1, 0), 1)
        saturation = 0.5 + 0.5 * polish
        // Face-on, the glint and the shade cancel out, so the settled badge shows the artwork as drawn.
        let sway = 0.08 * light.glint - 0.12 * light.shade
        brightness = -0.13 * (1 - polish) + 0.25 * flare + sway * polish
    }
}
