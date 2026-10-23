import Foundation

/// Fixed geometry of the hero canvas, in points.
enum HeroMetrics {
    static let canvasSize = 280.0

    static let tokenWidth = 160.0
    static let tokenHeight = 210.0
    static let tokenThickness = 18.0

    /// Embers thrown off the token are drawn on a larger canvas so they can fly past the hero.
    static let particleCanvasSize = 440.0
}
