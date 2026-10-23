import Foundation

/// How a coin-like token spun about its vertical axis lands on screen, viewed head-on.
///
/// Drawing it this way, rather than with stacked 3D layers, keeps the depth order trivially right: the edge
/// is always underneath, and only the face turned towards the viewer is ever drawn.
struct TokenProjection: Equatable, Sendable {
    /// Horizontal scale of the visible face: 0 edge-on, 1 face-on.
    let faceScale: Double
    /// Horizontal shift of the visible face, because it sits half the token's thickness in front of the axis.
    let faceOffset: Double
    /// How far the silhouette is stretched out on each side by the token's edge.
    let extrude: Double
    let showsFront: Bool
    /// 0 face-on, 1 edge-on: how much the edge faces the viewer, for lighting it.
    let edgeExposure: Double

    /// - Parameters:
    ///   - yaw: Degrees around the vertical axis. 0 shows the front.
    ///   - thickness: Depth of the token, in points.
    init(yaw: Double, thickness: Double) {
        let angle = yaw * .pi / 180
        let cosine = cos(angle)
        let sine = sin(angle)
        showsFront = cosine >= 0
        faceScale = abs(cosine)
        faceOffset = (showsFront ? 1 : -1) * thickness / 2 * sine
        extrude = thickness / 2 * abs(sine)
        edgeExposure = abs(sine)
    }
}
