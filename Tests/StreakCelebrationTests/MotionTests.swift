import Foundation
import Testing
@testable import StreakCelebration

struct CurveTests {
    @Test("Curves start at zero and end at one", arguments: [
        Curve.linear, .easeIn, .easeOut, .easeInOut, .backOut, .spring(damping: 0.45), .spring(damping: 0.9),
    ])
    func endpoints(curve: Curve) {
        #expect(abs(curve.apply(0)) < 1e-9)
        #expect(curve.apply(1) == 1)
    }

    @Test("Curves clamp progress outside 0...1")
    func clamping() {
        #expect(Curve.easeOut.apply(-2) == 0)
        #expect(Curve.easeOut.apply(3) == 1)
    }

    @Test("Springs overshoot before settling")
    func springOvershoot() {
        let peak = stride(from: 0.0, through: 1.0, by: 0.01).map { Curve.spring(damping: 0.45).apply($0) }.max() ?? 0
        #expect(peak > 1.05)
    }
}

struct TrackTests {
    let track = Track(1)
        .to(2, at: 1, over: 1, .linear)
        .to(0, at: 3, over: 0.5, .easeOut)

    @Test("Holds its initial value until the first segment")
    func holdsInitialValue() {
        #expect(track.value(at: 0) == 1)
        #expect(track.value(at: 0.99) == 1)
    }

    @Test("Interpolates inside a segment and holds between segments")
    func interpolates() {
        #expect(abs(track.value(at: 1.5) - 1.5) < 1e-9)
        #expect(track.value(at: 2.5) == 2)
    }

    @Test("Rests on the last target")
    func restsOnLastTarget() {
        #expect(track.value(at: 10) == 0)
        #expect(track.endTime == 3.5)
    }

    @Test("set(_:at:) jumps instantly")
    func setJumps() {
        let jump = Track(0).set(5, at: 1)
        #expect(jump.value(at: 0.999) == 0)
        #expect(jump.value(at: 1) == 5)
    }
}

struct CelebrationTimelineTests {
    @Test("Opens on the dormant medallion with an empty ring")
    func opensDormant() {
        let frame = CelebrationTimeline.frame(at: 0)
        #expect(!frame.showsGoldFace)
        #expect(frame.flipAngle == 0)
        #expect(frame.ringProgress == 0)
        #expect(frame.cometOpacity == 0)
        #expect(frame.haloOpacity == 0)
    }

    @Test("The ring closes as the flip begins")
    func ringCloses() {
        #expect(CelebrationTimeline.frame(at: CelebrationTimeline.arrive).ringProgress == 1)
        #expect(CelebrationTimeline.frame(at: CelebrationTimeline.arrive).flipAngle == 0)
    }

    @Test("The gold face takes over exactly at the reveal beat")
    func revealsGold() {
        #expect(!CelebrationTimeline.frame(at: CelebrationTimeline.reveal - 0.01).showsGoldFace)
        #expect(CelebrationTimeline.frame(at: CelebrationTimeline.reveal + 0.01).showsGoldFace)
    }

    @Test("The medallion is back down when it lands")
    func lands() {
        let frame = CelebrationTimeline.frame(at: CelebrationTimeline.land)
        #expect(abs(frame.medallionLift) < 4)
        #expect(frame.haloOpacity > 0.5)
    }

    @Test("Settles on the gold face inside a closed ring")
    func settles() {
        let frame = CelebrationTimeline.frame(at: CelebrationTimeline.restingTime, idleMotion: false)
        #expect(frame.showsGoldFace)
        #expect(abs(frame.flipAngle - 180) < 1)
        #expect(abs(frame.medallionScale - 1) < 0.01)
        #expect(abs(frame.medallionLift) < 0.1)
        #expect(frame.ringProgress == 1)
        #expect(frame.cometOpacity == 0)
        #expect(frame.haloOpacity == 0)
        #expect(abs(frame.shinePosition) >= 1.3)
        #expect(frame.glow == 1)
    }

    @Test("With idle motion the medallion glints again later")
    func glintsAgain() {
        let laterGlint = stride(from: CelebrationTimeline.restingTime, through: 12, by: 0.05).contains {
            abs(CelebrationTimeline.frame(at: $0).shinePosition) < 0.2
        }
        #expect(laterGlint)
    }

    @Test("Idle floating stays subtle")
    func floatIsSubtle() {
        for time in stride(from: 3.0, through: 10.0, by: 0.01) {
            #expect(abs(CelebrationTimeline.frame(at: time).medallionLift) <= 3.5)
        }
    }

    @Test("Beats run in order and finish before the resting time")
    func beatsInOrder() {
        let beats = [
            CelebrationTimeline.anticipate, CelebrationTimeline.charge, CelebrationTimeline.arrive,
            CelebrationTimeline.reveal, CelebrationTimeline.land, CelebrationTimeline.shine,
            CelebrationTimeline.details, CelebrationTimeline.week, CelebrationTimeline.actions,
        ]
        #expect(beats == beats.sorted())
        #expect(CelebrationTimeline.actions < CelebrationTimeline.restingTime)
    }

    @Test("Week dots pop in left to right and are all in place by the resting time")
    func dotsStagger() {
        for time in stride(from: CelebrationTimeline.week, through: CelebrationTimeline.restingTime, by: 0.02) {
            for index in 0..<6 {
                // No dot starts before the one to its left.
                let current = CelebrationTimeline.dotAppearance(index: index, at: time)
                let next = CelebrationTimeline.dotAppearance(index: index + 1, at: time)
                #expect(next == 0 || current > 0)
            }
        }
        for index in 0..<7 {
            #expect(CelebrationTimeline.dotAppearance(index: index, at: CelebrationTimeline.week) == 0)
            #expect(CelebrationTimeline.dotAppearance(index: index, at: CelebrationTimeline.restingTime) == 1)
            #expect(CelebrationTimeline.todayPulse(index: index, at: CelebrationTimeline.restingTime) == 1)
        }
    }
}

struct CelebrationClockTests {
    @Test("Waits at zero until started, and jumps to the end for Reduce Motion")
    func elapsed() {
        let now = Date()
        #expect(CelebrationClock(start: nil, reduceMotion: false).elapsed(at: now) == 0)
        #expect(CelebrationClock(start: now.addingTimeInterval(-2), reduceMotion: false).elapsed(at: now) == 2)
        #expect(CelebrationClock(start: now, reduceMotion: true).elapsed(at: now) == CelebrationTimeline.restingTime)
    }
}

struct ParticleFieldTests {
    @Test("Dust only exists after landing and then settles")
    func dustLifetime() {
        #expect(ParticleField.dust(at: -0.01, radius: 78).isEmpty)
        #expect(ParticleField.dust(at: 0, radius: 78).count == ParticleField.dustCount)
        #expect(ParticleField.dust(at: ParticleField.dustMaxLifetime, radius: 78).isEmpty)
    }

    @Test("Dust starts at the rim and drifts outwards")
    func dustSpreads() {
        let distances = { (particles: [Particle]) in
            particles.map { ($0.x * $0.x + $0.y * $0.y).squareRoot() }
        }
        #expect(distances(ParticleField.dust(at: 0, radius: 78)).allSatisfy { $0 > 60 })
        let early = distances(ParticleField.dust(at: 0.05, radius: 78)).max() ?? 0
        let later = distances(ParticleField.dust(at: 0.6, radius: 78)).max() ?? 0
        #expect(later > early)
    }

    @Test("Particles stay well-formed", arguments: [0.0, 0.3, 1.0, 2.5, 7.0, 15.0])
    func wellFormed(time: Double) {
        for particle in ParticleField.dust(at: time, radius: 78) + ParticleField.motes(at: time, spread: 120) {
            #expect((0...1).contains(particle.opacity))
            #expect(particle.size > 0)
        }
    }

    @Test("Motes wait for the landing")
    func motesWait() {
        #expect(ParticleField.motes(at: -0.1, spread: 120).isEmpty)
        #expect(!ParticleField.motes(at: 5, spread: 120).isEmpty)
    }

    @Test("Particles are deterministic")
    func deterministic() {
        #expect(ParticleField.dust(at: 0.4, radius: 78) == ParticleField.dust(at: 0.4, radius: 78))
        #expect(ParticleField.motes(at: 5.2, spread: 120) == ParticleField.motes(at: 5.2, spread: 120))
    }

    @Test("Noise stays in the unit interval")
    func noiseRange() {
        for index in -500..<500 {
            let value = Noise.unit(index, 7)
            #expect(value >= 0 && value < 1)
        }
    }
}
