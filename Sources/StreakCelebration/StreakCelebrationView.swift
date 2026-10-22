import SwiftUI

/// A full-screen celebration shown when the user extends their streak.
///
/// The grey flame from yesterday squashes, launches, bursts into a shockwave and re-ignites while the
/// count rolls over; then the week's progress fills in and the actions arrive.
///
///     .fullScreenCover(isPresented: $showStreak) {
///         StreakCelebrationView(streak: 10) { showStreak = false }
///     }
///
/// Tapping anywhere while it plays skips to the end. With Reduce Motion on it shows the final state.
public struct StreakCelebrationView: View {
    private let streak: Int
    private let previousStreak: Int
    private let week: StreakWeek
    private let message: String
    private let shareMessage: String
    private let onContinue: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var start: Date?
    @State private var stage = Stage.dormant
    @State private var countScale = 1.0

    /// - Parameters:
    ///   - streak: The streak after today's activity.
    ///   - previousStreak: What the counter rolls over from. Defaults to `streak - 1`.
    ///   - today: The day being celebrated.
    ///   - calendar: Decides the first day of the week and the weekday names.
    ///   - message: The line under the week. Defaults to one based on the streak.
    ///   - onContinue: Called when the user taps Continue.
    public init(
        streak: Int,
        previousStreak: Int? = nil,
        today: Date = .now,
        calendar: Calendar = .current,
        message: String? = nil,
        onContinue: @escaping () -> Void = {}
    ) {
        let streak = max(streak, 1)
        self.streak = streak
        self.previousStreak = previousStreak ?? streak - 1
        self.week = StreakWeek(streak: streak, today: today, calendar: calendar)
        self.message = message ?? StreakCopy.message(for: streak)
        self.shareMessage = StreakCopy.share(for: streak)
        self.onContinue = onContinue
    }

    public var body: some View {
        let palette = StreakPalette.standard(for: colorScheme)
        let clock = CelebrationClock(start: start, reduceMotion: reduceMotion)

        VStack(spacing: 0) {
            Spacer(minLength: 16)

            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    IgnitionHero(clock: clock, palette: palette)
                        .padding(.bottom, -22)
                    counter(palette: palette)
                    if stage >= .details {
                        Text("day streak")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(palette.accent)
                            .transition(.opacity.combined(with: .offset(y: 10)))
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("\(streak) day streak"))

                if stage >= .progress {
                    VStack(spacing: 18) {
                        WeekProgressBar(week: week, clock: clock, isSettled: stage >= .actions, palette: palette)
                        Text(message)
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(palette.secondaryInk)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 28)
                    .padding(.horizontal, 8)
                    .transition(.opacity.combined(with: .offset(y: 24)))
                }
            }

            Spacer(minLength: 16)

            actions(palette: palette)
                // Always in the layout so its arrival doesn't shove the content up a second time.
                .opacity(stage >= .actions ? 1 : 0)
                .offset(y: stage >= .actions ? 0 : 24)
                .allowsHitTesting(stage >= .actions)
                .accessibilityHidden(stage < .actions)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.background.ignoresSafeArea())
        .contentShape(Rectangle())
        .onTapGesture(perform: skipToEnd)
        .sensoryFeedback(trigger: stage) { _, newStage in
            switch newStage {
            case .burst: return .impact(weight: .heavy, intensity: 0.9)
            case .counted: return .success
            default: return nil
            }
        }
        .task { await play() }
    }

    // MARK: Pieces

    private func counter(palette: StreakPalette) -> some View {
        let isCounted = stage >= .counted
        return Text("\(isCounted ? streak : previousStreak)")
            .font(.system(size: 92, weight: .heavy, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(LinearGradient(
                colors: isCounted ? palette.number : palette.dormantNumber,
                startPoint: .top,
                endPoint: .bottom
            ))
            .contentTransition(.numericText(countsDown: true))
            .scaleEffect(countScale)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }

    private func actions(palette: StreakPalette) -> some View {
        HStack(spacing: 12) {
            ShareLink(item: shareMessage) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 20, weight: .bold))
                    .accessibilityLabel(Text("Share streak"))
            }
            .buttonStyle(ChunkyButtonStyle(face: palette.track, labelColor: palette.ink))
            .frame(width: 58)

            Button(action: onContinue) {
                Text("Continue")
                    .tracking(1)
                    .textCase(.uppercase)
            }
            .buttonStyle(ChunkyButtonStyle(face: .tint, labelColor: .white))
        }
    }

    // MARK: Choreography

    enum Stage: Int, Comparable {
        case dormant, burst, counted, details, progress, actions

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
            (IgnitionTimeline.burst, .burst),
            (IgnitionTimeline.countUp, .counted),
            (IgnitionTimeline.details, .details),
            (IgnitionTimeline.progress, .progress),
            (IgnitionTimeline.actions, .actions),
        ]
        for (time, next) in beats {
            guard await wait(until: time) else { return }
            await advance(to: next)
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

    private func advance(to next: Stage) async {
        guard next > stage else { return }
        switch next {
        case .counted:
            withAnimation(.spring(response: 0.42, dampingFraction: 0.8)) { stage = next }
            withAnimation(.spring(response: 0.18, dampingFraction: 0.6)) { countScale = 1.14 }
            try? await Task.sleep(for: .milliseconds(140))
            withAnimation(.spring(response: 0.45, dampingFraction: 0.45)) { countScale = 1 }
        case .actions:
            withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) { stage = next }
        default:
            withAnimation(.spring(response: 0.55, dampingFraction: 0.86)) { stage = next }
        }
    }

    private func skipToEnd() {
        guard stage < .actions, !reduceMotion else { return }
        // Move the clock forward so every time-driven layer lands on its final frame.
        start = Date.now.addingTimeInterval(-IgnitionTimeline.restingTime)
        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
            stage = .actions
            countScale = 1
        }
    }
}

#Preview("Streak extended") {
    StreakCelebrationPreview(streak: 10)
}

#Preview("Day one, dark") {
    StreakCelebrationPreview(streak: 1)
        .preferredColorScheme(.dark)
}

/// Replays the celebration when you tap Continue, so the animation can be tuned in the canvas.
private struct StreakCelebrationPreview: View {
    var streak: Int
    @State private var run = 0

    var body: some View {
        StreakCelebrationView(streak: streak) { run += 1 }
            .id(run)
    }
}
