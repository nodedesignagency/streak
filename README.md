# StreakCelebration

A SwiftUI screen for the moment a user extends their streak. On a dark stage, a thick satin-gold coin
with a streak flame in line relief at its centre winds up and flicks into two full spins. The new count comes round
on its rim, the gold polishes up as it lands, and gold leaf starts to fall. Then the week's dots pop in
and the actions arrive.

<p align="center">
  <img src="docs/preview.gif" width="260" alt="Animated preview of the streak celebration">
  &nbsp;&nbsp;
  <img src="docs/final-frame.png" width="260" alt="Settled state: gold coin with a line-relief flame inside a ring and 10 day streak lettered round the rim, week dots and Continue button">
</p>

> The previews above were rendered from this package's `CelebrationTimeline` and `ParticleField` values (the
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
}
```

| Parameter | Default | |
| --- | --- | --- |
| `streak` | required | The streak after today's activity. |
| `previousStreak` | `streak - 1` | What the counter rolls over from. |
| `today` | `.now` | The day being celebrated. |
| `calendar` | `.current` | First weekday and weekday names. |
| `message` | days to the next milestone | Line under the week. |
| `onContinue` | no-op | Called from the Continue button. |

Requires iOS 17 / macOS 14 and Xcode 16 or newer.

To tune it, open `Package.swift` in Xcode, open `StreakCelebrationView.swift` and use the canvas. In the
preview, tapping Continue replays the animation.

## Choreography

All timing lives in `Motion/CelebrationTimeline.swift`. Every layer is a pure function of elapsed time
(`Track(…).to(…, at:, over:, curve)`), so the sequence can be replayed, skipped, scrubbed and unit-tested.

| Time | Beat |
| --- | --- |
| 0.00s | The coin faces you, its gold dull, with yesterday's count round the rim. |
| 0.20s | Anticipation: it turns back a little and dips. |
| 0.40s | **Spin** (light haptic): it flicks into two full turns, rising, so you see its milled edge and its struck back go by. |
| 1.00s | The front comes round carrying the new count, which changed while the back was turned. |
| 1.55s | **Lands** (success haptic, heavy on a milestone day): it settles face-on, the gold flares and settles polished, and gold leaf flies off it and starts falling across the screen. From here the coin sways gently, its satin gold shifting between champagne and peach as it turns towards and away from the light (`Motion/CoinLight.swift`). |
| 2.45s | The week slides in and the layout lifts; the dots pop in left to right, ending on today's flame with a pulse. |
| 3.40s | Share and Continue arrive. |

The rim lettering is laid out by `Motion/ArcLayout.swift`. The coin is drawn as a projected solid
rather than with stacked 3D layers: the visible face is
squashed by the cosine of its angle and shifted by its thickness, and the edge is the outline stretched
sideways (`Motion/TokenProjection.swift`). That keeps the depth order right at every angle.

Other details:

- **Tap anywhere** to skip to the settled state.
- **Reduce Motion** shows the settled state straight away, without the sway or the falling gold leaf.
- **VoiceOver** reads "10 day streak" and "6 of 7 days this week", and the hidden buttons stay out of
  the accessibility tree until they appear.
- The screen always plays on its own dark stage and sets `.preferredColorScheme(.dark)` so the status bar
  stays readable. Colours, including the coin's gold, are in `Views/StreakPalette.swift`.
- The line under the week counts down to the next milestone (3, 7, 14, 21, 30, 50, 75, 100, 150, 200, 250,
  300, 365, then every 100 days) and calls it out on the day it's reached.

## Layout

```
Sources/StreakCelebration/
  StreakCelebrationView.swift   Screen, stage choreography, haptics, previews
  Motion/                       Pure Foundation: timeline, easing, particles, geometry
  Model/                        Pure Foundation: week, milestones, copy
  Views/                        Token, gold leaf, week dots, shapes, button style, palette
Tests/StreakCelebrationTests/   Swift Testing suites for Motion and Model
Demo/                           Demo app (StreakDemo.xcodeproj, generated from project.yml by XcodeGen)
scripts/run.sh                  Build the demo and launch it in the Simulator
```

Run the tests with `swift test`. `Motion` and `Model` don't import SwiftUI, so the suite also runs on Linux.

## References

The coin follows the third and fourth reference recordings: thick satin gold with fine raised rings,
wide capitals lettered round the rim and a single line-relief emblem at the centre, its colour shifting
between rich gold, champagne and peach as it spins. Here the emblem is the streak flame and the
lettering carries the count. The spin, thick edge, struck back and falling gold
leaf come from the second recording. The rest of the look
comes from these Mobbin screens:

- [Atoms](https://mobbin.com/screens/904f683f-daef-4507-ac61-d77f1dfd7ae8): a dark, dotted stage.
- [WHOOP](https://mobbin.com/screens/7cc5b73d-2c66-4ecf-b665-b7ee6dc8e480) and [Alta](https://mobbin.com/screens/85635c51-5d04-45a1-9034-4b590953fb70): a dark stage, a week of dots with today called out, and a white pill CTA.
- [Insight Timer](https://mobbin.com/screens/3a74a615-658c-463c-b117-afac5989f66e): "next milestone in N days" as the encouragement.
- [Crypto.com](https://mobbin.com/screens/600296a0-5fe0-4f4b-b5a9-16433b60db35) and [Rocket Money](https://mobbin.com/screens/44669c9f-a311-454a-9f65-595b0f53a001): earned badges presented as minted objects.
