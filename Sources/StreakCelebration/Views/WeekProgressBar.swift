import SwiftUI

/// Weekday labels over a capsule track that fills up to today, with a sparkle riding the leading edge.
struct WeekProgressBar: View {
    var week: StreakWeek
    var clock: CelebrationClock
    /// Once everything has settled the bar stops ticking and simply shows the finished state.
    var isSettled: Bool
    var palette: StreakPalette

    private static let trackHeight = 14.0

    var body: some View {
        TimelineView(.animation(paused: isSettled || clock.reduceMotion)) { context in
            let time = isSettled ? IgnitionTimeline.restingTime : clock.elapsed(at: context.date)
            let progress = IgnitionTimeline.weekProgress(at: time)
            VStack(spacing: 10) {
                labels(progress: progress)
                GeometryReader { proxy in
                    track(progress: progress, width: proxy.size.width)
                }
                .frame(height: Self.trackHeight)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(week.streakDaysThisWeek) of \(StreakWeek.length) days this week"))
    }

    private func labels(progress: Double) -> some View {
        let startFraction = week.streakStartIndex == 0 ? 0 : StreakWeek.center(of: week.streakStartIndex)
        let reachedFraction = startFraction + (StreakWeek.center(of: week.todayIndex) - startFraction) * progress
        return HStack(spacing: 0) {
            ForEach(week.days) { day in
                let isReached = day.isInStreak && progress > 0 && reachedFraction >= StreakWeek.center(of: day.index) - 0.001
                Text(day.symbol)
                    .font(.system(.caption, design: .rounded, weight: day.isToday ? .heavy : .semibold))
                    .foregroundStyle(labelColor(isToday: day.isToday, isReached: isReached))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func labelColor(isToday: Bool, isReached: Bool) -> Color {
        switch (isToday, isReached) {
        case (true, true): palette.accent
        case (false, true): palette.ink.opacity(0.75)
        default: palette.secondaryInk
        }
    }

    private func track(progress: Double, width: Double) -> some View {
        let height = Self.trackHeight
        let start = week.streakStartIndex == 0 ? 0 : width * StreakWeek.center(of: week.streakStartIndex) - height / 2
        let end = width * StreakWeek.center(of: week.todayIndex) + height / 2
        let fillWidth = max(height, (end - start) * progress)
        let head = start + fillWidth - height / 2
        let tomorrow = week.todayIndex + 1 < StreakWeek.length ? week.todayIndex + 1 : nil

        return ZStack(alignment: .leading) {
            Capsule()
                .fill(palette.track)

            if let tomorrow {
                // Tomorrow's flame, waiting to be lit.
                FlameView(style: .dormant, size: CGSize(width: 16, height: 18), palette: palette)
                    .position(x: width * StreakWeek.center(of: tomorrow), y: height / 2)
            }

            if progress > 0 {
                Capsule()
                    .fill(LinearGradient(colors: [palette.number[1], palette.flame[1]], startPoint: .leading, endPoint: .trailing))
                    .overlay(alignment: .top) {
                        Capsule()
                            .fill(.white.opacity(0.45))
                            .frame(height: height * 0.24)
                            .padding(.horizontal, 6)
                            .padding(.top, height * 0.18)
                    }
                    .frame(width: fillWidth)
                    .offset(x: start)

                SparkleShape(points: 4, pinch: 0.22)
                    .fill(.white)
                    .frame(width: 18, height: 18)
                    .shadow(color: palette.flame[1], radius: 4)
                    .position(x: head, y: height / 2)
            }
        }
        .frame(height: height)
    }
}
