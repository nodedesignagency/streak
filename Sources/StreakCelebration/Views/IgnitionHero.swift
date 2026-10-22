import SwiftUI

/// Where the celebration is in time. Every animated view reads elapsed time from the same clock, so the
/// hero, the week bar and the stage changes can never drift apart.
struct CelebrationClock: Equatable {
    var start: Date?
    var reduceMotion: Bool

    func elapsed(at date: Date) -> TimeInterval {
        if reduceMotion { return IgnitionTimeline.restingTime }
        guard let start else { return 0 }
        return max(0, date.timeIntervalSince(start))
    }
}

/// The dormant flame igniting: squash, launch, flash, shockwave, then a lit flame that keeps flickering.
struct IgnitionHero: View {
    var clock: CelebrationClock
    var palette: StreakPalette

    var body: some View {
        TimelineView(.animation(paused: clock.reduceMotion)) { context in
            let time = clock.elapsed(at: context.date)
            let frame = IgnitionTimeline.frame(at: time, idleMotion: !clock.reduceMotion)
            ZStack {
                ambience(frame, time: time)
                dormantFlame(frame)
                orb(frame)
                shockwave(frame)
                seed(frame)
                litFlame(frame)
                particles(time: time)
            }
            .frame(width: HeroMetrics.canvasWidth, height: HeroMetrics.canvasHeight)
        }
        .frame(width: HeroMetrics.canvasWidth, height: HeroMetrics.canvasHeight)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: Layers

    private func ambience(_ frame: IgnitionFrame, time: Double) -> some View {
        let center = CGPoint(x: HeroMetrics.midX, y: HeroMetrics.baseline - HeroMetrics.flameHeight / 2)
        return ZStack {
            SunburstShape()
                .fill(RadialGradient(
                    colors: [palette.glow.opacity(0.16), palette.glow.opacity(0)],
                    center: .center, startRadius: 40, endRadius: 190
                ))
                .frame(width: 380, height: 380)
                .rotationEffect(.degrees(time * 5))
                .opacity(frame.rays)
                .position(center)

            Circle()
                .fill(RadialGradient(
                    colors: [palette.glow.opacity(0.32), palette.glow.opacity(0)],
                    center: .center, startRadius: 0, endRadius: 150
                ))
                .frame(width: 300, height: 300)
                .scaleEffect(0.6 + 0.4 * frame.glow)
                .opacity(frame.glow)
                .position(center)
        }
    }

    private func dormantFlame(_ frame: IgnitionFrame) -> some View {
        let size = CGSize(width: HeroMetrics.flameWidth, height: HeroMetrics.flameHeight)
        return ZStack {
            groundShadow(color: .black.opacity(0.06), width: 84)
            FlameView(style: .dormant, size: size, palette: palette)
                .scaleEffect(x: frame.dormantScaleX, y: frame.dormantScaleY, anchor: .bottom)
                .position(x: HeroMetrics.midX, y: HeroMetrics.baseline - HeroMetrics.flameHeight / 2)
        }
        .opacity(frame.dormantOpacity)
    }

    private func orb(_ frame: IgnitionFrame) -> some View {
        let diameter = HeroMetrics.orbDiameter
        let width = diameter * frame.orbScaleX
        let height = diameter * frame.orbScaleY
        let centerY = HeroMetrics.baseline - frame.orbLift - height / 2
        let hot = min(frame.orbHeat, 1)
        return ZStack {
            // Ring left on the ground by the launch, seen in perspective.
            Ellipse()
                .stroke(palette.flame[1], lineWidth: 5)
                .frame(width: 96 * frame.haloScale, height: 26 * frame.haloScale)
                .opacity(frame.haloOpacity)
                .position(x: HeroMetrics.midX, y: HeroMetrics.baseline - 6)

            ZStack {
                Ellipse().fill(palette.orbColor(heat: frame.orbHeat))
                // A hot core that brightens as the orb heats up.
                Ellipse()
                    .fill(palette.flameCore[0])
                    .frame(width: width * 0.36, height: height * 0.36)
                    .offset(x: -width * 0.08 * (2 - frame.orbHeat), y: -height * 0.1)
                    .opacity(0.85 * hot)
            }
            .frame(width: width, height: height)
            .opacity(frame.orbOpacity)
            .position(x: HeroMetrics.midX, y: centerY)
        }
    }

    private func shockwave(_ frame: IgnitionFrame) -> some View {
        let diameter = HeroMetrics.orbDiameter * HeroMetrics.orbSwell * frame.waveScale
        let center = CGPoint(x: HeroMetrics.midX, y: HeroMetrics.burstY)
        return ZStack {
            Circle()
                .strokeBorder(palette.flame[1], lineWidth: max(1, diameter / 2 * frame.waveThickness))
                .frame(width: diameter, height: diameter)
                .opacity(frame.waveOpacity)

            // A star punched out of the disc for a couple of frames, the way a lens flare burns in.
            SparkleShape(points: 8, pinch: 0.42)
                .fill(palette.background)
                .frame(width: diameter * 0.8, height: diameter * 0.8)
                .rotationEffect(.degrees(frame.flashRotation))
                .opacity(frame.cutoutOpacity)

            SparkleShape(points: 4, pinch: 0.2)
                .fill(palette.flame[1])
                .frame(width: 80 * frame.flashScale, height: 80 * frame.flashScale)
                .rotationEffect(.degrees(frame.flashRotation))
                .opacity(frame.flashOpacity)
        }
        .position(center)
    }

    private func seed(_ frame: IgnitionFrame) -> some View {
        let width = HeroMetrics.seedWidth * frame.seedScale
        let height = HeroMetrics.seedHeight * frame.seedScale
        return DropShape()
            .fill(LinearGradient(colors: palette.flame, startPoint: .top, endPoint: .bottom))
            .overlay {
                DropShape()
                    .fill(palette.flameCore[0])
                    .frame(width: width * 0.4, height: height * 0.4)
                    .offset(y: height * 0.16)
            }
            .frame(width: width, height: height)
            .opacity(frame.seedOpacity)
            .position(x: HeroMetrics.midX, y: HeroMetrics.baseline - frame.seedLift - height / 2)
    }

    private func litFlame(_ frame: IgnitionFrame) -> some View {
        let size = CGSize(width: HeroMetrics.flameWidth, height: HeroMetrics.flameHeight)
        return ZStack {
            groundShadow(color: palette.flame[1].opacity(0.45), width: 92 * frame.flameScaleX)
            FlameView(style: .lit, sway: frame.flameSway, size: size, palette: palette)
                .scaleEffect(x: frame.flameScaleX, y: frame.flameScaleY, anchor: .bottom)
                .position(x: HeroMetrics.midX, y: HeroMetrics.baseline - HeroMetrics.flameHeight / 2)
        }
        .opacity(frame.flameOpacity)
    }

    private func particles(time: Double) -> some View {
        let palette = palette
        let reduceMotion = clock.reduceMotion
        let side = 460.0
        return Canvas { context, size in
            let burstOrigin = CGPoint(x: size.width / 2, y: size.height / 2)
            let emberOrigin = CGPoint(
                x: size.width / 2,
                y: size.height / 2 + CGFloat(HeroMetrics.emberY - HeroMetrics.burstY)
            )
            let sparks = ParticleField.sparks(at: time - IgnitionTimeline.burst)
            let embers = reduceMotion ? [] : ParticleField.embers(at: time - IgnitionTimeline.ignite - 0.3)
            for particle in sparks {
                drawParticle(particle, from: burstOrigin, in: context, palette: palette)
            }
            for particle in embers {
                drawParticle(particle, from: emberOrigin, in: context, palette: palette)
            }
        }
        .frame(width: side, height: side)
        .position(x: HeroMetrics.midX, y: HeroMetrics.burstY)
    }

    private func groundShadow(color: Color, width: Double) -> some View {
        Ellipse()
            .fill(color)
            .frame(width: width, height: 14)
            .blur(radius: 6)
            .position(x: HeroMetrics.midX, y: HeroMetrics.baseline + 4)
    }
}

private func drawParticle(_ particle: Particle, from origin: CGPoint, in context: GraphicsContext, palette: StreakPalette) {
    var layer = context
    layer.opacity = particle.opacity
    layer.translateBy(x: origin.x + CGFloat(particle.x), y: origin.y + CGFloat(particle.y))
    layer.rotate(by: .radians(particle.rotation))
    let size = particle.size
    let shape: Path
    if particle.isRound {
        shape = Path(ellipseIn: CGRect(x: -size / 2, y: -size / 2, width: size, height: size))
    } else {
        let height = size * 0.55
        shape = Path(roundedRect: CGRect(x: -size / 2, y: -height / 2, width: size, height: height), cornerRadius: height * 0.3)
    }
    layer.fill(shape, with: .color(palette.particles[particle.tint % palette.particles.count]))
}
