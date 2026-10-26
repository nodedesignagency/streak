import Foundation
import Testing
@testable import StreakCelebration

struct CurveTests {
    @Test("Curves start at zero and end at one", arguments: [
        Curve.linear, .easeIn, .easeOut, .easeInOut, .easeInOutQuad, .backOut, .spring(damping: 0.45), .spring(damping: 0.9),
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
    func frame(at time: Double, idleMotion: Bool = true) -> CelebrationFrame {
        CelebrationTimeline.frame(at: time, idleMotion: idleMotion)
    }

    func yaw(at time: Double, idleMotion: Bool = true) -> Double {
        frame(at: time, idleMotion: idleMotion).tokenYaw
    }

    /// Fastest turning speed, in degrees per second, between two times.
    func peakSpeed(from start: Double, to end: Double) -> Double {
        let step = 1.0 / 240
        return stride(from: start, to: end, by: step).map { (yaw(at: $0) - yaw(at: $0 + step)) / step }.max() ?? 0
    }

    @Test("Opens below the screen at one and a half times its size, in three-quarter view")
    func opensBelow() {
        let opening = frame(at: 0)
        #expect(opening.tokenScale == 1.5)
        #expect(opening.tokenYaw == CelebrationTimeline.startYaw)
        // Off the bottom of the tallest iPhone (956 pt) even if its place were only 250 pt down the screen.
        let topEdge = 250 + opening.tokenDrop - HeroMetrics.tokenHeight * opening.tokenScale / 2
        #expect(topEdge > 956)
    }

    @Test("Rises without stopping and never overshoots its place")
    func rises() {
        var previous = frame(at: 0).tokenDrop
        for time in stride(from: 0.0, through: CelebrationTimeline.restingTime, by: 1.0 / 120) {
            let drop = frame(at: time).tokenDrop
            #expect(drop <= previous + 1e-9)
            #expect(drop >= 0)
            previous = drop
        }
    }

    @Test("Comes to rest all at once: at its place, facing the viewer and at its own size")
    func lands() {
        let landing = frame(at: CelebrationTimeline.land)
        #expect(landing.tokenDrop == 0)
        #expect(abs(landing.tokenYaw - CelebrationTimeline.restingYaw) < 1e-9)
        #expect(landing.tokenScale == 1)
        // Still on its way a moment earlier, on all three counts.
        let before = frame(at: CelebrationTimeline.land - 0.2)
        #expect(before.tokenDrop > 0)
        #expect(before.tokenYaw > CelebrationTimeline.restingYaw)
        #expect(before.tokenScale > 1)
    }

    @Test("Never stops on the way: something is always moving until it settles")
    func neverStops() {
        let step = 1.0 / 240
        for time in stride(from: 0.01, to: CelebrationTimeline.land - 0.05, by: 0.01) {
            let now = frame(at: time)
            let next = frame(at: time + step)
            let turning = abs(next.tokenYaw - now.tokenYaw) / step > 5          // degrees a second
            let rising = abs(next.tokenDrop - now.tokenDrop) / step > 5         // points a second
            let shrinking = abs(next.tokenScale - now.tokenScale) / step > 0.05 // per second
            #expect(turning || rising || shrinking)
        }
    }

    @Test("Only ever turns one way, its right side coming towards the viewer")
    func turnsOneWay() {
        var previous = yaw(at: 0)
        for time in stride(from: 0.0, through: 30, by: 1.0 / 120) {
            let current = yaw(at: time)
            #expect(current <= previous + 1e-9)
            previous = current
        }
    }

    @Test("Shows its back once for each turn on the way up")
    func backGoesByEachTurn() {
        var passes = 0
        var wasShowingBack = false
        for time in stride(from: 0.0, through: CelebrationTimeline.land, by: 1.0 / 240) {
            let showingBack = !TokenProjection(yaw: yaw(at: time), thickness: HeroMetrics.tokenThickness).showsFront
            if showingBack && !wasShowingBack {
                passes += 1
            }
            wasShowingBack = showingBack
        }
        #expect(passes == 1 + Int(CelebrationTimeline.entranceTurns))
    }

    @Test("Spins in fast, nearly three turns, and winds down without ever speeding up again")
    func spinsInFast() {
        let turns = (CelebrationTimeline.startYaw - CelebrationTimeline.restingYaw) / 360
        #expect(turns > 2.5 && turns < 3)
        let step = 1.0 / 240
        func speed(at time: Double) -> Double { (yaw(at: time) - yaw(at: time + step)) / step }
        let idleStart = CelebrationTimeline.idleSpinStart
        let idlePeak = peakSpeed(from: idleStart, to: idleStart + CelebrationTimeline.idleSpinDuration)
        // Coming up into view it spins at several times the speed of its idle turns: about four turns a second.
        #expect(speed(at: 0.15) > 5 * idlePeak)
        #expect(speed(at: 0.15) > 4 * 360)
        var previous = speed(at: 0)
        for time in stride(from: step, to: CelebrationTimeline.land, by: step) {
            let current = speed(at: time)
            #expect(current <= previous + 1e-6)
            previous = current
        }
        #expect(speed(at: CelebrationTimeline.land) == 0)
    }

    @Test("Starts shrinking while it is still rising and turning, and finishes as it lands")
    func shrinksOnTheWay() {
        let starting = frame(at: CelebrationTimeline.shrink)
        #expect(starting.tokenScale == CelebrationTimeline.entranceScale)
        #expect(starting.tokenDrop > 0)
        #expect(starting.tokenYaw > CelebrationTimeline.restingYaw + 90)
        #expect(CelebrationTimeline.details >= CelebrationTimeline.land)
        var previous = CelebrationTimeline.entranceScale
        for time in stride(from: 0.0, through: CelebrationTimeline.restingTime, by: 1.0 / 120) {
            let scale = frame(at: time).tokenScale
            #expect(scale <= previous + 1e-9 && scale >= 1)
            previous = scale
        }
        // No jump: it is barely changing size as the shrink starts and as it ends.
        let step = 1.0 / 240
        let startRate = (CelebrationTimeline.entranceScale - frame(at: CelebrationTimeline.shrink + step).tokenScale) / step
        let endRate = (frame(at: CelebrationTimeline.land - step).tokenScale - 1) / step
        #expect(startRate < 0.01 && endRate < 0.01)
    }

    @Test("Settles face-on at its own size and place")
    func settles() {
        let settled = frame(at: CelebrationTimeline.restingTime, idleMotion: false)
        #expect(abs(settled.tokenYaw - CelebrationTimeline.restingYaw) < 1e-9)
        #expect(settled.tokenScale == 1)
        #expect(settled.tokenDrop == 0)
        let projection = TokenProjection(yaw: CelebrationTimeline.restingYaw, thickness: HeroMetrics.tokenThickness)
        #expect(projection.showsFront && abs(projection.faceScale - 1) < 1e-9)
    }

    @Test("Without idle motion it never turns again")
    func staysPutForReduceMotion() {
        for time in stride(from: CelebrationTimeline.restingTime, through: 40, by: 0.25) {
            #expect(abs(yaw(at: time, idleMotion: false) - CelebrationTimeline.restingYaw) < 1e-9)
        }
    }

    @Test("Between turns it rests face-on and perfectly still")
    func restsBetweenTurns() {
        for time in stride(from: CelebrationTimeline.land, through: 40, by: 0.01) {
            let sinceStart = time - CelebrationTimeline.idleSpinStart
            let turning = sinceStart >= 0
                && sinceStart.truncatingRemainder(dividingBy: CelebrationTimeline.idleSpinInterval) < CelebrationTimeline.idleSpinDuration
            if !turning {
                let offset = (yaw(at: time) - CelebrationTimeline.restingYaw).truncatingRemainder(dividingBy: 360)
                #expect(abs(offset) < 1e-9)
            }
        }
    }

    @Test("Turns a full circle every few seconds once settled")
    func turnsAgain() {
        let spins = 3.0
        let time = CelebrationTimeline.idleSpinStart + spins * CelebrationTimeline.idleSpinInterval - 0.01
        #expect(abs(CelebrationTimeline.restingYaw - yaw(at: time) - spins * 360) < 1e-9)
        #expect(CelebrationTimeline.idleSpinStart > CelebrationTimeline.restingTime)
        #expect(CelebrationTimeline.idleSpinDuration < CelebrationTimeline.idleSpinInterval)
    }

    @Test("Beats run in order and finish before the resting time")
    func beatsInOrder() {
        let beats = [
            CelebrationTimeline.spin, CelebrationTimeline.shrink, CelebrationTimeline.land,
            CelebrationTimeline.details, CelebrationTimeline.actions,
        ]
        #expect(beats == beats.sorted())
        #expect(CelebrationTimeline.actions < CelebrationTimeline.restingTime)
    }
}

struct GlowTests {
    func glow(at time: Double, idleMotion: Bool = true) -> GlowFrame {
        CelebrationTimeline.glow(at: time, idleMotion: idleMotion)
    }

    @Test("Draws in from nothing while the badge rises, and is whole as it lands")
    func drawsIn() {
        #expect(glow(at: 0).reveal == 0)
        #expect(glow(at: CelebrationTimeline.land).reveal == 1)
        var previous = 0.0
        for time in stride(from: 0.0, through: CelebrationTimeline.restingTime, by: 1.0 / 120) {
            let reveal = glow(at: time).reveal
            #expect(reveal >= previous && reveal <= 1)
            previous = reveal
        }
        // Half-way round (up the sides) half-way through the rise.
        #expect(abs(glow(at: CelebrationTimeline.land / 2).reveal - 0.5) < 1e-9)
    }

    @Test("Keeps its normal width while it draws in, then pulses: thin and faint, and back")
    func pulses() {
        for time in stride(from: 0.0, through: CelebrationTimeline.glowPulseStart, by: 0.01) {
            #expect(glow(at: time).thinning == 0)
        }
        let start = CelebrationTimeline.glowPulseStart
        let period = CelebrationTimeline.glowPulsePeriod
        #expect(abs(glow(at: start + period / 2).thinning - 1) < 1e-9)
        #expect(abs(glow(at: start + period).thinning) < 1e-9)
        for time in stride(from: start, through: start + 4 * period, by: 0.01) {
            let now = glow(at: time)
            #expect((0...1).contains(now.thinning))
            #expect(abs(now.thinning - glow(at: time + period).thinning) < 1e-9)
        }
    }

    @Test("At its thinnest it is narrower, sharper and fainter than at its normal")
    func thinnest() {
        let normal = GlowFrame(reveal: 1, thinning: 0)
        let thin = GlowFrame(reveal: 1, thinning: 1)
        #expect(normal.bandWidth == 28 && normal.blurRadius == 14 && normal.strength == 1)
        #expect(thin.bandWidth < normal.bandWidth)
        #expect(thin.blurRadius < normal.blurRadius)
        #expect(thin.strength < normal.strength && thin.strength >= 0.6)
    }

    @Test("With Reduce Motion it is whole and still")
    func reduceMotion() {
        for time in stride(from: CelebrationTimeline.restingTime, through: 30, by: 0.1) {
            let still = glow(at: time, idleMotion: false)
            #expect(still.reveal == 1 && still.thinning == 0)
        }
    }
}

struct WarpFieldTests {
    let reach = 560.0

    @Test("Plays the same way every time")
    func deterministic() {
        #expect(WarpField.streaks(at: 1.234, reach: reach) == WarpField.streaks(at: 1.234, reach: reach))
        #expect(WarpField.streaks(at: 0, reach: reach).count == WarpField.count)
    }

    @Test("Every streak points straight out from the centre, its bright head beyond its tail")
    func radial() {
        for time in stride(from: 0.0, through: 6, by: 0.37) {
            for streak in WarpField.streaks(at: time, reach: reach) {
                let tail = (Double(streak.tail.x) * Double(streak.tail.x) + Double(streak.tail.y) * Double(streak.tail.y)).squareRoot()
                let head = (Double(streak.head.x) * Double(streak.head.x) + Double(streak.head.y) * Double(streak.head.y)).squareRoot()
                #expect(head >= tail)
                // Same direction: the cross product of the two ends is zero.
                let cross = Double(streak.tail.x) * Double(streak.head.y) - Double(streak.tail.y) * Double(streak.head.x)
                #expect(abs(cross) < 1e-6 * max(head * head, 1))
                // Starts tucked in behind the badge, never further out than past the corners.
                #expect(tail >= 0.85 * WarpField.startFraction * reach - 1e-9)
                #expect(head <= 1.15 * WarpField.endFraction * reach + 1e-9)
                #expect((0...1).contains(streak.opacity) && streak.width > 0)
                #expect((0...2).contains(streak.colour))
            }
        }
    }

    @Test("Streaks speed up and stretch as they come, and never pop in or out")
    func perspective() {
        let step = 1.0 / 240
        var previous = WarpField.streaks(at: 0, reach: reach)
        for time in stride(from: step, through: 4, by: step) {
            let field = WarpField.streaks(at: time, reach: reach)
            for (before, now) in zip(previous, field) {
                let wasOut = Double(before.head.x).magnitude + Double(before.head.y).magnitude
                let isOut = Double(now.head.x).magnitude + Double(now.head.y).magnitude
                if isOut < wasOut {
                    // It has started again from the centre: both moments are all but invisible.
                    #expect(before.opacity < 0.05 && now.opacity < 0.05)
                } else {
                    #expect(abs(now.opacity - before.opacity) < 0.1)
                }
            }
            previous = field
        }
    }

    @Test("Fades in as the screen opens")
    func fadesIn() {
        #expect(WarpField.visibility(at: 0) == 0)
        #expect(WarpField.visibility(at: WarpField.fadeIn) == 1)
        #expect(WarpField.visibility(at: 10) == 1)
    }

    @Test("Its pseudo-random numbers are spread across 0..<1")
    func randomness() {
        let values = (0..<2000).map { WarpField.random($0, 7) }
        #expect(values.allSatisfy { (0..<1).contains($0) })
        let mean = values.reduce(0, +) / Double(values.count)
        #expect(abs(mean - 0.5) < 0.03)
        #expect(Set(values).count == values.count)
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

    @Test("Turned towards the light the chrome glints and the hot spot brightens; turned away both dim")
    func turning() {
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
