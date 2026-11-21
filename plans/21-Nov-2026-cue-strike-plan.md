<!--
Author: Claude Fable 5.2 High
Date: 21-November-2026
PURPOSE: Plan for making the cue's hit on the cue ball real: speed lost to an off-centre hit, the cue ball's sideways
         deflection with side spin, and miscues. Written for junior developers: what is missing, where it goes, the
         order of work and the tests.
Edited: Claude Opus 5.5 High, 21-November-2026 (step 8 list of the authored shots the new strike touches, at the end).
SRP/DRY check: Pass - checked spec section 3.3 (cue strike, miscue, squirt), Simulation.swift (applyStrike,
         applyRaisedStrike), AimGauges.swift, ShowpieceModel.swift and the physics proof plan.
-->
# A real cue strike

## In plain words

When the player hits the cue ball off centre, three things happen on a real table that do not happen in Breakdown.
The ball comes out slower, because some of the hit went into spin. With side spin the ball leaves slightly off the
line of the cue, away from the side that was struck. And if the tip is too far from the centre it slips: a miscue.
In Breakdown every hit sends the ball out at full speed, dead straight, and the tip can reach well past the point
where a real tip would slip. Side spin is therefore free, which is the single thing good players know it is not.

Depends on: the physics proof plan, package 1 (the switch). Independent of the rails plan; can be built alongside it.

## What exists today

- Simulation.swift, applyStrike and applyRaisedStrike: the ball's speed is exactly the power the player chose; spin
  is that speed times the tip offset, by the right formula; no deflection; no miscue.
- CueStrike (Parameters.swift) carries direction, speed, tip up, tip side and elevation. "Speed" means the ball's
  launch speed.
- The tip can travel to seventy percent of the radius (ShowpieceModel.tipLimit; AimGauges.swift draws the ring there
  and calls it the miscue limit). The spec puts the real limit at half the radius.
- The cue-strike event (LensEvent) has no miscue flag, though the spec lists one.

## The model to build (spec section 3.3)

- Speed with offset. Keep "speed" meaning the launch speed of a centre hit, so the power control and every authored
  shot mean the same thing at centre. For an off-centre hit multiply by: cue mass plus ball mass, divided by cue mass
  plus ball mass plus five halves of the cue mass times the squared offset over the squared radius. The squared
  offset is tip-up squared plus tip-side squared. New parameter: cue mass (the spec's value).
- Spin. Unchanged formula, but it uses the reduced speed.
- Deflection. The ball's direction turns away from the struck side by a small angle. The tangent of that angle is:
  five halves times x times the square root of one minus x squared, divided by one plus the ball mass over the
  shaft's effective end mass plus five halves of x squared, where x is the side offset over the radius. Only the side
  offset deflects. Use the tangent directly as the sideways-to-forward ratio and re-normalise the direction with a
  square root; no trigonometry. New parameter: effective end mass, set so the angle at half-radius offset is
  between two and three degrees (verify with a test before choosing the number).
- Miscue. If the total offset exceeds the limit (tip grip over the square root of one plus tip grip squared, times
  the radius; about half the radius), the strike is a miscue: the ball leaves at a fraction of the speed, deflected
  by a seeded random angle within a stated range, with little spin. New parameters: tip grip, miscue speed fraction.
  Randomness comes only from the shot's seed, through the existing seeded generator in Rack.swift.
- Raised cue. The offsets are already measured across the cue. Apply the same speed factor and miscue rule; apply
  the deflection in the horizontal plane only.

## Steps

1. Parameters.swift: add the four parameters; hash them only above generation one. Add a strikeModel note at the top
   of the file explaining that speed is the centre-hit launch speed.
2. Simulation.swift: add one private function that turns a CueStrike into the actual launch (direction, speed,
   spin, miscue or not) and have both strike functions call it at generation two and above. Generation one keeps
   the present lines exactly.
3. LensEvent.swift: add the miscue flag and the deflection angle's sine to the cue-strike event. Check the timeline
   file format and its content hash; a new field must not change the hash of old recordings (follow how the jump
   fields were added).
4. Captions.swift: two new captions, with translations and the equation for the maths option: "Off-centre hits
   are slower" and "Side spin pushes the cue ball off line", plus one for a miscue.
5. AimGauges.swift and ShowpieceModel.swift: draw the miscue ring at the true limit. Let the tip dot travel a little
   past the ring in free play and matches so a miscue can really happen; inside trick shots and puzzles keep the old
   travel until they are re-authored. Give the ring a VoiceOver description.
6. Aim guide (AimOverlay.swift and AimGeometry.swift): the guide line must show where the ball will really go. It
   is drawn from the aim direction today; take the direction from the same strike function so the guide bends with
   side spin. Without this step the new physics will feel like a bug.
7. Sound and feel: a miscue gets its own sound and haptic (FeelMapping.swift has the list of kinds).
8. Authored content: trick shots and puzzles that use side spin will miss on the new generation. Do not fix them
   here; the proof plan, package 4, re-authors everything once. List here which ones use side spin or tip offsets
   beyond half the radius (BreakProbe can print each shot's settings) so that step knows its size.

## Tests

- Spec test 12: follow, draw, left and right give the right spin directions; a centre hit gives none; launch speed
  matches the formula at five offsets; the miscue limit sits where the formula says, at three elevations.
- Deflection: zero at centre; away from the struck side; grows with offset up to the limit; two to three degrees
  at half-radius; top and bottom offsets alone deflect nothing.
- Miscue: same seed gives the same miscue; different seeds differ; speed is reduced.
- The proof plan's real-world case 10 now passes.
- Generation one is bit-for-bit unchanged.

## Done when

The tests pass, the guide line bends with side spin, a deliberate miscue can be made in free play behind the
developer flag, and the list for step 8 is written into this plan.

## Step 8: the authored shots this touches (written 21-Nov-2026, from TrickShots.swift and EightBallSituations.swift)

The new strike changes three things for authored content. Every off-centre hit launches slower (the speed factor), so
every shot with any tip offset plays a little shorter on the new physics; that is nearly all of them and needs no list
beyond "all of them, re-check speed". Side spin now pushes the cue ball off line. And an offset past the grip limit
(about half the radius, 14.3 mm on the pool ball) is now a miscue. Half the radius is 14.29 mm; offsets below are the
authored solution's total offset, the square root of height squared plus side squared.

Shots that use side spin (they will aim off by about 2.5 degrees per half-radius of side and must be re-aimed):

- Trick shot 8, Throw It In: side -12.0 mm with 7.5 mm of height, total 14.15 mm. Just inside the grip limit (0.495 of
  the radius against 0.502), so a small slip in the re-authoring search will tip it into miscues; search with the
  side and height window in mind.
- Behind the 8-Ball 6, The Z Shot, escape A (two-rail Z kick): side -5.0 mm, height -6.0 mm, total 7.8 mm. Deflects
  about 1 degree.

Shots past the grip limit (they will miscue on the new physics and must be re-authored with the tip inside the ring,
which for these massé and swerve shots also means more elevation or speed to get the same curve):

- Trick shot 9, The Massé: side 17.1 mm, height -3.5 mm, total 17.5 mm (0.61 of the radius), raised to 0.5.
- Behind the 8-Ball 4, Bend Around, escape A (swerve past the 6): side 20.0 mm, height -1.5 mm, total 20.1 mm (0.70),
  raised to 0.30.
- Behind the 8-Ball 8, Massé for the Win, escape B (full massé): side 17.0 mm, height -5.0 mm, total 17.7 mm (0.62),
  raised to 0.80.
- Behind the 8-Ball 11, Full-Table Swerve, escape B: side -20.0 mm, height -0.5 mm, total 20.0 mm (0.70), raised to 0.40.

Close to the limit without side spin (no deflection, but the speed factor is largest here, about 30 percent slower at
0.47 of the radius):

- Trick shot 3, The Long Bridge Draw: height -13.5 mm (0.47 of the radius).

Skill windows that reach past the limit: several measured windows extend the tip past 14.3 mm (Combination Chain's side
window is 19.5 mm, Two-Rail Kick's and Point-Blank B's height windows reach 14 to 19.5 mm). On the new physics the edges
of those windows are miscues, so every window must be measured again in the re-authoring pass, not copied.

Every authored solution in both files was checked for side and for a total offset past the limit; the shots above are
all of them. Every rail-using shot also changes with the new rails (rails plan), so package 4 of the proof plan re-runs the whole
TrickAuthoring and EightBallAuthoring check anyway; this list says which shots need more than a nudge of aim and speed.
