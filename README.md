# StreakCelebration

A SwiftUI screen for the moment a user extends their streak. Yesterday's grey flame squashes, launches,
bursts into a shockwave and re-ignites while the counter rolls over. Then the week fills in and the
actions slide up.

<p align="center">
  <img src="docs/preview.gif" width="260" alt="Animated preview of the streak celebration">
  &nbsp;&nbsp;
  <img src="docs/final-frame.png" width="260" alt="Settled state: lit flame, 10 day streak, week progress bar and Continue button">
</p>

> The previews above were rendered from this package's `IgnitionTimeline` and `ParticleField` values (the
> same numbers the SwiftUI views read), drawn with approximate shapes and fonts. For the real thing, open
> the package in Xcode and use the canvas preview.

## Run it in the Simulator

You need a Mac with Xcode 16 or newer. Clone once:

```sh
cd ~ && git clone https://github.com/nodedesignagency/streak.git
```

Then, whenever there are changes:

```sh
cd ~/streak && git fetch origin && git checkout claude/great-maxwell-9wf1fn && git pull && ./scripts/run.sh
```

`scripts/run.sh` builds `Demo/StreakDemo.xcodeproj`, boots an iPhone simulator, installs the app and launches
it. The celebration plays on launch; change the streak and tap **Celebrate** to see it again. Pass a
simulator name to pick one, for example `./scripts/run.sh "iPhone 16 Pro"`. You can also open
`Demo/StreakDemo.xcodeproj` in Xcode and press ⌘R.

## Use it

Add the package (File ▸ Add Package Dependencies… ▸ Add Local… or this repo's URL), then present the screen:

```swift
import StreakCelebration

.fullScreenCover(isPresented: $showStreak) {
    StreakCelebrationView(streak: 10) {
        showStreak = false
    }
    .tint(.blue) // colour of the Continue button
}
```

| Parameter | Default | |
| --- | --- | --- |
| `streak` | required | The streak after today's activity. |
| `previousStreak` | `streak - 1` | What the counter rolls over from. |
| `today` | `.now` | The day being celebrated. |
| `calendar` | `.current` | First weekday and weekday names. |
| `message` | milestone-aware | Line under the week bar. |
| `onContinue` | no-op | Called from the Continue button. |

Requires iOS 17 / macOS 14 and Xcode 16 or newer.

To tune it, open `Package.swift` in Xcode, open `StreakCelebrationView.swift` and use the canvas. In the
preview, tapping Continue replays the animation.

## Choreography

All timing lives in `Motion/IgnitionTimeline.swift`. Every layer is a pure function of elapsed time
(`Track(…).to(…, at:, over:, curve)`), so the sequence can be replayed, skipped, scrubbed and unit-tested.

| Time | Beat |
| --- | --- |
| 0.00s | Grey flame and the previous count. |
| 0.25s | Anticipation: the flame stretches up a little. |
| 0.40s | Squash: it collapses into a pill. |
| 0.62s | The pill becomes an orb and heats from ash to ember orange. |
| 0.74s | Launch: the orb stretches and jumps, leaving a gold ring on the ground. |
| 0.98s | Swell: it grows from its base and turns gold. |
| 1.16s | **Burst** (heavy haptic): a gold sparkle, then a disc with a star punched out, hollowing into an expanding ring, with sparks. |
| 1.40s | **Count up** (success haptic): the number rolls over and pops, grey to orange. |
| 1.50s | A teardrop falls back to the ground and springs up into the lit flame. Embers start rising and the flame flickers from here on. |
| 2.00s | "day streak" fades in. |
| 2.35s | The week block slides in and the layout lifts; the bar fills to today with a sparkle on its leading edge. |
| 3.40s | Share and Continue arrive. |

Other details:

- **Tap anywhere** to skip to the settled state.
- **Reduce Motion** shows the settled state straight away, with no flicker and no embers.
- **VoiceOver** reads "10 day streak" and "6 of 7 days this week", and the hidden buttons stay out of
  the accessibility tree until they appear.
- Light and dark palettes are in `Views/StreakPalette.swift`. Continue follows the environment `tint`.

## Layout

```
Sources/StreakCelebration/
  StreakCelebrationView.swift   Screen, stage choreography, haptics, previews
  Motion/                       Pure Foundation: timeline, easing, particles, geometry
  Model/                        Pure Foundation: week model, copy
  Views/                        Hero, shapes, week bar, button style, palette
Tests/StreakCelebrationTests/   Swift Testing suites for Motion and Model
Demo/                           Demo app (StreakDemo.xcodeproj, generated from project.yml by XcodeGen)
scripts/run.sh                  Build the demo and launch it in the Simulator
```

Run the tests with `swift test`. `Motion` and `Model` don't import SwiftUI, so the suite also runs on Linux.

## References

The motion follows the screen recording supplied with the brief: dormant flame → squash → launch → star
flash → shockwave → re-lit flame, the odometer roll, the week bar with a glowing head, and Continue last.
These Mobbin screens shaped the rest:

- [Numo](https://mobbin.com/screens/6bd56122-0f37-4c7c-a21b-9bfb35dd4cca): the confetti burst and the Share action next to the primary button.
- [BitePal](https://mobbin.com/screens/b04e4b6c-9383-498a-b2d0-6541427e3cc6): the week row with today highlighted, and the round share button paired with a wide CTA.
- [Speak](https://mobbin.com/screens/7acbb2fc-3817-408f-9db3-25380bb43706): a warm flame over a short encouragement line.
- [Finch](https://mobbin.com/screens/4bae1a7b-6d74-4a1c-ac18-3503cd56a616) and [Liven](https://mobbin.com/screens/92b03f22-7a06-49d3-8833-69ad40444247): the soft sunburst behind the hero.
- [Duolingo streak flow](https://mobbin.com/flows/d1739059-58c7-4b20-8630-8833869d34bb): milestone-aware copy.
