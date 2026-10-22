import Foundation

/// Everything the hero needs to draw one frame of the ignition sequence.
struct IgnitionFrame: Equatable, Sendable {
    // The grey, unlit flame shown before the streak extends.
    var dormantOpacity: Double
    var dormantScaleX: Double
    var dormantScaleY: Double

    // The flame collapses into an orb, launches and swells.
    var orbOpacity: Double
    var orbScaleX: Double
    var orbScaleY: Double
    /// Points above the resting position.
    var orbLift: Double
    /// 0 = ash grey, 1 = ember orange, 2 = gold.
    var orbHeat: Double

    // Ring left on the ground as the orb launches.
    var haloScale: Double
    var haloOpacity: Double

    // Gold four-point star at the instant of ignition, then a star punched out of the shockwave disc.
    var flashScale: Double
    var flashOpacity: Double
    var cutoutOpacity: Double
    /// Degrees.
    var flashRotation: Double

    // Shockwave: starts as a filled disc and hollows out into a thin ring as it grows.
    var waveScale: Double
    var waveOpacity: Double
    /// Ring thickness as a fraction of its radius (1 = solid disc).
    var waveThickness: Double

    // A small teardrop that falls back to the ground and becomes the flame.
    var seedOpacity: Double
    var seedScale: Double
    /// Height of the seed's bottom edge above the baseline, in points.
    var seedLift: Double

    // The lit flame, including idle flicker once it has settled.
    var flameOpacity: Double
    var flameScaleX: Double
    var flameScaleY: Double
    /// -1...1, leans the flame tips.
    var flameSway: Double

    // Ambient light behind the hero.
    var glow: Double
    var rays: Double
}

/// The whole celebration as pure functions of elapsed time, so it can be scrubbed, replayed, skipped and tested.
enum IgnitionTimeline {
    // MARK: Beats (seconds since the screen started playing)

    static let anticipate = 0.25
    static let squash = 0.40
    static let morph = 0.62
    static let launch = 0.74
    static let swell = 0.98
    static let burst = 1.16
    static let countUp = 1.40
    static let ignite = 1.50
    static let details = 2.00
    static let progress = 2.35
    static let progressDuration = 0.90
    static let actions = 3.40

    /// A moment after everything has settled; used for Reduce Motion and for skipping ahead.
    static let restingTime = 4.0

    // MARK: Tracks

    private static let dormantOpacity = Track(1)
        .to(0, at: morph - 0.02, over: 0.08, .linear)
    private static let dormantScaleX = Track(1)
        .to(0.94, at: anticipate, over: 0.15, .easeOut)
        .to(1.12, at: squash, over: 0.22, .easeIn)
    private static let dormantScaleY = Track(1)
        .to(1.08, at: anticipate, over: 0.15, .easeOut)
        .to(0.45, at: squash, over: 0.22, .easeIn)

    private static let orbOpacity = Track(0)
        .to(1, at: morph - 0.04, over: 0.06, .linear)
        .to(0, at: burst, over: 0.05, .linear)
    private static let orbScaleX = Track(1.8)
        .to(0.82, at: launch, over: 0.12, .easeOut)
        .to(1, at: launch + 0.12, over: 0.12, .easeOut)
        .to(HeroMetrics.orbSwell, at: swell, over: burst - swell, .easeIn)
    private static let orbScaleY = Track(0.8)
        .to(1.3, at: launch, over: 0.12, .easeOut)
        .to(1, at: launch + 0.12, over: 0.12, .easeOut)
        .to(HeroMetrics.orbSwell, at: swell, over: burst - swell, .easeIn)
    private static let orbLift = Track(0)
        .to(HeroMetrics.orbLift, at: launch, over: swell - launch, .easeOut)
    // Ash to ember quickly: a slow RGB blend between grey and orange passes through a muddy tan.
    private static let orbHeat = Track(0)
        .to(1, at: morph, over: 0.08, .easeOut)
        .to(2, at: swell, over: burst - swell, .linear)

    private static let haloScale = Track(0.6)
        .to(1.8, at: launch, over: 0.42, .easeOut)
    private static let haloOpacity = Track(0)
        .set(0.9, at: launch)
        .to(0, at: launch + 0.1, over: 0.32, .easeOut)

    private static let flashScale = Track(0.8)
        .to(1.8, at: burst, over: 0.24, .easeOut)
    private static let flashOpacity = Track(0)
        .set(1, at: burst)
        .to(0, at: burst + 0.06, over: 0.06, .linear)
    private static let cutoutOpacity = Track(0)
        .set(1, at: burst + 0.06)
        .to(0, at: burst + 0.14, over: 0.12, .easeIn)
    private static let flashRotation = Track(0)
        .to(45, at: burst, over: 0.3, .easeOut)

    private static let waveScale = Track(0.6)
        .to(2.6, at: burst, over: 0.62, .easeOut)
    private static let waveOpacity = Track(0)
        .set(1, at: burst + 0.05)
        .to(0, at: burst + 0.4, over: 0.24, .easeIn)
    private static let waveThickness = Track(1)
        .to(0.1, at: burst + 0.08, over: 0.5, .easeOut)

    private static let seedOpacity = Track(0)
        .to(1, at: burst + 0.1, over: 0.08, .linear)
        .to(0, at: ignite + 0.04, over: 0.1, .linear)
    private static let seedScale = Track(0.5)
        .to(1, at: burst + 0.1, over: ignite - burst - 0.1, .easeOut)
    private static let seedLift = Track(HeroMetrics.baseline - HeroMetrics.burstY - HeroMetrics.seedHeight / 2)
        .to(0, at: burst + 0.12, over: ignite - burst - 0.12, .easeIn)

    private static let flameOpacity = Track(0)
        .to(1, at: ignite, over: 0.08, .linear)
    private static let flameScaleX = Track(0.25)
        .to(1, at: ignite, over: 0.7, .spring(damping: 0.5))
    private static let flameScaleY = Track(0.35)
        .to(1, at: ignite, over: 0.6, .spring(damping: 0.42))
    private static let flicker = Track(0)
        .to(1, at: ignite + 0.5, over: 0.6, .easeInOut)

    private static let glow = Track(0)
        .to(1, at: burst, over: 0.5, .easeOut)
    private static let rays = Track(0)
        .to(1, at: burst + 0.1, over: 0.9, .easeOut)

    // MARK: Evaluation

    /// - Parameters:
    ///   - time: Seconds since the screen started playing.
    ///   - idleMotion: Whether the settled flame keeps flickering. Off for Reduce Motion.
    static func frame(at time: Double, idleMotion: Bool = true) -> IgnitionFrame {
        let flickerAmount = idleMotion ? flicker.value(at: time) : 0
        let breathe = (sin(time * 2 * .pi * 1.4) * 0.022 + sin(time * 2 * .pi * 3.1 + 1.3) * 0.010) * flickerAmount

        return IgnitionFrame(
            dormantOpacity: dormantOpacity.value(at: time),
            dormantScaleX: dormantScaleX.value(at: time),
            dormantScaleY: dormantScaleY.value(at: time),
            orbOpacity: orbOpacity.value(at: time),
            orbScaleX: orbScaleX.value(at: time),
            orbScaleY: orbScaleY.value(at: time),
            orbLift: orbLift.value(at: time),
            orbHeat: orbHeat.value(at: time),
            haloScale: haloScale.value(at: time),
            haloOpacity: haloOpacity.value(at: time),
            flashScale: flashScale.value(at: time),
            flashOpacity: flashOpacity.value(at: time),
            cutoutOpacity: cutoutOpacity.value(at: time),
            flashRotation: flashRotation.value(at: time),
            waveScale: waveScale.value(at: time),
            waveOpacity: waveOpacity.value(at: time),
            waveThickness: waveThickness.value(at: time),
            seedOpacity: seedOpacity.value(at: time),
            seedScale: seedScale.value(at: time),
            seedLift: seedLift.value(at: time),
            flameOpacity: flameOpacity.value(at: time),
            flameScaleX: flameScaleX.value(at: time) * (1 - breathe * 0.6),
            flameScaleY: flameScaleY.value(at: time) * (1 + breathe),
            flameSway: sin(time * 2 * .pi * 0.9) * flickerAmount,
            glow: glow.value(at: time),
            rays: rays.value(at: time)
        )
    }

    /// Fill progress (0...1) of the week bar.
    static func weekProgress(at time: Double) -> Double {
        Curve.easeInOut.apply((time - progress - 0.15) / progressDuration)
    }
}
