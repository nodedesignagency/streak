import SwiftUI

/// A thick brushed-gold coin with a streak flame struck in the middle and the count round its rim,
/// drawn mid-spin from a `CelebrationFrame`. It turns from tarnished to polished as it lands.
struct Token: View {
    var frame: CelebrationFrame
    /// The count currently on the front: the previous streak until the coin has turned its back.
    var count: Int
    var streak: Int
    /// When the streak was extended, struck on the back.
    var earnedOn: String
    var palette: StreakPalette

    private let diameter = HeroMetrics.tokenWidth

    var body: some View {
        let projection = TokenProjection(yaw: frame.tokenYaw, thickness: HeroMetrics.tokenThickness)
        let light = lightFacing
        ZStack {
            // The milled edge: the outline swept through the coin's thickness, lit as it turns towards us.
            TokenShape(squash: projection.faceScale, extrude: projection.extrude)
                .fill(LinearGradient(
                    colors: palette.edge(ignition: frame.ignition, light: light),
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .overlay {
                    TokenShape(squash: projection.faceScale, extrude: projection.extrude)
                        .fill(palette.reliefLight.opacity(0.12 * projection.edgeExposure))
                }

            Group {
                if projection.showsFront {
                    face { front }
                } else {
                    face { back }
                }
            }
            .scaleEffect(x: max(projection.faceScale, 0.001), y: 1)
            .offset(x: projection.faceOffset)
        }
        .frame(width: diameter, height: diameter)
        .scaleEffect(frame.tokenScale)
        .offset(y: -frame.tokenLift)
    }

    /// 1 when the face is turned towards the light (a little left of face-on), falling off as it turns away.
    private var lightFacing: Double {
        pow(max(0, cos((frame.tokenYaw - 25) * .pi / 180)), 2)
    }

    private var colors: [Color] {
        palette.face(ignition: frame.ignition, light: lightFacing)
    }

    // MARK: Faces

    /// Brushed gold with a raised rim, and a highlight and sheen that drift across as the coin turns.
    private func face<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        let rim = diameter * 0.075
        let drift = -sin((frame.tokenYaw - 15) * .pi / 180)
        return ZStack {
            Circle()
                .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            BrushedRings(color: palette.reliefLight)

            // The raised rim, lit from the top left, and the step down from it into the field.
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [palette.reliefLight.opacity(0.75), colors[1].opacity(0), palette.reliefShadow.opacity(0.65)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: rim
                )
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [palette.reliefShadow.opacity(0.75), palette.reliefLight.opacity(0.55)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .padding(rim)

            content()

            // A soft hot spot and a narrow sheen, both sliding with the turn.
            Circle()
                .fill(RadialGradient(
                    colors: [Color.white.opacity(0.32 * lightFacing), Color.white.opacity(0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: diameter * 0.4
                ))
                .frame(width: diameter * 0.8, height: diameter * 0.8)
                .offset(x: drift * diameter * 0.3, y: -diameter * 0.16)
                .blendMode(.plusLighter)
            LinearGradient(
                colors: [.white.opacity(0), .white.opacity(0.14), .white.opacity(0)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: diameter * 0.45, height: diameter * 1.4)
            .rotationEffect(.degrees(18))
            .offset(x: drift * diameter * 1.1)
            .blendMode(.plusLighter)
        }
        .frame(width: diameter, height: diameter)
        .clipShape(Circle())
    }

    private var front: some View {
        ZStack {
            flame
                .offset(y: diameter * 0.04)

            ArcText(
                text: "\(count) Day streak".uppercased(),
                radius: diameter * 0.355,
                placement: .top,
                font: .system(size: 12, weight: .heavy),
                degreesPerCharacter: 9.5
            )
            .foregroundStyle(colors[0])
            .modifier(Embossed(palette: palette))

            ArcText(
                text: "• • •",
                radius: diameter * 0.37,
                placement: .bottom,
                font: .system(size: 9, weight: .heavy),
                degreesPerCharacter: 9
            )
            .foregroundStyle(colors[0])
            .modifier(Embossed(palette: palette))
        }
        .frame(width: diameter, height: diameter)
    }

    /// The streak flame struck in relief, with its teardrop counter sunk into it.
    private var flame: some View {
        let width = diameter * 0.4
        let height = width * 1.1
        return ZStack {
            FlameShape()
                .fill(LinearGradient(colors: [colors[0], colors[1]], startPoint: .top, endPoint: .bottom))
            DropShape()
                .fill(LinearGradient(colors: [colors[2], colors[1]], startPoint: .top, endPoint: .bottom))
                .overlay {
                    DropShape().stroke(palette.reliefShadow.opacity(0.55), lineWidth: 1)
                }
                .frame(width: width * 0.38, height: height * 0.44)
                .offset(y: height * 0.2)
        }
        .frame(width: width, height: height)
        .modifier(Embossed(palette: palette))
    }

    private var back: some View {
        VStack(spacing: 7) {
            Text("STREAK")
                .font(.system(size: 11, weight: .heavy))
                .tracking(3)
            Rectangle()
                .frame(width: 24, height: 1.5)
            Text("\(streak) DAYS")
                .font(.system(size: 16, weight: .heavy))
                .tracking(1.5)
            Text(earnedOn)
                .font(.system(size: 9, weight: .bold))
                .tracking(2)
        }
        .foregroundStyle(colors[0])
        .modifier(Embossed(palette: palette))
    }
}

/// Raised relief: a catch-light on the top-left edge and a soft shadow falling bottom-right.
private struct Embossed: ViewModifier {
    var palette: StreakPalette

    func body(content: Content) -> some View {
        content
            .shadow(color: palette.reliefLight.opacity(0.8), radius: 0, x: -0.8, y: -0.8)
            .shadow(color: palette.reliefShadow.opacity(0.7), radius: 0.6, x: 1, y: 1.2)
    }
}

/// Fine concentric rings, like a lathe-brushed metal face.
private struct BrushedRings: View {
    var color: Color

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let maxRadius = Double(min(size.width, size.height)) / 2
            var radius = 3.0
            var light = true
            while radius < maxRadius {
                let ring = Path(ellipseIn: CGRect(
                    x: Double(center.x) - radius,
                    y: Double(center.y) - radius,
                    width: radius * 2,
                    height: radius * 2
                ))
                context.stroke(ring, with: .color(light ? color.opacity(0.05) : Color.black.opacity(0.05)), lineWidth: 1)
                radius += 2.5
                light.toggle()
            }
        }
        .allowsHitTesting(false)
    }
}
