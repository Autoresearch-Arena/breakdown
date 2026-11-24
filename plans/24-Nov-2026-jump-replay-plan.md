<!--
Author: Claude Opus 5.5 Medium
Date: 24-November-2026
PURPOSE: Plan for fixing the jump replay in the Physics Lens (the guided replay's take-off and landing beats). The Boss
         found it "doesn't look very good" on 23-Nov-2026; 0.7.7 fixed the room's wood and framed the whole flight, but
         the balls are still small and the flight height is printed four times on one card. Read from the 0.7.7 code:
         Captions.flightCaption, PacePlan.focusRegions and PacePlan.flight, MomentFrame (MomentFraming.frame,
         maxMagnification, fill), CaptionViews (CaptionFigureRow, the title's leading figure), LensLayer (the airborne
         trail and the flying ball's ground ring).
SRP/DRY check: Pass - every change edits the code that already owns that job (captions in Captions.swift, framing in
         PacePlan and MomentFrame, drawing in LensLayer); the one new drawing, the side view, is a new file because
         nothing draws a ball's height today.
-->
# The jump replay

## What is wrong now

The Boss's frame and the store clip of the jump over a blocker show the same three problems.

1. **The balls are small.** The take-off beat's focus rectangle (PacePlan.flight) holds the run-up, the whole flight,
   the ball that was jumped, *and* a hit's worth of roll-out after landing. On a long jump that is a third of the
   table, so the moment framing barely zooms, and the magnification is capped at 3.5 for every beat anyway. The flying
   ball ends up a few points across, the jumped ball fewer, and the gap between them, the whole point of a jump,
   is not visible at all.
2. **The height is said four times on one card.** The take-off caption puts the same figure in the title ("Off the
   slate · 8.1 cm"), in the sentence ("its lowest point is 8.1 cm above the cloth"), in the Flight height tile, and as
   the answer of the worked equation. The flight distance is then said again on the landing card.
3. **Nothing shows the height.** A jump is about going *up*, and the overhead Lens can only show it as a dashed line
   and a growing ring. The player reads a number and has to imagine the arc.

## What we do

### Part 1 — Come in close on the jump

- PacePlan.flight frames the take-off on the flight and the jumped ball only: drop the roll-out after landing (the
  landing beat frames that) and shorten the run-up to the last few centimetres.
- MomentFraming lets a flight beat zoom further than other beats: its own cap of 6 instead of 3.5, so a short hop
  over a blocker fills the open space. Every other beat keeps 3.5.
- The landing beat keeps today's framing (landing point plus roll-out), so the camera moves from "over the blocker"
  to "where it came down" between the two beats.

### Part 2 — Say each number once

The take-off card becomes:

- **Title:** Off the slate · *flight height*. The height is the headline, once.
- **Sentence:** the plain story with no repeated figure: it hits the slate going down, bounces up, leaves the cloth
  and clears the jumped ball with *so much* to spare. The spare gap is the one new number, and it is what a player
  cares about.
- **Tiles:** Speed down, Bounce up, To spare. Flight height leaves the tiles (it is in the title); Flight distance
  leaves the take-off card (the landing card already has it).
- **Worked equation:** unchanged. It is where the height comes from, so its answer matching the title is the point,
  not a repeat.

When nothing was jumped (a hop on open cloth) the sentence ends at "leaves the cloth" and the third tile is Flight
distance, so the row is still full.

### Part 3 — Show the height as a picture

A small side view of the flight, drawn in the Lens's own style, hangs over the table near the jump while the
take-off beat is held:

- The cloth as a line, the jumped ball as a circle sitting on it, and the flying ball's arc drawn from take-off to
  landing at true scale, so the gap over the blocker is plainly visible.
- A short vertical marker at the top of the arc, carrying the flight height. This is the picture the title's number
  belongs to.
- It draws itself along the arc as the replay plays through the flight, and fades out when the beat lets go.
- Placement follows the layout rules already in place: on the upright phone it sits above the blurb and never over
  the balls; on the open Duo it stays on the table half; on iPad and Mac it sits beside the jump.
- With Reduce Motion on, it appears whole instead of drawing along.

This is the one new piece of graphics, in a new file, fed from the same flight data the caption already reads
(Captions.flightSegment and flightTop), so the picture and the numbers cannot disagree.

## Out of scope

The take-off physics, the solver, the landing card's wording, other beats' framing, the clips (they pick all of this
up for free, since they render the same scene and captions), and Ride.

## Translations

Changed sentences and the new "To spare" label go through localization/pending in all twelve languages, merged by
scripts/localization-merge.py and checked by scripts/translation-check.py.

## Checks

- App test: the take-off focus rectangle for the jump over a blocker holds both balls and is smaller than it is today.
- App test: the take-off caption's title, sentence and tiles hold the flight height exactly once outside the worked
  equation.
- One spot check: the jump over a blocker on the iPhone 17 Pro simulator, take-off beat held, compared with the Boss's
  frame. Then ship.

## How it is built

Small enough for one developer in one pass: Parts 1 and 2 first (they fix what the Boss saw), Part 3 after them, one
compile, the tests above, version 0.7.8, CHANGELOG entry, push to TestFlight.
