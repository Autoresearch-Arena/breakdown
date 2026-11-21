<!--
Author: GPT 6.2 Sol (session reasoning)
Date: 21-November-2026
PURPOSE: Plan the spotted ball, hand bridge poses, massé cue, swan rest and corner pocket for the equipment branch.
SRP/DRY check: Reuse Timeline orientation, CueRig, the existing shot authoring tool and the table's pocket geometry.
-->
# Spotted cue ball, hand bridges and close-up equipment

The editable source scenes are in the [equipment folder](../art/equipment). Review the Blender models before the app build. The first renders should answer two questions. Can you follow the cue ball's spin in slow motion? Can you see exactly what supports the shaft in each bridge?

## What to show

- **Draw shot.** Use six flush marks on the cue ball. Show it travelling forward while the marks turn backward, then coming back after contact. The Blender study uses trajectory and orientation samples from the current solver. In the game, drive the marks with the ball's recorded orientation so the replay shows the actual result.
- **Hand bridges.** Show the open V between thumb and index finger, the closed loop around the shaft, and a rail bridge with the hand anchored to the cushion rail. Use one left hand and matched camera angles. The game can choose a pose automatically. A later lesson can let the player move the front hand and compare what a small rear-hand error does to the tip.
- **Massé cue.** Give the short, heavier cue dark plum wood, ivory-coloured points and a broad chalked tip. Make shaft length, mass and tip distinct from the jump cue. Test the shot through the landed raised-strike solver before promising a particular amount of curve.
- **Swan-neck rest.** Put the cue groove ahead of the feet. Show a ball near the point where a conventional rest head would have to stand. Keep the support point, feet and neck as separately inspectable geometry.
- **Corner pocket.** Build one corner with a rolled leather lip, lined drop, stitched facing, cloth-covered cushion noses, and inlaid rail diamond. Show it from ball height. Before integration, fit the visible mouth and cushion faces to the landed knuckle, jaw and shelf measurements. Confirm with a clean pot and a near-jaw rebound viewed in slow motion.

## Teach the draw-massé carom

The current Massé challenge teaches curved travel around a blocker. The branch adds an original exercise where the cue ball contacts a first object ball, draws around after the hit, and reaches a second object ball. The current exercise lets the player replay and scrub both contacts. A follow-up can hold at the first contact and again on the returning path. A standalone solver sweep found that levelling the cue, removing draw or removing side spin prevents the carom. Repeat the sweep on the merged solver before the final build.

## Fit the work into the final build

Review the assets together with the five existing cues. Keep the Blender sources on Team 4TB and push the portable asset files on the equipment branch. When the other changes land, export the selected meshes and textures, reuse the existing replay orientation, and fit the rest and pocket to the same geometry the solver and foul judge use. Use the normal equipment and table screens for the optional ball and equipment. Include the integration in the one combined app build.
