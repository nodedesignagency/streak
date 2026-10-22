import Foundation

/// One particle, positioned relative to its emitter. Y grows downwards, matching SwiftUI.
struct Particle: Equatable, Sendable {
    var x: Double
    var y: Double
    var size: Double
    var opacity: Double
    /// Index into the palette's particle colours.
    var tint: Int
    /// Round specks, or little four-point glints.
    var isRound: Bool
}

/// Stateless particle systems: every particle is a function of time and its index, so there is nothing
/// to spawn, store or clean up, and a replay looks identical every time.
enum ParticleField {
    static let dustCount = 30
    static let dustMaxLifetime = 1.9

    static let moteCount = 10
    static let motePeriod = 3.6

    /// Gold dust shaken off the medallion's rim as it lands.
    /// - Parameters:
    ///   - age: Seconds since landing.
    ///   - radius: Radius of the medallion, where the dust starts.
    static func dust(at age: Double, radius: Double) -> [Particle] {
        guard age >= 0, age < dustMaxLifetime else { return [] }
        return (0..<dustCount).compactMap { i in
            let lifetime = 1.1 + 0.8 * Noise.unit(i, 21)
            guard age < lifetime else { return nil }
            let p = age / lifetime

            let angle = Double(i) / Double(dustCount) * 2 * .pi + (Noise.unit(i, 22) - 0.5) * 0.4
            let distance = radius * (0.85 + 0.2 * Noise.unit(i, 23)) + (30 + 90 * Noise.unit(i, 24)) * Curve.easeOut.apply(p)
            let fall = 40 * age * age
            let twinkle = 0.65 + 0.35 * sin(age * (14 + 10 * Noise.unit(i, 25)) + Double(i))
            let fade = p < 0.5 ? 1 : 1 - (p - 0.5) / 0.5
            let isGlint = i % 5 == 0

            return Particle(
                x: cos(angle) * distance,
                y: sin(angle) * distance + fall,
                size: (1.5 + 2.5 * Noise.unit(i, 26)) * (isGlint ? 2.4 : 1),
                opacity: fade * twinkle,
                tint: i % 3,
                isRound: !isGlint
            )
        }
    }

    /// Slow motes that keep drifting up around the medallion once it has landed.
    /// - Parameters:
    ///   - time: Seconds since landing.
    ///   - spread: How far from the centre motes may appear.
    static func motes(at time: Double, spread: Double) -> [Particle] {
        guard time >= 0 else { return [] }
        return (0..<moteCount).compactMap { i in
            // Stagger the first appearance so they don't all start together.
            let delay = Double(i) / Double(moteCount) * motePeriod + 0.3 * Noise.unit(i, 30)
            let local = time - delay
            guard local >= 0 else { return nil }

            let cycle = Int(local / motePeriod)
            let age = local.truncatingRemainder(dividingBy: motePeriod)
            let seed = i &* 97 &+ cycle // a fresh path every time the mote respawns
            let lifetime = motePeriod * (0.7 + 0.3 * Noise.unit(seed, 31))
            guard age < lifetime else { return nil }
            let p = age / lifetime

            let startX = (Noise.unit(seed, 32) - 0.5) * 2 * spread
            let startY = (Noise.unit(seed, 33) - 0.3) * spread
            let rise = 30 + 40 * Noise.unit(seed, 34)
            let sway = sin(age * 1.6 + Noise.unit(seed, 35) * 2 * .pi) * 6
            let fadeIn = min(1, p / 0.2)
            let fadeOut = p > 0.6 ? 1 - (p - 0.6) / 0.4 : 1
            let twinkle = 0.6 + 0.4 * sin(age * 5 + Double(i))

            return Particle(
                x: startX + sway,
                y: startY - rise * p,
                size: 1.5 + 2 * Noise.unit(seed, 36),
                opacity: fadeIn * fadeOut * twinkle,
                tint: seed % 3,
                isRound: i % 4 != 0
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
