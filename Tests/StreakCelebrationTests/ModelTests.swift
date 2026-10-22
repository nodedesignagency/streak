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

struct StreakMilestoneTests {
    @Test("Heads for the next milestone on the ladder", arguments: [
        (1, 3), (2, 3), (3, 3), (4, 7), (10, 14), (29, 30), (100, 100), (300, 300), (364, 365),
    ])
    func target(streak: Int, expected: Int) {
        #expect(StreakMilestone(streak: streak).target == expected)
    }

    @Test("Counts in hundreds after a year")
    func afterAYear() {
        #expect(StreakMilestone(streak: 366).target == 400)
        #expect(StreakMilestone(streak: 400).isReached)
        #expect(StreakMilestone(streak: 401).target == 500)
        #expect(StreakMilestone(streak: 365).next == 400)
    }

    @Test("Knows when one is reached and what comes next")
    func reached() {
        let week = StreakMilestone(streak: 7)
        #expect(week.isReached)
        #expect(week.daysLeft == 0)
        #expect(week.next == 14)
        #expect(!StreakMilestone(streak: 8).isReached)
        #expect(StreakMilestone(streak: 8).daysLeft == 6)
    }
}

struct StreakCopyTests {
    @Test("Messages point at the next milestone")
    func messages() {
        #expect(StreakCopy.message(for: 1).contains("Day one"))
        #expect(StreakCopy.message(for: 10) == "4 more days to your 14-day milestone.")
        #expect(StreakCopy.message(for: 13) == "1 more day to your 14-day milestone.")
        #expect(StreakCopy.message(for: 7) == "You reached the 7-day milestone. Next stop: 14 days.")
    }
}
