<!--
Author: Claude Fable 5.2 Medium
Date: 25-November-2026
PURPOSE: Build plan for the strike panel: before every shot the player sees exactly what they are about to do to the
         ball, in real units (swing speed, the speed the ball leaves at, the push, the force, the energy, the spin, the
         tip offset, the cue angle), and after the shot sees what they planned beside what they delivered. Also makes
         the shot controls large and plain on iPad and the open folding phone. Written for a junior developer.
         Read plans/25-Nov-2026-award-scores-order-plan.md first.
SRP/DRY check: Pass - checked App/ShotPanel.swift, App/AimGauges.swift (TipPicker, PowerGauge), App/Phone/PhoneAimPanel.swift,
         App/Stroke (CueProfile, StrokeModel, StrokeWords, StrokeGesture), App/NotebookPanel.swift and App/NotebookInfo.swift
         (NotebookNumbers shows a shot's figures after it is played; this plan adds the figures before it is played and
         reuses the same tile) and Packages/BreakdownCore/Sources/BreakdownPhysics/Parameters.swift (the strike model the
         figures are read from). No file shows the planned strike in units today.
-->
# The strike panel and plain controls

## In plain words

Today the player sets the power on a thin bar and reads one small figure, the swing speed. The force they are about
to put into the ball is not shown anywhere. On the iPad all the controls sit in a small card in the bottom-left
quarter of the screen, while the half beside them shows one line: "Once the balls move, every hit is explained
here."

This plan fills that empty half with the strike, in numbers, while the player is aiming. Every number changes live
as they aim, set the power and move the tip. After the shot, each number shows what was planned and what was
actually delivered. The controls themselves get large enough to use without care.

## Decisions already made

- **Every figure is worked out from the same numbers the solver is given.** No figure is typed in or rounded to
  look nice. If a figure is an estimate, its label says "about".
- **Force is an estimate and is labelled so.** The solver strikes in an instant, so it knows the push (the impulse)
  exactly and not the force. Force is the push divided by how long the tip touches the ball, which for a leather tip
  is about a thousandth of a second. The tile says "about" and names that contact time.
- **The Shoot button and the hand stroke both stay.** Power as swing speed is the Boss's own decision. The button
  plays the planned strike. The hand stroke plays the planned strike plus the player's own wobble. The panel shows
  the difference.
- **The upright phone gets the same panel behind one tap** on its swing figure. It is never forced onto the small
  screen.
- **No new physics.** Nothing in the solver package changes.

## Stage 1: the figures (pure, tested, no screens)

1. **New file** `App/Strike/StrikeFigures.swift`. One value type holding the figures and one function that builds it
   from the things the model already has: the power, the cue in hand (`CueProfile`), the tip offset up and sideways,
   the cue angle, the surface's parameters. The figures:

   | Figure | Unit | Where it comes from |
   |---|---|---|
   | Swing | metres per second | `CueProfile.swing(forPower:)`, already shown today |
   | Ball leaves at | metres per second | `CueProfile.launchSpeed(forPower:)`, then the off-centre factor written beside `cueMass` in Parameters.swift |
   | Push | newton-seconds | ball mass times the speed the ball leaves at |
   | Force | newtons, "about" | the push divided by the tip contact time |
   | Energy | joules | half the ball's mass times the leaving speed squared, plus the spin's share |
   | Spin | turns per second, split into top or back and side | from the tip offset and the leaving speed, for a solid ball |
   | Tip | millimetres up or down, millimetres left or right | the model's tip values |
   | Cue angle | degrees | the model's elevation |
   | Cut | degrees | the angle the aim overlay already draws ("Ball goes here 2.4° left", App/AimOverlay.swift) |

2. **The contact time** is one named constant in this file, with a comment saying what it is, that it is typical
   for a leather tip, and that it is the only figure here the solver does not use. Do not add it to the solver's
   parameters: those are hashed, and every authored shot depends on that hash.
3. **A second builder** for the delivered strike: the same figures from the strike that was really solved (the
   attempt's own `CueStrike`, after `StrokeModel.delivery` has added the stroke's aim and tip error).
4. **Tests** `StrikeFiguresTests`: a centre hit leaves at the launch speed; an off-centre hit leaves slower; the push
   is mass times speed; a centre hit has no spin; planned and delivered are equal when the stroke adds no error.

Done when the tests pass.

## Stage 2: the panel on iPad, Mac and the open folding phone

1. **New file** `App/Strike/StrikePanel.swift`. A grid of tiles, one per figure, using the tile that
   `NotebookNumbers` already draws in `App/NotebookInfo.swift` (lift that tile into its own small view so both use
   it; do not draw a second one). Each tile: the figure large in the monospaced number font, the unit, a one- or
   two-word label under it.
2. **Where it goes.** In `App/NotebookPanel.swift`, the commentary column shows a placeholder line while the balls
   are at rest and nobody has shot. Show the strike panel there instead, whenever the player is aiming. When the
   balls move it gives way to the commentary, as now.
3. **Planned against delivered.** When a shot ends, the panel returns with two figures in each tile that differs:
   the planned one dimmed, the delivered one bright, and the error in plain units ("0.4° left", "2 mm low"). Tiles
   that did not differ show one figure.
4. **Type an exact value.** Tapping the Swing, Tip, Cue angle or Cut tile opens a small number field with a stepper,
   so a player can enter 2.60 or step by a hundredth. It writes the same model values the gauges write, so the
   gauges move with it.
5. **The hidden sheet goes away on big screens.** "Fine controls" in the More menu exists because the gauges were
   small. On iPad, Mac and the open folding phone the panel replaces it. Keep the sheet on the upright phone and for
   VoiceOver.

Done when: on an iPad, moving the tip, the power or the aim changes the tiles at once; after a hand stroke two tiles
show a planned and a delivered figure; typing 3.00 into Swing moves the power bar.

## Stage 3: controls that are not fiddly

All sizes are for iPad, Mac and the open folding phone. The upright phone keeps `PhoneAimPanel` as it is, except for
item 5.

1. **The tip picker** (`TipPicker` in `App/AimGauges.swift`) is 52 points today. Make it at least 132 points on big
   screens. It snaps gently to dead centre and to the straight-up and straight-across lines, so a plain stop shot or
   a plain draw is easy to set. The millimetre figures show beside it.
2. **The power bar** (`PowerGauge`) is 12 points tall. Make it at least 28. Drop the minus and plus buttons on big
   screens; the bar is big enough to drag and the Swing tile takes exact values.
3. **The cue angle** is a menu today. Draw it as a quarter-circle dial with the cue as its needle: drag the needle,
   read the degrees. Keep the lesson zones it already marks (`App/CueAngleControl.swift`).
4. **Shoot** is the largest thing on the panel and sits in the corner nearest the player's hand: bottom-right, or
   bottom-left when the left-handed option from the Everyone can play plan is on.
5. **One hint, in one place.** The instruction "Drag on the table to aim. Pull back from the white ball, then push
   through it" sits over the top of the table on the upright phone. Move it below the table, into the panel, on
   every layout. Add one more line for a stylus when one is in use: "Hover to aim. Tilt to raise the cue."
6. **Two fingers never needed.** Everything the bridge finger does can also be set on the panel.

Done when: on an iPad a new player can set centre ball, a firm swing and a level cue, and shoot, with four taps or
drags and without opening any menu.

## Stage 4: the upright phone

1. Tapping the swing figure in `App/Phone/PhoneAimPanel.swift` opens the strike panel as a sheet over the lower
   half. The table stays visible above it.
2. After a shot, the phone's explanation blurb gains one line when planned and delivered differ: the largest error
   only.

## Words

Every label and unit is new text. Put them in a new file in `localization/pending`. Use the unit symbols the game
already uses for metres per second. "About" must be translated, not dropped.

## What not to do

- Do not change the solver or its parameters.
- Do not remove the hand stroke or the Shoot button.
- Do not show a figure the game cannot work out from the planned strike. No guessed "chance of making it".
- Do not put the panel over the table on any layout.
