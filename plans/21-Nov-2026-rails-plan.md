<!--
Author: Claude Fable 5.2 High
Date: 21-November-2026
PURPOSE: Plan for replacing Breakdown's flat-wall rail with the rail the spec designed: contact above the ball's
         centre, bounce that depends on speed, and the cloth's part in the rebound. Written for junior developers:
         what is wrong, the exact places to change, the order, and the tests that say it is right.
SRP/DRY check: Pass - checked spec section 3.3 (cushion, Level A), Impacts.swift, Simulation.swift and the physics
         proof plan. The formulas' source of truth is the spec; this plan says how to build and check them.
-->
# Real rails

## In plain words

A rail in Breakdown today is a flat vertical wall that touches the ball at the height of its centre and gives back
the same share of speed however hard it is hit. A real rail's nose sits above the ball's centre, so it pushes the
ball down into the cloth as well as back; it is livelier at low speed than at high speed; and that downward push is
why a ball with topspin or backspin comes off a rail differently. A pool player feels the difference on the first
bank shot. The spec designed the better rail (its "Level A") and the code built a simpler one and kept the name.

Depends on: the physics proof plan, package 1 (the switch) and package 2 (the target tests). Do those first.

## What exists today

- Impacts.swift, function cushion: horizontal normal, fixed restitution, Coulomb friction on the contact point, the
  vertical part of the friction impulse thrown away. Its header says the nose tilt "comes with Level B", which
  contradicts the spec.
- Simulation.swift: the four walls, the jaws, the knuckles and the posts all call that one function. The wall
  contact line is one ball radius from the nose line.
- Parameters.swift already has the nose height (used only for jumps).
- Two surfaces change rail bounce and grip (PlaySurface.swift).

## The model to build

All of it is in section 3.3 of the spec; read that first. In short:

- The contact point is above the centre by the nose height minus the radius. Call the sine of the tilt s (about a
  quarter) and its cosine c; c comes from s by a square root, so no trigonometry is needed.
- The normal on the ball is c times the horizontal inward direction, plus s straight down.
- Resolve the impact in three dimensions with that normal: restitution along it, friction against the slip of the
  contact point across it (the contact point is one radius from the centre, opposite the normal).
- Afterwards the ball has some downward speed. The bed stops it: remove the downward speed with no bounce and apply
  bed friction for that impulse, using the slate routine's friction part with zero restitution. This second small
  impact is what changes topspin and backspin at the rail.
- Restitution falls with the speed into the rail: start from the present value at walking pace and fall in a
  straight line to a floor at break speed. Two new parameters (the slope and the floor); both tuned in the proof plan.
- The ball's centre stops closer to the nose line than one radius: at the radius times c.

## Steps

1. Parameters.swift: add the slope and floor for rail restitution and fold them into the hash only when the model
   generation is above one.
2. Impacts.swift: add a new function beside cushion (keep the old one untouched for generation one). Inputs: the
   state, the horizontal inward normal, the parameters. It builds the tilted normal, does the three-dimensional
   impact, then the no-bounce bed impact, and returns the same result type with the summed impulses. Comment each
   stage. Use the existing three-dimensional ball-ball routine as a pattern for the vector work.
3. Guard against energy gain: after the impact, compute kinetic plus spin energy; it must not exceed the value
   before. The spec's test 5 sweeps this. If any case gains energy, clamp the friction impulse, do not ship it.
4. Simulation.swift: where walls are built, use the new contact distance at generation two and above. Where the
   wall, jaw and knuckle handlers call the old function, call the new one at generation two and above. Posts keep
   the old flat model (they are round rubber posts, not rail noses); say so in a comment.
5. The position fix-up after each rail hit ("put the ball exactly on its contact line") must use the same new
   distance, or balls will creep into the rail.
6. Airborne balls: a ball in the air below the nose still meets the rail. Keep the existing rule, but with the new
   function its vertical speed is no longer ignored: pass it through.
7. The drawn table: TableBuilder.swift draws the cushion nose from the same nose line, so nothing should move, but
   balls now rest a hair closer to the rail. Look at a ball frozen on a rail in the app and confirm it touches the
   nose and does not sink into it.
8. Rail events for the Lens: the event already carries normal and friction impulse. Add the downward impulse into
   the bed as its own field on the event (LensEvent.swift) so a caption can say the rail pushed the ball into the
   cloth. Add one caption for it in Captions.swift, with translations.
9. Other tables: BumperPoolTable, FivePinTable and BarBilliardsTable may tune rail bounce. Re-check their default
   shots on the new generation.

## Tests (must pass before merge)

- Spec test 3a, mirror: with restitution one, no friction and the nose at centre height, the new function gives an
  exact mirror bounce.
- Spec test 3b: a naturally rolling ball into the rail at forty-five degrees leaves steeper than it arrived, at
  slow speed.
- Spec test 4: running side spin widens the rebound, reverse narrows it, in order, never the wrong way.
- Topspin test: a rolling ball straight into a rail comes back and, because it still carries forward spin relative
  to its new direction, slows sharply or curves back toward the rail briefly. A ball with backspin comes off livelier.
  Assert the order of the three rebound distances: backspin longest, stun middle, natural roll shortest.
- Speed test: rebound speed share at slow speed is higher than at break speed.
- Energy sweep: ten thousand random speeds, angles and spins; no case gains energy; no result is not-a-number.
- The proof plan's real-world cases 6, 7 and 8.
- Generation one is bit-for-bit unchanged.

## Done when

All tests above pass, the developer flag from the proof plan lets the Boss bank balls on the new rails, and the
header of Impacts.swift tells the truth about which model is which. The switch to make it the default belongs to
the proof plan, package 4, not to this one.

## Not in this plan

The spec's "Level B" rail (a step-by-step model of rubber and cloth together). Do not start it. Level A, tuned, is
what good simulators ship.
