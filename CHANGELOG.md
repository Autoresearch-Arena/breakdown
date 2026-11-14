<!--
Author: Claude Sonnet 5.5 High
Date: 13-November-2026
PURPOSE: Record project changes, including documentation and licensing readiness without altering gameplay.
SRP/DRY check: Pass — checked existing README, specification and history; links retain one source for detailed design.
-->
# Changelog

All notable changes to this project are listed here, newest first. Versions follow SemVer.

## [0.3.1] - 13-November-2026

Author: Claude Sonnet 5.5 High

- What: The Physics Lens now fits and glows. The whole table sits inside the screen, clear of the status bar, the title and the controls, in portrait and landscape on iPhone, iPad and Mac window shapes. Trails glow (a bright core inside a soft halo, with the system bloom added where the system has it), fade with age so the newest second or two is bright and older path stays as a faint trace, and stay exact when you scrub back and forth. Impact rings and velocity arrows glow and sit above the trails. The grid is quieter and now shows the cushion line, the rail outline and a ring at every pocket. A small legend (amber is sliding, cyan is rolling, thicker is faster, older fades) appears the first time trails show. With Reduce Motion on, the table and Lens cross-fade under one steady near-overhead camera instead of swinging.
- Why: The Boss called the look awful: the table ran off the screen and behind the title in portrait, the trails were thin flat scribbles that all stayed on screen, and nobody could read a paused frame.
- How: Camera framing is now exact maths (new CameraFraming file) fed by the window's real size and safe areas; trails are two meshes whose vertices carry the time the ball was there, with a generated picture slid along by the playback clock, so the fade is a pure function of the clock and no trail piece is ever switched on or off; rings use a fixed span of clock time. Bloom is behind an availability check (iOS 27 and macOS 27 only; the app targets 26). Checked: iPhone simulator (iOS 27.2 and 26.5) and Mac builds succeed, the 15 physics tests pass, a 170-case framing sweep passes, scrub exactness passes by fingerprint and by identical screenshots after a forward-and-back tour. Not checked: a launched Mac window, a real device, the largest text size. Physics untouched.

## [0.3.0] - 13-November-2026

Author: Claude Sonnet 5.5 High

- What: Every control is now a standard Apple control. Buttons are Liquid Glass, play and pause morph with the system symbol effect, speed is a segmented control (a menu at the largest text sizes), and Lens and Your shot are toggle buttons whose label never changes, so the buttons beside them no longer jump. The caption has moved off the action: under the title on a phone held upright, in a side column on iPad, Mac and any sideways screen, with a ring around the ball it describes and a thin line back to the card. The shot panel (break, then shot after shot) works exactly as before but is built from standard sliders and buttons, and the table now moves up to clear it instead of being covered. The status label at the top right wraps instead of running off the edge. The scrub bar has a full-size touch area, a light haptic tick at each impact as you drag, and speaks its position to VoiceOver. On the Mac there is a real window toolbar, a Playback menu (space play or pause, Command-R replay, Command-L Lens, Command-1 to 4 speed, Command-Y your shot), pointer hover feedback and a minimum window size.
- Why: The Boss judged the old look awful. The glow-up plan (package 3) asks for standard parts, one palette, text that scales, safe areas, 44 point touch targets and VoiceOver support, and a Mac build that has been looked at.
- How: ShowpieceView was split into ShowpieceView (layout), TableStage (hosts the 3D scene), PlaybackControls, ScrubBar, CaptionViews, ShotPanel, Surfaces, MacChrome and Theme. Colours live once in Theme with light, dark and increased-contrast values. All text uses system text styles. The controls get their room from a measurement, so large text pushes the table up instead of hiding it. The ring is found by projecting the ball's table position (from the recorded timeline) through the camera; no model change. Not changed: the physics package, ShowpieceModel, the table, Lens, camera and sound files. Checked: iPhone simulator and Mac builds succeed, the physics tests pass, and screenshots on an iPhone 17 Pro simulator (portrait, landscape, largest text size, Increase Contrast, and Reduce Transparency compared on against off), an iPad Pro simulator and the Mac build were looked at, and the Mac Playback menu was clicked through. When the ball a caption describes is hidden behind the caption card (phone portrait puts the card across the top of the table) the ring is left out; the camera needs a top margin to fix that properly. Not checked: a real device, a real VoiceOver run, haptics on hardware, the look with Reduce Motion on (the setting is honoured in the code, but no motion was compared), light appearance (the app stays dark because the table is a dark room).

## [0.2.5] - 13-November-2026

Author: Claude Sonnet 5.5 Medium

- What: The break now has a proper sound and, on phones with a haptic motor, a feel. A sharp crack when the rack bursts, soft clicks for light contacts and brighter ones for hard hits, a weighty thump on the rail (heavier for harder hits), a short tock for the cue tip, and a thud followed by a rattle when a ball drops. The phone taps along with the same events, harder for stronger impacts. Nothing changes on a Mac or in the simulator, which have no haptic motor, and the mute launch switch still silences everything.
- Why: The break should feel like something hit something. Before, thirty contacts at the same instant were played as a pile of identical clicks, and nothing was felt.
- How: A new mapping file turns the impacts crossed in a frame into a few cues (one crack plus a few scatter clicks, not thirty sounds), scaled by each impact's recorded strength. Sound and haptics both read those cues. Haptics only fire while the clock plays forward live, so dragging the scrubber stays quiet and still. Haptics stay on under Reduce Motion, since that setting is about on-screen movement; the system's own haptics switch is still respected. A new launch switch, log feel, prints each cue for checking against the recording. Checked: builds and physics tests (see the work report). Not judged by ear or by hand: the actual sound and feel were not heard or felt, only checked through the cue log.

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
