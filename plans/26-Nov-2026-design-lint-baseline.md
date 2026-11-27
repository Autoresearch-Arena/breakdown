<!--
Author: Claude Opus 5.5 Medium
Date: 26-November-2026
Edited: 27-November-2026 by Claude Opus 5.5 Medium (UI rethink package 3, the closing sweep): the report is
        rerun after the wave's merge and the sweep; it is empty, and the kept values carry the allow comment.
Edited: 26-November-2026 by Claude Opus 5.5 Medium (UI rethink package 3, lint pass): the script now also
        lists corners parked in named constants and default arguments; report rerun.
PURPOSE: The starting list for the design drift guard (UI rethink package 3, "The component kit", part D). It says
         what scripts/design-lint.py checks, how to run it, how to read its report, and holds the report as it stood
         when the script was written, so packages 4 to 9 of plans/26-Nov-2026-ui-rethink-plan.md know what they must
         clear and the coordinator can see the list shrink. Since the closing sweep it holds the latest run (empty);
         the original starting list is in this file's git history.
SRP/DRY check: Pass - the rules live in plans/26-Nov-2026-design-language.md and the tokens in App/Theme.swift; the
         package map is read from the plan by the script. This page only records one run of it.
-->
# Design lint: the starting list

## What it checks

The script lists every place in the app's Swift code that sets a look by hand instead of through the shared tokens
(App/Theme.swift) and the component kit (App/Kit/):

- **bare colour**: a colour written as numbers or a name (red, green, blue, white, hue, an asset name, a system
  colour, or one of SwiftUI's named colours such as white, black, red), where a Palette role belongs;
- **bare font size**: a system font given a point size written as a number, where a Theme text role or figure font
  belongs;
- **bare corner radius**: a corner written as a number, where a Theme corner value belongs.

It skips the tokens files and the kit folder, the colours of the 3D scene and texture code (cloth, wood, balls,
lights and Lens paint, where raw colour is the real input; the list of those files and the reason for each is in the
script), the bevels of generated 3D meshes, and the game's own ball-colour names on bar billiards, five-pin and bumper
pool. A line that carries the comment "design-lint: allow" followed by its reason is left out too; that is for the
rare value the design language itself fixes outside the tokens, such as the black stops of a fade mask, which only
use the colour's transparency.

System colours wrapped for SwiftUI (a system blue or grey, a platform colour) are checked too; on 26 November none
were in the app outside the tokens.

It only reads files and always finishes without failing, so it can sit in a build log.

## How to run it

From the top of the repository:

    python3 scripts/design-lint.py            # every hit, then the counts by package
    python3 scripts/design-lint.py --summary  # only the counts by package

Each hit is one line: the file and line, the kind, and the text that matched. The counts that follow are grouped by
the plan's work packages, read from the plan's own file lists: packages 4 to 9 first (the before-launch clean-up),
then any other package that names the file, then "unowned" for files no package names. A file two packages share is
shown under both; the total counts it once.

## Reading the starting list

- Packages 4 to 9 each clear their own group. A file shown under two packages is cleared by the later one named in
  the plan (for example the notebook column by package 8, the caption views by package 6).
- Package 1 files are merged before wave 3 by the plan; their hits fall to whichever later package takes the file
  (the aim gauges to package 4) or stay for the coordinator.
- Package 3's own leftovers (the scrub bar and the number tile) go away when they are folded into the shot reel and
  the figure tile.
- The "unowned" group holds the overlays, the what-if views, the clip overlay, the trick path thumbnails and the
  every-surface views, and the shared glass card in App/Surfaces.swift (its default corner). No package owns
  them yet; the coordinator assigns them or they are cleared alongside the
  nearest package.
- The fade masks in the notebook (NotebookPanel and NotebookStory) use black only for transparency; they should be
  marked with the allow comment rather than changed.

## The report on 27 November 2026, after the sweep

Taken with every package of the wave merged and nobody else editing. The list is empty: every bare colour, font size
and corner in App outside the tokens, the kit and the 3D scene files is now a Palette role, a text role or figure
font, or a Theme corner. What remains outside the tokens is kept on purpose and carries the allow comment with its
reason, 30 lines in all: the balls' own colours, rims and printed numbers where a ball is drawn (the aim gauges' cue
ball, the target ball badge, the mode frame's ball), the drawn table of the trick shot thumbnails and the Ride map
(cloth, wood and the drawn corners), the fade masks' black stops (notebook), the invisible VoiceOver hit areas (table
access layer), the strokes drawn into a clip's frame bitmap, each surface's own line colour on the every-surface fan,
the tag symbol drawn on the table, the leader's legibility shadow, the caption accent bar's inset and the match ball
icon's size. Run grep for "design-lint: allow" in App to see
them; review should still question any new one.

```text
Breakdown design lint: bare colours, font sizes and corner radii outside Theme, NumberStyle and Kit
Colours not checked in 15 3D scene and texture files (named in the script's SCENE_FILES).


Summary by package (plans/26-Nov-2026-ui-rethink-plan.md)

Total: 0 hits in 0 files (0 bare colour, 0 bare font size, 0 bare corner radius)
```
