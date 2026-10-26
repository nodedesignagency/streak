import Foundation

/// How the light falls on the badge at a given turn.
///
/// The light sits a little to the left of the viewer. Turned towards it, the hot spot brightens and the
/// chrome edge flashes white; turned away, both fade. As the badge sways it moves between these, the way
/// polished metal and glossy enamel do.
struct TokenLight: Equatable, Sendable {
    /// 1 facing the light, falling to 0 as the face turns away; drives the hot spot.
    let facing: Double
    /// How far the chrome is pushed towards white (0...0.8).
    let glint: Double

    /// - Parameter yaw: Degrees around the vertical axis. 0 shows the front.
    init(yaw: Double) {
        func towards(_ degrees: Double) -> Double {
            max(0, cos((yaw - degrees) * .pi / 180))
        }
        facing = pow(towards(25), 2)
        glint = pow(towards(25), 6) * 0.8
    }
}
