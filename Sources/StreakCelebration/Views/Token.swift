import SwiftUI

/// A satin black metal token with the streak inlaid in gold on the front and an engraving on the back,
/// drawn mid-spin from a `CelebrationFrame`.
struct Token: View {
    var frame: CelebrationFrame
    /// The count currently on the front: the previous streak until the token has turned its back.
    var count: Int
    var streak: Int
    /// When the streak was extended, engraved on the back.
    var earnedOn: String
    var palette: StreakPalette

    private let width = HeroMetrics.tokenWidth
    private let height = HeroMetrics.tokenHeight

    var body: some View {
        let projection = TokenProjection(yaw: frame.tokenYaw, thickness: HeroMetrics.tokenThickness)
        ZStack {
            // The edge: the outline swept through the token's thickness, lit as it turns towards us.
            TokenShape(squash: projection.faceScale, extrude: projection.extrude)
                .fill(LinearGradient(colors: palette.edge, startPoint: .leading, endPoint: .trailing))
                .overlay {
                    TokenShape(squash: projection.faceScale, extrude: projection.extrude)
                        .fill(palette.ink.opacity(0.07 * projection.edgeExposure))
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

    // MARK: Faces

    /// Satin black metal with a bevelled rim, an inner groove and a sheen that slides as the token turns.
    private func face<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        let sheen = -sin((frame.tokenYaw - 15) * .pi / 180) * width * 1.1
        return ZStack {
            TokenShape()
                .fill(LinearGradient(colors: palette.metal, startPoint: .topLeading, endPoint: .bottomTrailing))
            TokenShape()
                .fill(RadialGradient(
                    colors: [palette.ink.opacity(0.10), palette.ink.opacity(0)],
                    center: UnitPoint(x: 0.3, y: 0.15),
                    startRadius: 0,
                    endRadius: height * 0.7
                ))
            TokenShape()
                .strokeBorder(
                    LinearGradient(
                        colors: [palette.ink.opacity(0.24), palette.ink.opacity(0.03), .black.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
            TokenShape(insetAmount: 8)
                .stroke(
                    LinearGradient(
                        colors: [.black.opacity(0.55), palette.ink.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )

            content()

            LinearGradient(
                colors: [.white.opacity(0), .white.opacity(0.12), .white.opacity(0)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: width * 0.55, height: height * 1.4)
            .rotationEffect(.degrees(18))
            .offset(x: sheen)
            .blendMode(.plusLighter)
        }
        .frame(width: width, height: height)
        .mask { TokenShape() }
    }

    private var front: some View {
        // The gold catches the light hardest a little left of face-on.
        let specular = pow(max(0, cos((frame.tokenYaw - 20) * .pi / 180)), 12)
        let brightness = frame.inlayGlow * (0.85 + 0.3 * specular)
        return VStack(spacing: 0) {
            Text("DAY")
                .font(.system(size: 15, weight: .heavy))
                .tracking(2.5)
                .foregroundStyle(palette.engraving)
                .modifier(Stamped())

            Text("\(count)")
                .font(.system(size: 118, weight: .black).width(.condensed))
                .foregroundStyle(LinearGradient(
                    colors: palette.inlay(brightness: brightness),
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .lineLimit(1)
                .minimumScaleFactor(0.3)
                .frame(width: width * 0.8)
                // Recessed into the metal, with a warm bloom once it's lit.
                .shadow(color: .black.opacity(0.75), radius: 0, x: 0, y: -1.5)
                .shadow(color: palette.inlayLit[1].color.opacity(0.35 * min(frame.inlayGlow, 1)), radius: 8)
        }
        .offset(y: 6)
    }

    private var back: some View {
        VStack(spacing: 7) {
            Text("STREAK")
                .font(.system(size: 10, weight: .heavy))
                .tracking(3)
            Rectangle()
                .frame(width: 22, height: 1)
            Text("\(streak) DAYS")
                .font(.system(size: 13, weight: .bold))
                .tracking(1.5)
            Text(earnedOn)
                .font(.system(size: 8, weight: .semibold))
                .tracking(2)
        }
        .foregroundStyle(palette.engraving)
        .modifier(Stamped())
    }
}

/// Lettering pressed into the metal: a dark lip above and a faint catch-light below.
private struct Stamped: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: -1)
            .shadow(color: .white.opacity(0.07), radius: 0, x: 0, y: 1)
    }
}
