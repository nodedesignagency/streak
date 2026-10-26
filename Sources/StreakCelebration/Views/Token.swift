import SwiftUI

/// The streak badge mid-spin, drawn from a `CelebrationFrame`: the enamel-and-chrome artwork on both faces
/// and a chrome edge as deep as the badge is thick. The artwork keeps its own colours throughout; only a hot
/// spot and a sheen slide across it as it turns.
struct Token: View {
    var frame: CelebrationFrame
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
                    colors: palette.edge(light: light),
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .overlay {
                    BadgeShape(squash: projection.faceScale, extrude: projection.extrude)
                        .fill(palette.reliefLight.opacity(0.18 * projection.edgeExposure))
                }

            // Front and back carry the same artwork, so it looks the same whichever way round it is.
            face
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

    /// The artwork, with a hot spot and a sheen that drift across it as the badge turns.
    private var face: some View {
        let drift = -sin((frame.tokenYaw - 15) * .pi / 180)
        return ZStack {
            Image("StreakBadge", bundle: .module)
                .resizable()
                .interpolation(.high)
                .frame(width: width, height: height)

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
}
