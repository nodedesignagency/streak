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

struct IgnitionTimelineTests {
    @Test("Opens on the dormant flame")
    func opensDormant() {
        let frame = IgnitionTimeline.frame(at: 0)
        #expect(frame.dormantOpacity == 1)
        #expect(frame.orbOpacity == 0)
        #expect(frame.flameOpacity == 0)
        #expect(frame.waveOpacity == 0)
        #expect(frame.glow == 0)
    }

    @Test("The swollen orb bursts exactly where the flash and shockwave are drawn")
    func burstLinesUp() {
        let frame = IgnitionTimeline.frame(at: IgnitionTimeline.burst - 1e-6)
        let center = HeroMetrics.baseline - frame.orbLift - HeroMetrics.orbDiameter * frame.orbScaleY / 2
        #expect(abs(center - HeroMetrics.burstY) < 0.5)
    }

    @Test("The squashed flame hands over to an orb of about the same size")
    func squashHandover() {
        let frame = IgnitionTimeline.frame(at: IgnitionTimeline.morph)
        let flameHeight = HeroMetrics.flameHeight * frame.dormantScaleY
        let orbHeight = HeroMetrics.orbDiameter * frame.orbScaleY
        #expect(abs(flameHeight - orbHeight) < 4)
    }

    @Test("The seed lands on the baseline as the flame ignites")
    func seedLands() {
        let frame = IgnitionTimeline.frame(at: IgnitionTimeline.ignite)
        #expect(abs(frame.seedLift) < 0.01)
    }

    @Test("Settles on a lit flame with nothing else showing")
    func settles() {
        let frame = IgnitionTimeline.frame(at: IgnitionTimeline.restingTime, idleMotion: false)
        #expect(frame.flameOpacity == 1)
        #expect(abs(frame.flameScaleX - 1) < 0.01)
        #expect(abs(frame.flameScaleY - 1) < 0.01)
        #expect(frame.flameSway == 0)
        #expect(frame.dormantOpacity == 0)
        #expect(frame.orbOpacity == 0)
        #expect(frame.seedOpacity == 0)
        #expect(frame.waveOpacity == 0)
        #expect(frame.flashOpacity == 0)
        #expect(frame.cutoutOpacity == 0)
        #expect(frame.haloOpacity == 0)
        #expect(frame.glow == 1)
    }

    @Test("Idle flicker stays subtle")
    func flickerIsSubtle() {
        for time in stride(from: 3.0, through: 8.0, by: 0.01) {
            let frame = IgnitionTimeline.frame(at: time)
            #expect(abs(frame.flameScaleY - 1) < 0.04)
            #expect(abs(frame.flameSway) <= 1)
        }
    }

    @Test("Beats run in order and finish before the resting time")
    func beatsInOrder() {
        let beats = [
            IgnitionTimeline.anticipate, IgnitionTimeline.squash, IgnitionTimeline.morph, IgnitionTimeline.launch,
            IgnitionTimeline.swell, IgnitionTimeline.burst, IgnitionTimeline.countUp, IgnitionTimeline.ignite,
            IgnitionTimeline.details, IgnitionTimeline.progress, IgnitionTimeline.actions,
        ]
        #expect(beats == beats.sorted())
        #expect(IgnitionTimeline.actions < IgnitionTimeline.restingTime)
    }

    @Test("The week fills once the bar is on screen")
    func weekFills() {
        #expect(IgnitionTimeline.weekProgress(at: IgnitionTimeline.progress) == 0)
        #expect(IgnitionTimeline.weekProgress(at: IgnitionTimeline.actions) == 1)
        #expect(IgnitionTimeline.weekProgress(at: IgnitionTimeline.restingTime) == 1)
    }
}

struct ParticleFieldTests {
    @Test("Sparks only exist after the burst and then burn out")
    func sparkLifetime() {
        #expect(ParticleField.sparks(at: -0.01).isEmpty)
        #expect(ParticleField.sparks(at: 0).count == ParticleField.sparkCount)
        #expect(ParticleField.sparks(at: ParticleField.sparkMaxLifetime).isEmpty)
    }

    @Test("Sparks fly outwards")
    func sparksSpread() {
        let spread = { (particles: [Particle]) in
            particles.map { ($0.x * $0.x + $0.y * $0.y).squareRoot() }.max() ?? 0
        }
        #expect(spread(ParticleField.sparks(at: 0.3)) > spread(ParticleField.sparks(at: 0.05)))
    }

    @Test("Embers rise and stay well-formed")
    func embersRise() {
        for time in stride(from: 0.0, through: 12.0, by: 0.05) {
            for ember in ParticleField.embers(at: time) {
                #expect(ember.y <= 0)
                #expect((0...1).contains(ember.opacity))
                #expect(ember.size > 0)
            }
        }
    }

    @Test("Particles are deterministic")
    func deterministic() {
        #expect(ParticleField.sparks(at: 0.4) == ParticleField.sparks(at: 0.4))
        #expect(ParticleField.embers(at: 5.2) == ParticleField.embers(at: 5.2))
    }

    @Test("Noise stays in the unit interval")
    func noiseRange() {
        for index in -500..<500 {
            let value = Noise.unit(index, 7)
            #expect(value >= 0 && value < 1)
        }
    }
}
