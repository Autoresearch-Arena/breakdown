<!--
Author: Claude Fable 5.2 High
Date: 21-November-2026
PURPOSE: Plan for proving Breakdown's physics instead of assuming it: fill in the missing tests from the spec, build
         the outside-reference checks the spec promised, tune the guessed numbers against them, and set up the one
         safe way to change physics without breaking the trick shots. This plan goes FIRST; the rails, cue and pocket
         plans all depend on it. Written for junior developers.
SRP/DRY check: Pass - checked the spec (sections 3.4, 3.5, 9.1, 9.1b), the four existing test files and BreakProbe.
         This plan adds the missing tests and the reference checks; it does not restate the spec's formulas.
-->
# Proving the physics, and changing it safely

## In plain words

The game's whole promise is that the physics on screen is real. Today that promise rests on first guesses. Five of
the numbers that decide how a ball behaves (cloth grip, rolling drag, spin fade, rail bounce, rail grip) are marked
"calibrate" in the code and were never calibrated. The spec lists twenty-five tests and a set of checks against
real-world behaviour; about half the tests and none of the real-world checks exist. And every trick shot and
Behind the 8-Ball puzzle was authored on today's exact physics, so any physics fix can silently break them.

This plan fixes the footing first: finish the tests, build the real-world checks, tune the numbers, and put every
physics change behind a version switch so old content keeps working until it is re-authored once.

## What exists today

- Tests: Packages/BreakdownCore/Tests has four files. They cover slide-to-roll, stopping distance, the ninety-degree
  rule, momentum and energy at events, the mirror bounce, pockets, jumps and the other tables' features.
- Missing from the spec's list in section 9.1 (numbers are the spec's): 2 rolling-ball departure, 3b real rail
  angle, 4 side spin on a rail, 7 mirror symmetry, 8 comparison against tiny-step integration, 11 break statistics
  over many seeds, 12 cue strike, 15 file round trip, 18 spin-down time, 19 energy ledger, 21 frozen balls, 23
  relabelled balls, 24 stick-or-slide oracles. Check each against the test files before you start; write only what
  is truly missing.
- The parameters value (Parameters.swift) has a version field, but nothing reads it to choose behaviour. Free play
  stamps version one; the default is two. It only changes the hash.
- BreakProbe (Sources/BreakProbe) is the command-line tool that authored the trick shots and puzzles. TrickSearch
  can search for a shot that works; TrickAuthoring and EightBallAuthoring check the authored ones.

## Rules for this work

1. The solver stays free of Foundation and of any math library: add, subtract, multiply, divide and square root only.
   A test already enforces this. Tests themselves may use anything.
2. No stubs and no invented numbers. A reference value in a test is either derived (show the derivation in a
   comment) or measured (say in the comment what kind of measurement, in general terms; no names, brands or links).
3. A level strike with default parameters must stay bit-for-bit what it is today until package 4 flips the switch.
   The test testLevelStrikesAreBitForBitUnchanged guards this; never weaken it.
4. Use a scratch folder on the Team 4TB drive for package builds (pass the scratch path to the test command).

## Package 1: the physics switch

Goal: one safe way to turn new physics on.

Steps
1. Add a model-generation field to PoolParameters (a plain integer; generation one is today's behaviour). Unlike the
   existing version field it is read by the solver. Fold it into the hash only when it is not one, behind its own
   marker, exactly as the jump numbers were folded in, so today's hashes do not change.
2. Every later physics change (rails, cue strike, pockets, jam guard) checks this field and takes the old path at
   generation one. Document the rule at the top of Simulation.swift.
3. Leave the default at generation one. Add a test that default parameters hash to the same value as before (record
   today's hash in the test first).
4. Add a launch flag to the app, for developers only, that plays free play on the newest generation, so new physics
   can be felt before it is the default. ShowpieceModel's solve function is the single place every shot passes
   through; set it there.

Done when: all tests pass unchanged and the flag is the only way to reach new behaviour.

## Package 2: finish the spec's test list

Write the missing tests from section 9.1 of the spec, one test per numbered item, named after it. Notes on the ones
that are easy to get wrong:

- Item 8: integrate the sliding equations with a very small fixed step in the test and compare position, velocity
  and spin with the solver's closed form at ten sample times.
- Item 11: run the break over two hundred seeds. Check ball count, momentum at every event, that no solve hits the
  event limit, and that left and right halves of the table receive balls in roughly equal numbers. State the band.
- Item 21: start with two balls touching, and with a ball touching a rail, and strike another ball elsewhere. No
  event may involve the resting pair until something reaches them.
- Item 23: swap two object balls' numbers and positions; resting positions must match after swapping back, except
  where the tie-break is documented.
- Item 12 belongs to the cue plan and items 3b and 4 to the rails plan. Write them here as tests that describe the
  target behaviour and mark them as expected failures with a comment naming the plan that will make them pass.

Done when: every item in 9.1 has a test or a written reason in the test file for why it does not apply.

## Package 3: checks against the real world

Goal: a second test file, RealWorldTests, where each case states a behaviour any player can verify on a real table,
a pass band, and what it constrains. These use bands, not exact values.

Cases to write
1. Roll distance: a lag shot from the head line that should die near the far rail after one length. Constrains
   rolling drag.
2. Stop shot: a firm centre-ball hit straight on from one diamond away stops the cue ball dead; a soft one rolls
   through. Constrains cloth grip (how fast backspin or slide turns to roll).
3. Draw distance: a firm low hit straight on from one diamond away pulls back roughly a table width, not a table
   length. Constrains cloth grip and the cue strike.
4. Thirty-degree rule: a rolling cue ball deflects about thirty degrees over a wide range of cut angles.
5. Throw: a cut shot at slow speed is thrown a few degrees off the line of centres; less at high speed; side spin
   can cancel it. Constrains ball-to-ball grip.
6. Rail speed loss: a ball rolled straight into a rail comes back with a little under half its energy at medium
   speed, and proportionally less at high speed. Constrains rail bounce.
7. Rail angle: a rolling ball sent into a rail at forty-five degrees comes off shorter (steeper) at slow speed and
   longer at high speed. Constrains rail grip.
8. Lengths of the table: a hard break-speed ball with no rack travels about four to five lengths before stopping.
9. Spin-down: a ball spinning in place like a top at a brisk rate stops in a handful of seconds.
10. Sideways deflection of the cue ball with side spin, and speed lost to an off-centre hit: written here, expected
    to fail, passed by the cue plan.
11. Jump height: a steep, hard, centre hit clears a ball one ball-width away; a shallow one does not.

For each case: set up the shot through the public solver, measure from the timeline, compare with the band. Put
the band and the reasoning in a comment above the test.

Done when: every case runs and reports pass or fail, and a short table of results is added to this plan under a new
"Measured" heading (say how it was measured: local package test run).

## Package 4: tune, re-author, flip

Do this only after the rails, cue and pocket plans have landed behind the switch, so the content is re-authored once.

Steps
1. Add a sweep command to BreakProbe that runs the RealWorldTests cases over a grid of the five guessed numbers and
   prints how many bands each combination passes. Pick the combination that passes the most, preferring values in
   the middle of their plausible range. Record the chosen numbers and the sweep output in this plan.
2. The surfaces (PlaySurface.swift: tournament cloth, dive bar, ice, glass, sand, Moon) each override some numbers.
   Re-check that the ordinary cloths still pass the bands and that the strange ones still feel like their name.
3. Re-author the content on the new generation. Run the trick-shot and eight-ball authoring checks in BreakProbe.
   For every shot that no longer works, use TrickSearch to find new aim, power and tip values near the old ones and
   update the authored numbers in TrickShots.swift and EightBallSituations.swift. If a shot cannot be recovered,
   list it for the Boss; do not delete it quietly. Re-check the "how forgiving" windows and the puzzle ratings.
4. Re-pick the showpiece break (Rack.swift, showpieceBreak) with the BreakProbe sweep so the opening still drops two
   balls and keeps the cue ball up.
5. Flip the default generation. Old recordings keep working because playback reads the stored timeline.
6. Remove the "calibrate" comments from Parameters.swift and replace each with one line saying which checks fixed it.

Done when: all tests pass on the new default, every trick shot and puzzle is confirmed by the probe, and the
CHANGELOG says in plain words that the physics is now tuned against real-table behaviour.
