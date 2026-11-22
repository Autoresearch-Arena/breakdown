<!--
Author: Claude Opus 5.5 High
Date: 22-November-2026
PURPOSE: Plan for the roll-along camera (Ride): make it unmistakable what the player is looking at and from where, as the
         view moves from the overhead table to riding with the struck ball, through the hit, and back. Written for junior
         developers from a read of the 0.7.5 code; builds on the 0.7.6 camera fixes (plans/22-Nov-2026-v076-phone-plan.md,
         stream camera) and must land after them.
SRP/DRY check: Pass - checked plans/ (the 0.7.6 plan fixes Ride's bugs but adds no hand-over) and the 0.7.5 Ride code in
         App/ShotCamera.swift, App/TableCamera.swift, App/TrickShotMode.swift, App/ShowpieceModel.swift.
-->
# Ride: a hand-over the player can follow

## In plain words

The Boss: "We don't know what we're seeing exactly or from what point of view. If we're going to show off the roll-along
camera, we want it to be very clear to the player what's happening: we're switching from the view of you making the shot
overhead on the table to how the balls are actually rolling and what happens when the balls hit each other."

Today Ride swoops in while the ball is already moving, says nothing about what it is, runs at full speed, drops the
explanation at the hit, and is back overhead within a few seconds. Over the Lens the real table is hidden, so nothing in
the picture is upright. On an upright phone the swoop can roll the picture end over end (0.7.6 fixes that roll, the hard
cut on every later shot, and the too-narrow lens; it does not add a hand-over).

After this plan, a ride is a short scene in four acts, each named on screen, with the clock held still while the camera
moves so the player never has to watch two things change at once.

## What exists today (0.7.5, read in the code)

- ShotCamera.swift: RidePlan (first contact time, struck ball, travel end, the rise), the chase pose (behind and above the
  ball, looking ahead along its smoothed path), a crane up and back after the first contact, the rise to overhead within
  three seconds of the hit, and a slow-motion curve around the first contact (about a fifth of the chosen speed). All of
  it is a pure function of the playback clock, except `engage`, a half-second wall-clock blend when Ride is toggled.
- ShotCamera.mix blends the table camera and the ride camera (0.7.6 changes it to blend orientations).
- TableCamera.update applies the ride after the fitted pose and the hand zoom.
- ShowpieceModel: guided pacing (holds on beats, explanations) and Ride exclude each other; Ride runs the clock at real
  speed times the contact dip. Tapping Ride during a guided replay drops the hold.
- TrickShotMode's Watch it and the Behind the 8-Ball hint turn Ride on and strike in the same call, at real speed, with
  the Lens off; when the answer ends, Ride goes off and the Lens replay starts in the same frame.
- The title row has a status slot that names the intro's stages (stageTitle); Ride never uses it.
- With the Lens on, TableScene fades the table body out, so a ride over the Lens is a flat grid seen at a low angle.
- Reduce Motion: no ride; one still low view behind the cue ball, cut to overhead at the first contact.

## The four acts

Act 1, Mount (clock held at the strike, about 1.5 seconds of real time):
- The overhead view stays. A ring pulses on the ball that will be struck; its coming path is drawn dotted up to the first
  ball it will hit, which gets its own ring. The title row's status slot reads "Riding with the white ball" (or "Riding
  with the yellow ball" and so on, from the ball's own name on that table).
- The camera then comes down to the ball: the table tips and turns about the ball, which stays pinned at the same place
  on screen, until the view looks down the dotted line from behind and above the ball. Height, distance and turn ease
  separately and take the shortest way round.
- A short still beat behind the ball, then the strike plays.

Act 2, Roll (clock runs):
- The chase as today, with the 0.7.6 width. The ridden ball keeps a thin ring so the eye knows which ball is "you".
- A small table map sits in the title row: the table's outline, a dot for the ridden ball, a narrow wedge for which way
  the camera faces, the struck ball's target pocket ringed. It is the answer to "from what point of view".
- With the Lens on, the table's rails, pockets and shadows stay faintly drawn under the Lens marks, so the picture has
  something upright. The sliding (magenta) and rolling (cyan) trail under the ridden ball reads from behind.

Act 3, The hit (clock held on the first contact):
- Slow-motion deepens to a stop on the contact. The existing crane lifts to a three-quarter view over both balls. The
  held-hit drawing (line of centres, tangent, momentum triangle) appears, at the 0.7.6 readable sizes, and the hit's
  explanation card holds with Continue (the 0.7.6 card: fixed room, pages, its own reading time).
- On Continue, both balls leave slowly along their arrows, the camera staying over them. The ride keeps watching the
  struck ball to its pocket (or its stop) before it rises.
- This means guided holds and Ride no longer exclude each other during a ride: a ride holds two beats only, the first
  contact and the struck ball's pocket (or its stop when nothing drops). Every other beat is skipped while riding.

Act 4, Dismount:
- The status slot reads "Back to the table"; the camera rises to the overhead view the shot began from, the map and the
  ridden ball's ring fade, and the Ride button stays lit (it is a standing choice for later replays, as today).
- When a trick's Watch it ends, the next scene (the slow Lens replay) is announced the same way, "Now the same shot,
  slowed down", with the intro's rewind, instead of starting in the same frame.

## Work packages

1. Hold the clock for the mount and the dismount. ShowpieceModel gains a ride stage (mount, roll, hit, dismount) driven by
   real time while the clock is held, the way the intro's freeze, melt and rewind already are (advance's stage switch).
   TrickShotMode's Watch it and the Behind the 8-Ball hint start the mount instead of striking at once.
2. The mount move. In ShotCamera, a mount pose path from the fitted overhead pose to the first chase pose, orbiting about
   the ball (ball pinned on screen), driven by the mount stage's progress. It stays a pure function of (stage, progress,
   clock) so the self-test can check it; extend ShotCamera.selfTest to cover the mount and dismount for smoothness (no
   turn faster than the existing limit) and for the ball staying pinned during the orbit.
3. The rings and the dotted path. Reuse the caption leader's projection (CaptionViews, LeaderState) for the rings, and
   TablePathStroke for the dotted path to the first ball, computed from the recorded timeline.
4. The status line. Use the title row's status slot (ShowpieceView's ScreenHeader and the model's stageTitle) for the
   four act names. New strings: "Riding with the %@", "Back to the table", "Now the same shot, slowed down".
5. The table map. A small SwiftUI Canvas in the title row: the table outline from TableFrame, the ridden ball from the
   timeline at the clock, the camera's facing from ShotCamera's current heading. Reuse the trick gallery's path
   thumbnails (TrickPathThumb) for the drawing style.
6. The hit beat. Lift the guided/Ride exclusion for a ride: a RidePlan gives its two beats (first contact, the struck
   ball's pocket or stop) to the pace plan as the only beats while riding; the held-hit drawing's gate (TableStage) and
   the explanation card's hold work as in a guided replay. The crane holds still while the clock is held.
7. Something upright over the Lens. While riding, TableScene keeps the table body at a low opacity instead of fading it
   out (rails, pockets and shadows faint under the Lens marks).
8. Reduce Motion. Every act is a cut with the same names, rings, map and holds; no orbit, no crane.
9. The first time Ride is used, the mount lasts a little longer and the status line adds "Tap Ride again for the table
   view" once (remembered, like the Lens tips). Never pushed: Ride stays a button the player chooses, plus the trick
   shots' Watch it.

## Order and checks

- Lands after the 0.7.6 merge (it builds on the orientation blend, the engage fix and the wider lens).
- Package 1 and 2 first (the mount and dismount are the heart of it), then 6 (the hit), then 3, 4, 5, then 7, 8, 9.
- Checks on the iPhone 17 Pro simulator, upright and sideways: The Called Break's Watch it and a straight cut in free
  play with Ride on, Lens on and off; scrubbing back and forth through a ride shows the same picture for the same time;
  Reduce Motion cuts; the open folding phone and iPad keep their layout (the map and status sit in their own title rows).
- The first minute is unchanged: Ride is never switched on by itself there.

## Not in this plan

- Switching the ride to another ball mid-shot (the hand-over is the confusing part; it happens once).
- Any slow motion or hand-over on a live shot. Ride is for replays and the trick shots' Watch it.
