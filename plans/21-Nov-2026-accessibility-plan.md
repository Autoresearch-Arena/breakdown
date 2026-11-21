<!--
Author: Claude Fable 5.2 High
Date: 21-November-2026
PURPOSE: Plan for closing the accessibility gaps in Breakdown so that a player who cannot see the table, cannot tell
         its colours apart, or cannot make a drag gesture can still play and still learn the physics. Written for
         junior developers: what is already good, what is missing, the work in order and how each part is checked.
SRP/DRY check: Pass - checked every accessibility use in App (about a hundred and seventy across twenty files),
         Theme.swift, AimOverlay.swift, AimGauges.swift, TableStage.swift, LensLayer.swift and the glow-up plan's
         rule 5. The controls are already labelled; this plan covers what the labels do not reach.
-->
# Accessibility: the table itself

## In plain words

The controls are in good shape: buttons and sliders are labelled, text follows the system size, the palette has
high-contrast values, Reduce Motion stills the camera, and the aim can be turned with VoiceOver or arrow keys. That
is more than most games do.

What is missing is the table. To VoiceOver the whole 3D view is one element that says "Table view". A blind player
can turn the aim but is told the aim as a number of degrees, with no idea where any ball is. When a shot is played,
nothing is spoken about what happened. The two colours that carry the Physics Lens's main idea (orange for sliding,
blue for rolling) are told apart by colour alone. And there is no way to play without dragging on the table other
than sliders in a menu. Apple gives a design award for inclusivity; a physics game that can narrate its own physics
is unusually well placed to earn it, because the captions that explain each moment already exist as text.

## What exists today

- TableStage.swift: the 3D view is one accessibility element with the value "Table view" or "Physics Lens view".
- AimOverlay.swift: one adjustable element; aim is spoken in degrees (or millimetres from the lead ball on a break).
- CaptionViews.swift and DuoStory.swift: captions are readable by VoiceOver when on screen.
- No spoken announcements anywhere (nothing posts an announcement when a shot ends or a ball drops).
- No check of the system's Differentiate Without Colour setting. No game controller support.
- ShotPanel.swift caps text growth at one size below the largest accessibility sizes for its own layout.

## Package 1: say where the balls are

1. Add a function that describes a layout in words, in a new file App/TableWords.swift: for each ball on the
   table, its name ("the 3, a solid"), and where it is in table terms a player would use: near which pocket or rail,
   and how far in ball-widths or diamonds. Also relations that matter for a shot: "the 8 is between the cue ball
   and the 3". Geometry helpers for clear paths exist in EightBallJudge.swift (the functions that test a clear line
   between two points); move them somewhere shared rather than copying.
2. Expose the table to VoiceOver as a container with one element per ball, in a sensible order (cue ball first,
   then by distance from it), each with the description from step 1. Use accessibility children over the 3D view,
   positioned at each ball's place on screen so touch exploration finds balls where they are. TableStage already
   projects a ball to the screen for the caption ring; reuse that projection.
3. Pockets are elements too ("foot-left corner pocket"), named as EightBallPocket names them.

## Package 2: aim by target, not by degrees

1. The aim element's value becomes a sentence: what the cue ball will hit first, how full the hit is ("half ball,
   cutting it to the left"), and where that ball is heading ("toward the right side pocket, missing by about a
   ball-width"). The aim guide already computes the first contact and both paths (AimGeometry.swift).
2. Custom actions on the aim element: "Aim at next ball" (cycles through balls that can be hit), "Aim to pot in
   nearest pocket" (sets the aim so the guide's object-ball path meets the pocket), "Finer", "Coarser" for the
   adjustable step.
3. The same actions are reachable from a hardware keyboard and from Switch Control, since they are ordinary actions.

## Package 3: narrate the shot

1. When a shot finishes, post one spoken summary built from the recorded events: what was hit, what dropped and
   where, where the cue ball stopped. One or two sentences. Build it in TableWords from the timeline.
2. Offer "Step through the shot" as a rotor or custom action: each explained moment, in order, read from the
   caption engine's list (the same list DuoStory shows), with the replay moving to that moment.
3. In the games from the rules-games plan, speak the ruling and whose turn it is.
4. Respect the Shot explanations option: off means summary only.

## Package 4: not by colour alone

1. When Differentiate Without Colour is on, sliding trails are drawn dashed and rolling trails solid, in LensLayer
   .swift and LensTextures.swift, and the legend in CaptionViews.swift shows the same patterns.
2. Check both trail colours, the accent and the warning colour in Theme.swift against the three common kinds of
   colour blindness with a simulator filter. Adjust the palette if any pair collapses.
3. Solids and stripes are already different shapes. The target-ball badge from the look plan adds the word.
4. Status that is shown only by a colour tint anywhere (legal or illegal placement, pass or fail) gains a symbol.

## Package 5: other ways to play

1. Game controller: left stick turns the aim, triggers set power, right stick moves the tip, a button shoots,
   shoulder buttons step the replay. Use the system's controller framework and declare support in the project.
2. One-finger alternative for every drag: tap a ball to aim at it, tap a pocket to aim the pot, a stepper beside
   the power bar. Some of this is package 2's actions given buttons.
3. Remove the text-size cap in ShotPanel.swift by letting the panel scroll at the largest sizes.
4. Hold-free play: no control may need a press held for a time.
5. Sound has a visual twin already (impact rings in the Lens). Check that every sound cue that carries meaning
   (a foul, a miscue, a turn change) also shows on screen.

## How this is checked

Each package ends with the game played start to finish under the setting it serves, by the developer, with the
screen curtain on for VoiceOver: launch, break, aim at a chosen ball, pot it, hear the result. Use the Accessibility
Inspector's audit on every screen and fix what it lists. Add the VoiceOver walk-through to the release checklist in
the release-safety plan.

## Done when

A player using only VoiceOver can pot a called ball in free play and be told correctly what happened, and a player
with Differentiate Without Colour on can tell sliding from rolling in the Lens.
