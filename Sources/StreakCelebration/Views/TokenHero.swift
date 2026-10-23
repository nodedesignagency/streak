import SwiftUI

/// The coin spinning in and landing, with the warm light behind it and gold leaf thrown off as it lands.
struct TokenHero: View {
    var clock: CelebrationClock
    var previousStreak: Int
    var streak: Int
    var earnedOn: String
    var palette: StreakPalette

    var body: some View {
        TimelineView(.animation(paused: clock.reduceMotion)) { context in
            let time = clock.elapsed(at: context.date)
            let frame = CelebrationTimeline.frame(at: time, idleMotion: !clock.reduceMotion)
            ZStack {
                ambience(frame)
                shadow(frame)
                Token(
                    frame: frame,
                    count: frame.showsNewCount ? streak : previousStreak,
                    streak: streak,
                    earnedOn: earnedOn,
                    palette: palette
                )
                burst(at: time)
            }
            .frame(width: HeroMetrics.canvasSize, height: HeroMetrics.canvasSize)
        }
        .frame(width: HeroMetrics.canvasSize, height: HeroMetrics.canvasSize)
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(streak) day streak"))
    }

    // MARK: Layers

    private func ambience(_ frame: CelebrationFrame) -> some View {
        Circle()
            .fill(RadialGradient(
                colors: [palette.glow.opacity(0.28), palette.glow.opacity(0)],
                center: .center, startRadius: 0, endRadius: 170
            ))
            .frame(width: 340, height: 340)
            .opacity(frame.glow)
    }

    /// A soft contact shadow that narrows with the token as it turns and fades as it lifts.
    private func shadow(_ frame: CelebrationFrame) -> some View {
        let projection = TokenProjection(yaw: frame.tokenYaw, thickness: HeroMetrics.tokenThickness)
        let width = (HeroMetrics.tokenWidth * projection.faceScale + projection.extrude * 2) * 0.85
        return Ellipse()
            .fill(Color.black.opacity(0.6))
            .frame(width: max(width, 12), height: 18)
            .blur(radius: 10)
            .opacity(1 - min(max(frame.tokenLift, 0) / 40, 0.5))
            .offset(y: HeroMetrics.tokenHeight / 2 + 20)
    }

    private func burst(at time: Double) -> some View {
        let flakes = ParticleField.burst(
            at: time - CelebrationTimeline.land,
            halfWidth: HeroMetrics.tokenWidth / 2,
            halfHeight: HeroMetrics.tokenHeight / 2
        )
        return GoldLeafCanvas(flakes: flakes, origin: .center, colors: palette.flakes)
            .frame(width: HeroMetrics.particleCanvasSize, height: HeroMetrics.particleCanvasSize)
    }
}

/// Gold leaf falling across the whole screen once the token has landed.
struct GoldLeafRain: View {
    var clock: CelebrationClock
    var palette: StreakPalette

    var body: some View {
        if !clock.reduceMotion {
            TimelineView(.animation) { context in
                let time = clock.elapsed(at: context.date)
                let opacity = CelebrationTimeline.frame(at: time).flakesOpacity
                GeometryReader { proxy in
                    GoldLeafCanvas(
                        flakes: ParticleField.flakes(
                            at: time - CelebrationTimeline.land,
                            width: Double(proxy.size.width),
                            height: Double(proxy.size.height)
                        ),
                        origin: .topLeading,
                        colors: palette.flakes
                    )
                }
                .opacity(opacity)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

/// Draws flakes of gold leaf relative to an origin within the canvas.
private struct GoldLeafCanvas: View {
    var flakes: [Particle]
    var origin: UnitPoint
    var colors: [Color]

    var body: some View {
        Canvas { context, size in
            let originX = Double(size.width) * Double(origin.x)
            let originY = Double(size.height) * Double(origin.y)
            for flake in flakes {
                var layer = context
                layer.opacity = flake.opacity
                layer.translateBy(x: originX + flake.x, y: originY + flake.y)
                layer.rotate(by: .radians(flake.rotation))
                let rect = CGRect(x: -flake.width / 2, y: -flake.height / 2, width: flake.width, height: flake.height)
                layer.fill(Path(rect), with: .color(colors[flake.tint % colors.count]))
            }
        }
    }
}
