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
    @Test("Opens facing front, at rest")
    func opensAtRest() {
        let frame = CelebrationTimeline.frame(at: 0)
        #expect(frame.tokenYaw == 0)
        #expect(frame.tokenLift == 0)
        #expect(frame.tokenScale == 1)
    }

    @Test("Winds up the other way before it spins")
    func windsUp() {
        #expect(CelebrationTimeline.frame(at: CelebrationTimeline.spin).tokenYaw < 0)
    }

    @Test("Shows its back twice in the spin, once per turn, before it lands")
    func backGoesByTwice() {
        var passes = 0
        var wasShowingBack = false
        for time in stride(from: 0.0, through: CelebrationTimeline.land, by: 1.0 / 240) {
            let frame = CelebrationTimeline.frame(at: time)
            let showingBack = !TokenProjection(yaw: frame.tokenYaw, thickness: HeroMetrics.tokenThickness).showsFront
            if showingBack && !wasShowingBack {
                passes += 1
            }
            wasShowingBack = showingBack
        }
        #expect(passes == 2)
    }

    @Test("Has come back down by the time it lands")
    func landsLow() {
        #expect(abs(CelebrationTimeline.frame(at: CelebrationTimeline.land).tokenLift) < 4)
    }

    @Test("Settles face-on after exactly two turns")
    func settles() {
        let frame = CelebrationTimeline.frame(at: CelebrationTimeline.restingTime, idleMotion: false)
        #expect(abs(frame.tokenYaw - CelebrationTimeline.restingYaw) < 0.5)
        #expect(abs(frame.tokenScale - 1) < 0.01)
        #expect(abs(frame.tokenLift) < 0.1)
    }

    @Test("Without idle motion it never turns again")
    func staysPutForReduceMotion() {
        for time in stride(from: CelebrationTimeline.restingTime, through: 40, by: 0.25) {
            #expect(abs(CelebrationTimeline.frame(at: time, idleMotion: false).tokenYaw - CelebrationTimeline.restingYaw) < 0.5)
        }
    }

    @Test("Between idle turns it rests face-on, swaying gently")
    func restsBetweenTurns() {
        for time in stride(from: 3.0, through: 40, by: 0.01) {
            let frame = CelebrationTimeline.frame(at: time)
            #expect(abs(frame.tokenLift) <= 3.5)
            let sinceStart = time - CelebrationTimeline.idleSpinStart
            let turning = sinceStart >= 0
                && sinceStart.truncatingRemainder(dividingBy: CelebrationTimeline.idleSpinInterval) < CelebrationTimeline.idleSpinDuration
            if !turning {
                let offset = (frame.tokenYaw - CelebrationTimeline.restingYaw).truncatingRemainder(dividingBy: 360)
                #expect(abs(offset) <= 15 || abs(offset) >= 345)
            }
        }
    }

    @Test("Turns a full circle every few seconds once settled")
    func turnsAgain() {
        let spins = 3.0
        let time = CelebrationTimeline.idleSpinStart + spins * CelebrationTimeline.idleSpinInterval - 0.01
        let frame = CelebrationTimeline.frame(at: time)
        let turned = frame.tokenYaw - CelebrationTimeline.restingYaw
        #expect(abs(turned - spins * 360) <= 15)
        #expect(CelebrationTimeline.idleSpinStart > CelebrationTimeline.restingTime)
    }

    @Test("Beats run in order and finish before the resting time")
    func beatsInOrder() {
        let beats = [
            CelebrationTimeline.anticipate, CelebrationTimeline.spin, CelebrationTimeline.land,
            CelebrationTimeline.details, CelebrationTimeline.actions,
        ]
        #expect(beats == beats.sorted())
        #expect(CelebrationTimeline.actions < CelebrationTimeline.restingTime)
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

struct TokenLightTests {
    @Test("Face-on, the chrome catches some of the light but not all of it")
    func faceOn() {
        let light = TokenLight(yaw: 0)
        #expect(light.glint > 0.3 && light.glint < 0.8)
    }

    @Test("Swaying towards the light glints and brightens the hot spot; swaying away dims both")
    func sway() {
        let towards = TokenLight(yaw: CelebrationTimeline.restingYaw + 14)
        let away = TokenLight(yaw: CelebrationTimeline.restingYaw - 14)
        #expect(towards.glint > away.glint)
        #expect(towards.facing > away.facing)
    }

    @Test("Stays within its ranges all the way round", arguments: stride(from: -180.0, through: 900, by: 7.5).map { $0 })
    func ranges(yaw: Double) {
        let light = TokenLight(yaw: yaw)
        #expect((0...1).contains(light.facing))
        #expect((0...0.8).contains(light.glint))
    }
}

struct BadgeOutlineTests {
    let rect = CGRect(x: 10, y: 20, width: HeroMetrics.tokenWidth, height: HeroMetrics.tokenHeight)
    var radius: Double { BadgeOutline.cornerRadius * HeroMetrics.tokenWidth }

    func bounds(_ points: [CGPoint]) -> (minX: Double, maxX: Double, minY: Double, maxY: Double) {
        (
            points.map { Double($0.x) }.min() ?? 0, points.map { Double($0.x) }.max() ?? 0,
            points.map { Double($0.y) }.min() ?? 0, points.map { Double($0.y) }.max() ?? 0
        )
    }

    @Test("Face-on it fills its rect: flat sides left and right, rounded points top and bottom")
    func faceOn() {
        let points = BadgeOutline.points(in: rect, radius: radius)
        let box = bounds(points)
        #expect(abs(box.minX - Double(rect.minX)) < 1e-9 && abs(box.maxX - Double(rect.maxX)) < 1e-9)
        #expect(abs(box.minY - Double(rect.minY)) < 1e-9 && abs(box.maxY - Double(rect.maxY)) < 1e-9)
        let top = points.filter { abs(Double($0.y) - Double(rect.minY)) < 1e-9 }
        #expect(top.allSatisfy { abs(Double($0.x) - Double(rect.midX)) < 1e-9 })
        // The flat sides are vertical: both ends of the right one sit on the rect's right edge.
        #expect(points.filter { abs(Double($0.x) - Double(rect.maxX)) < 1e-9 }.count >= 2)
    }

    @Test("Mid-spin each half is squashed and pushed out, opening the points into flats")
    func midSpin() {
        let squash = 0.4
        let extrude = 6.0
        let points = BadgeOutline.points(in: rect, radius: radius, squash: squash, extrude: extrude)
        let box = bounds(points)
        #expect(abs((box.maxX - box.minX) - (Double(rect.width) * squash + 2 * extrude)) < 1e-9)
        let top = points.filter { abs(Double($0.y) - Double(rect.minY)) < 1e-9 }.map { Double($0.x) }
        #expect(abs((top.min() ?? 0) - (Double(rect.midX) - extrude)) < 1e-9)
        #expect(abs((top.max() ?? 0) - (Double(rect.midX) + extrude)) < 1e-9)
    }

    @Test("The slanted sides run at 30 degrees, like the artwork's")
    func slant() {
        let steps = 8
        let points = BadgeOutline.points(in: rect, radius: radius, stepsPerCorner: steps)
        // The end of the top corner's right half, then the start of the top-right corner.
        let from = points[steps / 2]
        let to = points[steps / 2 + 1]
        let angle = atan2(Double(to.y - from.y), Double(to.x - from.x)) * 180 / .pi
        #expect(abs(angle - 30) < 1e-9)
    }

    @Test("An inset outline runs parallel to the edge")
    func inset() {
        let inset = 12.0
        let outer = BadgeOutline.points(in: rect, radius: radius, stepsPerCorner: 32)
        let inner = BadgeOutline.points(in: rect.insetBy(dx: inset, dy: inset), radius: radius - inset)
        func distance(_ point: CGPoint) -> Double {
            zip(outer, outer.dropFirst() + [outer[0]]).map { start, end in
                let dx = Double(end.x - start.x), dy = Double(end.y - start.y)
                let length = max(dx * dx + dy * dy, 1e-12)
                let t = min(max((Double(point.x - start.x) * dx + Double(point.y - start.y) * dy) / length, 0), 1)
                let x = Double(start.x) + t * dx - Double(point.x), y = Double(start.y) + t * dy - Double(point.y)
                return (x * x + y * y).squareRoot()
            }.min() ?? 0
        }
        for point in inner {
            #expect(abs(distance(point) - inset) < 0.05)
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
