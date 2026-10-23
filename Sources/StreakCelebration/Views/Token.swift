import SwiftUI

/// A thick satin-gold coin with a streak flame in line relief at its centre and the count lettered round
/// its rim, drawn mid-spin from a `CelebrationFrame`. It turns from tarnished to polished as it lands.
struct Token: View {
    var frame: CelebrationFrame
    /// The count currently on the front: the previous streak until the coin has turned its back.
    var count: Int
    var streak: Int
    /// When the streak was extended, lettered on the back.
    var earnedOn: String
    var palette: StreakPalette

    private let diameter = HeroMetrics.tokenWidth

    var body: some View {
        let projection = TokenProjection(yaw: frame.tokenYaw, thickness: HeroMetrics.tokenThickness)
        ZStack {
            // The edge: the outline swept through the coin's thickness, catching a pale highlight as it
            // turns towards us.
            TokenShape(squash: projection.faceScale, extrude: projection.extrude)
                .fill(LinearGradient(
                    colors: palette.edge(ignition: frame.ignition, light: light),
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .overlay {
                    TokenShape(squash: projection.faceScale, extrude: projection.extrude)
                        .fill(palette.reliefLight.opacity(0.18 * projection.edgeExposure))
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

    private var light: CoinLight {
        CoinLight(yaw: frame.tokenYaw)
    }

    private var colors: [Color] {
        palette.face(ignition: frame.ignition, light: light)
    }

    // MARK: Faces

    /// Satin gold with a soft bevel at the edge, a fine raised ring just inside it, and a hot spot and
    /// sheen that drift across as the coin turns.
    private func face<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        let drift = -sin((frame.tokenYaw - 15) * .pi / 180)
        return ZStack {
            Circle()
                .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [palette.reliefLight.opacity(0.7), palette.reliefLight.opacity(0), palette.reliefShadow.opacity(0.45)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.5
                )
            Circle()
                .strokeBorder(colors[0], lineWidth: 1.6)
                .padding(diameter * 0.045)
                .modifier(Embossed(palette: palette))

            content()

            Circle()
                .fill(RadialGradient(
                    colors: [Color.white.opacity(0.3 * light.facing), Color.white.opacity(0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: diameter * 0.4
                ))
                .frame(width: diameter * 0.8, height: diameter * 0.8)
                .offset(x: drift * diameter * 0.3, y: -diameter * 0.16)
                .blendMode(.plusLighter)
            LinearGradient(
                colors: [.white.opacity(0), .white.opacity(0.12), .white.opacity(0)],
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
            innerRing
            flame
                .offset(y: diameter * 0.015)
            ArcText(
                text: "\(count) Day streak".uppercased(),
                radius: diameter * 0.37,
                placement: .top,
                font: .system(size: 14, weight: .semibold).width(.expanded),
                degreesPerCharacter: 15.5
            )
        }
        .foregroundStyle(colors[0])
        .modifier(Embossed(palette: palette))
        .frame(width: diameter, height: diameter)
    }

    private var back: some View {
        ZStack {
            innerRing
            VStack(spacing: 4) {
                Text("STREAK")
                    .font(.system(size: 9, weight: .semibold).width(.expanded))
                    .tracking(2)
                Text("\(streak)")
                    .font(.system(size: 30, weight: .semibold).width(.expanded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(width: diameter * 0.5)
                Text("DAYS")
                    .font(.system(size: 9, weight: .semibold).width(.expanded))
                    .tracking(2)
            }
            ArcText(
                text: earnedOn,
                radius: diameter * 0.37,
                placement: .bottom,
                font: .system(size: 11, weight: .semibold).width(.expanded),
                degreesPerCharacter: 12
            )
        }
        .foregroundStyle(colors[0])
        .modifier(Embossed(palette: palette))
        .frame(width: diameter, height: diameter)
    }

    /// The fine ring that separates the lettering from the centre.
    private var innerRing: some View {
        Circle()
            .strokeBorder(colors[0], lineWidth: 1.6)
            .frame(width: diameter * 0.58, height: diameter * 0.58)
    }

    /// The streak flame drawn as a raised line, with its teardrop inside, like a logo struck on a coin.
    private var flame: some View {
        let width = diameter * 0.3
        let height = width * 1.1
        return ZStack {
            FlameShape()
                .stroke(colors[0], style: StrokeStyle(lineWidth: 3.2, lineJoin: .round))
            DropShape()
                .stroke(colors[0], style: StrokeStyle(lineWidth: 2.6, lineJoin: .round))
                .frame(width: width * 0.38, height: height * 0.44)
                .offset(y: height * 0.2)
        }
        .frame(width: width, height: height)
    }
}

/// Raised relief: a catch-light on the top-left edge and a soft shadow falling bottom-right.
private struct Embossed: ViewModifier {
    var palette: StreakPalette

    func body(content: Content) -> some View {
        content
            .shadow(color: palette.reliefLight.opacity(0.85), radius: 0, x: -0.8, y: -0.8)
            .shadow(color: palette.reliefShadow.opacity(0.7), radius: 0.6, x: 1, y: 1.2)
    }
}
