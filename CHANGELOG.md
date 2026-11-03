# Changelog

All notable changes to this project are listed here, newest first. Versions follow SemVer.

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
