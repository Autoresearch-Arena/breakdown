<!--
Author: Claude Opus 5.5 Medium
Date: 26-November-2026
PURPOSE: The one design language for every screen of Breakdown: the principles, what each colour means, the type
         scale, the figure face, spacing, corners, surfaces, the component kit, motion and the per-device layout rules.
         Concrete values a builder can build to. The order of the work that brings the screens into it is in
         26-Nov-2026-ui-rethink-plan.md.
SRP/DRY check: Pass - this page holds the rules only; the work packages live in the rethink plan. Colour values start
         from App/Theme.swift (Palette) and change it where the six area reviews of 26 November found a clash. When
         this page and the code disagree, this page wins and the code is changed.
-->
# Breakdown: one design language

## The idea in one paragraph

Breakdown is a measuring instrument laid beside a real pool table. The table is the hero and is never covered on a
big screen. Everything else is one calm, dark, flat instrument panel: plain words in a sans face, measured figures
in one monospaced face with their units in grey, and colour used only to mean something that also shows on the
cloth. A player who learns one screen has learned them all: the same card, the same button, the same figure, the
same place for the main action, on every mode and every device.

## Principles (in order, when two collide the earlier one wins)

1. **The table first.** On iPad, Mac and the open folding phone nothing is drawn over the cloth except marks (lines,
   rings, ghost ball, a bare figure). Words live in the panel. On the upright phone, the table keeps its full frame;
   words live in one fixed strip under it.
2. **Colour is physics.** Each hue means one thing, the same on the cloth and in the panel. Headings, counters and
   alarms never borrow a physics colour.
3. **One figure face.** Every measured value is the same monospaced face, the unit smaller and grey on the same
   baseline, always a real unit, one precision per unit (table below).
4. **One plain sentence, more behind a tap.** Each card leads with one sentence a non-player understands. Longer
   text sits behind a worded "More", never a bare dot.
5. **Large, plain, worded controls.** Every button has a word. Minimum hit area 44 by 44 points; main actions are
   bigger. One primary action per screen.
6. **Same thing, same place.** The primary action is always bottom right of the controls. Dismiss is always "Done",
   top right. The scoreboard is always the first line of the state card.
7. **Calm first.** The first minute shows the table, one sentence, the tip, the swing and Break. Everything else
   appears after the first shot lands. Lessons are offered, never pushed.
8. **No names.** No people, brands or sources anywhere in the interface or the store.

## Colour: the roles

All values are sRGB on the dark ground. The second value is the Increase Contrast tone. Builders use the role name
from Palette, never a raw value in a view.

### Ground and surfaces

| Role | Normal | High contrast | Used for |
| --- | --- | --- | --- |
| ground | #05080D | #000000 | The page behind everything, every sheet's background too |
| panel | #10151D | #171C26 | Every reading surface: cards, the aiming panel, the notebook, sheets' groups |
| panelSunken | #0C1016 | #12171F | A strip set into a panel (the physics line, the scoreboard, a figure tile) |
| rule | #1F2833 | #4D5C70 | Hairline dividers (1 point) and panel edges |
| glass | system thin material over the table | system regular material | Only small controls floating over the 3D table |

### Text

| Role | Value | Used for |
| --- | --- | --- |
| paper | #EBF5FF (high: #FFFFFF) | Titles, body, figures, headings, counters |
| paper2 | paper at 64 percent | Secondary text: descriptions, labels under figures, units |
| paper3 | paper at 40 percent | Tertiary: disabled text, axis ticks, "not earned yet" |

### Meaning colours (these appear on the cloth and in the panel with the same meaning)

| Role | Normal | High contrast | Means | Never used for |
| --- | --- | --- | --- | --- |
| cyan | #4DE0FF | #8CF2FF | A ball rolling cleanly, and "you can act here": the primary button fill, selected state, links, switches, slider fill, the one editable figure mark | Headings, difficulty, body text, whole list rows |
| magenta | #FF4DB3 | #FF85D1 | A ball sliding, and friction | Fouls, counters, headings, difficulty, try counts, tags |
| contact | #FFD98C | #FFEBB8 | A strike or a ball-on-ball hit (one warm colour; strike and impact are merged) | Anything that is not a contact |
| pocket | #FFC21A | #FFD966 | A ball pocketed, a medal | Warnings, the planned-against-delivered difference |
| cushion | #8CB8FF | #B8D6FF | A rail or bumper hit | Links |
| whatIf | #B87AFF | #D6B3FF | The what-if path and its figures only | Anything else |
| warning | #FF6A3D | #FF9470 | A foul, a miss, a loss of turn, a destructive action | Pocket or contact events |

Rules:

- **Planned against delivered has no hue of its own.** The old delta yellow is retired. The difference shows as the
  delivered figure in paper with a small up or down arrow and the difference in paper2 ("2.61 m/s, 0.13 under"),
  inside a "Last shot" card. It never swaps the live figures.
- **Headings, counters and emphasis are paper semibold.** That is the one neutral emphasis.
- **Difficulty is a scale of five dots** in paper (filled) and paper3 (empty), never a colour.
- **Marks on the cloth that mean "aim here" or "target"** (pocket target rings, the aim ring around the cue ball)
  are drawn paper with a cyan centre dot, so a solid cyan line on the cloth always means rolling.
- **The window tint is cyan.** System switches, links and icons take it; no system blue or green appears anywhere.
- Every adjacent pair of meaning colours must pass a side-by-side check under both contrast settings and the three
  common colour-blind simulations; contact and pocket are kept apart in lightness (contact is pale, pocket is deep
  gold), not only in hue.

## Type

### The text scale (system text styles, so everything follows the reader's text size)

| Role | Style | Used for |
| --- | --- | --- |
| display | Large Title, serif (New York), semibold, tracking +6 for the wordmark only | The game's name, sheet titles on big screens |
| title | Title 2, serif, semibold | Page and sheet titles, the mode card's item name on big screens |
| heading | Headline (sans, semibold) | Card titles, list row titles, the phone's title row |
| body | Body on big screens, Subheadline on the upright phone | The plain sentence, paragraphs |
| label | Subheadline, medium | Control names ("Swing", "Cue angle"), button words |
| section | Caption, bold, upper case, tracking 1.4, paper2 | Every section label everywhere ("WHAT THE BALL GETS", list headers in sheets) |
| caption | Caption, regular, paper2 | Notes under figures, footers, the version line |

Rules: no italics except the equation style (serif italic, for worked equations only). No rounded design anywhere.
List numbers are plain sans in paper2, not italic serif. Sentence case for every title, tab and button ("Trick
shots", not "Trick Shots"). The store headline face is the serif display.

### The figure face (one family, three sizes)

All figures: system monospaced, semibold, tabular digits. The unit sits on the same baseline at 55 percent of the
figure size, medium weight, paper2, never smaller than the caption size. Words after a figure ("up from level",
"firm") are the label style in proportional sans, paper2.

| Size | Built from | Used for |
| --- | --- | --- |
| lead | Large Title | The four "what the ball gets" figures, the result figure on a result card |
| control | Title | A figure carried by a control (swing, tip, cue angle, bridge), scoreboard numbers, tile figures (daily, how forgiving, Lens summary) |
| inline | Subheadline | Figures inside a sentence, chips, the physics line, menu progress chips, the speed pill |

The rounded figure styles, the phone blurb figure styles and the extra small figure styles are retired into these
three.

### Units and precision (one rule per unit)

| Quantity | Unit as written | Precision |
| --- | --- | --- |
| Speed | m/s | two decimals below 10, one at 10 and over |
| Spin | turns/s | one decimal |
| Angle | ° (no space) | one decimal |
| Tip offset, ball size | mm | one decimal for offsets, whole for sizes |
| Distance on the table | cm | whole, one decimal below 10 |
| Table size | m | two decimals |
| Time | s (never "sec") | two decimals in the notebook, one on the scrub bar |
| Force | N | whole |
| Impulse | N·s | two decimals |
| Energy | J | two decimals |
| Gravity | m/s² | two decimals |
| Friction, resistance | no unit, named in words | two or three significant figures |

Ticks on a scale drop alternate labels whenever two labels would sit closer than their own width plus 8 points.

### The editable figure mark

A figure that the player can tap to type an exact value carries a 1.5 point dotted cyan underline. No read-only
figure carries it. That is its only meaning.

## Spacing and grid

- Base unit 4 points. The steps are 4, 8, 12, 16, 24, 32, 48. No other gap in a view.
- Page side margin: 16 on the upright phone, 20 on the open folding phone panel, 24 on iPad and Mac.
- Inside a card: 16 padding on the phone, 20 on big screens. Between cards: 12 on the phone, 16 on big screens.
- Between a section label and its content: 8. Between a figure and its label below: 4.
- Big-screen panels use a 12 column grid with 16 point gutters inside the panel's own width.

## Corners

Three values only, stored once in Theme. No bare corner number in a view.

| Name | Radius | Used for |
| --- | --- | --- |
| small | 8 | Chips, figure tiles, list thumbnails, the tip picture's frame |
| medium | 16 | Cards, panels, sheets' groups, the playback bar |
| capsule | half the height | Every button, pill and progress chip |

Anything nested inside a card uses the card's radius minus its padding (concentric), floored at small.

## Surfaces

- **Panel (the house surface).** Opaque panel colour, a 1 point rule edge, medium corners, no shadow, no blur. Every
  reading surface uses it: the aiming panel, mode cards, result cards, the notebook, ruling cards, daily, sheets.
- **Sunken strip.** panelSunken, no edge, small corners, set inside a panel for the physics line, the scoreboard,
  figure tiles.
- **Glass (floating controls only).** Small controls over the 3D table: the back button, Menu, Zoom, Share, the mode
  pills, playback on the phone. Thin material, capsule, paper text. Glass never holds a paragraph.
- **Sheets.** Ground background, panel groups, the section label style for headers, cyan "Done" top right, serif
  title. No system grouped grey.

## Components (the kit; every screen is built from these and nothing else)

### Buttons (three roles, one shape)

| Role | Look | Height (phone / big) | Rule |
| --- | --- | --- | --- |
| Primary | Cyan fill, ground text (#05080D), heading weight, capsule | 50 / 56 | One per screen, bottom right of the controls. Shoot and Break are the primary at full action-column height (at least 112 on big screens), still a capsule |
| Secondary | Panel fill, 1 point rule edge, paper text, capsule | 50 / 56 | At most one beside the primary ("Try again", "Watch a way out", "Share") |
| Quiet | Text only, cyan, label style | 44 hit area | Links, "More", "Done", "How scoring works" |

Every button carries a word. An icon may lead the word (outline, medium weight). Anything beyond one primary and one
secondary goes into a worded "More" button that opens a menu. Destructive actions use warning text in a secondary
button.

### Icons

SF-style outline, medium weight, paper2 by default, cyan only on a selected or primary row. No filled icon beside
outline ones. One icon per meaning: the cloth card gets a cloth icon; Menu is the word "Menu", not a grid.

### Panel card

Panel surface. Top row: section label or title on the left, at most one quiet action on the right. Then content.
Then, if it has actions, a button row at the bottom with the primary on the right.

### Mode card (every mode fills it in)

1. Name row: the item's name (heading), its difficulty dots on the right.
2. One plain sentence: the goal.
3. Status line (inline figures): try count, time left, best result, score.
4. "How forgiving" tiles where the mode sets up a shot: aim in °, speed in m/s, tip in mm.
5. Button row: primary right ("Try it", "Shoot", "Next"), secondary left of it ("Watch it", "Share"), "More" for the
   rest.

### Result card

Verdict word (heading, coloured only if it is a foul: warning; pocketed or passed: pocket gold; otherwise paper),
then the one real-unit figure that matters at lead size, then the score with its breakdown behind "More", then the
button row: "Try again" secondary, "Next" primary, "Share" quiet.

### Ruling card

Verdict word (Foul in warning, Legal in paper, Loss of turn in paper2), one line saying what happens next ("Ball in
hand for the computer"), the reason behind "More". The table shows the ruling with a mark (the ball-in-hand area
ringed in paper).

### Scoreboard strip

A sunken strip at the top of the state card: two names ("You", "Computer"), each one's group or score in the
control figure, a cyan dot for whose turn it is, the target ("first to 60") in caption. The computer's level appears
once, as a small paper2 badge.

### Figure tile

Sunken strip, small corners, 12 padding. Label on top (caption, paper2), figure below (control size), note under it
(caption). Tiles in a row share one width.

### Chip

Capsule, panelSunken, 6 by 10 padding, inline figure plus caption word. Event chips on the cloth carry a 3 point
leading dot in their meaning colour; the chip itself stays neutral.

### Progress chip

Capsule chip inside the row, right side: inline figure "3/13" and nothing else. Hidden until the first item is
earned. A tick replaces it when a collection is complete. The same chip on every menu row and tile.

### List row

Leading: number (paper2) or tick (cyan) or medal (pocket). Then title (heading, paper) and one line (body, paper2).
Then a meta line (difficulty dots and best result). Trailing: a small table drawing of the start layout (small
corners), and a chevron in paper3. No tint on the row text, ever.

### Section label

The section style above every group, list and band. One style everywhere.

### Sheet

Ground background, serif title top left, "Done" in cyan top right, panel groups, 24 margins on big screens. Options
has four groups: Feel, Physics Lens, Aiming and hands, Board, then the version in caption at the foot.

### Playback bar ("shot reel")

One bar: play, track, time in s, speed pill, replay, in that order. Height 52 on big screens, 44 on the phone. The
track shows the paced beats and pots as tall ticks in their meaning colour, and minor events as a faint density
band. Shown after a shot and during replays only. While aiming it folds into a secondary "Last shot" button.

### Swing bar (one design on every device)

A cyan fill on a sunken track, the calm limit always drawn as a hatched zone with its figure in m/s ("calm limit
5.3 m/s"), a scale in m/s with labels thinned so none touch, and the swing figure in the control size above it. The
phone version is the same parts at a smaller height.

## Motion

- Standard ease: 0.25 s, ease out, for cards appearing, chips changing, a sheet's content. Spring (response 0.35,
  damping 0.85) only for something the finger drags.
- Figures change by counting with tabular digits, never by sliding.
- A card's height changes animate; its position never jumps between screens.
- Camera moves on the table: one move per beat, 0.6 to 0.9 s, ease in and out; zoom on the action but keep the next
  ball and a rail in frame.
- Reduce Motion: cross-fades only, no camera fly-throughs between beats.
- No sound tied to the interface while a ball travels. Contact sounds only.

## Layout per device

### Upright iPhone (deliberate, not shrunken)

Three fixed zones, top to bottom:

1. **Title row** (44): back on the left, the thing being played as the title ("Draw", "Eight-ball"), Menu on the
   right. Never who is up or the score.
2. **Table**: the full frame from under the title row to the top of the dock. Nothing covers it except marks and at
   most one small chip with a bare figure. The camera frames to the top of the dock.
3. **Thumb dock**: a fixed-height word strip (two lines of body plus "More"), then the scrub row when a shot exists,
   then the action row (secondary left, primary right, 50 high, 16 margins). Longer text, recipes, rulings and the
   notebook open in one pull-up sheet with two detents (half and full) that shows the same pages as the iPad
   notebook.

The aiming controls on the phone are a sheet that grows out of the dock; the camera reframes so the table stays
whole above it. Every action lives in the dock, none in the top corners.

### Open folding phone

Table alone on one half, every word on the other half. The table half draws marks only: aim line, ghost ball, rings,
the bare degree figure on the fork. Labels ("1 ball, solid, goes 1.2° left") move to the top line of the panel. The
panel half uses the big-screen side column below at 20 margins. Half open and closed postures get their own capture
before launch.

### iPad sideways and Mac (the reference layout)

The table fills the stage on the left. A side column of 400 points (Mac: 380 to 440, follows the window) sits on the
right, full height, on the ground with panels inside it. Order in the column: state card (scoreboard, ruling, mode
card), the live figures, the controls, the action column at the bottom right, then the shot reel when there is a
shot. The notebook and step list are a tab of the same column, not a second column. The top bar over the table holds
glass controls only: Back, Menu, Zoom, Share, each with its word.

### iPad upright

The table takes the top 58 percent, framed tight to the rails. Under it, one full-width column with no gaps: the
shot reel directly under the table (when a shot exists), the state card, then the live figures band, then the
controls band with the action column on the right. No empty column, no heading over nothing. The step list is a tab
in the same band.

### The front door on big screens

The table fills the stage. The menu is the side column (sideways iPad, Mac, open folding phone) or a full-width
bottom panel (upright iPad). The same column later becomes the play panel, so opening the game and taking a shot are
one continuous place.
