import SwiftUI

/// A full-screen celebration shown when the user extends their streak.
///
/// The streak badge rises from below the screen at one and a half times its size, spinning in fast and
/// winding down, and shrinks back to its own size as it settles at its place facing you, in one continuous
/// movement, while the gold at the bottom of the screen warms up. Then the date, title and description
/// arrive, and the share button. After that it turns a full circle every few seconds, like a trophy on a
/// turntable.
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

        VStack(spacing: 0) {
            HStack {
                Spacer()
                closeButton
            }
            .padding(.top, 8)

            Spacer(minLength: 8)

            TokenHero(clock: clock, palette: palette)

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
            StageBackground(palette: palette, warmth: stage >= .landed ? 1 : 0.3)
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
        .buttonStyle(PillButtonStyle(fill: palette.button, labelColor: palette.ink))
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

/// Charcoal at the top, warming through amber into bright gold at the bottom.
private struct StageBackground: View {
    var palette: StreakPalette
    /// 0 plain charcoal, 1 the full warm wash.
    var warmth: Double

    var body: some View {
        ZStack {
            palette.background
            LinearGradient(
                stops: [
                    .init(color: palette.warmth[0].opacity(0), location: 0.42),
                    .init(color: palette.warmth[0], location: 0.6),
                    .init(color: palette.warmth[1], location: 0.8),
                    .init(color: palette.warmth[2], location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .opacity(warmth)
            // Brightest at the bottom centre, a little deeper towards the corners.
            RadialGradient(
                colors: [palette.warmth[2].opacity(0.5), palette.warmth[2].opacity(0)],
                center: .bottom,
                startRadius: 0,
                endRadius: 380
            )
            .opacity(warmth)
        }
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
