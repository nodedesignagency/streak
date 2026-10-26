import SwiftUI

/// The badge spinning in, landing and then turning on its own every few seconds.
struct TokenHero: View {
    var clock: CelebrationClock
    var previousStreak: Int
    var streak: Int
    var earnedOn: String
    var palette: StreakPalette

    var body: some View {
        TimelineView(.animation(paused: clock.reduceMotion)) { context in
            let time = clock.elapsed(at: context.date)
            let frame = CelebrationTimeline.frame(at: time, idleMotion: !clock.reduceMotion)
            Token(
                frame: frame,
                count: frame.showsNewCount ? streak : previousStreak,
                earnedOn: earnedOn,
                palette: palette
            )
        }
        .frame(width: HeroMetrics.canvasSize, height: HeroMetrics.canvasSize)
        .allowsHitTesting(false)
        // The title underneath says the same thing in words.
        .accessibilityHidden(true)
    }
}
