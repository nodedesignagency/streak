import Foundation

/// One particle, positioned relative to its emitter. Y grows downwards, matching SwiftUI.
struct Particle: Equatable, Sendable {
    var x: Double
    var y: Double
    var size: Double
    /// Radians.
    var rotation: Double
    var opacity: Double
    /// Index into the palette's particle colours.
    var tint: Int
    /// Round dots or little confetti chips.
    var isRound: Bool
}

/// Stateless particle systems: every particle is a function of time and its index, so there is nothing
/// to spawn, store or clean up, and a replay looks identical every time.
enum ParticleField {
    static let sparkCount = 22
    static let sparkMaxLifetime = 1.1

    static let emberCount = 9
    static let emberPeriod = 2.4

    /// The ring of sparks thrown out when the orb bursts.
    /// - Parameter age: Seconds since the burst.
    static func sparks(at age: Double) -> [Particle] {
        guard age >= 0, age < sparkMaxLifetime else { return [] }
        return (0..<sparkCount).compactMap { i in
            let lifetime = 0.7 + 0.4 * Noise.unit(i, 1)
            guard age < lifetime else { return nil }
            let p = age / lifetime

            let angle = Double(i) / Double(sparkCount) * 2 * .pi + (Noise.unit(i, 2) - 0.5) * 0.5
            let distance = (80 + 90 * Noise.unit(i, 3)) * Curve.easeOut.apply(p)
            let gravity = 70 * age * age

            return Particle(
                x: cos(angle) * distance,
                y: sin(angle) * distance + gravity,
                size: (4 + 5 * Noise.unit(i, 4)) * (1 - 0.4 * p),
                rotation: angle + (Noise.unit(i, 5) - 0.5) * 12 * age,
                opacity: p < 0.55 ? 1 : 1 - (p - 0.55) / 0.45,
                tint: i % 3,
                isRound: i % 3 == 0
            )
        }
    }

    /// Embers that keep drifting up from the lit flame.
    /// - Parameter time: Seconds since the flame was lit.
    static func embers(at time: Double) -> [Particle] {
        guard time >= 0 else { return [] }
        return (0..<emberCount).compactMap { i in
            // Stagger the first appearance so they don't all leave the flame together.
            let delay = Double(i) / Double(emberCount) * emberPeriod * 0.9 + 0.2 * Noise.unit(i, 10)
            let local = time - delay
            guard local >= 0 else { return nil }

            let cycle = Int(local / emberPeriod)
            let age = local.truncatingRemainder(dividingBy: emberPeriod)
            let seed = i &* 131 &+ cycle // a fresh path every time the ember respawns
            let lifetime = emberPeriod * (0.65 + 0.3 * Noise.unit(seed, 11))
            guard age < lifetime else { return nil }
            let p = age / lifetime

            let startX = (Noise.unit(seed, 12) - 0.5) * 56
            let rise = 70 + 60 * Noise.unit(seed, 13)
            let swayFrequency = 2.5 + 2 * Noise.unit(seed, 14)
            let swayAmplitude = 4 + 6 * Noise.unit(seed, 15)
            let sway = sin(age * swayFrequency + Noise.unit(seed, 16) * 2 * .pi) * swayAmplitude
            let fadeIn = min(1, p / 0.15)
            let fadeOut = p > 0.55 ? 1 - (p - 0.55) / 0.45 : 1

            return Particle(
                x: startX + sway,
                y: -rise * Curve.easeOut.apply(p),
                size: (2.5 + 3 * Noise.unit(seed, 17)) * (1 - 0.5 * p),
                rotation: 0,
                opacity: fadeIn * fadeOut,
                tint: i % 2,
                isRound: true
            )
        }
    }
}

/// Cheap, deterministic pseudo-randomness (SplitMix64) keyed by an index and a salt.
enum Noise {
    /// A value in 0..<1 that is always the same for the same `index` and `salt`.
    static func unit(_ index: Int, _ salt: UInt64) -> Double {
        var z = UInt64(bitPattern: Int64(index)) &* 0x9E37_79B9_7F4A_7C15 &+ salt &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        z ^= z >> 31
        return Double(z >> 11) * 0x1p-53
    }
}
