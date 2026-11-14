<!--
Author: GPT-6.1 Sol (inherited reasoning)
Date: 10-November-2026
PURPOSE: Explain the working game, current versus planned technology, verified setup and linked project documents.
SRP/DRY check: Pass — checked existing README, specification and history; links retain one source for detailed design.
-->
# Breakdown

A physics game for iPhone and Mac that lets you see the physics working.

The first table is pool. You watch an ordinary break. Then the table melts into a dark grid, and each ball leaves a glowing path. Arrows show speed and spin, and short notes show where energy changed hands. You can scrub through the shot, slow it down, and try a different version of it. Then you take the cue.

The longer-term design extends the physics view to scan-and-smash scenes. That work is not implemented. The pool launch ships natively in this Swift app, built for iPhone Duo; Unreal stays open for the later scan-and-smash phase (decision of 11 November 2026, see the Duo research note).

- Spec: [docs/2026-11-02-breakdown-spec.md](docs/2026-11-02-breakdown-spec.md)
- Change log: [CHANGELOG.md](CHANGELOG.md)

Built natively in Swift with Xcode on the Mac Mini. The pool physics is our own deterministic solver, so every quantity shown in the physics view is something the game actually computed.

Created for the repository owner with AI coding assistance. The original commit history preserves contributor credits. Hosting under Autoresearch-Arena does not, by itself, establish legal ownership.

## What runs today (milestone 1a and most of 1b)

- The cold open: a normal break at full speed, freeze, the table melts into a blueprint grid, rewind, then slow motion with glowing trails (orange while sliding, cyan while rolling), velocity arrows, impact rings, and plain-language captions with the equation that matters.
- Replay controls: play and pause, speeds from a tenth to full, a scrub bar with a tick for every impact, Lens on and off, and replay.
- "Your break": aim, power and cue-tip height, then the same cold open on your own shot.
- Sound is generated in code and scaled by each impact.
- Not built yet: pocket jaws and knuckles, spin and elevation controls beyond the break, lessons, challenges, haptics, scan-and-smash. See the spec milestones.

## Who it is for and how it is built

For players curious about why a pool shot behaves as it does. The current app uses SwiftUI for controls, RealityKit for rendering and AVFoundation for generated audio. A local Swift package supplies the solver, event model and recorded playback. There are no remote package dependencies or bundled purchased asset packs in the current tree.

- [Roadmap and completion checks](ROADMAP.md)
- [Dependencies, research references and rights scope](THIRD_PARTY_NOTICES.md)
- [Repository readiness review](docs/2026-11-10-readiness-review.md)
- [MIT license](LICENSE)

## Build and run

Use a Mac with full Xcode selected as the active developer tools, not only the command-line tools. This checkout was checked with Xcode 27.2. The package requires Swift tools 6.2; the app targets iOS 26 and macOS 26. Windows and Linux cannot build the Apple user interface.

From the repository root, run the physics tests:

```sh
swift test --package-path Packages/BreakdownCore
```

Open `Breakdown.xcodeproj` in Xcode, select the Breakdown scheme, then choose My Mac or an installed iPhone simulator and press Run. A physical iPhone requires your own signing team; no signing credentials belong in Git. The simulator name is not fixed: choose one installed on your Mac.

For build-only checks that do not require signing:

```sh
xcodebuild -project Breakdown.xcodeproj -scheme Breakdown -destination 'generic/platform=macOS' -derivedDataPath build-mac CODE_SIGNING_ALLOWED=NO build
xcodebuild -project Breakdown.xcodeproj -scheme Breakdown -destination 'generic/platform=iOS Simulator' -derivedDataPath build-ios CODE_SIGNING_ALLOWED=NO build
```

On the shared Mac Mini, put build output and package scratch storage on the Team 4TB drive instead of those local folders. Pass an external path to `-derivedDataPath`, and `--scratch-path` to `swift test`.

Launch with the argument `-yourBreakDemo` to run the player's own break without tapping. Otherwise, watch the opening break, use the replay controls to pause or scrub, and choose Your break to aim and set power and tip height.

No server, account, API key or environment file is needed. If Xcode reports an unavailable destination, select an installed simulator or the generic build destination above. Build success is not a substitute for checking appearance and touch controls on a device.
