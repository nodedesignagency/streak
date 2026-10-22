import SwiftUI

/// The ring closing, the medallion flipping to gold and landing, and the dust and motes around it.
struct MedallionHero: View {
    var clock: CelebrationClock
    var palette: StreakPalette

    var body: some View {
        TimelineView(.animation(paused: clock.reduceMotion)) { context in
            let time = clock.elapsed(at: context.date)
            let frame = CelebrationTimeline.frame(at: time, idleMotion: !clock.reduceMotion)
            ZStack {
                ambience(frame)
                particles(motesAt: time)
                ring(frame)
                Medallion(frame: frame, palette: palette)
                particles(dustAt: time)
            }
            .frame(width: HeroMetrics.canvasSize, height: HeroMetrics.canvasSize)
        }
        .frame(width: HeroMetrics.canvasSize, height: HeroMetrics.canvasSize)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: Layers

    private func ambience(_ frame: CelebrationFrame) -> some View {
        Circle()
            .fill(RadialGradient(
                colors: [palette.glow.opacity(0.30), palette.glow.opacity(0)],
                center: .center, startRadius: 0, endRadius: 170
            ))
            .frame(width: 340, height: 340)
            .opacity(frame.glow)
    }

    private func ring(_ frame: CelebrationFrame) -> some View {
        let diameter = HeroMetrics.ringDiameter
        let width = HeroMetrics.ringWidth
        let headAngle = (frame.ringProgress * 360 - 90) * .pi / 180
        return ZStack {
            Circle()
                .stroke(palette.track, lineWidth: width)

            // Symmetric around the circle so the closed ring has no seam where it started.
            Circle()
                .trim(from: 0, to: frame.ringProgress)
                .stroke(
                    AngularGradient(
                        colors: [palette.gold[1], palette.gold[0], palette.gold[1], palette.gold[2], palette.gold[1]],
                        center: .center,
                        angle: .zero
                    ),
                    style: StrokeStyle(lineWidth: width, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: palette.glow.opacity(0.8 * min(frame.ringGlow, 1)), radius: 10)

            // The bright head that leads the ring round.
            Circle()
                .fill(palette.goldHighlight)
                .frame(width: 14, height: 14)
                .shadow(color: palette.glow, radius: 8)
                .offset(x: cos(headAngle) * diameter / 2, y: sin(headAngle) * diameter / 2)
                .opacity(frame.cometOpacity)

            // A thin echo that pulses out when the medallion lands.
            Circle()
                .stroke(palette.gold[1], lineWidth: 2)
                .frame(width: diameter * frame.haloScale, height: diameter * frame.haloScale)
                .opacity(frame.haloOpacity)
        }
        .frame(width: diameter, height: diameter)
    }

    private func particles(dustAt time: Double) -> some View {
        let dust = ParticleField.dust(at: time - CelebrationTimeline.land, radius: HeroMetrics.medallionDiameter / 2)
        return particleCanvas(dust)
    }

    private func particles(motesAt time: Double) -> some View {
        let motes = clock.reduceMotion ? [] : ParticleField.motes(at: time - CelebrationTimeline.land, spread: 120)
        return particleCanvas(motes)
    }

    private func particleCanvas(_ particles: [Particle]) -> some View {
        let colors = palette.particles
        let side = HeroMetrics.particleCanvasSize
        return Canvas { context, size in
            let origin = CGPoint(x: size.width / 2, y: size.height / 2)
            for particle in particles {
                var layer = context
                layer.opacity = particle.opacity
                let rect = CGRect(
                    x: origin.x + CGFloat(particle.x - particle.size / 2),
                    y: origin.y + CGFloat(particle.y - particle.size / 2),
                    width: CGFloat(particle.size),
                    height: CGFloat(particle.size)
                )
                let shape = particle.isRound ? Path(ellipseIn: rect) : SparkleShape(points: 4, pinch: 0.25).path(in: rect)
                layer.fill(shape, with: .color(colors[particle.tint % colors.count]))
            }
        }
        .frame(width: side, height: side)
    }
}
