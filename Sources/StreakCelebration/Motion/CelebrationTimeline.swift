import Foundation

/// Everything the hero needs to draw one frame of the celebration.
struct CelebrationFrame: Equatable, Sendable {
    /// Degrees around the vertical axis. 0 faces the viewer. The badge rises in three-quarter view, turns the
    /// rest of the way round to face the viewer, and turns a full circle every few seconds after that. The
    /// angle falls as it turns: the badge's right side comes towards the viewer.
    var tokenYaw: Double
    /// Points below its place on the screen.
    var tokenDrop: Double
    /// Its size relative to its own.
    var tokenScale: Double
}

/// The whole celebration as pure functions of elapsed time, so it can be scrubbed, replayed, skipped and tested.
///
/// The badge rises from below the screen at twice its size, turning at twice the speed of its idle turns,
/// and comes to rest at its place facing the viewer. Then it shrinks back to its own size, and the words and
/// the share button arrive. After that it turns a full circle every few seconds, the slow way the coin turns
/// in the trophy-screen recording.
enum CelebrationTimeline {
    // MARK: Beats (seconds since the screen started playing)

    /// It starts rising and turning.
    static let spin = 0.0
    /// It comes to rest at its place, face-on and still twice its size; the gold at the bottom of the screen
    /// warms up.
    static let land = 1.8
    /// It shrinks back to its own size.
    static let shrink = 2.0
    static let shrinkDuration = 0.5
    /// The date, title and description arrive once it is back to its own size.
    static let details = 2.55
    /// The share button arrives.
    static let actions = 3.15

    /// A moment after everything has settled; used for Reduce Motion and for skipping ahead.
    static let restingTime = 4.0

    /// How it starts: three-quarters on, its chrome edge showing on the right.
    static let startYaw = -37.0
    /// Facing the viewer, after turning the rest of the way round from three-quarter view.
    static let restingYaw = -360.0
    /// How far below its place it starts, in points: off the bottom of the tallest iPhone even at twice its size.
    static let riseDistance = 1000.0
    /// Its size as it rises.
    static let entranceScale = 2.0

    /// Once settled, it turns another full circle every few seconds, at half the speed it rose with.
    static let idleSpinStart = 6.0
    static let idleSpinInterval = 6.0
    static let idleSpinDuration = 3.6

    // MARK: Tracks

    // Rising and turning end together, so it comes to rest at its place just as it faces the viewer.
    private static let yaw = Track(startYaw)
        .to(restingYaw, at: spin, over: land - spin, .easeInOutQuad)
    private static let drop = Track(riseDistance)
        .to(0, at: spin, over: land - spin, .easeOut)
    private static let scale = Track(entranceScale)
        .to(1, at: shrink, over: shrinkDuration, .easeInOut)

    // MARK: Evaluation

    /// - Parameters:
    ///   - time: Seconds since the screen started playing.
    ///   - idleMotion: Whether the settled badge keeps turning every few seconds. Off for Reduce Motion.
    static func frame(at time: Double, idleMotion: Bool = true) -> CelebrationFrame {
        CelebrationFrame(
            tokenYaw: yaw.value(at: time) - (idleMotion ? idleSpin(at: time) : 0),
            tokenDrop: drop.value(at: time),
            tokenScale: scale.value(at: time)
        )
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
