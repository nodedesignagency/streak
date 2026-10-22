import Foundation

/// Words shown on the celebration.
enum StreakCopy {
    /// The line under the week: what the next milestone is, or that one was just reached.
    static func message(for streak: Int) -> String {
        let milestone = StreakMilestone(streak: streak)
        if milestone.streak == 1 {
            return "Day one. Come back tomorrow to keep it going."
        }
        if milestone.isReached {
            return "You reached the \(milestone.target)-day milestone. Next stop: \(milestone.next) days."
        }
        let days = milestone.daysLeft == 1 ? "day" : "days"
        return "\(milestone.daysLeft) more \(days) to your \(milestone.target)-day milestone."
    }

    static func share(for streak: Int) -> String {
        "I'm on a \(streak) day streak! 🔥"
    }
}
