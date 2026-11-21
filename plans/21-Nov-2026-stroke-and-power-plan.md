<!--
Author: Claude Opus 5.5 High
Date: 21-November-2026
PURPOSE: The plan for the stroke: power as how hard the player swings, a calm zone and a warm zone on the power bar,
         delivery drift that grows faster than the swing, the finger's stroke on the cloth as the thing that is
         measured, the bridge hand, practice strokes, the Pencil's angle as the cue's angle, and a straight-stroke
         drill. Approved by the Boss in conversation on 21-Nov-2026; this page writes it down before it is built.
SRP/DRY check: Pass - checked the cue-strike plan (power stays the centre-hit launch speed for every authored shot),
         the cues-and-bridges plan (the launch-per-swing formula and the rear-hand lever this plan uses), and the
         learn-from-a-retry plan (the comparison gains one fact, the stroke, and keeps its five sentences).
-->
# The stroke and what power means

## In plain words

Power is how hard you swing, not how fast the ball leaves. With the one cue the game has today the two are the same
thing, so nothing that has ever been played changes. When more cues arrive, a heavier cue sends the ball faster for
the same swing, and the power bar keeps meaning the swing.

Swinging hard costs control. The power bar gets a calm zone and a warm zone. Inside the calm zone a stroke goes where
it is aimed, near enough. Past it, the delivery drifts: the tip lands a little to one side and the cue points a
little off line, and the drift grows faster than the swing does. A hard shot with heavy side spin can slip off the
ball by itself on the new physics.

On a touch screen the pull-back on the cue ball is the stroke. A faint groove is drawn on the cloth along the cue
line while you pull and push through, your finger's thin trace stays visible, and how far the finger wanders off the
groove near the end of the stroke is the drift. Pull back and let go keeps the power, as today; pull back and push
quickly forward through the cue ball plays the shot. A second finger resting on the cloth is the bridge hand: a long
bridge lets you swing harder before the warm zone, a short one steadies the tip but tops out sooner. A few short
practice strokes first, in a steady rhythm, make the final one steadier. Nothing has to be held and nothing is
required.

Keyboard, controller, VoiceOver and the sliders have no stroke to measure, so they get a fixed drift set by the swing
alone: none in the calm zone. On iPad the Pencil's tilt while stroking sets the cue's angle where a raised cue is
allowed.

## Where it lives

- App/Stroke/CueProfile.swift: the cue as numbers. Only the house cue now, read from the physics parameters; the one
  place the equipment work plugs further cues in.
- App/Stroke/StrokeModel.swift: the zones, the drift curve, the bridge lever and the bound that keeps authored shots
  makeable. Pure, tested.
- App/Stroke/StrokeTracker.swift: turns the finger's path into a measured stroke (wander, rhythm, the forward
  push). Pure, tested.
- App/Stroke/StrokeGesture.swift: the touches, the groove and trace drawing, the haptic texture, the bridge finger and
  the Pencil.
- App/Stroke/StrokeWords.swift, StrokeViews.swift, StrokeDrill.swift: the words, the result line and replay trace, and
  the drill.
- Hooks: the model applies the drift to the strike before solving (only for a shot the player fires, never a
  demonstration), keeps the delivered strike and the trace on the attempt, and a retry restores the stroke so an
  untouched retry still repeats exactly.

## The curve and why

Drift is a sideways wobble of the rear hand. The cue turns about the bridge, so the tip moves by that wobble times the
tip-to-bridge length over the bridge-to-hand length, and the cue's direction turns by the wobble over the
bridge-to-hand length. Past the calm zone the wobble is multiplied by the square of the swing over the calm limit:
to reach a faster swing in the same stroke length the arm must accelerate harder, as the square of the speed, and a
push's sideways error grows with how hard it pushes. The calm limit is the house cue's comfortable top swing, the
swing that launches a break's softest speed; a short bridge lowers it, because a shorter backswing reaches a lower
top speed.

## Authored shots stay makeable

Every trick shot, Behind the 8-Ball escape and lesson is played inside the calm zone. There, in those modes, the drift
from any stroke is capped below a third of the tightest aim window and well under the finest tip window that was
measured; the numbers and the check are written beside the cap in StrokeModel.swift. Watching an answer or a hint
never drifts.

## Show it

After a hard shot whose drift mattered the result line says so plainly, VoiceOver says the same, and the stroke's
trace is drawn faintly on the cloth during the replay. A retry can say the stroke was straighter this time.

## The drill

"Straight stroke" in the Play list: the cue ball alone on the head spot, sent up the table, off the far rail and back,
judged by how close it returns to the cue line, with the stroke's trace on its card. The best result and the count of
dead-straight strokes are remembered. It works as a card in the notebook beside the table.

## Done when

The tests pass (house cue changes nothing, a straight calm stroke has no drift, drift grows with wander and with warm
swing, the same input gives the same shot, the bridge scales the tip as the lever says), the strings have their
eleven translations, and the coordinator's single build compiles.
