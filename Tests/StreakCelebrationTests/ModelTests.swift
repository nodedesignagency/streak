import Foundation
import Testing
@testable import StreakCelebration

struct StreakWeekTests {
    private func calendar(firstWeekday: Int) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(identifier: "UTC")!
        calendar.firstWeekday = firstWeekday
        return calendar
    }

    /// Friday 23 October 2026, noon UTC.
    private let friday = Date(timeIntervalSince1970: 1_792_756_800)

    @Test("Labels the week with two-letter days, starting on Sunday")
    func sundayFirst() {
        let week = StreakWeek(streak: 10, today: friday, calendar: calendar(firstWeekday: 1))
        #expect(week.days.map(\.symbol) == ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"])
        #expect(week.todayIndex == 5)
        #expect(week.days[5].isToday)
    }

    @Test("Respects a Monday-first calendar")
    func mondayFirst() {
        let week = StreakWeek(streak: 10, today: friday, calendar: calendar(firstWeekday: 2))
        #expect(week.days.first?.symbol == "Mo")
        #expect(week.days.last?.symbol == "Su")
        #expect(week.todayIndex == 4)
    }

    @Test("A long streak covers the whole week so far")
    func longStreak() {
        let week = StreakWeek(streak: 10, today: friday, calendar: calendar(firstWeekday: 1))
        #expect(week.streakStartIndex == 0)
        #expect(week.streakDaysThisWeek == 6)
        #expect(week.days.filter(\.isInStreak).count == 6)
        #expect(!week.days[6].isInStreak)
    }

    @Test("A short streak starts mid-week", arguments: [(1, 5), (2, 4), (3, 3)])
    func shortStreak(streak: Int, expectedStart: Int) {
        let week = StreakWeek(streak: streak, today: friday, calendar: calendar(firstWeekday: 1))
        #expect(week.streakStartIndex == expectedStart)
        #expect(week.streakDaysThisWeek == streak)
    }

    @Test("A zero streak is treated as day one")
    func zeroStreak() {
        let week = StreakWeek(streak: 0, today: friday, calendar: calendar(firstWeekday: 1))
        #expect(week.streakDaysThisWeek == 1)
    }
}

struct StreakCopyTests {
    @Test("Messages call out milestones")
    func milestones() {
        #expect(StreakCopy.message(for: 1).contains("Day one"))
        #expect(StreakCopy.message(for: 7).contains("week"))
        #expect(StreakCopy.message(for: 40).contains("40 days"))
        #expect(StreakCopy.message(for: 13) == StreakCopy.message(for: 14))
    }
}
