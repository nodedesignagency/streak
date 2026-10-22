import Foundation

/// Where the celebration is in time. Every animated view reads elapsed time from the same clock, so the
/// hero, the week dots and the stage changes can never drift apart.
struct CelebrationClock: Equatable {
    var start: Date?
    var reduceMotion: Bool

    func elapsed(at date: Date) -> TimeInterval {
        if reduceMotion { return CelebrationTimeline.restingTime }
        guard let start else { return 0 }
        return max(0, date.timeIntervalSince(start))
    }
}
