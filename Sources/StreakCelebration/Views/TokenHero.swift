import SwiftUI

/// The badge spinning in, landing and then turning on its own every few seconds.
struct TokenHero: View {
    var clock: CelebrationClock
    var palette: StreakPalette

    var body: some View {
        TimelineView(.animation(paused: clock.reduceMotion)) { context in
            let time = clock.elapsed(at: context.date)
            Token(
                frame: CelebrationTimeline.frame(at: time, idleMotion: !clock.reduceMotion),
                palette: palette
            )
        }
        .frame(width: HeroMetrics.canvasSize, height: HeroMetrics.canvasSize)
        .allowsHitTesting(false)
        // The title underneath says the same thing in words.
        .accessibilityHidden(true)
    }
}
