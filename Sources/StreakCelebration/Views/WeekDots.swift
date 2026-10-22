import SwiftUI

/// The week as a row of dots: gold checks for streak days, a flame for today, empty rings for the rest.
/// They pop in one after another, ending on today.
struct WeekDots: View {
    var week: StreakWeek
    var clock: CelebrationClock
    /// Once everything has settled the dots stop ticking and simply show the finished state.
    var isSettled: Bool
    var palette: StreakPalette

    private static let dotSize = 34.0

    var body: some View {
        TimelineView(.animation(paused: isSettled || clock.reduceMotion)) { context in
            let time = isSettled ? CelebrationTimeline.restingTime : clock.elapsed(at: context.date)
            HStack(spacing: 0) {
                ForEach(week.days) { day in
                    VStack(spacing: 10) {
                        dot(day, time: time)
                        Text(day.symbol.uppercased())
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(0.6)
                            .foregroundStyle(day.isToday ? palette.gold[0] : palette.tertiaryInk)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(week.streakDaysThisWeek) of \(StreakWeek.length) days this week"))
    }

    private func dot(_ day: StreakWeek.Day, time: Double) -> some View {
        let appearance = CelebrationTimeline.dotAppearance(index: day.index, at: time)
        let pulse = CelebrationTimeline.todayPulse(index: day.index, at: time)
        let size = Self.dotSize
        return ZStack {
            if day.isInStreak {
                Circle()
                    .fill(LinearGradient(colors: [palette.gold[0], palette.gold[1]], startPoint: .top, endPoint: .bottom))
                if day.isToday {
                    FlameShape()
                        .fill(palette.background)
                        .frame(width: 13, height: 15)
                } else {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(palette.background)
                }
            } else {
                Circle()
                    .strokeBorder(palette.track, lineWidth: 1.5)
            }

            if day.isToday {
                Circle()
                    .strokeBorder(palette.gold[1].opacity(0.45), lineWidth: 1.5)
                    .padding(-5)
                Circle()
                    .stroke(palette.gold[1], lineWidth: 2)
                    .scaleEffect(1 + 0.8 * pulse)
                    .opacity(pulse > 0 ? 0.8 * (1 - pulse) : 0)
            }
        }
        .frame(width: size, height: size)
        .scaleEffect(day.isInStreak ? 0.4 + 0.6 * appearance : 1)
        .opacity(min(1, appearance * 2.5))
    }
}
