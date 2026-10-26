import Foundation

/// Fixed geometry of the hero canvas, in points.
enum HeroMetrics {
    /// Room for the badge, with a margin round it.
    static let canvasSize = 264.0

    /// The badge artwork's bounding box, in its own proportions (`Resources/Badge.xcassets`).
    static let tokenWidth = 208.0
    static let tokenHeight = 228.0
    static let tokenThickness = 16.0
}
