import Foundation

/// Words shown on the celebration.
enum StreakCopy {
    /// The encouragement under the week, calling out milestones.
    static func message(for streak: Int) -> String {
        switch streak {
        case 1: "Day one. Come back tomorrow to keep the flame alive."
        case 7: "A full week! This is turning into a habit."
        case 30: "30 days in a row. That's a real habit now."
        case 100: "100 days. Absolutely unstoppable."
        case let days where days.isMultiple(of: 10): "\(days) days and counting. Keep the fire going."
        default: "Show up every day to keep your streak burning."
        }
    }

    static func share(for streak: Int) -> String {
        "I'm on a \(streak) day streak! 🔥"
    }
}
