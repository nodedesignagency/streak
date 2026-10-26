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

/// How the glow round the edges of the screen looks at a given moment.
struct GlowFrame: Equatable, Sendable {
    /// How far it has drawn in, 0...1: from the middle of the bottom edge, up both sides at once, to the
    /// middle of the top.
    var reveal: Double
    /// Where it is in a pulse: 0 its normal width and strength, 1 at its thinnest and faintest.
    var thinning: Double

    /// Width of the glowing band along the edge, in points, before it is blurred.
    var bandWidth: Double { 28 - 12 * thinning }
    /// How soft the band is, in points.
    var blurRadius: Double { 14 - 4 * thinning }
    /// Its opacity, relative to its normal strength.
    var strength: Double { 1 - 0.3 * thinning }
}

/// The whole celebration as pure functions of elapsed time, so it can be scrubbed, replayed, skipped and tested.
///
/// The badge rises from below the screen at one and a half times its size, spinning in fast, nearly three
/// turns, and winding down as it goes. As it nears its place it starts shrinking back to its own size, and
/// it settles in one continuous movement: the rise, the spin and the shrink all come to rest together,
/// facing the viewer. Meanwhile the glow round the edges of the screen draws in from the bottom, up both
/// sides, meeting at the top as the badge lands, and from then on it pulses; as it lands, streaks of light
/// start bursting out from behind it. Then the words and the share button arrive. After that the badge turns a full circle every few seconds, the slow way the coin turns
/// in the trophy-screen recording.
enum CelebrationTimeline {
    // MARK: Beats (seconds since the screen started playing)

    /// It starts rising and spinning.
    static let spin = 0.0
    /// It starts shrinking back to its own size while it is still rising and spinning, so it never stops
    /// before it settles.
    static let shrink = 0.8
    /// It comes to rest at its place, facing the viewer and at its own size, all at once; the gold glows
    /// brighten.
    static let land = 1.8
    /// The date, title and description arrive once it has settled.
    static let details = 1.95
    /// The share button arrives.
    static let actions = 2.55

    /// A moment after everything has settled; used for Reduce Motion and for skipping ahead.
    static let restingTime = 3.4

    /// How it starts: three-quarters on, its chrome edge showing on the right.
    static let startYaw = -37.0
    /// Whole turns it spins on its way in, on top of turning the rest of the way round to face the viewer.
    static let entranceTurns = 2.0
    /// Facing the viewer, after spinning in from three-quarter view.
    static let restingYaw = -360.0 * (1 + entranceTurns)
    /// How far below its place it starts, in points: off the bottom of the tallest iPhone even at its
    /// entrance size.
    static let riseDistance = 900.0
    /// Its size as it rises.
    static let entranceScale = 1.5

    /// Once settled, it turns another full circle every few seconds, slowly and evenly.
    static let idleSpinStart = 6.0
    static let idleSpinInterval = 6.0
    static let idleSpinDuration = 3.6

    /// The glow round the edges of the screen draws in from the bottom while the badge rises, meeting at the
    /// top as the badge lands. Then it pulses: thinning and fading a little, and back, once per period.
    static let glowRevealStart = spin
    static let glowPulseStart = land
    static let glowPulsePeriod = 2.4

    /// The hyperspace streaks start bursting out from behind the badge as it settles (`WarpField`). They
    /// set off a moment before, because each spends the start of its flight hidden behind the badge, so the
    /// first ones come out from behind it just as it lands.
    static let warpStart = land - 0.2

    // MARK: Tracks

    // Rising, spinning and shrinking all end together at `land`, each easing to a stop, so the badge comes
    // to rest at its place, facing the viewer and at its own size, in one movement. The spin eases out: it
    // is fastest as the badge comes up into view and winds down from there, like a coin spun on a table.
    // The shrink starts from rest while the badge is still on its way, so there is no pause and no sudden
    // jump in size.
    private static let yaw = Track(startYaw)
        .to(restingYaw, at: spin, over: land - spin, .easeOut)
    private static let drop = Track(riseDistance)
        .to(0, at: spin, over: land - spin, .easeOut)
    private static let scale = Track(entranceScale)
        .to(1, at: shrink, over: land - shrink, .easeInOutQuad)
    private static let glowReveal = Track(0)
        .to(1, at: glowRevealStart, over: glowPulseStart - glowRevealStart, .easeInOutQuad)

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

    /// - Parameters:
    ///   - time: Seconds since the screen started playing.
    ///   - idleMotion: Whether the glow keeps pulsing once it has drawn in. Off for Reduce Motion.
    static func glow(at time: Double, idleMotion: Bool = true) -> GlowFrame {
        let sincePulse = time - glowPulseStart
        let thinning = idleMotion && sincePulse > 0
            ? (1 - cos(2 * .pi * sincePulse / glowPulsePeriod)) / 2
            : 0
        return GlowFrame(reveal: glowReveal.value(at: time), thinning: thinning)
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
