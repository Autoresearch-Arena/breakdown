<!--
Author: Claude Fable 5.2 High
Date: 21-November-2026
PURPOSE: Plan for making the cue's hit on the cue ball real: speed lost to an off-centre hit, the cue ball's sideways
         deflection with side spin, and miscues. Written for junior developers: what is missing, where it goes, the
         order of work and the tests.
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
