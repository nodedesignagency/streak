import Foundation

/// Fixed geometry of the hero canvas, in points.
enum HeroMetrics {
    static let canvasSize = 280.0
    static var center: Double { canvasSize / 2 }

    static let ringDiameter = 232.0
    static let ringWidth = 6.0

    static let medallionDiameter = 156.0
    /// Width of the flame engraved on the medallion's face.
    static let glyphWidth = 54.0

    /// Particles are drawn on a larger canvas so dust can drift past the ring.
    static let particleCanvasSize = 420.0
}
