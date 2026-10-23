import Foundation

/// Fixed geometry of the hero canvas, in points.
enum HeroMetrics {
    static let canvasSize = 280.0

    static let tokenWidth = 132.0
    static let tokenHeight = 204.0
    static let tokenThickness = 16.0

    /// Gold leaf thrown off the token is drawn on a larger canvas so it can fly past the hero.
    static let particleCanvasSize = 440.0
}
