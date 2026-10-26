import SwiftUI

/// The streak badge mid-spin, drawn from a `CelebrationFrame`: the enamel-and-chrome artwork on the front,
/// a chrome edge as deep as the badge is thick, and a chrome back engraved with the count and the date.
/// The enamel is muted while it spins, then flares and settles to its own colours as it lands.
struct Token: View {
    var frame: CelebrationFrame
    /// The count engraved on the back: the previous streak the first time the back goes by, then the new one.
    var count: Int
    /// When the streak was extended, engraved on the back.
    var earnedOn: String
    var palette: StreakPalette

    private let width = HeroMetrics.tokenWidth
    private let height = HeroMetrics.tokenHeight

    var body: some View {
        let projection = TokenProjection(yaw: frame.tokenYaw, thickness: HeroMetrics.tokenThickness)
        ZStack {
            // The edge: the outline swept through the badge's thickness, catching a pale highlight as it
            // turns towards us.
            BadgeShape(squash: projection.faceScale, extrude: projection.extrude)
                .fill(LinearGradient(
                    colors: palette.edge(ignition: frame.ignition, light: light),
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .overlay {
                    BadgeShape(squash: projection.faceScale, extrude: projection.extrude)
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
        .frame(width: width, height: height)
        .scaleEffect(frame.tokenScale)
        .offset(y: -frame.tokenLift)
    }

    private var light: TokenLight {
        TokenLight(yaw: frame.tokenYaw)
    }

    // MARK: Faces

    /// Either face, with a hot spot and a sheen that drift across it as the badge turns.
    private func face<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        let drift = -sin((frame.tokenYaw - 15) * .pi / 180)
        return ZStack {
            content()

            Circle()
                .fill(RadialGradient(
                    colors: [Color.white.opacity(0.22 * light.facing), Color.white.opacity(0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: width * 0.4
                ))
                .frame(width: width * 0.8, height: width * 0.8)
                .offset(x: drift * width * 0.3, y: -height * 0.16)
                .blendMode(.plusLighter)
            LinearGradient(
                colors: [.white.opacity(0), .white.opacity(0.12), .white.opacity(0)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: width * 0.45, height: height * 1.4)
            .rotationEffect(.degrees(18))
            .offset(x: drift * width * 1.1)
            .blendMode(.plusLighter)
        }
        .frame(width: width, height: height)
        .clipShape(BadgeShape())
    }

    /// The artwork, its enamel muted until the badge lands.
    private var front: some View {
        let finish = BadgeFinish(ignition: frame.ignition, light: light)
        return Image("StreakBadge", bundle: .module)
            .resizable()
            .interpolation(.high)
            .saturation(finish.saturation)
            .brightness(finish.brightness)
            .frame(width: width, height: height)
    }

    /// A polished chrome frame, like the one on the front, round a sunken plate engraved with the count.
    private var back: some View {
        let chrome = palette.plate(ignition: frame.ignition, light: light)
        let frameWidth = width * 0.075
        return ZStack {
            BadgeShape()
                .fill(LinearGradient(colors: chrome, startPoint: .topLeading, endPoint: .bottomTrailing))
            // The frame's bevel: catching the light on the top left, in shadow on the bottom right.
            BadgeShape()
                .strokeBorder(
                    LinearGradient(
                        colors: [palette.reliefLight.opacity(0.8), palette.reliefLight.opacity(0), palette.reliefShadow.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.5
                )
            // The plate, a step down from the frame: its shadow falls along the top left.
            BadgeShape()
                .inset(by: frameWidth)
                .fill(LinearGradient(
                    colors: [chrome[2], chrome[1], chrome[1]],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            BadgeShape()
                .inset(by: frameWidth)
                .strokeBorder(
                    LinearGradient(
                        colors: [palette.reliefShadow.opacity(0.6), palette.reliefLight.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )

            engraving
                .foregroundStyle(chrome[2])
                .modifier(Engraved(palette: palette))
        }
        .frame(width: width, height: height)
    }

    private var engraving: some View {
        ZStack {
            VStack(spacing: 2) {
                Text("STREAK")
                    .font(.system(size: 10, weight: .semibold).width(.expanded))
                    .tracking(2)
                Text("\(count)")
                    .font(.system(size: 46, weight: .semibold).width(.expanded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(maxWidth: width * 0.6)
                Text(count == 1 ? "DAY" : "DAYS")
                    .font(.system(size: 10, weight: .semibold).width(.expanded))
                    .tracking(2)
            }
            .offset(y: -height * 0.02)
            Text(earnedOn)
                .font(.system(size: 9, weight: .semibold).width(.expanded))
                .tracking(1)
                .offset(y: height * 0.29)
        }
    }
}

/// Cut into the metal: a shadow along the top left of each stroke and a catch-light along the bottom right.
private struct Engraved: ViewModifier {
    var palette: StreakPalette

    func body(content: Content) -> some View {
        content
            .shadow(color: palette.reliefShadow.opacity(0.55), radius: 0, x: -0.6, y: -0.6)
            .shadow(color: palette.reliefLight.opacity(0.8), radius: 0, x: 0.8, y: 0.8)
    }
}
