import Foundation

/// Everything the hero needs to draw one frame of the celebration.
struct CelebrationFrame: Equatable, Sendable {
    /// Degrees around the vertical axis. 0 faces the viewer; the spin ends two full turns later, and it
    /// keeps turning a full circle every few seconds after that.
    var tokenYaw: Double
    /// Points above the resting position.
    var tokenLift: Double
    var tokenScale: Double
}

/// The whole celebration as pure functions of elapsed time, so it can be scrubbed, replayed, skipped and tested.
enum CelebrationTimeline {
    // MARK: Beats (seconds since the screen started playing)

    /// The badge winds up, turning back a little.
    static let anticipate = 0.20
    /// It flicks into two full turns, rising as it goes.
    static let spin = 0.40
    /// It settles facing the viewer; the gold at the bottom of the screen warms up.
    static let land = 1.55
    /// The date, title and description arrive.
    static let details = 1.85
    /// The share button arrives.
    static let actions = 2.60

    /// A moment after everything has settled; used for Reduce Motion and for skipping ahead.
    static let restingTime = 4.3

    static let restingYaw = 720.0

    /// Once settled, the badge turns another full circle every few seconds, like a trophy on a turntable.
    static let idleSpinStart = land + 4.0
    static let idleSpinInterval = 6.0
    static let idleSpinDuration = 1.4

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
    private static let idle = Track(0)
        .to(1, at: land + 0.5, over: 1.0, .easeInOut)

    // MARK: Evaluation

    /// - Parameters:
    ///   - time: Seconds since the screen started playing.
    ///   - idleMotion: Whether the settled badge keeps swaying, floating and turning. Off for Reduce Motion.
    static func frame(at time: Double, idleMotion: Bool = true) -> CelebrationFrame {
        let idleAmount = idleMotion ? idle.value(at: time) : 0
        // A slow sway so the light keeps moving across the chrome and enamel.
        let sway = sin((time - land) * 2 * .pi * 0.16) * 14 * idleAmount
        let bob = sin(time * 2 * .pi * 0.35) * 3 * idleAmount

        return CelebrationFrame(
            tokenYaw: yaw.value(at: time) + sway + (idleMotion ? idleSpin(at: time) : 0),
            tokenLift: lift.value(at: time) + bob,
            tokenScale: scale.value(at: time)
        )
    }

    /// Whole turns added since the badge settled, easing in and out of each one.
    private static func idleSpin(at time: Double) -> Double {
        guard time >= idleSpinStart else { return 0 }
        let elapsed = time - idleSpinStart
        let completed = (elapsed / idleSpinInterval).rounded(.down)
        let phase = elapsed - completed * idleSpinInterval
        return 360 * (completed + Curve.easeInOut.apply(phase / idleSpinDuration))
    }
}
