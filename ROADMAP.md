<!--
Author: GPT-6.1 Sol (inherited reasoning)
Date: 10-November-2026
Edited: Claude Opus 5.5 High, 21-November-2026 (replaced with a pointer to the order-of-work plan of 21 November, per
        plans/21-Nov-2026-release-safety-plan.md package 4; the items that are done (pocket jaws and knuckles, spin and
        elevation controls, trick shots, replay comparison) are removed rather than repeated here).
PURPOSE: Say in one place where the list of unfinished work lives and what is next, without duplicating the plans.
SRP/DRY check: Pass - the plans folder holds the steps; this page only points at them and names the order.
-->
# Roadmap

The work still to do is planned in the plans folder, and its front page says what comes first and why:
[plans/21-Nov-2026-award-gaps-order-plan.md](plans/21-Nov-2026-award-gaps-order-plan.md). That page is the roadmap;
this one only summarises it.

## Next, in order

1. **Prove the physics.** Finish the spec's test list, check the physics against real-table behaviour, and put every
   physics change behind a switch so authored shots keep working (physics proof plan). The tests run before every
   upload (release safety plan).
2. **Make it real.** Real rails, a real cue strike with miscues, pockets that can refuse a fast ball, and a guard
   against wedged balls (rails, cue-strike, and pockets-and-jams plans).
3. **Play a real game.** Eight-ball and nine-ball for two players with turns, fouls, ball in hand and a winner (rules
   and games plan), then a computer opponent.
4. **Tune once, re-author once.** Tune the guessed numbers against the real-table checks, re-author every trick shot
   and puzzle on the new physics, and make it the default (physics proof plan, package 4).
5. **Finish the rest.** The opening for a first-time player and lessons, the look of the table up close, iPad and Mac
   as themselves, the table spoken aloud for blind players, sound, and scores on the other three tables (their plans
   in the same folder).

## Later

Scan-and-smash (the Physics Lens pointed at a scanned room) remains a later design idea, not current work. Its design
is in the spec, section 12; nothing of it is built. Device claims in the older research notes need checking before any
of it is started. The [engine decision](docs/2026-11-03-duo-research.md) ships pool natively in Swift and keeps Unreal
for that later phase; no Unreal project is committed. Its possible camera, depth and machine-learning scope would need
its own program eligibility review, so do not describe this repository as permanently free of such plans.
