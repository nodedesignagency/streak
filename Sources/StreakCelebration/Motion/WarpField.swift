import Foundation

/// The hyperspace streaks behind the badge: lines of light rushing out from a point at the badge's centre,
/// short and faint near it, long, thick and bright by the edges of the screen, like the jump to light speed.
///
/// Each streak is a point of light flying straight at the viewer along its own line, at its own speed. Seen in
/// perspective it races outwards from the centre, faster and faster, stretching as it comes, and once it has
/// left the screen it starts again far away, too faint to see. Everything is a pure function of time, so the
/// field never pops, can be scrubbed and tested, and plays the same way every time.
enum WarpField {
    struct Streak: Equatable, Sendable {
        /// Its two ends, in points from the vanishing point; the head is the bright end, furthest out.
        var tail: CGPoint
        var head: CGPoint
        /// Line width at the head, in points.
        var width: Double
        /// 0...1, at the head; the streak fades away to nothing towards its tail.
        var opacity: Double
        /// Which of the palette's warp colours it is (0 orange, 1 gold, 2 warm white).
        var colour: Int
    }

    static let count = 180
    /// How long a streak of average speed takes to fly from the centre to the edge, in seconds.
    static let crossing = 1.4
    /// It fades in over this long when the screen opens.
    static let fadeIn = 0.6
    /// Where a streak starts, and where it has gone by the end of its flight, as fractions of `reach`. It
    /// starts tucked behind the badge and ends past the furthest corner.
    static let startFraction = 0.16
    static let endFraction = 1.15

    /// - Parameters:
    ///   - time: Seconds since the screen started playing.
    ///   - reach: Distance from the vanishing point to the furthest corner of the screen, in points.
    static func streaks(at time: Double, reach: Double) -> [Streak] {
        let start = startFraction * reach
        let end = endFraction * reach
        return (0..<count).map { index in
            let speed = 0.7 + 0.7 * random(index, 0)
            let progress = fraction(random(index, 1) + time * speed / crossing)
            let angle = 2 * Double.pi * random(index, 2)
            let spread = 0.85 + 0.3 * random(index, 3)
            // The tail is where the head was a moment ago, so faster streaks are longer.
            let tailProgress = max(0, progress - 0.16 * speed)

            func radius(_ progress: Double) -> Double {
                // Perspective: distance from the centre goes as one over depth, and depth falls steadily.
                spread * start / (1 - progress * (1 - start / end))
            }
            func point(_ radius: Double) -> CGPoint {
                CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            }

            // Mostly dim streaks, with the odd bright one.
            let brightness = 0.3 + 0.7 * pow(random(index, 4), 2)
            let colourRoll = random(index, 5)
            return Streak(
                tail: point(radius(tailProgress)),
                head: point(radius(progress)),
                width: (0.4 + 0.6 * random(index, 6)) * (0.5 + 2.2 * progress * progress),
                // Fades in as it sets off, and out at the very end in case it is still on screen.
                opacity: brightness * smoothstep(progress / 0.3) * smoothstep((1 - progress) / 0.06),
                colour: colourRoll < 0.5 ? 0 : colourRoll < 0.8 ? 1 : 2
            )
        }
    }

    /// How visible the whole field is: 0 when the screen opens, rising to 1 over `fadeIn`.
    static func visibility(at time: Double) -> Double {
        smoothstep(time / fadeIn)
    }

    // MARK: Helpers

    private static func fraction(_ value: Double) -> Double {
        value - value.rounded(.down)
    }

    private static func smoothstep(_ value: Double) -> Double {
        let x = min(max(value, 0), 1)
        return x * x * (3 - 2 * x)
    }

    /// A fixed pseudo-random number in 0..<1 for a streak and one of its properties, the same on every run.
    static func random(_ index: Int, _ property: Int) -> Double {
        // SplitMix64 on the pair, so neighbouring streaks are unrelated.
        var z = UInt64(truncatingIfNeeded: index &* 0x9E37_79B9 &+ property &* 0x85EB_CA6B) &+ 0x9E37_79B9_7F4A_7C15
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        z ^= z >> 31
        return Double(z >> 11) / Double(UInt64(1) << 53)
    }
}
