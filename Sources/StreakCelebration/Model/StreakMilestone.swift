import Foundation

/// The milestone a streak is heading for.
struct StreakMilestone: Equatable, Sendable {
    /// Milestones up to a year; after that, every hundred days.
    static let ladder = [3, 7, 14, 21, 30, 50, 75, 100, 150, 200, 250, 300, 365]

    let streak: Int
    /// The first milestone at or above the streak.
    let target: Int

    init(streak: Int) {
        let streak = max(streak, 1)
        self.streak = streak
        self.target = Self.ladder.first { $0 >= streak } ?? (streak + 99) / 100 * 100
    }

    /// The streak landed exactly on a milestone today.
    var isReached: Bool { streak == target }

    var daysLeft: Int { target - streak }

    /// The milestone after `target`.
    var next: Int { StreakMilestone(streak: target + 1).target }
}
