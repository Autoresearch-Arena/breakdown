<!--
Author: GPT 6.2 Sol (session reasoning)
Edited: GPT 6.2 Sol, 21-November-2026 (rebuilt the swan-neck rest and corner pocket, and archived the hand studies).
Date: 21-November-2026
PURPOSE: Plan the spotted ball, hand bridge poses, massé cue, swan rest and corner pocket for the equipment branch.
SRP/DRY check: Reuse Timeline orientation, CueRig, the existing shot authoring tool and the table's pocket geometry.
-->
# Spotted cue ball and close-up equipment

The editable source scenes are in the [equipment folder](../art/equipment). Review the Blender models before the app build. Check that the cue ball's spin is visible in slow motion and the rest's cradle visibly supports the shaft.

## What to show

- **Draw shot.** Use six flush marks on the cue ball. Show it travelling forward while the marks turn backward, then coming back after contact. The Blender study uses trajectory and orientation samples from the current solver. In the game, drive the marks with the ball's recorded orientation so the replay shows the actual result.
- **Massé cue.** Give the short, heavier cue dark plum wood, ivory-coloured points and a broad chalked tip. Make shaft length, mass and tip distinct from the jump cue. Test the shot through the landed raised-strike solver before promising a particular amount of curve.
- **Swan-neck rest.** Put the cue groove ahead of the feet. Show a ball where a spider would have to stand. Draw and advance the same continuous cue along its axis through the groove. Check that the cue clears the rest neck and the intervening ball across the full stroke.
- **Corner pocket.** Set the dark liner flush with the rail and keep the well below the felt. Sweep the cushion profile to the actual knuckles, then follow the jaw direction to make the facings. The Blender corner uses the current table’s 120.7 mm mouth. Recheck that fit against the merged solver and table mesh. Confirm with a clean pot and a near-jaw rebound viewed in slow motion.

## Teach the draw-massé carom

The current Massé challenge teaches curved travel around a blocker. The branch adds an original exercise where the cue ball contacts a first object ball, draws around after the hit, and reaches a second object ball. The current exercise lets the player replay and scrub both contacts. A follow-up can hold at the first contact and again on the returning path. A standalone solver sweep found that levelling the cue, removing draw or removing side spin prevents the carom. Repeat the sweep on the merged solver before the final build.

## Hand bridge studies

The three hand renders had unnatural finger shapes and contact with the shaft. Keep the editable meshes in [art studies](../art/studies) and exclude them from the final build. The equipment work can move forward with the existing cue controls.

## Fit the work into the final build

Review the assets together with the five existing cues. Keep the Blender sources on Team 4TB and push the portable asset files on the equipment branch. When the other changes land, export the selected meshes and textures, reuse the existing replay orientation, and fit the rest and pocket to the same geometry the solver and foul judge use. Use the normal equipment and table screens for the optional ball and equipment. Include the integration in the one combined app build.
