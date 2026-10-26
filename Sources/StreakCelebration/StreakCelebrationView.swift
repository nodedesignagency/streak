import SwiftUI

/// A full-screen celebration shown when the user extends their streak.
///
/// The streak badge rises from below the screen at one and a half times its size, spinning in fast and
/// winding down, and shrinks back to its own size as it settles at its place facing you, in one continuous
/// movement, while the gold glows round the edges of the screen and behind the badge brighten. Then the
/// date, title and description arrive, and the share button. After that it turns a full circle every few
/// seconds, like a trophy on a turntable.
///
///     .fullScreenCover(isPresented: $showStreak) {
///         StreakCelebrationView(streak: 10) { showStreak = false }
///     }
///
/// Tapping anywhere while it plays skips to the end. With Reduce Motion on it shows the final state.
public struct StreakCelebrationView: View {
    private let streak: Int
    private let milestone: StreakMilestone
    private let dateLine: String
    private let title: String
    private let message: String
    private let shareMessage: String
    private let onClose: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var start: Date?
    @State private var stage = Stage.dormant

    private let palette = StreakPalette.night

    /// - Parameters:
    ///   - streak: The streak after today's activity.
    ///   - today: The day being celebrated, shown above the title.
    ///   - message: The paragraph under the title. Defaults to how far the next milestone is.
    ///   - onClose: Called when the user taps the close button.
    public init(
        streak: Int,
        today: Date = .now,
        message: String? = nil,
        onClose: @escaping () -> Void = {}
    ) {
        let streak = max(streak, 1)
        self.streak = streak
        self.milestone = StreakMilestone(streak: streak)
        self.dateLine = today.formatted(.dateTime.month(.twoDigits).day(.twoDigits).year(.twoDigits))
        self.title = StreakCopy.title(for: streak)
        self.message = message ?? StreakCopy.description(for: streak)
        self.shareMessage = StreakCopy.share(for: streak)
        self.onClose = onClose
    }

    public var body: some View {
        let clock = CelebrationClock(start: start, reduceMotion: reduceMotion)
        // The glows are dim while the badge comes in and brighten as it lands.
        let warmth = stage >= .landed ? 1.0 : 0.3

        VStack(spacing: 0) {
            HStack {
                Spacer()
                closeButton
            }
            .padding(.top, 8)
            // Above the badge's spotlight, which spreads well past the badge.
            .zIndex(1)

            Spacer(minLength: 8)

            TokenHero(clock: clock, palette: palette)
                .background {
                    BadgeSpotlight(palette: palette)
                        .opacity(warmth)
                        .animation(.easeOut(duration: 1.2), value: stage >= .landed)
                        .allowsHitTesting(false)
                }

            VStack(spacing: 10) {
                Text(dateLine)
                    .font(.system(size: 12, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(palette.tertiaryInk)
                Text(title)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(palette.ink)
                Text(message)
                    .font(.system(size: 15))
                    .lineSpacing(3)
                    .foregroundStyle(palette.secondaryInk)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 16)
            }
            .padding(.top, 12)
            .opacity(stage >= .details ? 1 : 0)
            .offset(y: stage >= .details ? 0 : 14)
            .accessibilityElement(children: .combine)
            .accessibilityHidden(stage < .details)

            // The badge and words sit high, as in the reference: more room below them than above.
            Spacer(minLength: 16)
            Spacer(minLength: 0)

            shareButton
                .opacity(stage >= .actions ? 1 : 0)
                .offset(y: stage >= .actions ? 0 : 20)
                .allowsHitTesting(stage >= .actions)
                .accessibilityHidden(stage < .actions)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            StageBackground(palette: palette, warmth: warmth)
                .animation(.easeOut(duration: 1.2), value: stage >= .landed)
                .ignoresSafeArea()
        }
        .preferredColorScheme(.dark)
        .contentShape(Rectangle())
        .onTapGesture(perform: skipToEnd)
        .sensoryFeedback(trigger: stage) { _, newStage in
            switch newStage {
            case .spinning: return .impact(weight: .light)
            case .landed: return milestone.isReached ? SensoryFeedback.impact(weight: .heavy) : SensoryFeedback.success
            default: return nil
            }
        }
        .task { await play() }
    }

    // MARK: Pieces

    private var closeButton: some View {
        Button(action: onClose) {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(palette.ink)
                .frame(width: 40, height: 40)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(palette.ink.opacity(0.1)))
        }
        .accessibilityLabel(Text("Close"))
    }

    private var shareButton: some View {
        ShareLink(item: shareMessage) {
            Text("Share your streak")
        }
        .buttonStyle(PillButtonStyle(
            fill: LinearGradient(colors: palette.buttonFill, startPoint: .top, endPoint: .bottom),
            labelColor: palette.buttonInk
        ))
    }

    // MARK: Choreography

    enum Stage: Int, Comparable {
        case dormant, spinning, landed, details, actions

        static func < (lhs: Stage, rhs: Stage) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    private func play() async {
        guard !reduceMotion else {
            stage = .actions
            return
        }
        start = .now

        let beats: [(TimeInterval, Stage)] = [
            (CelebrationTimeline.spin, .spinning),
            (CelebrationTimeline.land, .landed),
            (CelebrationTimeline.details, .details),
            (CelebrationTimeline.actions, .actions),
        ]
        for (time, next) in beats {
            guard await wait(until: time) else { return }
            advance(to: next)
        }
    }

    /// Sleeps until `time` on the celebration clock. Re-reads the clock, so skipping ahead wakes it early.
    private func wait(until time: TimeInterval) async -> Bool {
        guard let start else { return false }
        let remaining = time - Date.now.timeIntervalSince(start)
        if remaining > 0 {
            try? await Task.sleep(for: .seconds(remaining))
        }
        return !Task.isCancelled
    }

    private func advance(to next: Stage) {
        guard next > stage else { return }
        switch next {
        case .spinning, .landed:
            stage = next
        default:
            withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) { stage = next }
        }
    }

    private func skipToEnd() {
        guard stage < .actions, !reduceMotion else { return }
        // Move the clock forward so every time-driven layer lands on its final frame.
        start = Date.now.addingTimeInterval(-CelebrationTimeline.restingTime)
        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
            stage = .actions
        }
    }
}

/// Charcoal, with a soft gold glow just inside the edges of the screen, brightest along the top.
private struct StageBackground: View {
    var palette: StreakPalette
    /// How bright the glow is, 0...1.
    var warmth: Double

    var body: some View {
        ZStack {
            palette.background
            // A band centred on the screen's edge and blurred, so only its soft inner half shows: brightest
            // right at the edge, half as bright about 15 points in, and gone by about 45.
            RoundedRectangle(cornerRadius: HeroMetrics.screenCornerRadius, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [palette.warmth[2].opacity(0.85), palette.warmth[2].opacity(0.7), palette.warmth[1].opacity(0.65)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 16
                )
                .blur(radius: 16)
                .opacity(warmth)
        }
    }
}

/// The warm light behind the badge: a bright gold core fading through amber into the charcoal, centred a
/// little above the badge as if it were lit from above.
private struct BadgeSpotlight: View {
    var palette: StreakPalette

    var body: some View {
        let radius = HeroMetrics.spotlightRadius
        RadialGradient(
            stops: [
                .init(color: palette.warmth[2].opacity(0.7), location: 0),
                .init(color: palette.warmth[1].opacity(0.42), location: 0.3),
                .init(color: palette.warmth[0].opacity(0.32), location: 0.62),
                .init(color: palette.warmth[0].opacity(0), location: 1),
            ],
            center: .center,
            startRadius: 0,
            endRadius: radius
        )
        .frame(width: radius * 2, height: radius * 2)
        .offset(y: -HeroMetrics.spotlightRise)
    }
}

#Preview("Streak extended") {
    StreakCelebrationPreview(streak: 10)
}

#Preview("Milestone reached") {
    StreakCelebrationPreview(streak: 7)
}

/// Replays the celebration when you tap close, so the animation can be tuned in the canvas.
private struct StreakCelebrationPreview: View {
    var streak: Int
    @State private var run = 0

    var body: some View {
        StreakCelebrationView(streak: streak) { run += 1 }
            .id(run)
    }
}
