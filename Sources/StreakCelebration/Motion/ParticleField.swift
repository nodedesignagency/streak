import Foundation

/// One flake of gold leaf. Y grows downwards, matching SwiftUI.
struct Particle: Equatable, Sendable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double
    /// Radians.
    var rotation: Double
    var opacity: Double
    /// Index into the palette's colours; 2 is the bright glint of a flake caught face-on.
    var tint: Int
}

/// Stateless particle systems: every flake is a function of time and its index, so there is nothing to
/// spawn, store or clean up, and a replay looks identical every time.
enum ParticleField {
    static let burstCount = 36
    static let burstMaxLifetime = 2.0

    static let flakeCount = 90

    /// Gold leaf thrown off the coin as it lands, relative to its centre.
    /// - Parameters:
    ///   - age: Seconds since landing.
    ///   - halfWidth: Half the coin's width; flakes start around its outline.
    ///   - halfHeight: Half the token's height.
    static func burst(at age: Double, halfWidth: Double, halfHeight: Double) -> [Particle] {
        guard age >= 0, age < burstMaxLifetime else { return [] }
        return (0..<burstCount).compactMap { i in
            let lifetime = 1.2 + 0.8 * Noise.unit(i, 21)
            guard age < lifetime else { return nil }
            let p = age / lifetime

            let angle = Double(i) / Double(burstCount) * 2 * .pi + (Noise.unit(i, 22) - 0.5) * 0.5
            let travel = (40 + 100 * Noise.unit(i, 23)) * Curve.easeOut.apply(p)
            let fall = 60 * age * age
            let spin = age * (6 + 8 * Noise.unit(i, 24)) + Noise.unit(i, 25) * 2 * .pi
            let tumble = abs(cos(spin))
            let size = 4 + 5 * Noise.unit(i, 26)
            let fade = p < 0.6 ? 1 : 1 - (p - 0.6) / 0.4

            return Particle(
                x: cos(angle) * (halfWidth + travel),
                y: sin(angle) * (halfHeight + travel) + fall,
                width: size * max(0.15, tumble),
                height: size * 0.5,
                rotation: angle + spin * 0.3,
                opacity: fade * (0.6 + 0.4 * tumble),
                tint: tumble > 0.9 ? 2 : i % 2
            )
        }
    }

    /// Gold leaf drifting down across an area, endlessly. Nearer flakes are bigger, brighter and faster.
    /// - Parameters:
    ///   - time: Seconds since the flakes started.
    ///   - width: Width of the area, in points.
    ///   - height: Height of the area; flakes wrap from just below it to just above it.
    static func flakes(at time: Double, width: Double, height: Double) -> [Particle] {
        guard time >= 0, width > 0, height > 0 else { return [] }
        let span = height + 40
        return (0..<flakeCount).map { i in
            let depth = Noise.unit(i, 40)
            let speed = 30 + 60 * depth
            let y = (Noise.unit(i, 41) * span + speed * time).truncatingRemainder(dividingBy: span) - 20
            let drift = sin(time * (0.5 + Noise.unit(i, 42)) + Noise.unit(i, 43) * 2 * .pi) * (6 + 10 * depth)
            let spin = time * (1.5 + 4 * Noise.unit(i, 44)) + Noise.unit(i, 45) * 2 * .pi
            let tumble = abs(cos(spin))
            let size = (2.5 + 5 * Noise.unit(i, 46)) * (0.55 + 0.45 * depth)

            return Particle(
                x: Noise.unit(i, 47) * width + drift,
                y: y,
                width: size * max(0.15, tumble),
                height: size * 0.5,
                rotation: Noise.unit(i, 48) * .pi + spin * 0.2,
                opacity: (0.35 + 0.65 * depth) * (0.55 + 0.45 * tumble),
                tint: tumble > 0.92 ? 2 : i % 2
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
