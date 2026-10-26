import Foundation

/// Words shown on the celebration.
enum StreakCopy {
    static func title(for streak: Int) -> String {
        "\(max(streak, 1)) Day Streak"
    }

    /// The paragraph under the title: what the badge is for, and what the next milestone is (or that one
    /// was just reached).
    static func description(for streak: Int) -> String {
        let milestone = StreakMilestone(streak: streak)
        let earned = milestone.streak == 1
            ? "You started a streak by showing up today."
            : "You earned this badge by showing up \(milestone.streak) days in a row."
        if milestone.isReached {
            return "\(earned) That's the \(milestone.target)-day milestone. Next stop: \(milestone.next) days."
        }
        let days = milestone.daysLeft == 1 ? "day" : "days"
        return "\(earned) \(milestone.daysLeft) more \(days) to your \(milestone.target)-day milestone."
    }

    static func share(for streak: Int) -> String {
        "I'm on a \(max(streak, 1)) day streak! 🔥"
    }
}
