import Foundation

/// Fixed geometry of the hero canvas, in points.
enum HeroMetrics {
    /// Room for the coin at its largest mid-spin, lifted.
    static let canvasSize = 264.0

    /// The coin is round, so its width and height are both its diameter.
    static let tokenWidth = 216.0
    static let tokenHeight = 216.0
    static let tokenThickness = 18.0
}
