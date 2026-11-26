<!--
Author: Claude Opus 5.5 Medium
Date: 26-November-2026
PURPOSE: Redesign plan for the aiming panel (the strike figures and the shot controls) after the Boss said the UI does
         not look good. Picks one direction out of three designer proposals (hierarchy, instrument, space), grafts the
         best parts of the other two, and gives a junior developer build steps per file. Mockups:
         store/review/aiming-redesign.png (upright 13-inch iPad, aiming) and store/review/aiming-redesign-wide.png
         (Mac window / iPad sideways, just after a shot). Builds on plans/25-Nov-2026-strike-panel-and-controls-plan.md,
         which stays the source for what each figure means and how it is computed.
SRP/DRY check: Pass - checked App/Strike (StrikePanel with StrikeSlot and StrikeSheet, NumberTile, StrikeEntry with
         StrikeEntryField, StrikeFigures, StrikeReading, StrikeSpoken, StrikeWords, StrikeHint, CueAngleDial),
         App/ShotPanel.swift (roomyRow, roomyStacked, roomyPowerColumn, roomyFireButton), App/AimGauges.swift
         (TipPicker, PowerGauge), App/NotebookPanel.swift, App/Phone/PhoneAimPanel.swift, App/ScrubBar.swift,
         App/PlaybackControls.swift and App/Theme.swift (Palette). No physics changes: every figure is still read from
         StrikeFigures and StrikeReading. The one new file (App/Strike/Instrument.swift) holds the handle, readout and
         rule that the tip picture, the power bar and the dial each draw by hand today, so they come from one place.
-->
# The aiming panel, redesigned

## In plain words

**What is wrong.** Twelve identical grey boxes with the same cyan figure in each, so nothing reads first. The cut on
the ball you are potting gets the same weight as the bridge length. The same figure is printed two or three times
(the swing in a box and again over the power bar; the tip offset in two boxes and again beside the ball; the cue
angle in a box and again under the dial). Cyan is on everything, so it no longer tells you what you can touch. The
controls you actually use are squeezed into one short strip at the bottom, and the power bar has no scale at all.
On the Mac, a disabled Shoot is the biggest shape on screen and looks broken. On the phone, the sheet covers half the
table and its figures get cut off.

**What it will look like.** Three bands, in the same order on every big screen:

1. **What the ball gets**, read first: the cut on the object ball, the speed the ball leaves at, back or top spin,
   and side spin. Four big white figures, nothing else.
2. **The physics**, one quiet line: push, force and energy. Still there, still in real units, just not shouting.
3. **What you set**, the controls, and each control carries its own figure: the tip picture with its two millimetre
   figures under it, the swing figure over a power bar that now has a metres-per-second scale, the cue-angle dial with
   its degrees beside the needle, the bridge with minus and plus, and Shoot as the biggest thing on the screen, in the
   corner under your hand.

Every figure is printed once. Cyan now means "you can move this". White means "this is what follows". A dotted
underline under a figure means "tap to type it exactly". After a shot, a warm yellow shows only what came out
different from the plan, drawn on the controls themselves (where you aimed the tip, and where you actually hit it).
The plain sentence above the figures stays. The table is untouched on every screen; on the open folding phone the
table keeps its half alone and all of this sits on the other half.

Mockups: `store/review/aiming-redesign.png` (upright iPad, while aiming) and
`store/review/aiming-redesign-wide.png` (Mac window or iPad sideways, just after a shot that went 4 mm low).

## The direction and what came from where

The spine is the **hierarchy** proposal: rank the figures into three groups, take the set figures out of the grid and
put each on its control, figures white and cyan only for what you touch, a separate colour for planned-against-
delivered. It answers both faults the Boss sees (no order, everything doubled) with the fewest new words.

Grafted from the **instrument** proposal:
- One shared kit for the three controls (one drag handle, one readout block, one hairline rule), in a new
  `App/Strike/Instrument.swift`, so the tip picture, the bar and the dial stop looking like three different apps.
- Flat matte surfaces with hairline rules instead of twelve glass tiles. Glass stays on the window chrome and the
  chips over the table only.
- The tip picture becomes a flat technical drawing: rings every 5 mm with 10 and 20 labelled, a full crosshair, dotted
  leader lines from the axes to the tip spot. No glossy white ball (it was the loudest thing on the panel).
- A real metres-per-second scale under the power bar (labelled whole numbers only, no fine ticks, so it stays plain).
- The dotted underline as the "you can type this" mark, replacing the corner pencils nobody can see.
- Disabled Shoot never becomes a grey slab: it becomes an outline with grey "Rolling" while balls move.

Grafted from the **space** proposal:
- Units at about 55 percent of the figure's size, grey, on the same baseline. This alone stops "11.9 turns/s" from
  being cut off; no unit rename is needed.
- Shoot always in the bottom corner on the playing hand's side, always the largest control.
- The hint loses its card and its close button and becomes one plain grey line.

Rejected, and why:
- The instrument proposal's fine ticks every 0.1 m/s, thin slider-bar thumb and screenful of tracked uppercase labels:
  fiddly and wordy, against "large plain controls" and "fewer words".
- Magenta for errors (instrument and space): magenta already means "ball sliding" in the Physics Lens one tap away. A
  screen cannot have magenta mean two things. A new warm yellow takes the error role (amber left the palette in 0.7.2,
  so the slot is free).
- "rev/s" in place of "turns/s" (instrument and space): the truncation is fixed by the smaller unit instead, and
  "turns/s" is already translated in every language (German "U/s"). No new unit string.
- Moving the Lens, Ride and Your shot pills into the top bar, and collapsing the scrubber while aiming (space): out of
  scope for "the aiming UI does not look good", and they touch the Mac toolbar and playback. Not now.
- The "Strike | Steps" switch shown only after a shot (space): the heading row's plain "Step by step ›" text button
  does the job with less chrome.

## Decisions settled here (do not reopen while building)

- **Error colour:** new `Palette.delta`, warm yellow, normal (0.98, 0.80, 0.35), Increase Contrast (1.0, 0.88, 0.50).
  Used only for planned-against-delivered. Never for warnings, never on the table.
- **Cyan** (`Palette.accent`) only on things you move: tip handle, power fill and thumb, dial needle, minus and plus
  glyphs, editable figures, and Shoot as the single solid cyan fill.
- **Result figures** in `Palette.paper`. Units and labels in secondary grey.
- **The plain sentence stays** as its own line under the heading, built by StrikeWords from the lead figures (for
  example "Back spin with some right side. The 11 is cut 3.4° and runs 1.2° left of the cue."). It is not the hint.
  After a shot it names the biggest difference in one line ("You hit 4.0 mm low, so 4.8 turns/s more back spin than
  planned.").
- **The hint** (StrikeHint) is a separate plain line under the controls band. It keeps its current show and hide
  rules, including the hand-over in the first minute.
- **Units unchanged:** m/s, turns/s, N·s, N, J, mm, °, cm. Force keeps "≈" plus a small "over 1 ms"; VoiceOver still
  says "about 416 newtons, over one millisecond of tip contact".
- **Nothing is deleted.** Every figure the panel shows today is still shown, in real units, and every typed-entry
  popover still opens, now from the figure on the control.

## Layout per screen

### Upright 13-inch iPad (1032 × 1376 pt; mockup `aiming-redesign.png`)

Top to bottom under the table (the table keeps its current share, about the top 37 percent):

1. Top bar, unchanged.
2. Heading row: "Your strike" in `.title3` bold on the left, "Step by step ›" as a plain text button on the right.
   Replaces the segmented control and the "YOUR STRIKE" caption.
3. The plain sentence, `.callout`, secondary.
4. **What the ball gets**, full width, about 146 pt: four equal columns split by 1 pt rules, no boxes. Label above
   (`.subheadline` semibold, secondary, one line), figure (`Theme.leadFigure`, about 44 pt), unit on the baseline
   (`Theme.leadUnit`), optional sub-line (`.footnote`, tertiary): "goes 1.2° left" under Cut, "from a 2.40 m/s swing"
   under Leaves at. Cut keeps its dotted underline (it is typeable).
5. **The physics**, full width, 38 pt: caption then Push 0.42 N·s, Force ≈416 N over 1 ms, Energy 0.71 J on one line.
6. **What you set**, full width, takes all remaining height (about 360 pt here):
   - left column: tip picture 180 pt across (grows to 220 pt when there is room), then "10.0 mm below" and
     "5.7 mm right" under it at `Theme.controlFigure` size.
   - middle column, top: "Swing", then "2.40 m/s" and the zone word ("firm"), then the 48 pt bar with the calm mark
     labelled "calm limit 3.5 m/s" and the 0 to 6 m/s scale under it (the top of the scale is the cue's top swing from
     the cue profile, not a fixed 6).
   - middle column, bottom: the cue-angle dial (100 pt radius, ticks at 0, 20, 45 and 90°) with "5.0°" and
     "up from level" beside the needle; then Bridge "20 cm" over a 132 × 52 pt minus/plus pill.
   - hand-side column: Shoot 178 × 166 pt, then Try again (56 pt tall, outlined) and "…" (52 pt circle).
     Left-handed play mirrors the whole band.
7. The hint, one line of `.footnote` secondary, no card, no close button.
8. Scrubber and the Lens / Ride / Your shot pills, unchanged.

### Mac window, iPad sideways (panel about 600 pt wide; mockup `aiming-redesign-wide.png`)

Same three bands in the same order in the right column:
- What the ball gets as 2 × 2 (Cut, Leaves at / Back spin, Side spin), figures about 34 pt.
- The physics on one line; wraps to two lines below about 420 pt of width.
- What you set: tip picture (at least 148 pt) with its millimetre lines under it, the dial beside it with its figure;
  then the swing figure and bar with its scale; then Bridge with minus/plus, Try again and "…" in one row under the
  bar; Shoot (at least 150 × 136 pt) in the bottom corner on the hand side, spanning the bar row and the button row.
- Scrubber at the foot.
- Disabled Shoot: 1 pt outline, secondary text "Rolling".

### Open folding phone

The table half stays alone. The text half takes the Mac order, sized down: lead figures about 28 pt, tip picture and
dial 132 pt, Shoot at least 150 × 72 pt at the bottom edge on the hand side. Nothing crosses the hinge.

### Upright iPhone

The strike sheet shows only What the ball gets (2 × 2) and The physics. The phone's aim panel already carries the set
figures. Opaque background (no table showing through), no repeated title, about 250 pt tall, so the shot line stays
visible. No label wraps at default text size.

## After a shot (planned against delivered)

- Heading becomes "Your stroke". The plain sentence names the single biggest difference.
- Lead band: each figure shows the delivered value at lead size. Under a figure that moved, a delta chip in
  `Palette.delta` (`.footnote` monospaced, 15 percent delta fill), for example "+4.8 vs 11.9 planned". A figure that
  did not move shows a small secondary "as planned". No PLANNED / DELIVERED word pairs, no doubled figures; every
  column stays three lines tall.
- The physics line: delivered values, each followed by a small signed delta in yellow when it moved
  ("Push 0.40 N·s −0.02").
- Controls show the plan as a hollow ghost and the delivery solid: a hollow cyan ring at the planned tip spot, a solid
  yellow dot where the tip actually hit, a 1.5 pt line between them; a yellow tick on the power bar at the delivered
  swing; a faint ghost needle on the dial at the planned angle. The millimetre lines read "10.0 → 14.0 mm below" with
  the arrow and new value in yellow.
- The ghosts clear on the first control move (the rule StrikeReading.current already follows).
- VoiceOver keeps the "planned, then delivered" order through StrikeSpoken.

## Build steps per file

Work in this order; each step compiles on its own. Compile once at the end of the merge, per the Boss's workflow.

1. **App/Theme.swift**
   - Add `Palette.delta` (normal and Increase Contrast values above), with a raw triple `deltaRGB` / `deltaHighRGB`
     beside `slideRGB`.
   - Add surface tokens: `Palette.band` (#10151D), `Palette.ledger` (#0C1016), `Palette.rule` (#1F2833).
   - Add fonts, all system text styles so Dynamic Type works: `leadFigure` (`.largeTitle`, monospaced, semibold,
     monospaced digits), `leadUnit` (`.title3`, medium), `controlFigure` (`.title`, monospaced, semibold),
     `ledgerFigure` (`.callout`, monospaced), `groupCaption` (`.caption`, bold, uppercase, tracking 1.4).
   - Leave the existing rounded figure styles in place for NotebookNumbers; the aiming panel stops using them.

2. **App/Strike/Instrument.swift (new)**
   - `InstrumentHandle`: the one drag handle (cyan disc with a dark ring, 44 pt hit area, soft halo while dragged).
   - `Readout`: label, figure, unit at about 55 percent size on the baseline, optional sub-line, optional dotted
     underline when editable (tap opens the existing StrikeEntryField popover), optional planned→delivered form.
   - `DeltaChip`: the signed yellow pill.
   - `BandSurface` and `HairlineRule`: the flat band background and the 1 pt rule.
   - TipPicker, PowerGauge and CueAngleDial must draw their handle and readout from here, nowhere else.

3. **App/Strike/NumberTile.swift**
   - Add a lead variant (no box: label above, `leadFigure`, unit on the baseline, sub-line or DeltaChip) and a ledger
     variant (label, `ledgerFigure`, unit, optional small delta).
   - Replace the four stacked lines of planned-against-delivered with delivered figure plus DeltaChip.
   - Keep the old compact tile as it is for NotebookNumbers.

4. **App/Strike/StrikePanel.swift**
   - Remove the twelve-tile grid and the `evenColumns` / `tileHeight` stretch rule.
   - Build the lead band (Cut, Leaves at, top/back spin, side spin): four columns on the upright iPad, 2 × 2 on the
     Mac, the open fold and the phone sheet. One figure per row at accessibility text sizes.
   - Build the physics line (Push, Force, Energy).
   - Remove the Swing, Tip below, Tip right, Cue angle and Bridge tiles; their figures move onto the controls.
   - `StrikeSlot`: heading row with "Your strike" / "Your stroke" and the "Step by step ›" text button in place of the
     segmented picker; drop the "YOUR STRIKE" caption; hand the leftover height to the controls band.
   - `StrikeSheet`: lead band and physics line only, opaque, no duplicate title, about 250 pt.

5. **App/AimGauges.swift**
   - TipPicker on roomy screens: flat ball (soft grey shade, no gloss), rings every 5 mm with 10 and 20 labelled,
     crosshair, dashed miscue ring, dotted leader lines to the handle, size from the layout (180 to 220 pt upright
     iPad, at least 148 pt on Mac, 132 pt on the fold). The two millimetre Readouts sit under it. Remove the small
     "draw, −10.0 mm / right, +5.7 mm" text. After a shot: hollow planned ring, solid delta dot, line between.
     Snapping to centre and to the axes stays. The phone keeps its small picture but takes the flat look.
   - PowerGauge on roomy screens: 48 pt bar (40 pt on Mac), cyan fill, white thumb, the zone past the calm mark as a
     quiet grey hatch (the lavender and brown fills go), the calm mark labelled "calm limit" with its m/s figure, a
     whole-number m/s scale under the bar up to the cue's top swing, the Swing Readout above it with the zone word, a
     yellow delivered tick after a shot. Remove the small "firm · swing 2.4 m/s" header on roomy screens. Keep the
     calm-label showing count as it is.

6. **App/Strike/CueAngleDial.swift**
   - Larger arc (about 100 pt radius on iPad), ticks at 0, 20, 45 and 90°, the needle and handle from Instrument,
     a flat pivot ball, the "5.0°" Readout with "up from level" beside the needle. Remove the small "5° up" caption.
     Faint ghost needle at the planned angle after a shot. Lesson band and lock stay.

7. **App/Strike/StrikeEntry.swift**
   - A Bridge control: Readout plus a minus/plus pill reusing the existing bridge setter and StrikeEntryField.

8. **App/ShotPanel.swift**
   - Replace `roomyRow` / `roomyStacked` with the What-you-set band: tip column, swing-and-dial column, hand-side
     Shoot column on the upright iPad; the stacked order above on the Mac and fold.
   - `roomyFireButton`: Shoot sized as above (rounded rectangle, not a pill), Try again outlined, "…" as an outlined
     circle. Disabled Shoot drawn as an outline with "Rolling".
   - Move StrikeHint out of the card to a plain line under the band.

9. **App/Strike/StrikeHint.swift**
   - A plain one-line footnote form with no card and no close button on roomy screens. Same show and hide rules,
     including the hand-over.

10. **App/Strike/StrikeWords.swift**
    - **Do this first, before step 3 draws anything.** Today the number and its unit are glued in one localized
      format (speed, push, force, energy, spin, millimetres, degrees, centimetres all return strings like
      "2.40 m/s" and "about 416 N"). The smaller grey unit needs them apart. Add a small `FigureText` pair (number
      string, unit string) and a function per figure that returns it; the unit strings ("m/s", "N·s", "N", "J",
      "turns/s", "mm", "°", "cm") become their own catalogue entries, carrying over the existing translations
      (for example German "U/s"). Keep the glued functions for the notebook, the phone and anything else that
      still uses them. StrikeFigures keeps returning plain numbers; it needs no change.
    - Short labels ("Cut on the 11", "Leaves at", "Back spin" / "Top spin", "Right spin" / "Left spin", "Push",
      "Force", "over 1 ms", "Energy"), the group captions, sub-lines ("goes 1.2° left", "from a 2.40 m/s swing",
      "up from level", "as planned", "calm limit", "Rolling"), the delta chip format ("+4.8 vs 11.9 planned"),
      the before-shot plain sentence, and the after-shot sentence naming the biggest difference.
    - A zero spin reads "0.0 turns/s" labelled "No top or back spin"; never hidden.

11. **App/Strike/StrikeReading.swift**
    - The after-shot sentence reuses StrikeWords.largestErrorLine, which already picks the biggest difference;
      extend it only if it needs to name the spin that followed from the tip miss. Reads the comparison only; no
      physics changes.

12. **App/Strike/StrikeSpoken.swift**
    - Spoken values for the lead and physics elements; force still "about … newtons, over one millisecond of tip
      contact"; the planned-then-delivered order kept.

13. **App/NotebookPanel.swift**
    - Order the slot: heading, plain sentence, lead band, physics line, controls band (takes the remaining height),
      hint line, scrubber. Same order on the Mac and the fold's text half; the table half untouched.

14. **App/Phone/PhoneAimPanel.swift**
    - Host the slimmer opaque StrikeSheet; its own small readouts follow the cyan-for-set, white-for-result rule.

15. **Words**
    - New strings in a new file under `localization/pending` (beside the existing v07 files there), merged into
      App/Localizable.xcstrings the usual way, with "≈"/"about" translated, never dropped. Unit translations are
      carried over from the glued strings already in the catalogue.

16. **CHANGELOG and version**
    - Top CHANGELOG entry crediting Claude Opus 5.5 Medium. Patch step only.

## What not to do

- Do not change any physics or any figure's value; this is layout, type and colour only.
- Do not drop a figure or a typed-entry popover. Do not hide figures behind a disclosure on big screens.
- Do not print a figure twice anywhere.
- Do not use magenta for anything but a sliding ball.
- Do not put anything over the table on the iPad, the Mac or the open fold, and nothing from the text half moves onto
  the fold's table half.
- Do not add brand names, people or sources to any label.
- Do not rename units, and do not add fine ticks, uppercase label walls or small hit targets (nothing under 44 pt).
- Do not move the Lens / Ride / Your shot pills or redesign the scrubber in this pass.
- Do not cut the plain sentence, and do not merge it with the hint.
- Do not use fixed point sizes for figures; use the text styles so Dynamic Type still works.
- Do not stretch boxes to fill space; the controls band takes the leftover height and grows the tip picture and dial.
