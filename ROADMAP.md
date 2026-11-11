<!--
Author: GPT-6.1 Sol (inherited reasoning)
Date: 10-November-2026
PURPOSE: Show unfinished game work and concrete completion checks, grounded in existing design milestones.
SRP/DRY check: Pass — checked existing README, specification and history; links retain one source for detailed design.
-->
# Roadmap

Breakdown has a running pool prototype. The work below extends that game; it is not a promise that every feature is underway or a declaration of hours committed to a program.

## Next playable milestone

- Complete pocket jaws and knuckles. Slow centered shots should drop, while near-jaw shots should rebound or rattle with the events visible in replay.
- Extend aim, cue-tip offset and elevation controls beyond the current break. Verify follow, draw and side-spin shots through recorded outcomes, not only visual effects.
- Check the game on a physical iPhone and Mac: sound, touch and pointer controls, window resizing and readable Lens captions. Capture and inspect the key opening/replay states.

## Explain and teach

- Add spin rings, what-if ghost shots and captions selected from recorded physics events. Scrubbing must show the same event state in either direction.
- Build guided lessons for stun, follow, draw and throw, with a clear debrief explaining the outcome.
- Add trick-shot and prediction challenges. Before sharing deterministic daily seeds, verify repeatability across the supported devices.

## Polish and later engine work

- Improve accessibility and Reduced Motion, controller support and recorded clip export.
- The later [engine decision](docs/2026-11-03-duo-research.md#engine-decision-boss-03-november-2026-unreal) calls for an Unreal implementation, retaining the Swift app as a reference. A port must preserve the Lens event model and verify the solver against the reference tests. No Unreal project is committed yet.
- Scan-and-smash remains a later design exploration, not current functionality. Device-specific claims in the older research notes need primary-source verification before implementation. Its potential camera/depth data and machine-learning scope require a separate program eligibility review; do not describe this repository as permanently free of such plans.

The [full specification](docs/2026-11-02-breakdown-spec.md#10-milestones) retains the detailed design and acceptance lists. The current submission candidate is ordinary game/physics development; do not silently change the stated scope or claim reviewer approval.
