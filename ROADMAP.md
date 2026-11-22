<!--
Author: GPT-6.1 Sol (inherited reasoning)
Date: 10-November-2026
Edited: Claude Opus 5.5 High, 21-November-2026 (replaced with a pointer to the order-of-work plan of 21 November, per
        plans/21-Nov-2026-release-safety-plan.md package 4; the items that are done (pocket jaws and knuckles, spin and
        elevation controls, trick shots, replay comparison) are removed rather than repeated here).
Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0: the five steps of the 21 November order shipped in 0.6.6, so
        the next step is the bug plan for 0.7.0, then what the spec still lacks).
Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.2: the release item no longer promises a layered icon; the approved
        momentum artwork is the icon again, on the Mac too).
PURPOSE: Say in one place where the list of unfinished work lives and what is next, without duplicating the plans.
SRP/DRY check: Pass - the plans folder holds the steps; this page only points at them and names the order.
-->
# Roadmap

The work still to do is planned in the plans folder. The plan being worked on now is
[plans/21-Nov-2026-bugs-after-0-6-6-plan.md](plans/21-Nov-2026-bugs-after-0-6-6-plan.md); this page only summarises it.

Done in 0.6.6, from the order of 21 November: the physics proved against real-table checks and made the default,
real rails, a real cue strike with miscues, pockets that refuse a fast ball, eight-ball and nine-ball with a computer
opponent, the opening for a first-time player, six lessons, iPad and Mac layouts, the table spoken aloud, new sound,
and scores on the three other tables.

## Next, in order

1. **Version 0.7.0: every bug the review of 0.6.6 found** (the bug plan): the stroke and the first minute, touch and
   zoom, free play and lessons, matches and the computer, the three other tables, the physics the Lens shows, the Mac
   and iPad pointer, the look and sound, the release (the approved icon on the Mac too, the Mac on TestFlight, the store page), the
   controller and translations, and VoiceOver last.
2. **What the spec still lacks** (its status note): the what-if fork in the Lens first, then predict-the-shot and the
   break challenge, a daily challenge, and a computer opponent for the three other tables.

## Later

Scan-and-smash (the Physics Lens pointed at a scanned room) remains a later design idea, not current work. Its design
is in the spec, section 12; nothing of it is built. Device claims in the older research notes need checking before any
of it is started. The [engine decision](docs/2026-11-03-duo-research.md) ships pool natively in Swift and keeps Unreal
for that later phase; no Unreal project is committed. Its possible camera, depth and machine-learning scope would need
its own program eligibility review, so do not describe this repository as permanently free of such plans.
