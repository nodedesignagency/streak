import Foundation

/// Fixed geometry of the hero canvas, in points.
enum HeroMetrics {
    /// Room for the badge at its own size, with a margin round it. It rises in larger than this, from below.
    static let canvasSize = 264.0

    /// The badge artwork's bounding box, in its own proportions (`Resources/Badge.xcassets`).
    static let tokenWidth = 208.0
    static let tokenHeight = 228.0
    static let tokenThickness = 16.0

    /// Roughly the corner radius of a modern iPhone's screen, for the glow round its edges.
    static let screenCornerRadius = 54.0
}
