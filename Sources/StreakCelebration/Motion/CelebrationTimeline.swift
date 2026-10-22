import Foundation

/// Everything the hero needs to draw one frame of the celebration.
struct CelebrationFrame: Equatable, Sendable {
    // The medallion.
    var medallionScale: Double
    /// Points above the resting position.
    var medallionLift: Double
    /// Degrees around the vertical axis. Past 90 the gold face is showing.
    var flipAngle: Double
    /// Horizontal position of the shine band across the gold face: ±1.3 is fully off the medallion.
    var shinePosition: Double

    // The ring that closes around it.
    /// 0...1 of the circle drawn.
    var ringProgress: Double
    /// Glowing head riding the end of the ring while it closes.
    var cometOpacity: Double
    var ringGlow: Double
    /// A thin ring that pulses outwards when the medallion lands.
    var haloScale: Double
    var haloOpacity: Double

    /// Warm light behind the hero.
    var glow: Double

    var showsGoldFace: Bool { flipAngle > 90 }
}

/// The whole celebration as pure functions of elapsed time, so it can be scrubbed, replayed, skipped and tested.
enum CelebrationTimeline {
    // MARK: Beats (seconds since the screen started playing)

    /// The medallion dips, winding up.
    static let anticipate = 0.20
    /// The ring starts closing and the medallion rises with it.
    static let charge = 0.35
    static let chargeDuration = 0.75
    /// The ring closes and the medallion starts to flip.
    static let arrive = 1.10
    /// Edge-on: the gold face takes over and the count rolls.
    static let reveal = 1.28
    /// The medallion settles back down and shakes off gold dust.
    static let land = 1.42
    static let shine = 1.75
    static let details = 2.05
    static let week = 2.40
    static let actions = 3.40

    /// A moment after everything has settled; used for Reduce Motion and for skipping ahead.
    static let restingTime = 4.2

    static let shineSweep = 0.9
    static let shineInterval = 5.0
    static let dotStagger = 0.07

    // MARK: Tracks

    private static let medallionScale = Track(1)
        .to(0.94, at: anticipate, over: 0.15, .easeOut)
        .to(1.02, at: charge, over: chargeDuration, .easeInOut)
        .to(1.12, at: arrive, over: reveal - arrive, .easeOut)
        .to(1, at: reveal, over: 0.6, .spring(damping: 0.45))
    private static let medallionLift = Track(0)
        .to(-4, at: anticipate, over: 0.15, .easeOut)
        .to(16, at: charge, over: chargeDuration, .easeInOut)
        .to(0, at: reveal, over: 0.5, .spring(damping: 0.55))
    // Accelerate into the edge-on moment, then spring through to the back. The change of pace happens
    // while the medallion is edge-on, where nobody can see it.
    private static let flipAngle = Track(0)
        .to(90, at: arrive, over: reveal - arrive, .easeIn)
        .to(180, at: reveal, over: 0.6, .spring(damping: 0.5))

    private static let ringProgress = Track(0)
        .to(1, at: charge, over: chargeDuration, .easeInOut)
    private static let comet = Track(0)
        .to(1, at: charge, over: 0.1, .linear)
        .to(0, at: arrive + 0.05, over: 0.35, .easeOut)
    private static let ringGlow = Track(0)
        .to(1, at: arrive - 0.05, over: 0.12, .easeOut)
        .to(0.35, at: arrive + 0.1, over: 0.9, .easeOut)
    private static let haloScale = Track(1)
        .to(1.4, at: land, over: 0.8, .easeOut)
    private static let haloOpacity = Track(0)
        .set(0.6, at: land)
        .to(0, at: land + 0.05, over: 0.75, .easeOut)

    private static let glow = Track(0.2)
        .to(1, at: land - 0.15, over: 0.6, .easeOut)
    private static let idle = Track(0)
        .to(1, at: land + 0.4, over: 0.8, .easeInOut)

    // MARK: Evaluation

    /// - Parameters:
    ///   - time: Seconds since the screen started playing.
    ///   - idleMotion: Whether the settled medallion keeps floating and glinting. Off for Reduce Motion.
    static func frame(at time: Double, idleMotion: Bool = true) -> CelebrationFrame {
        let idleAmount = idleMotion ? idle.value(at: time) : 0
        let bob = sin(time * 2 * .pi * 0.35) * 3 * idleAmount
        let breathe = (sin(time * 2 * .pi * 0.5) * 0.5 + 0.5) * 0.25 * idleAmount

        return CelebrationFrame(
            medallionScale: medallionScale.value(at: time),
            medallionLift: medallionLift.value(at: time) + bob,
            flipAngle: flipAngle.value(at: time),
            shinePosition: shinePosition(at: time, idleMotion: idleMotion),
            ringProgress: ringProgress.value(at: time),
            cometOpacity: comet.value(at: time),
            ringGlow: ringGlow.value(at: time) + breathe,
            haloScale: haloScale.value(at: time),
            haloOpacity: haloOpacity.value(at: time),
            glow: glow.value(at: time)
        )
    }

    /// One sweep after landing, then (with idle motion) another glint every few seconds.
    private static func shinePosition(at time: Double, idleMotion: Bool) -> Double {
        let firstSweepEnd = shine + shineSweep
        let pause = 1.5
        guard idleMotion, time > firstSweepEnd + pause else {
            return -1.3 + 2.6 * Curve.easeInOut.apply((time - shine) / shineSweep)
        }
        let cycle = (time - firstSweepEnd - pause).truncatingRemainder(dividingBy: shineInterval)
        return -1.3 + 2.6 * Curve.easeInOut.apply(cycle / shineSweep)
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
