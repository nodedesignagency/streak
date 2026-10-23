import Foundation

/// Everything the hero needs to draw one frame of the celebration.
struct CelebrationFrame: Equatable, Sendable {
    /// Degrees around the vertical axis. 0 faces the viewer; the spin ends two full turns later.
    var tokenYaw: Double
    /// Points above the resting position.
    var tokenLift: Double
    var tokenScale: Double
    /// Brightness of the gold inlay: dull before the spin, flashing past 1 as the token lands, then 1.
    var inlayGlow: Double
    /// Warm light behind the hero.
    var glow: Double
    /// Gold leaf falling across the screen.
    var flakesOpacity: Double

    /// The token has turned its back since the spin began, so its front may now carry the new count.
    var showsNewCount: Bool { tokenYaw >= CelebrationTimeline.swapAngle }
}

/// The whole celebration as pure functions of elapsed time, so it can be scrubbed, replayed, skipped and tested.
enum CelebrationTimeline {
    // MARK: Beats (seconds since the screen started playing)

    /// The token winds up, turning back a little.
    static let anticipate = 0.20
    /// It flicks into two full turns, rising as it goes.
    static let spin = 0.40
    /// The front comes round carrying the new count, and the counter rolls.
    static let reveal = 1.00
    /// It settles facing the viewer: the gold lights up and gold leaf flies.
    static let land = 1.55
    static let details = 2.10
    static let week = 2.45
    static let actions = 3.40

    /// A moment after everything has settled; used for Reduce Motion and for skipping ahead.
    static let restingTime = 4.3

    /// Yaw at which the count on the front changes. The token is edge-on here and its back comes next.
    static let swapAngle = 450.0
    static let restingYaw = 720.0
    static let dotStagger = 0.07

    // MARK: Tracks

    private static let yaw = Track(0)
        .to(-18, at: anticipate, over: spin - anticipate, .easeOut)
        .to(restingYaw + 8, at: spin, over: land - spin, .easeOut)
        .to(restingYaw, at: land, over: 0.5, .spring(damping: 0.5))
    private static let lift = Track(0)
        .to(-4, at: anticipate, over: spin - anticipate, .easeOut)
        .to(14, at: spin, over: 0.6, .easeOut)
        .to(0, at: 1.40, over: 0.6, .spring(damping: 0.55))
    private static let scale = Track(1)
        .to(0.96, at: anticipate, over: spin - anticipate, .easeOut)
        .to(1.06, at: spin, over: 0.6, .easeOut)
        .to(1, at: 1.40, over: 0.6, .spring(damping: 0.5))
    private static let inlayGlow = Track(0.35)
        .to(1.35, at: land - 0.05, over: 0.15, .easeOut)
        .to(1, at: land + 0.1, over: 0.6, .easeOut)
    private static let glow = Track(0.2)
        .to(1, at: land - 0.1, over: 0.6, .easeOut)
    private static let flakes = Track(0)
        .to(1, at: land - 0.05, over: 0.3, .easeOut)
    private static let idle = Track(0)
        .to(1, at: land + 0.5, over: 1.0, .easeInOut)

    // MARK: Evaluation

    /// - Parameters:
    ///   - time: Seconds since the screen started playing.
    ///   - idleMotion: Whether the settled token keeps swaying and floating. Off for Reduce Motion.
    static func frame(at time: Double, idleMotion: Bool = true) -> CelebrationFrame {
        let idleAmount = idleMotion ? idle.value(at: time) : 0
        // A slow sway so the light keeps catching the gold.
        let sway = sin((time - land) * 2 * .pi * 0.16) * 14 * idleAmount
        let bob = sin(time * 2 * .pi * 0.35) * 3 * idleAmount

        return CelebrationFrame(
            tokenYaw: yaw.value(at: time) + sway,
            tokenLift: lift.value(at: time) + bob,
            tokenScale: scale.value(at: time),
            inlayGlow: inlayGlow.value(at: time),
            glow: glow.value(at: time),
            flakesOpacity: flakes.value(at: time)
        )
    }

    /// How far a week dot has popped in: 0 before it starts, springing past 1 and settling on 1.
    static func dotAppearance(index: Int, at time: Double) -> Double {
        Curve.spring(damping: 0.5).apply((time - dotStart(index: index)) / 0.5)
    }

    /// Progress (0...1) of the ring that pulses out of today's dot once it has popped in.
    static func todayPulse(index: Int, at time: Double) -> Double {
        let start = dotStart(index: index) + 0.2
        guard time >= start else { return 0 }
        return min(1, (time - start) / 0.7)
    }

    private static func dotStart(index: Int) -> Double {
        week + 0.12 + Double(index) * dotStagger
    }
}
