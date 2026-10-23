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
    @Test("Opens facing front, dull, showing the previous count")
    func opensDormant() {
        let frame = CelebrationTimeline.frame(at: 0)
        #expect(frame.tokenYaw == 0)
        #expect(!frame.showsNewCount)
        #expect(frame.ignition == 0)
        #expect(frame.flakesOpacity == 0)
    }

    @Test("Winds up the other way before it spins")
    func windsUp() {
        #expect(CelebrationTimeline.frame(at: CelebrationTimeline.spin).tokenYaw < 0)
    }

    @Test("The count only changes while the front is turned away")
    func swapsOutOfSight() {
        var sawBackBeforeReveal = false
        var previous = CelebrationTimeline.frame(at: 0)
        for time in stride(from: 0.0, through: CelebrationTimeline.restingTime, by: 1.0 / 240) {
            let frame = CelebrationTimeline.frame(at: time)
            let projection = TokenProjection(yaw: frame.tokenYaw, thickness: HeroMetrics.tokenThickness)
            if frame.showsNewCount != previous.showsNewCount {
                // Edge-on at the swap (within one sample of it): neither face is readable.
                #expect(projection.faceScale < 0.1)
            }
            if !projection.showsFront && time < CelebrationTimeline.reveal {
                sawBackBeforeReveal = true
            }
            previous = frame
        }
        #expect(sawBackBeforeReveal)
    }

    @Test("At the reveal the front is back in view carrying the new count")
    func reveal() {
        let frame = CelebrationTimeline.frame(at: CelebrationTimeline.reveal)
        #expect(frame.showsNewCount)
        #expect(TokenProjection(yaw: frame.tokenYaw, thickness: HeroMetrics.tokenThickness).showsFront)
    }

    @Test("Stays dull while spinning, and lights up as it lands")
    func lightsUp() {
        for time in stride(from: 0, to: CelebrationTimeline.land - 0.05, by: 0.01) {
            #expect(CelebrationTimeline.frame(at: time).ignition <= 0.2)
        }
        let landing = CelebrationTimeline.frame(at: CelebrationTimeline.land)
        #expect(abs(landing.tokenLift) < 4)
        #expect(landing.ignition > 1)
    }

    @Test("Settles face-on after exactly two turns")
    func settles() {
        let frame = CelebrationTimeline.frame(at: CelebrationTimeline.restingTime, idleMotion: false)
        #expect(abs(frame.tokenYaw - CelebrationTimeline.restingYaw) < 0.5)
        #expect(abs(frame.tokenScale - 1) < 0.01)
        #expect(abs(frame.tokenLift) < 0.1)
        #expect(frame.ignition == 1)
        #expect(frame.glow == 1)
        #expect(frame.flakesOpacity == 1)
        #expect(frame.showsNewCount)
    }

    @Test("Idle sway keeps the front in view and stays gentle")
    func swayIsGentle() {
        for time in stride(from: 3.0, through: 12.0, by: 0.01) {
            let frame = CelebrationTimeline.frame(at: time)
            #expect(abs(frame.tokenYaw - CelebrationTimeline.restingYaw) <= 15)
            #expect(abs(frame.tokenLift) <= 3.5)
            #expect(frame.showsNewCount)
        }
    }

    @Test("Beats run in order and finish before the resting time")
    func beatsInOrder() {
        let beats = [
            CelebrationTimeline.anticipate, CelebrationTimeline.spin, CelebrationTimeline.reveal,
            CelebrationTimeline.land, CelebrationTimeline.week,
            CelebrationTimeline.actions,
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

struct TokenProjectionTests {
    let thickness = 16.0

    @Test("Face-on shows the whole front with no edge")
    func faceOn() {
        let projection = TokenProjection(yaw: 0, thickness: thickness)
        #expect(projection.showsFront)
        #expect(projection.faceScale == 1)
        #expect(projection.faceOffset == 0)
        #expect(projection.extrude == 0)
    }

    @Test("Edge-on shows only the edge, as wide as the token is thick")
    func edgeOn() {
        let projection = TokenProjection(yaw: 90, thickness: thickness)
        #expect(projection.faceScale < 1e-9)
        #expect(abs(projection.extrude * 2 - thickness) < 1e-9)
        #expect(abs(projection.edgeExposure - 1) < 1e-9)
    }

    @Test("Half a turn shows the back, and whole turns the front", arguments: [180.0, 540.0])
    func back(yaw: Double) {
        #expect(!TokenProjection(yaw: yaw, thickness: thickness).showsFront)
        #expect(TokenProjection(yaw: yaw + 180, thickness: thickness).showsFront)
    }

    @Test("The visible face sits flush with one side of the edge", arguments: [20.0, 60.0, 130.0, 250.0, 700.0])
    func faceIsFlush(yaw: Double) {
        let projection = TokenProjection(yaw: yaw, thickness: thickness)
        let halfWidth = HeroMetrics.tokenWidth / 2
        let silhouette = halfWidth * projection.faceScale + projection.extrude
        let faceEdge = abs(projection.faceOffset) + halfWidth * projection.faceScale
        #expect(abs(silhouette - faceEdge) < 1e-9)
    }
}

struct ArcLayoutTests {
    @Test("Lettering is centred on twelve o'clock across the top", arguments: ["10 DAY STREAK", "AXA", "W"])
    func centredOnTop(text: String) throws {
        let positions = ArcLayout.positions(for: text, placement: .top, degreesPerCharacter: 9)
        let first = try #require(positions.first)
        let last = try #require(positions.last)
        let firstWidth = ArcLayout.relativeWidth(try #require(text.first)) * 9 / 2
        let lastWidth = ArcLayout.relativeWidth(try #require(text.last)) * 9 / 2
        // The outer edges of the first and last letters sit symmetrically about the top.
        #expect(abs((first.angle - firstWidth + 90) + (last.angle + lastWidth + 90)) < 1e-9)
    }

    @Test("Top lettering runs clockwise; bottom lettering runs the other way so both read left to right")
    func readsLeftToRight() {
        let top = ArcLayout.positions(for: "STREAK", placement: .top, degreesPerCharacter: 9)
        let bottom = ArcLayout.positions(for: "STREAK", placement: .bottom, degreesPerCharacter: 9)
        #expect(zip(top, top.dropFirst()).allSatisfy { $0.angle < $1.angle })
        #expect(zip(bottom, bottom.dropFirst()).allSatisfy { $0.angle > $1.angle })
    }

    @Test("Letters stand square to the circle")
    func upright() {
        for position in ArcLayout.positions(for: "10 DAY STREAK", placement: .top, degreesPerCharacter: 9) {
            #expect(abs(position.rotation - (position.angle + 90)) < 1e-9)
        }
        for position in ArcLayout.positions(for: "• • •", placement: .bottom, degreesPerCharacter: 9) {
            #expect(abs(position.rotation - (position.angle - 90)) < 1e-9)
        }
    }

    @Test("Narrow characters take less of the arc than wide ones")
    func widths() {
        #expect(ArcLayout.relativeWidth("I") < ArcLayout.relativeWidth("A"))
        #expect(ArcLayout.relativeWidth("W") > ArcLayout.relativeWidth("A"))
    }
}

struct CoinLightTests {
    @Test("Face-on, the gold sits between champagne and peach")
    func faceOn() {
        let light = CoinLight(yaw: 0)
        #expect(light.champagne > 0.3 && light.champagne < 0.8)
        #expect(light.peach > 0.1 && light.peach < 0.5)
    }

    @Test("Swaying one way goes champagne, the other way goes peach")
    func sway() {
        let towards = CoinLight(yaw: CelebrationTimeline.restingYaw + 14)
        let away = CoinLight(yaw: CelebrationTimeline.restingYaw - 14)
        #expect(towards.champagne > away.champagne)
        #expect(away.peach > towards.peach)
        #expect(towards.facing > away.facing)
    }

    @Test("Stays within its ranges all the way round", arguments: stride(from: -180.0, through: 900, by: 7.5).map { $0 })
    func ranges(yaw: Double) {
        let light = CoinLight(yaw: yaw)
        #expect((0...1).contains(light.facing))
        #expect((0...0.8).contains(light.champagne))
        #expect((0...0.5).contains(light.peach))
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
    @Test("The burst only exists after landing and then settles")
    func burstLifetime() {
        #expect(ParticleField.burst(at: -0.01, halfWidth: 66, halfHeight: 102).isEmpty)
        #expect(ParticleField.burst(at: 0, halfWidth: 66, halfHeight: 102).count == ParticleField.burstCount)
        #expect(ParticleField.burst(at: ParticleField.burstMaxLifetime, halfWidth: 66, halfHeight: 102).isEmpty)
    }

    @Test("The burst starts on the token's outline and flies outwards")
    func burstSpreads() {
        let distance = { (particles: [Particle]) in
            particles.map { ($0.x * $0.x + $0.y * $0.y).squareRoot() }
        }
        #expect(distance(ParticleField.burst(at: 0, halfWidth: 66, halfHeight: 102)).allSatisfy { $0 >= 65 })
        let early = distance(ParticleField.burst(at: 0.05, halfWidth: 66, halfHeight: 102)).max() ?? 0
        let later = distance(ParticleField.burst(at: 0.6, halfWidth: 66, halfHeight: 102)).max() ?? 0
        #expect(later > early)
    }

    @Test("Falling flakes stay in their lane and keep falling", arguments: [0.0, 1.3, 7.9, 60.0])
    func flakesFall(time: Double) {
        let flakes = ParticleField.flakes(at: time, width: 390, height: 844)
        #expect(flakes.count == ParticleField.flakeCount)
        for flake in flakes {
            #expect(flake.y >= -20 && flake.y < 844 + 20)
            #expect(flake.x > -30 && flake.x < 390 + 30)
        }
    }

    @Test("Flakes stay well-formed", arguments: [0.0, 0.3, 1.0, 2.5, 7.0, 15.0])
    func wellFormed(time: Double) {
        let all = ParticleField.burst(at: time, halfWidth: 66, halfHeight: 102)
            + ParticleField.flakes(at: time, width: 390, height: 844)
        for flake in all {
            #expect((0...1).contains(flake.opacity))
            #expect(flake.width > 0 && flake.height > 0)
            #expect((0...2).contains(flake.tint))
        }
    }

    @Test("Flakes are deterministic")
    func deterministic() {
        #expect(ParticleField.burst(at: 0.4, halfWidth: 66, halfHeight: 102) == ParticleField.burst(at: 0.4, halfWidth: 66, halfHeight: 102))
        #expect(ParticleField.flakes(at: 5.2, width: 390, height: 844) == ParticleField.flakes(at: 5.2, width: 390, height: 844))
    }

    @Test("Noise stays in the unit interval")
    func noiseRange() {
        for index in -500..<500 {
            let value = Noise.unit(index, 7)
            #expect(value >= 0 && value < 1)
        }
    }
}
