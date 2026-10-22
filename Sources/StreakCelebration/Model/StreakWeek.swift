import Foundation

/// The current calendar week as the progress bar needs it: which day is today and how far back the
/// streak reaches inside this week.
struct StreakWeek: Equatable, Sendable {
    struct Day: Equatable, Sendable, Identifiable {
        let index: Int
        /// Two-letter weekday, e.g. "Mo".
        let symbol: String
        let isToday: Bool
        let isInStreak: Bool

        var id: Int { index }
    }

    static let length = 7

    let days: [Day]
    let todayIndex: Int
    /// First day of this week covered by the streak.
    let streakStartIndex: Int

    init(streak: Int, today: Date, calendar: Calendar) {
        let symbols = calendar.shortStandaloneWeekdaySymbols
        let firstWeekday = calendar.firstWeekday // 1 = Sunday
        let todayIndex = (calendar.component(.weekday, from: today) - firstWeekday + Self.length) % Self.length
        let streakStartIndex = max(0, todayIndex - (max(streak, 1) - 1))

        self.todayIndex = todayIndex
        self.streakStartIndex = streakStartIndex
        self.days = (0..<Self.length).map { index in
            let symbol = symbols[(firstWeekday - 1 + index) % Self.length]
            return Day(
                index: index,
                symbol: String(symbol.prefix(2)),
                isToday: index == todayIndex,
                isInStreak: (streakStartIndex...todayIndex).contains(index)
            )
        }
    }

    /// Number of days in this week that belong to the streak, today included.
    var streakDaysThisWeek: Int {
        todayIndex - streakStartIndex + 1
    }

    /// Horizontal centre of a day's column as a fraction of the bar's width.
    static func center(of index: Int) -> Double {
        (Double(index) + 0.5) / Double(length)
    }
}
