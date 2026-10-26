# StreakCelebration

A SwiftUI screen for the moment a user extends their streak, laid out like a trophy screen: a hexagonal
fire badge in chrome and glossy enamel, then the date, the title "10 Day Streak" and a short description,
over a charcoal stage that warms into gold towards the bottom, with a single share button.

The badge winds up and flicks into two full spins, showing its chrome edge and the same artwork on its
back, in its own colours from start to finish. As it lands the gold at the bottom of the screen warms up;
then the words and the share button arrive. After that it keeps turning a full circle every few seconds,
like a trophy on a turntable.

<p align="center">
  <img src="docs/preview.gif" width="260" alt="Animated preview of the streak celebration">
  &nbsp;&nbsp;
  <img src="docs/final-frame.png" width="260" alt="Settled state: a hexagonal chrome-and-enamel fire badge, the date, the title 10 Day Streak, a description and a Share your streak button on a gold gradient">
</p>

> The previews above were rendered from this package's `CelebrationTimeline`, `TokenProjection`,
> `TokenLight` and `BadgeOutline` values (the same numbers the SwiftUI views read). Both faces are the real
> badge artwork; the edge, the light and the fonts are close approximations of what SwiftUI draws. For the
> real thing, open the package in Xcode and use the canvas preview.

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
}
```

| Parameter | Default | |
| --- | --- | --- |
| `streak` | required | The streak after today's activity. |
| `today` | `.now` | The day being celebrated, shown above the title. |
| `message` | days to the next milestone | The paragraph under the title. |
| `onClose` | no-op | Called from the close button. |

Requires iOS 17 / macOS 14 and Xcode 16 or newer.

To tune it, open `Package.swift` in Xcode, open `StreakCelebrationView.swift` and use the canvas. In the
preview, tapping the close button replays the animation.

## Choreography

All timing lives in `Motion/CelebrationTimeline.swift`. Every layer is a pure function of elapsed time
(`Track(…).to(…, at:, over:, curve)`), so the sequence can be replayed, skipped, scrubbed and unit-tested.

| Time | Beat |
| --- | --- |
| 0.00s | The badge faces you in its full colours. The gold wash at the bottom of the screen is dim. |
| 0.20s | Anticipation: it turns back a little and dips. |
| 0.40s | **Spin** (light haptic): it flicks into two full turns, rising, so you see its chrome edge and its back go by. The back carries the same artwork as the front. |
| 1.55s | **Lands** (success haptic, heavy on a milestone day): it settles face-on and the gold wash warms up. From here it sways gently, and a hot spot and a sheen slide across it as it turns towards and away from the light; the chrome edge glints as it catches it (`Motion/TokenLight.swift`). |
| 1.85s | The date, title and description rise in. |
| 2.60s | The share button arrives. |
| 5.55s | It turns a full circle, and again every six seconds after that. |

Both faces of the badge are the artwork itself (`Resources/Badge.xcassets`), shown in its own colours.
What turns with it is drawn in SwiftUI: the chrome edge, and a hot spot and sheen that slide across the
face. They share one outline, a rounded hexagon fitted to the artwork (`Motion/BadgeOutline.swift`),
which also cuts the artwork out. The badge is drawn as a projected solid rather than with stacked 3D layers:
the visible face is squashed by the cosine of its angle and shifted by its thickness, and the edge is the
outline stretched sideways (`Motion/TokenProjection.swift`). That keeps the depth order right at every angle.

To use different artwork, keep it the same shape: 624 × 684 px (208 × 228 pt at @3x), transparent
outside the outline. If its proportions or corner radius differ, update `HeroMetrics` and
`BadgeOutline.cornerRadius` to match.

Other details:

- **Tap anywhere** to skip to the settled state.
- **Reduce Motion** shows the settled state straight away, without the sway or the idle turns.
- **VoiceOver** reads the date, title and description together, then the share and close buttons; the
  badge itself is decorative because the title says the same thing.
- The screen always plays on its own dark stage and sets `.preferredColorScheme(.dark)` so the status bar
  stays readable. Colours, including the badge's chrome, are in `Views/StreakPalette.swift`.
- The description counts down to the next milestone (3, 7, 14, 21, 30, 50, 75, 100, 150, 200, 250, 300,
  365, then every 100 days) and calls it out on the day it's reached.

## Layout

```
Sources/StreakCelebration/
  StreakCelebrationView.swift   Screen, stage choreography, haptics, previews
  Motion/                       Pure Foundation: timeline, easing, projection, lighting, badge outline
  Model/                        Pure Foundation: milestones, copy
  Views/                        Badge, its outline shape, button style, palette
  Resources/                    Badge artwork (asset catalog)
Tests/StreakCelebrationTests/   Swift Testing suites for Motion and Model
Demo/                           Demo app (StreakDemo.xcodeproj, generated from project.yml by XcodeGen)
scripts/run.sh                  Build the demo and launch it in the Simulator
```

Run the tests with `swift test`. `Motion` and `Model` don't import SwiftUI, so the suite also runs on Linux.

## References

The screen follows the third and fourth reference recordings (a "Workout of the Day" trophy screen):
a trophy that turns on its own, then a small date, a title and a short description over a charcoal stage
that warms into gold at the bottom, a dark share pill on the gold and a rounded close button. The badge
and the title-and-description pairing under it come from the "Fire Streak" badge reference: a hexagon
with raised chrome outlines and glossy red, orange and yellow enamel, a flame in the centre with an inner
yellow flame and a white four-point sparkle, and rays out to the left and right. The spin with its thick
edge comes from the second recording.
