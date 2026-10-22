import SwiftUI

/// A full-screen celebration shown when the user extends their streak.
///
/// A ring closes around a dull graphite medallion, which lifts, flips to polished gold and lands in a
/// puff of gold dust while the count rolls over. Then the week's dots pop in and the actions arrive.
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
    private let milestone: StreakMilestone
    private let message: String
    private let shareMessage: String
    private let onContinue: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var start: Date?
    @State private var stage = Stage.dormant
    @State private var countScale = 1.0

    private let palette = StreakPalette.night

    /// - Parameters:
    ///   - streak: The streak after today's activity.
    ///   - previousStreak: What the counter rolls over from. Defaults to `streak - 1`.
    ///   - today: The day being celebrated.
    ///   - calendar: Decides the first day of the week and the weekday names.
    ///   - message: The line under the week. Defaults to how far the next milestone is.
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
        self.milestone = StreakMilestone(streak: streak)
        self.message = message ?? StreakCopy.message(for: streak)
        self.shareMessage = StreakCopy.share(for: streak)
        self.onContinue = onContinue
    }

    public var body: some View {
        let clock = CelebrationClock(start: start, reduceMotion: reduceMotion)

        VStack(spacing: 0) {
            Spacer(minLength: 12)

            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    MedallionHero(clock: clock, palette: palette)
                        .padding(.bottom, -10)
                    counter
                    if stage >= .details {
                        Text("Day streak")
                            .font(.system(.footnote, weight: .semibold))
                            .tracking(3)
                            .textCase(.uppercase)
                            .foregroundStyle(palette.secondaryInk)
                            .transition(.opacity.combined(with: .offset(y: 8)))
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("\(streak) day streak"))

                if stage >= .week {
                    VStack(spacing: 22) {
                        WeekDots(week: week, clock: clock, isSettled: stage >= .actions, palette: palette)
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(palette.secondaryInk)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 30)
                    .transition(.opacity.combined(with: .offset(y: 24)))
                }
            }

            Spacer(minLength: 12)

            actions
                // Always in the layout so its arrival doesn't shove the content up a second time.
                .opacity(stage >= .actions ? 1 : 0)
                .offset(y: stage >= .actions ? 0 : 24)
                .allowsHitTesting(stage >= .actions)
                .accessibilityHidden(stage < .actions)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            ZStack {
                palette.background
                DotGrid(color: palette.dotGrid)
            }
            .ignoresSafeArea()
        }
        .preferredColorScheme(.dark)
        .contentShape(Rectangle())
        .onTapGesture(perform: skipToEnd)
        .sensoryFeedback(trigger: stage) { _, newStage in
            switch newStage {
            case .charged: return .impact(weight: milestone.isReached ? .heavy : .light)
            case .landed: return .success
            default: return nil
            }
        }
        .task { await play() }
    }

    // MARK: Pieces

    private var counter: some View {
        let isRevealed = stage >= .revealed
        return Text("\(isRevealed ? streak : previousStreak)")
            .font(.system(size: 88, weight: .regular, design: .serif))
            .monospacedDigit()
            .foregroundStyle(LinearGradient(
                colors: isRevealed ? palette.number : palette.dormantNumber,
                startPoint: .top,
                endPoint: .bottom
            ))
            .contentTransition(.numericText())
            .scaleEffect(countScale)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }

    private var actions: some View {
        HStack(spacing: 12) {
            ShareLink(item: shareMessage) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 19, weight: .semibold))
                    .accessibilityLabel(Text("Share streak"))
            }
            .buttonStyle(PillButtonStyle(fill: palette.ink.opacity(0.1), labelColor: palette.ink))
            .frame(width: 56)

            Button("Continue", action: onContinue)
                .buttonStyle(PillButtonStyle(fill: palette.ink, labelColor: palette.background))
        }
    }

    // MARK: Choreography

    enum Stage: Int, Comparable {
        case dormant, charged, revealed, landed, details, week, actions

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
            (CelebrationTimeline.arrive, .charged),
            (CelebrationTimeline.reveal, .revealed),
            (CelebrationTimeline.land, .landed),
            (CelebrationTimeline.details, .details),
            (CelebrationTimeline.week, .week),
            (CelebrationTimeline.actions, .actions),
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
        case .revealed:
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { stage = next }
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) { countScale = 1.1 }
            try? await Task.sleep(for: .milliseconds(160))
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) { countScale = 1 }
        case .charged, .landed:
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
            countScale = 1
        }
    }
}

#Preview("Streak extended") {
    StreakCelebrationPreview(streak: 10)
}

#Preview("Milestone reached") {
    StreakCelebrationPreview(streak: 7)
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
