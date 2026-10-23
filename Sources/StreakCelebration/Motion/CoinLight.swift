import Foundation

/// How the light falls on the coin's satin gold at a given turn.
///
/// The light sits a little to the left of the viewer. Turned towards it, the gold goes pale champagne;
/// turned the other way, it warms to peach; face-on it is rich gold. As the coin sways it moves between
/// these, the way polished metal does.
struct CoinLight: Equatable, Sendable {
    /// 1 facing the light, falling to 0 as the face turns away; drives the hot spot.
    let facing: Double
    /// How far the gold is pushed towards champagne (0...0.8).
    let champagne: Double
    /// How far the gold is pushed towards peach (0...0.5).
    let peach: Double

    /// - Parameter yaw: Degrees around the vertical axis. 0 shows the front.
    init(yaw: Double) {
        func towards(_ degrees: Double) -> Double {
            max(0, cos((yaw - degrees) * .pi / 180))
        }
        facing = pow(towards(25), 2)
        champagne = pow(towards(25), 6) * 0.8
        peach = pow(towards(-30), 4) * 0.5
    }
}
