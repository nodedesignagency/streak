import Foundation

/// Fixed geometry of the hero canvas, in points.
enum HeroMetrics {
    static let canvasSize = 280.0

    /// The coin is round, so its width and height are both its diameter.
    static let tokenWidth = 196.0
    static let tokenHeight = 196.0
    static let tokenThickness = 18.0

    /// Gold leaf thrown off the coin is drawn on a larger canvas so it can fly past the hero.
    static let particleCanvasSize = 440.0
}
