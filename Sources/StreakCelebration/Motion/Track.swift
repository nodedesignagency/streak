import Foundation

/// Maps linear progress (0...1) to eased progress.
enum Curve: Sendable {
    case linear
    case easeIn
    case easeOut
    case easeInOut
    /// A gentler ease-in-out (quadratic): it gathers speed and slows down more gradually than `easeInOut`,
    /// peaking at twice its average speed rather than three times.
    case easeInOutQuad
    /// Overshoots slightly, then settles. Good for things that "pop" into place.
    case backOut
    /// A damped spring that comes to rest by the end of the segment.
    /// Lower damping wobbles more; 0.4–0.6 reads as playful, 0.8+ as calm.
    case spring(damping: Double)

    func apply(_ progress: Double) -> Double {
        let p = min(max(progress, 0), 1)
        switch self {
        case .linear:
            return p
        case .easeIn:
            return p * p * p
        case .easeOut:
            let q = 1 - p
            return 1 - q * q * q
        case .easeInOut:
            return p < 0.5 ? 4 * p * p * p : 1 - pow(-2 * p + 2, 3) / 2
        case .easeInOutQuad:
            return p < 0.5 ? 2 * p * p : 1 - pow(-2 * p + 2, 2) / 2
        case .backOut:
            let overshoot = 1.70158
            let q = p - 1
            return 1 + (overshoot + 1) * q * q * q + overshoot * q * q
        case .spring(let damping):
            guard p < 1 else { return 1 }
            let zeta = min(max(damping, 0.05), 0.95)
            // Pick the natural frequency so the envelope has decayed to ~0.1% at p == 1.
            let omega = 7 / zeta
            let omegaD = omega * (1 - zeta * zeta).squareRoot()
            let envelope = exp(-zeta * omega * p)
            return 1 - envelope * (cos(omegaD * p) + (zeta * omega / omegaD) * sin(omegaD * p))
        }
    }
}

/// One animatable value described as a run of timed segments, so it can be evaluated at any time.
///
/// Each segment animates from wherever the value is when the segment starts to its target,
/// which keeps a whole multi-step choreography readable in a single expression:
///
///     Track(1).to(1.3, at: 0.4, over: 0.2, .easeIn).to(1, at: 0.6, over: 0.3, .spring(damping: 0.5))
struct Track: Sendable {
    private struct Segment: Sendable {
        var start: Double
        var duration: Double
        var target: Double
        var curve: Curve
    }

    private let initial: Double
    private var segments: [Segment] = []

    init(_ initial: Double) {
        self.initial = initial
    }

    /// Animates to `target`, starting `start` seconds into the timeline. Segments must be added in time order.
    func to(_ target: Double, at start: Double, over duration: Double, _ curve: Curve = .easeInOut) -> Track {
        var copy = self
        copy.segments.append(Segment(start: start, duration: duration, target: target, curve: curve))
        return copy
    }

    /// Jumps to `value` instantly at `time`.
    func set(_ value: Double, at time: Double) -> Track {
        to(value, at: time, over: 0, .linear)
    }

    func value(at time: Double) -> Double {
        var value = initial
        for segment in segments {
            guard time >= segment.start else { break }
            let progress = segment.duration > 0 ? (time - segment.start) / segment.duration : 1
            value += (segment.target - value) * segment.curve.apply(progress)
        }
        return value
    }

    /// The moment the last segment comes to rest.
    var endTime: Double {
        segments.map { $0.start + $0.duration }.max() ?? 0
    }
}
