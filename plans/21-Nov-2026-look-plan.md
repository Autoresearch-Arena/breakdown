<!--
Author: Claude Fable 5.2 High
Date: 21-November-2026
PURPOSE: Plan for the remaining gaps in how Breakdown looks, found by studying the newest store captures (iPhone and
         iPad, 21 November 2026) and the drawing code. Written for junior developers: what is weak, where the code is,
         the work packages in order and how each is checked.
SRP/DRY check: Pass - checked the glow-up plan of 13 November (its packages are done; this plan picks up what the
         captures still show), TableBuilder.swift, TableMeshes.swift, SurfaceTextures.swift, TableCamera.swift,
         ShotCamera.swift and Surfaces.swift. Nothing here repeats finished glow-up work.
-->
# The look: what the pictures still show

## In plain words

From above, the table now looks good and the Physics Lens looks excellent. The weaknesses show in three places. When
the Ride camera drops low beside the ball, the game is seen from an angle the table was never dressed for: flat
cloth, a blocky black pocket, and nothing at all beyond the rail. On a phone held upright the balls are small enough
that their numbers cannot be read. And on an iPad most of the right-hand side of the screen is empty black with a
small card in the corner. Award entries in the visuals category are judged on their worst angle, not their best.

How this was reviewed: from the raw store captures on the Team 4TB drive (store-shots, raw, the English iPhone and
iPad sets) and from the drawing code. Not from play on a device.

## What the captures show

1. Low camera (the jump capture): above the far rail the screen is solid black. There is no room, no lamp, no wall,
   no floor in view. The cloth up close is a smooth green blur with no weave. The corner pocket is a black box with
   square edges and a thin drawn rim. There is a dark seam where cushion meets cloth.
2. Overhead on iPhone: pocket liners read as loose brown arcs with jagged ends rather than a moulded pocket. Rails
   are one flat wood picture with no cloth-covered cushion top visibly distinct from the wood. Balls are a few
   millimetres across on screen; stripes and numbers are not readable.
3. iPad upright: the table takes the left two thirds; the right third holds one small card and is otherwise empty.
4. Lens: strong. The racked balls are small and the labels beside the pockets crowd the top edge.
5. The room is always dark and the game is forced to dark appearance. That is a fair choice for a pool hall; it
   must be a choice that looks intended, with something in the dark to see.

## Rules

The glow-up plan's rules still stand: Apple frameworks only, pictures made in code, models from our own Blender
scripts in Tools/blender. The physics package is not touched. Every change is checked on the oldest supported iPhone
for frame rate, and with Reduce Motion, Increase Contrast and Reduce Transparency on.

## Package 1: a room to be in

1. Build a simple room around the table in TableBuilder.swift, under the warm table group so it fades in the Lens:
   four walls a few metres out with a dark painted finish and a wooden rail at waist height, a floor that reaches
   the walls (today's floor fades to nothing), and the lamp itself: a long shade hanging over the table, lit from
   inside, so the light has a visible source. Make the shade in Blender (new script beside the others).
2. Two or three props at the walls, kept dim and out of focus: a cue rack, a chalk on the rail, a stool. Geometry
   only, materials dressed in code as CueRig.swift does.
3. Rebuild the generated room picture used for reflections (the lamp-and-room picture in TableBuilder) from the new
   room so the balls reflect what is actually there.
4. Check the Ride camera (ShotCamera.swift) from every corner: no angle may show the room's edge or bare black.

Done when: the jump capture's black sky is a dim room with a lit lamp in it.

## Package 2: the table up close

1. Cloth: add fine detail that only shows when the camera is near. SurfaceTextures.swift draws the weave into the
   colour picture at one scale; add a second, small-scale weave as a normal map on the bed material, or raise the
   colour picture's detail and tiling so it holds up at the Ride distance. Measure launch time before and after.
2. Pockets: rebuild the pocket as one moulded piece in Blender (liner, lip and the drop behind it) instead of a
   wall, a floor and a rim built in code. Six copies placed by TableBuilder. The mouth must still follow the physics
   jaws and capture circle; the code comment in TableBuilder explains why. Replace the square well.
3. Cushions: round the nose profile further and give the cushion top its own cloth with a visible edge against the
   wooden rail, with a soft contact shadow where cushion meets bed to remove the dark seam.
4. Chalk marks and wear, very faint, on the default cloth only. The dive-bar surface gets more.
5. Balls: a clear glossy coat with a sharp lamp highlight, and a soft contact shadow under each ball that tightens
   as the ball lands from a jump.

## Package 3: read the balls on a phone

1. On an upright phone the camera fits the whole table, so balls are tiny. Keep that view, and add: when aiming,
   the ball the cue is pointed at shows a small floating badge with its number and whether it is a solid or a
   stripe (CaptionViews.swift has the pattern for anchoring a label to a ball).
2. Pinch to zoom and two-finger drag to pan on the table view, springing back when a shot is played. The camera's
   framing is a fitted distance with multipliers (TableCamera.swift); add zoom as one more multiplier and an offset,
   clamped so the table never leaves the screen entirely.
3. Double tap a ball to centre and zoom on it; double tap again to return.
4. Raise ball picture contrast for small sizes: thicker stripe, larger number disc when the ball is under a set
   size on screen. BallTextures.swift already made one pass at this; measure the on-screen size and switch pictures.

## Package 4: iPad and Mac

Moved to its own plan, 21-Nov-2026-ipad-and-mac-plan.md, because it is too large to be a package here. Everything in
this look plan must be checked on iPad and Mac as well as iPhone.

## Package 5: small things that add up

- A ball dropping into a pocket: check it follows the new pocket shape and disappears behind the lip, not through it.
- The cue: a soft shadow on the cloth under it while aiming.
- The aim line fades at the first contact instead of running on.
- The Lens: keep labels clear of the top controls on a phone; enlarge the racked balls slightly in the Lens only.
- Light appearance: decide and write down that the game is always dark, and remove any half-kept light values from
  Theme.swift, or support it properly. Do not leave it between the two.

## How this is checked

Rendering cannot be checked by a build. After each package: capture the same six views before and after (overhead
upright, overhead sideways, Ride at a corner pocket, Ride mid-table during a jump, Lens, iPad upright) with the
store-shot script, put the pairs side by side on the Team 4TB drive, and send the Boss the build. Record frame rate
on the oldest supported iPhone during a break with Ride on.
