import Foundation

/// Fixed geometry of the hero canvas, in points. The timeline and the view both read from here so the
/// orb's launch height and the burst centre can never drift apart.
enum HeroMetrics {
    static let canvasWidth = 260.0
    static let canvasHeight = 230.0
    /// Where the bottom of the flame sits, measured from the top of the canvas.
    static let baseline = 200.0

    static let flameWidth = 112.0
    static let flameHeight = 124.0

    static let orbDiameter = 70.0
    /// How far the orb jumps when it launches off the ground.
    static let orbLift = 38.0
    /// How much the orb swells (from its bottom edge) right before it bursts.
    static let orbSwell = 1.5

    static let seedWidth = 30.0
    static let seedHeight = 42.0

    static var midX: Double { canvasWidth / 2 }
    static var flameTop: Double { baseline - flameHeight }
    /// Centre of the swollen orb at the instant it bursts: the origin of the flash, ring and sparks.
    static var burstY: Double { baseline - orbLift - orbDiameter * orbSwell / 2 }
    /// Embers leave from just inside the flame's tips.
    static var emberY: Double { flameTop + 26 }
}
