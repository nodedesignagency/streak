import SwiftUI

/// A minted medal with a flame engraved on it. It flips from a dull graphite face to a polished gold one.
struct Medallion: View {
    var frame: CelebrationFrame
    var palette: StreakPalette

    var body: some View {
        let diameter = HeroMetrics.medallionDiameter
        ZStack {
            if frame.showsGoldFace {
                // Past 90° we're looking at the back of the coin, so un-mirror its face.
                goldFace(diameter: diameter)
                    .scaleEffect(x: -1)
            } else {
                dormantFace(diameter: diameter)
            }
        }
        .frame(width: diameter, height: diameter)
        .rotation3DEffect(.degrees(frame.flipAngle), axis: (x: 0, y: 1, z: 0), perspective: 0.4)
        .scaleEffect(frame.medallionScale)
        .offset(y: -frame.medallionLift)
        .shadow(color: .black.opacity(0.5), radius: 18, y: 12 + frame.medallionLift * 0.5)
    }

    private func goldFace(diameter: Double) -> some View {
        let rosette = RosetteShape()
        let inner = diameter * 0.74
        return ZStack {
            rosette.fill(LinearGradient(colors: palette.gold, startPoint: .top, endPoint: .bottom))
            rosette.stroke(
                LinearGradient(colors: [palette.goldHighlight, palette.goldHighlight.opacity(0)], startPoint: .top, endPoint: .center),
                lineWidth: 1.5
            )

            // A recessed field, lit from below so it reads as stamped in.
            Circle()
                .fill(LinearGradient(colors: [palette.goldDeep, palette.gold[1]], startPoint: .top, endPoint: .bottom))
                .frame(width: inner, height: inner)
            Circle()
                .strokeBorder(
                    LinearGradient(colors: [palette.goldDeep.opacity(0.8), palette.goldHighlight.opacity(0.9)], startPoint: .top, endPoint: .bottom),
                    lineWidth: 1.5
                )
                .frame(width: inner, height: inner)

            engraving(
                fill: LinearGradient(colors: [palette.goldHighlight, palette.gold[0]], startPoint: .top, endPoint: .bottom),
                core: palette.gold[1],
                shadow: palette.goldDeep
            )

            // The glint that sweeps across after landing.
            LinearGradient(
                colors: [.white.opacity(0), .white.opacity(0.6), .white.opacity(0)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: diameter * 0.32, height: diameter * 1.6)
            .rotationEffect(.degrees(20))
            .offset(x: frame.shinePosition * diameter * 0.7)
            .blendMode(.plusLighter)
        }
        .frame(width: diameter, height: diameter)
        .mask { rosette }
    }

    private func dormantFace(diameter: Double) -> some View {
        let rosette = RosetteShape()
        let inner = diameter * 0.74
        return ZStack {
            rosette.fill(LinearGradient(colors: palette.graphite, startPoint: .top, endPoint: .bottom))
            rosette.stroke(
                LinearGradient(colors: [palette.ink.opacity(0.14), palette.ink.opacity(0)], startPoint: .top, endPoint: .center),
                lineWidth: 1.5
            )
            Circle()
                .fill(LinearGradient(colors: [palette.graphiteDeep, palette.graphite[1]], startPoint: .top, endPoint: .bottom))
                .frame(width: inner, height: inner)
            engraving(fill: palette.graphite[0], core: palette.graphiteDeep, shadow: .black.opacity(0.6))
        }
        .frame(width: diameter, height: diameter)
    }

    /// The flame stamped into the face, with a hard shadow below it for depth.
    private func engraving<Fill: ShapeStyle, Core: ShapeStyle>(fill: Fill, core: Core, shadow: Color) -> some View {
        let width = HeroMetrics.glyphWidth
        let height = width * 1.1
        return ZStack {
            FlameShape().fill(shadow).offset(y: 2)
            FlameShape().fill(fill)
            DropShape()
                .fill(core)
                .frame(width: width * 0.38, height: height * 0.44)
                .offset(y: height * 0.2)
        }
        .frame(width: width, height: height)
    }
}
