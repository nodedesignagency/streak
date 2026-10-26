import Foundation

/// Everything the hero needs to draw one frame of the celebration.
struct CelebrationFrame: Equatable, Sendable {
    /// Degrees around the vertical axis. 0 faces the viewer. The badge opens in three-quarter view, turns the
    /// rest of the way round to face the viewer, and turns a full circle every few seconds after that. The
    /// angle falls as it turns: the badge's right side comes towards the viewer.
    var tokenYaw: Double
}

/// The whole celebration as pure functions of elapsed time, so it can be scrubbed, replayed, skipped and tested.
///
/// The badge's motion follows the trophy-screen recording: it holds still in three-quarter view, then makes
/// one slow, smooth turn, gathering speed until its back has gone by and easing off as it comes round to
/// face the viewer. It never lifts, grows or bobs; only the turn moves.
enum CelebrationTimeline {
    // MARK: Beats (seconds since the screen started playing)

    /// It starts to turn.
    static let spin = 0.50
    /// The date, title and description arrive while it turns.
    static let details = 0.90
    /// The share button arrives.
    static let actions = 1.50
    /// It comes round to face the viewer and comes to rest; the gold at the bottom of the screen warms up.
    static let land = 4.10

    /// A moment after everything has settled; used for Reduce Motion and for skipping ahead.
    static let restingTime = 4.6

    /// Where it starts: three-quarters on, its chrome edge showing on the right.
    static let startYaw = -37.0
    /// Facing the viewer, after turning the rest of the way round from three-quarter view.
    static let restingYaw = -360.0

    /// Once settled, it turns another full circle every few seconds, the same slow way.
    static let idleSpinStart = land + 2.4
    static let idleSpinInterval = 6.0
    static let idleSpinDuration = land - spin

    // MARK: Tracks

    private static let yaw = Track(startYaw)
        .to(restingYaw, at: spin, over: land - spin, .easeInOutQuad)

    // MARK: Evaluation

    /// - Parameters:
    ///   - time: Seconds since the screen started playing.
    ///   - idleMotion: Whether the settled badge keeps turning every few seconds. Off for Reduce Motion.
    static func frame(at time: Double, idleMotion: Bool = true) -> CelebrationFrame {
        CelebrationFrame(tokenYaw: yaw.value(at: time) - (idleMotion ? idleSpin(at: time) : 0))
    }

    /// Whole turns made since the badge settled, easing in and out of each one.
    private static func idleSpin(at time: Double) -> Double {
        guard time >= idleSpinStart else { return 0 }
        let elapsed = time - idleSpinStart
        let completed = (elapsed / idleSpinInterval).rounded(.down)
        let phase = elapsed - completed * idleSpinInterval
        return 360 * (completed + Curve.easeInOutQuad.apply(phase / idleSpinDuration))
    }
}
