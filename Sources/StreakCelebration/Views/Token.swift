import SwiftUI

/// A flame-shaped enamel token with the streak raised on the front and an engraving on the back, drawn
/// mid-spin from a `CelebrationFrame`. It starts as cold ash and catches fire as it lands.
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
                .fill(LinearGradient(colors: palette.edge(ignition: frame.ignition), startPoint: .leading, endPoint: .trailing))
                .overlay {
                    TokenShape(squash: projection.faceScale, extrude: projection.extrude)
                        .fill(palette.ink.opacity(0.08 * projection.edgeExposure))
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

    /// Enamel in the flame's colours, with a hot core, a gloss, a bevelled rim, an inset groove and a
    /// sheen that slides across as the token turns.
    private func face<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        let heat = min(max(frame.ignition, 0), 1)
        let sheen = -sin((frame.tokenYaw - 15) * .pi / 180) * width * 1.1
        return ZStack {
            TokenShape()
                .fill(LinearGradient(colors: palette.body(ignition: frame.ignition), startPoint: .top, endPoint: .bottom))
            TokenShape()
                .fill(RadialGradient(
                    colors: [palette.core.opacity(0.9 * heat), palette.core.opacity(0)],
                    center: UnitPoint(x: 0.5, y: 0.8),
                    startRadius: 0,
                    endRadius: height * 0.5
                ))

            // A soft streak of gloss down the left of the belly, like light on glazed enamel, clear of the number.
            Capsule()
                .fill(Color.white.opacity(0.08 + 0.2 * heat))
                .frame(width: width * 0.06, height: height * 0.2)
                .rotationEffect(.degrees(-6))
                .blur(radius: 2.5)
                .position(x: width * 0.12, y: height * 0.62)

            TokenShape()
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.4), .white.opacity(0.02), .black.opacity(0.35)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.5
                )
            TokenShape(insetAmount: 10)
                .stroke(palette.stamp(ignition: frame.ignition).opacity(0.55), lineWidth: 1.5)

            content()

            LinearGradient(
                colors: [.white.opacity(0), .white.opacity(0.16), .white.opacity(0)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: width * 0.5, height: height * 1.4)
            .rotationEffect(.degrees(18))
            .offset(x: sheen)
            .blendMode(.plusLighter)
        }
        .frame(width: width, height: height)
        .mask { TokenShape() }
    }

    private var front: some View {
        // Placed by fraction of the token rather than stacked, so the font's line padding can't shift them.
        ZStack {
            Text("\(count)")
                .font(.system(size: 92, weight: .black).width(.condensed))
                .foregroundStyle(LinearGradient(
                    colors: palette.numeral(ignition: frame.ignition),
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .lineLimit(1)
                .minimumScaleFactor(0.3)
                .frame(width: width * 0.62)
                // Raised off the enamel, with a warm glow once it's lit.
                .shadow(color: palette.stamp(ignition: frame.ignition).opacity(0.85), radius: 0, x: 0, y: 2)
                .shadow(color: palette.core.opacity(0.6 * min(max(frame.ignition, 0), 1)), radius: 10)
                .position(x: width / 2, y: height * 0.62)

            Text("Day streak")
                .font(.system(size: 10, weight: .heavy))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundStyle(palette.stamp(ignition: frame.ignition))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(width: width * 0.62)
                .modifier(Stamped())
                .position(x: width / 2, y: height * 0.86)
        }
        .frame(width: width, height: height)
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
        .foregroundStyle(palette.stamp(ignition: frame.ignition))
        .modifier(Stamped())
        .position(x: width / 2, y: height * 0.64)
        .frame(width: width, height: height)
    }
}

/// Lettering pressed into the enamel: a shadowed lip above and a catch-light below.
private struct Stamped: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: .black.opacity(0.35), radius: 0, x: 0, y: -1)
            .shadow(color: .white.opacity(0.18), radius: 0, x: 0, y: 1)
    }
}
