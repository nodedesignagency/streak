import Foundation
import Testing
@testable import StreakCelebration

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
    @Test("The title carries the count")
    func title() {
        #expect(StreakCopy.title(for: 10) == "10 Day Streak")
        #expect(StreakCopy.title(for: 0) == "1 Day Streak")
    }

    @Test("The description says what the badge is for and points at the next milestone")
    func description() {
        #expect(StreakCopy.description(for: 1) == "You started a streak by showing up today. 2 more days to your 3-day milestone.")
        #expect(StreakCopy.description(for: 10) == "You earned this badge by showing up 10 days in a row. 4 more days to your 14-day milestone.")
        #expect(StreakCopy.description(for: 13).hasSuffix("1 more day to your 14-day milestone."))
        #expect(StreakCopy.description(for: 7).hasSuffix("That's the 7-day milestone. Next stop: 14 days."))
    }
}
