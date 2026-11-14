<!--
Author: GPT-6.1 Sol (inherited reasoning)
Date: 10-November-2026
PURPOSE: Record project changes, including documentation and licensing readiness without altering gameplay.
SRP/DRY check: Pass — checked existing README, specification and history; links retain one source for detailed design.
-->
# Changelog

All notable changes to this project are listed here, newest first. Versions follow SemVer.

## [0.2.4] - 13-November-2026

Author: Claude Sonnet 5.5 High

- What: The table now looks like a real pool table in a real room. The cloth stops exactly at the cushions (no more green sheet sticking out), the cushions have a rounded sloped nose, the wooden rails have a rounded edge, a real wood grain and pearl diamond sights, and each pocket is a proper well with a metal rim that a ball visibly drops into. There are head and foot spots on the cloth, legs under the table, and a dark floor with a warm pool of lamplight and a soft table shadow. The lamp is now a spotlight hung over the middle that casts shadows under every ball. Ball numbers are now real-sized discs at both ends of each ball's stripe line, drawn crisp and turned toward the camera, so in the resting rack nearly every number can be read on a phone.
- Why: The Boss judged the old look awful. This is package 1 of the Apple showcase glow-up plan: a still of the resting table should pass for a product photo at a glance.
- How: Lighting route confirmed against the installed Xcode 27.2 SDK: a SpotLight with shadows (available since iOS 18) as the key light, and the existing generated lamp picture kept as image-based light and retuned. New files for custom mesh building (TableMeshes), and for cloth, wood and floor pictures drawn in code (SurfaceTextures); the table builder and ball pictures were rebuilt. Everything new sits under the one table group, so the melt into the Lens still fades it all, and the Lens view shows none of it. Physics code is untouched. Checked: iPhone simulator stills at rest, mid-break and at four points of the melt; iPhone and Mac builds; physics tests. Not checked on a real device. Known gaps: no soft penumbra control on shadows (RealityKit offers none), the felt weave is drawn into the colour rather than a normal map, and the Lens still shows the old trails (package 2).

## [0.2.3] - 13-November-2026

Author: Claude Sonnet 5.5 Medium

- What: Nothing changes on screen. The drawing code is now split into separate files for the table, the Lens, and the camera, with a short coordinator on top.
- Why: The glow-up plan has three people changing the table look, the Lens, and the camera at once. One big file would have made them collide.
- How: The old single scene file became four files, each with a header saying what belongs in it. Checked: iPhone and Mac builds succeed, the physics tests all pass, and screenshots from the iPhone 17 Pro simulator match the old build (the title and table frames are identical to the pixel; the Lens frames show the same grid, trails, rings, arrows and caption). Not checked on a real device.

## [0.2.2] - 11-November-2026

Author: Claude Sonnet 5.5 Medium

- What: First look pass. The balls now reflect a warm lamp so they look glossy, the table is lit warmer, trails are wider where a ball is faster and have a soft glow strip, and all text uses Apple's own fonts (New York serif for titles and equations, the standard system font for labels, its monospaced cut for numbers) under one shared colour set. Controls are a solid dark strip instead of frosted glass. A new launch argument, -muteSound, silences the game for testing.
- Why: The game looked generic and janky. This is the first slice of the plan to make it worth featuring on iPhone Duo. Gameplay and physics are unchanged.
- How: New Theme file shared by the screen and the 3D scene; a lamp reflection image drawn in code and applied as image-based light; trail pieces get per-point width from the recorded speed plus a wider faint child strip. Still to do: trail pieces still appear in small steps (a shader-driven trail is the next rendering job), no bloom (iOS 27 only, needs an availability check), rails are still plain boxes, pockets are still flat discs. Checked: iPhone and Mac builds succeed, physics tests unchanged, and screenshots on the iPhone 17 Pro simulator before and after the Lens melts in. Not checked on a real device or the Duo.

## [0.2.1] - 11-November-2026

Author: Claude Sonnet 5.5 Medium

- What: The game now builds for iPhone, iPad and Mac, and the TestFlight build runs on iPad as well as iPhone.
- Why: The earlier build was set to iPhone only to get past Apple's first checks. The Boss wants all devices.
- How: Turned iPad support back on and allowed all four screen orientations, which Apple requires for iPad. Checked clean builds for Mac, iPhone and iPad hardware and the simulator. Build number 3.

## [0.2.0] - 11-November-2026

Author: Claude Sonnet 5.5 Medium

- What: You can now keep playing after the break. Take shot after shot from wherever the balls stopped: aim with a slider and nudge buttons, set power, cue-tip height (follow and draw) and side spin, then shoot. A scratched cue ball goes back on the head spot, pocketed balls stay gone, and Re-rack starts a fresh game. The new app icon (drawn by the other assistant) is in this build.
- Why: Until now the game was one break and a replay. This turns it into something you can play, which is the next milestone on the roadmap.
- How: A small new piece of the physics package carries the resting layout from one recorded shot to the next, with tests for the layout, the scratch respot and repeatability. The app panel switches from break controls to shot controls after the first shot. Pocket jaws and knuckles are still not built. Build number 2.

## [0.1.3] - 11-November-2026

Author: Claude Opus 5.5 High

- What: Recorded the Boss's decision to ship the pool launch natively in Swift for iPhone Duo and keep Unreal for the later smashing phase. Corrected the Duo research note against Apple's own pages.
- Why: Apple counts an app as optimized for iPhone Duo only when built with the iOS 27.1 SDK or later, and Unreal does not yet target it; the Duo simulator, needed for pose testing and store screenshots, also favours the native app.
- How: Updated the Duo research note (new decision section and corrections: no second live display through scene accessories, hinge as a smoothed control only, confirmed screenshot sizes), spec section 14, README and roadmap. No code changed.

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
