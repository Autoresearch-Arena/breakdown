<!--
Author: Claude Fable 5.2 High
Date: 21-November-2026
PURPOSE: Plan for two loose ends in the solver: pockets and holes that swallow a ball at any speed, and jammed balls
         that send the solver into a storm of tiny events (which can freeze the app). Written for junior developers.
SRP/DRY check: Pass - checked spec sections 3.3 (pockets) and 3.5 (Zeno guards), Simulation.swift, the eight-ball
         judge's event budget and PocketTests.swift.
-->
# Pockets that can refuse a ball, and no more jams

## In plain words

Two separate problems, both in the solver's event loop, so one plan.

First, a ball that reaches a hole drops, whatever its speed. On a real table a ball hit too hard across a side
pocket, or over a hole in the bed of a bar-billiards table, skips over it. The spec asked for this and for the
pocket event to record how fast and at what angle the ball came in, so the Lens can say "too fast for the pocket".

Second, when a ball is wedged (between two balls, or a ball and a rail), the solver can grind through tens of
thousands of tiny bounces. There is a hard limit that stops it, and the eight-ball judge works around it with a
smaller limit, but an ordinary shot in free play has no protection: the app solves on the main thread and can stall
for seconds. The spec designed a guard for this and it was not built.

Depends on: the physics proof plan, package 1 (the switch). Part B (jams) should ship as early as possible.

## Part A: pockets

What exists today
- Simulation.swift: in nextEvent, a ball on the cloth is captured the moment its centre is inside a hole's capture
  circle. applyPocket records the event with no speed or angle. Jaws and knuckles already make near misses rattle.
- Bed holes (bar billiards, bumper pool cups) use the same rule.

What to build
- A ball over a hole starts to fall. It is captured if, before its centre leaves the far side of the hole, it has
  fallen far enough that the far edge catches it; otherwise it crosses and carries on.
- Work it out in closed form, no stepping: the path across the capture circle is a chord; the time to cross is
  the chord length over the speed (ignore friction for this instant); the fall in that time is half of gravity
  times the time squared. Captured when the fall is at least a set fraction of the ball's radius (new parameter;
  start at one third and tune it in the proof plan). Compare squared quantities so no trigonometry is needed.
- Edge pockets have a back wall: a ball that crosses the hole on a line that ends in the pocket's back (between the
  two jaws) is always captured, as now. Only a ball whose line across the capture circle leaves on the table side
  can skip. In practice this is a fast ball clipping across the mouth of a side pocket.
- Bed holes have no back wall: the rule applies fully.
- A ball that skips a hole gets a new event kind (a rim skip) with its speed, so sound, haptics and a caption can
  mark it. It loses a little speed (new parameter).
- Every pocket event records entry speed and the angle between the ball's path and the pocket's centre line, as a
  sine and cosine.

Steps
1. Parameters.swift: the two new parameters, hashed only above generation one.
2. Simulation.swift: in nextEvent, at generation two and above, when a capture candidate is found compute the
   crossing test; produce either a pocket candidate or a rim-skip candidate at the time the ball leaves the circle.
   After a skip, that ball must not be tested against the same hole again until it has left the circle (keep a
   small per-ball "last hole skipped" marker and clear it on the next event for that ball outside the circle).
3. LensEvent.swift: entry speed and angle on pocket events; the new rim-skip kind. Keep old recordings' hashes.
4. Captions.swift: "Too fast for the pocket" with translations. FeelMapping.swift: a rim sound.
5. App drawing: TableScene.swift animates a ball sinking; check a skipped ball does not start to sink.
6. Other tables: re-check bar billiards and bumper pool default shots at generation two.

Tests
- A slow centred ball drops in every pocket and hole (already tested; keep).
- A ball crossing a bed hole off-centre at high speed skips; the same line at low speed drops.
- A break-speed ball straight into a corner pocket drops.
- A fast ball along the long rail past the side pocket does not drop; a slow one does.
- Speed at which a centred ball first skips a bed hole rises with hole size.
- Random sweep: no ball ends inside a hole's circle still on the cloth; nothing is not-a-number.

## Part B: jams

What exists today
- PoolSolver has a limit of sixty thousand events and ninety seconds. A wedged ball can use all of it.
- ShowpieceModel.solve runs on the main thread for every shot.
- Positions are nudged apart after a ball-ball hit by a vanishing amount; nothing detects a storm.

What to build (spec section 3.5, "Zeno guards")
- Storm detection: keep, per ball, the time and count of its recent impacts. If a ball has more than a set number
  of impacts inside one millisecond of game time, it is jammed.
- Resolution: bring every ball in the jam to rest in contact. That means zero velocity, keep vertical-axis spin,
  positions fixed up so nothing overlaps, and one event recorded (a new kind: settled in contact) listing the balls
  and the energy removed, so the energy ledger still closes and the Lens can caption it.
- Resting contact afterwards: a pair at rest and touching is skipped by the existing rule that ignores two
  stationary balls. A ball at rest touching a rail produces no event because it is not moving. Confirm both with
  tests.
- Applies at every generation, because it only changes shots that today hit the limit. Confirm that claim: run the
  trick-shot and puzzle authoring checks and the bit-for-bit test; if any normal shot changes, the threshold is too
  low.

Steps
1. Find real jams first. Add a BreakProbe command that solves ten thousand random free-play shots and prints every
   input whose event count passes five thousand. Save twenty of them as test fixtures. The eight-ball judge's notes
   name one: the steep jump in the "point-blank" puzzle wedges the cue ball in a narrow band of speeds.
2. Build detection and resolution in Simulation.swift's run loop. Comment why each number was chosen.
3. Lower the hard limit once the guard works, and log (not crash) if it is ever reached.
4. Move solving off the main thread in the app. ShowpieceModel.solve is called from many places and returns the
   timeline directly, so do this carefully: add an asynchronous solve used by shootNow and breakNow, show the cue
   following through while it runs, and drop a result that arrives after the player has moved on. EightBallMode's
   Scoring phase is the pattern. Table and surface changes may keep the direct call.
5. Remove the judge's reliance on the event budget only if its timings stay as fast; otherwise leave it.

Tests
- Every saved jam fixture finishes in under two thousand events and a few milliseconds.
- After each, no two balls overlap, nothing is inside a rail, and total energy did not rise.
- Spec test 21 (frozen balls stay quiet) passes.
- The bit-for-bit test and the authoring checks are unchanged.

## Done when

Part A's tests pass behind the switch. Part B's tests pass at every generation, a ten-thousand-shot random sweep
never exceeds two thousand events, and free play never blocks the screen while a shot is solved.
