# Breakdown

A physics game for iPhone and Mac that lets you see the physics working.

The first table is pool. You watch an ordinary break. Then the table melts into a dark grid, and each ball leaves a glowing path. Arrows show speed and spin, and short notes show where energy changed hands. You can scrub through the shot, slow it down, and try a different version of it. Then you take the cue.

Later, the same physics view comes to scenes you scan with your iPhone: point it at your room or a pile of objects, get a physics scene, and smash it.

- Spec: [docs/2026-11-02-breakdown-spec.md](docs/2026-11-02-breakdown-spec.md)
- Change log: [CHANGELOG.md](CHANGELOG.md)

Built natively in Swift with Xcode on the Mac Mini. The pool physics is our own deterministic solver, so every quantity shown in the physics view is something the game actually computed.

Started 02-November-2026 by Claude Opus 5.5 Medium for the Boss.

## What runs today (milestone 1a and most of 1b)

- The cold open: a normal break at full speed, freeze, the table melts into a blueprint grid, rewind, then slow motion with glowing trails (orange while sliding, cyan while rolling), velocity arrows, impact rings, and plain-language captions with the equation that matters.
- Replay controls: play and pause, speeds from a tenth to full, a scrub bar with a tick for every impact, Lens on and off, and replay.
- "Your break": aim, power and cue-tip height, then the same cold open on your own shot.
- Sound is generated in code and scaled by each impact.
- Not built yet: pocket jaws and knuckles, spin and elevation controls beyond the break, lessons, challenges, haptics, scan-and-smash. See the spec milestones.

## Build and run

Needs Xcode 27. No project generator is used; the Xcode project is hand-written and the physics lives in a local package.

```bash
# physics tests (about three seconds)
cd Packages/BreakdownCore && swift test

# build and run on the iPhone simulator
xcodebuild -project Breakdown.xcodeproj -scheme Breakdown -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build build
xcrun simctl boot "iPhone 17 Pro"
xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/Breakdown.app
xcrun simctl launch booted com.voynichlabs.breakdown

# build for the Mac
xcodebuild -project Breakdown.xcodeproj -scheme Breakdown -destination 'platform=macOS' -derivedDataPath build-mac build
```

Launch with the argument `-yourBreakDemo` to run the player's own break without tapping.
