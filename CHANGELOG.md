<!--
Author: GPT-6.1 Sol (inherited reasoning)
Date: 10-November-2026
PURPOSE: Record project changes, including documentation and licensing readiness without altering gameplay.
SRP/DRY check: Pass — checked existing README, specification and history; links retain one source for detailed design.
-->
# Changelog

All notable changes to this project are listed here, newest first. Versions follow SemVer.

## [0.2.0] - 11-November-2026

Author: Claude Sonnet 5.5 Medium

- What: You can now keep playing after the break. Take shot after shot from wherever the balls stopped: aim with a slider and nudge buttons, set power, cue-tip height (follow and draw) and side spin, then shoot. A scratched cue ball goes back on the head spot, pocketed balls stay gone, and Re-rack starts a fresh game. The new app icon (drawn by the other assistant) is in this build.
- Why: Until now the game was one break and a replay. This turns it into something you can play, which is the next milestone on the roadmap.
- How: A small new piece of the physics package carries the resting layout from one recorded shot to the next, with tests for the layout, the scratch respot and repeatability. The app panel switches from break controls to shot controls after the first shot. Pocket jaws and knuckles are still not built. Build number 2.

## [0.1.2] - 11-November-2026

Author: Claude Sonnet 5.5 Medium

- What: Added the app version (0.1.1), build number 1, the no-special-encryption declaration, a placeholder app icon, and made the iOS build iPhone-only.
- Why: App Store Connect refused the first TestFlight uploads: empty version fields, no app icon, and iPad orientation rules.
- How: Build settings in both configurations plus an asset catalog with a generated 1024-pixel icon; no gameplay code changed.

## [0.1.1] - 10-November-2026

Author: GPT-6.1 Sol (inherited reasoning)

- What: Added the MIT license, clear setup and project scope, roadmap, dependency/research notices and repository-readiness review. Expanded exclusions for local credentials and build folders.
- Why: Prepare the original game repository for review without overstating finished work, ownership or program acceptance.
- How: Preserved the original history and private visibility, reviewed all published historical files, and checked existing tests and both platform builds. No gameplay code changed; see the readiness review for exact evidence and remaining decisions.

## [0.1.0] - 03-November-2026

Author: Claude Sonnet 5.5 Medium

- What: First running app. Hand-written Xcode project (iPhone and Mac, deployment targets 26), the BreakdownCore package (event-driven pool solver, recorded timeline, event model, twelve passing tests), the table scene, the cold open (break, freeze, melt, rewind, slow motion), the Physics Lens (grid, phase-coloured trails, velocity arrows, impact rings, captions with equations), replay controls and generated sound.
- Why: The spec's milestone one: a running app that shows the break and the table melting into the physics.
- How: Solver finds exact contact times with a quartic root finder, uses closed-form segments per motion phase, and records everything; playback only reads the timeline. Deviations from the spec: the cushion uses the flat-normal Level A model with no tilt yet; equations and captions are a SwiftUI card, not billboards in the scene; rack jitter is a fifth of the gap so no ball pair starts overlapping; the iPhone cold open was checked in the simulator, the Mac build compiles and launches but was not looked at yet.

## [0.0.2] - 03-November-2026

Author: Claude Opus 5.5 Medium

- What: Finalized the product and build spec after three reviews (Apple API check, physics check, fit with the Boss's ask).
- Why: Reviews found physics test errors, a determinism rule that contradicted itself, missing pocket and audio work in the first milestone, and a Part One question that was not a real decision.
- How: Applied the findings that held up; deployment targets moved to 26 so everything is testable here; milestone one split into 1a and 1b with a Step Zero.

## [0.0.1] - 02-November-2026

Author: Claude Opus 5.5 Medium

- What: Created the repository with the README, this change log, a Swift/Xcode ignore file, and the product and build spec in docs.
- Why: The Boss wants a native iPhone and Mac physics game. Pool comes first, with the table "melting" into the physics. Scan-and-smash with the iPhone's depth scanner comes later. The spec settles what we are building before any code is written.
- How: Four research passes (pool physics, Apple SDKs checked against the copies installed on this Mac along with a test build in the Simulator, game and physics-view design, scan-to-smash). One writer drafted the spec. Three reviewers checked it for Apple API accuracy, physics correctness, and fit with what the Boss asked for. A final pass applied their fixes.
