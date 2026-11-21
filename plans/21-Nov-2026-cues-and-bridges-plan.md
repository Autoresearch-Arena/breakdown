<!--
Author: GPT 6.2 Astra High
Date: 21-November-2026
PURPOSE: Design five playable cues and two mechanical rests for integration after the pending game work.
SRP/DRY check: Reuse the cue-strike solver, existing cue rig and foul judge. Equipment supplies measurements.
-->
# Five cues and two bridges

Give each cue one shot that shows why someone would take it out of the case. Keep the familiar cue and automatic hands as the starting setup. These masses are proposed design targets for fictional equipment. The physics comparisons below are experiments to run on the final solver.

| Cue | Mass target | Appearance | Shot worth trying |
|---|---:|---|---|
| House maple | 19 oz | Honey maple, single black ring | The reference for every comparison. Inherit the landed default profile at full precision. |
| Rosewood four-point | 18 oz | Rosewood butt, pale maple points, green linen wrap | Repeat the maple centre hit at identical tip speed with a lighter butt. Match shaft and tip properties to isolate mass. |
| Cobalt | 19.5 oz | Black carbon-composite shaft, cobalt joint rings, graphite wrap | Apply side spin down a long straight line. Build a lightweight shaft nose and measure how much the initial direction changes. |
| Oxblood break | 21 oz | Wine-stained maple, black chevrons, reinforced ferrule | Compare centre-hit launch speeds on the same rack. Match tip speed for the demonstration. A player's achievable swing speed depends on the cue. |
| Amber jump | 10 oz | Short figured maple, ivory-coloured diamond inlays | Get the butt into position for a steep downward strike in tight space. Use the raised-strike solver and measure blocker clearance and landing. |

Custom cue makers already offer choices in weight, shafts, wraps and inlay. A wood or colour is an art choice. Assign performance through the cue's measured or calibrated physical properties.

## Decide what stays equal in a comparison

The existing [cue-strike plan](21-Nov-2026-cue-strike-plan.md) defines power as the launch speed of a centre hit. Keep that contract for existing authored shots. For a same-stroke equipment comparison, convert the reference setting to incoming tip speed once. For a level centre strike the simple model gives ball speed as (1 + restitution) × cue mass ÷ (cue mass + ball mass) × tip speed. With a 170 g ball, the model predicts only about 4% more ball speed for a 21 oz cue than an 18 oz cue at equal tip speed and restitution. Label the quantity held fixed. Apply the landed off-centre strike calculation once.

Measure sidespin deflection immediately after contact, before the cloth curves the path. Isolate the shaft effect by matching outgoing speed, tip offset and elevation. Record spin as well as angle. Use the existing tip-grip and miscue model. Calibrate launch and rebound for the jump cue with a raised strike before describing a difference to the player.

## Two mechanical rests

- **Brass cross.** A walnut handle and a low brass X head. Offer a long reach across open cloth with the cue close to level. Rotating the head changes which groove supports the shaft.
- **Silver spider.** An ash handle and a tall arched head. Its feet can straddle an intervening ball. The higher cradle changes the cue angle needed to reach the chosen point on the cue ball. Give the player room to see the shaft clear the blocker.

Author feet, cradle locations, shaft radius and cue length in table metres. Use those same landmarks for the Blender mesh, aiming preview, delivered elevation and the foul judge. The existing fixed setback and bridge-head box would falsely fill the spider's open arch. Test a ball under that arch, a ball touching a foot and a shaft clipping a blocker during the stroke. With identical delivered strikes the ball should follow the same path from either rest.

## Integration after the other developer's push

Read the merged strike and retry code first. Feed one equipment profile to preview, solve, replay and judge. Save the profile/version and bridge pose with the shot. Older shots and authored demonstrations use their original default equipment. Make equipment selectable in practice and carry the chosen cue through a retry. Fit the export to the existing cue rig's tip origin and named materials. Use the [generated finish study](../docs/cue-and-bridge-finishes.jpg) for colour, grain and inlays. Model the actual contact geometry in Blender. Check grip markings at playing distance and bridge clearance from the side. Include the additions in the agreed single final app build.

**Stretch lesson.** Set the bridge hand automatically. For one exercise, let the player move it along the shaft while the rear hand stays at the same starting point. Give the rear hand the same small sideways displacement on each attempt. The tip's lateral displacement is approximately the rear-hand displacement times tip-to-bridge distance divided by bridge-to-rear-hand distance. Let the player predict the second contact mark and see both marks in the Lens. The same geometry works with two taps or a keyboard.

**Art provenance.** Built-in ImageGen, 21 November 2026. Finish-reference prompt follows.

A workshop catalog photograph on charcoal green baize. Show five parallel custom billiard cue butt and forearm close-ups: plain honey maple with one black ring, rosewood with green linen and pale maple points, satin black carbon shaft with cobalt rings and graphite grip, wine red break cue with black chevrons, short amber jump cue with white diamond marks. Beneath them, separately display two real mechanical rest heads on short lengths of handle: a brass X cross rest with four rounded feet and open V cradle, and a silver spider rest with tall arched legs, clear space between feet and an open cue groove atop the arch. True pool equipment proportions, tactile wood grain, elegant studio side light, no lettering, no logos. Landscape concept art for Blender material reference.
