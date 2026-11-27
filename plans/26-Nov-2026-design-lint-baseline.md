<!--
Author: Claude Opus 5.5 Medium
Date: 26-November-2026
Edited: 26-November-2026 by Claude Opus 5.5 Medium (UI rethink package 3, lint pass): the script now also
        lists corners parked in named constants and default arguments; report rerun.
PURPOSE: The starting list for the design drift guard (UI rethink package 3, "The component kit", part D). It says
         what scripts/design-lint.py checks, how to run it, how to read its report, and holds the report as it stood
         when the script was written, so packages 4 to 9 of plans/26-Nov-2026-ui-rethink-plan.md know what they must
         clear and the coordinator can see the list shrink.
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

## The report on 26 November 2026

Taken while other builders were still editing, so line numbers move; rerun the script for the current list.

```text
Breakdown design lint: bare colours, font sizes and corner radii outside Theme, NumberStyle and Kit
Colours not checked in 15 3D scene and texture files (named in the script's SCENE_FILES).

App/Achievements/AchievementViews.swift:420  bare corner radius  cornerRadius: 18
App/Achievements/AchievementViews.swift:444  bare corner radius  cornerRadius: 18
App/AimGauges.swift:162  bare colour  Color(white:
App/AimGauges.swift:162  bare colour  Color(white:
App/AimGauges.swift:165  bare colour  .black
App/AimGauges.swift:171  bare colour  .black
App/AimGauges.swift:178  bare colour  .black
App/AimGauges.swift:186  bare colour  Color.black
App/AimGauges.swift:192  bare colour  .black
App/AimGauges.swift:221  bare colour  Color.black
App/AimGauges.swift:252  bare colour  Color(white:
App/AimGauges.swift:252  bare colour  Color(white:
App/AimGauges.swift:254  bare colour  .black
App/AimGauges.swift:260  bare colour  .black
App/AimGauges.swift:261  bare colour  .black
App/AimGauges.swift:472  bare corner radius  cornerRadius: 3
App/AimGauges.swift:474  bare corner radius  cornerRadius: 3
App/AimGauges.swift:511  bare font size  .system(size: 6
App/AimGauges.swift:702  bare colour  Color.white
App/AimGauges.swift:712  bare colour  .white
App/AimGauges.swift:715  bare corner radius  topLeadingRadius: 0
App/AimGauges.swift:715  bare corner radius  bottomLeadingRadius: 0
App/AimGauges.swift:726  bare corner radius  cornerRadius: 4
App/AimGauges.swift:728  bare corner radius  cornerRadius: 4
App/AimGauges.swift:779  bare font size  .system(size: 12
App/AimGauges.swift:895  bare colour  Color(red:
App/AimOverlay.swift:229  bare colour  Color.white
App/AimOverlay.swift:709  bare colour  Color.white
App/AimOverlay.swift:730  bare colour  .black
App/AimOverlay.swift:824  bare colour  Color.white
App/AimOverlay.swift:839  bare colour  .black
App/BreakdownApp.swift:150  bare colour  Color(red:
App/BreakdownApp.swift:229  bare colour  Color(red:
App/CaptionViews.swift:334  bare corner radius  cornerRadius: 10
App/CaptionViews.swift:361  bare corner radius  cornerRadius: 18
App/CaptionViews.swift:1068  bare corner radius  cornerRadius: 16
App/CaptionViews.swift:1356  bare colour  .black
App/Clips/ClipOverlay.swift:49  bare colour  .white
App/Clips/ClipOverlay.swift:60  bare colour  .white
App/Clips/ClipOverlay.swift:63  bare corner radius  cornerRadius: 12
App/Clips/ClipOverlay.swift:64  bare colour  .black
App/Clips/ClipOverlay.swift:65  bare colour  .white
App/Clips/ClipOverlay.swift:65  bare corner radius  cornerRadius: 12
App/Clips/ClipOverlay.swift:370  bare colour  CGColor(srgbRed:
App/Clips/ClipOverlay.swift:374  bare colour  CGColor(srgbRed:
App/Clips/ClipViews.swift:138  bare corner radius  cornerRadius: 22
App/Daily/DailyViews.swift:199  bare corner radius  cornerRadius: 22
App/Daily/DailyViews.swift:343  bare colour  .white
App/Daily/DailyViews.swift:343  bare corner radius  cornerRadius: 10
App/EightBall/EightBallPhoneBlurbs.swift:204  bare colour  .white
App/EightBall/EightBallPhoneBlurbs.swift:291  bare colour  .white
App/EightBall/EightBallViews.swift:86  bare colour  Color(white:
App/EightBall/EightBallViews.swift:89  bare colour  Color(red:
App/EightBall/EightBallViews.swift:368  bare corner radius  cornerRadius: 22
App/EightBall/EightBallViews.swift:831  bare corner radius  cornerRadius: 48
App/EveryWorldLook.swift:24  bare colour  Color(red:
App/EveryWorldOverlay.swift:189  bare colour  .black
App/EveryWorldOverlay.swift:199  bare colour  .black
App/EveryWorldOverlay.swift:202  bare font size  .system(size: 10
App/EveryWorldViews.swift:114  bare colour  .white
App/EveryWorldViews.swift:125  bare colour  .white
App/EveryWorldViews.swift:219  bare corner radius  cornerRadius: 22
App/EveryWorldViews.swift:290  bare corner radius  cornerRadius: 22
App/EveryWorldViews.swift:418  bare colour  .white
App/FlightSideView.swift:351  bare corner radius  cornerRadius: 14
App/FlightSideView.swift:356  bare corner radius  cornerRadius: 14
App/FlightSideView.swift:357  bare colour  .black
App/FlightSideView.swift:358  bare colour  .white
App/FlightSideView.swift:358  bare corner radius  cornerRadius: 14
App/FlightSideView.swift:372  bare corner radius  cornerRadius: 14
App/FreePlayPhoneBlurbs.swift:98  bare colour  Color.white
App/FreePlayPhoneBlurbs.swift:98  bare colour  Color.red
App/FreePlayViews.swift:215  bare colour  Color.red
App/FreePlayViews.swift:228  bare corner radius  cornerRadius: 22
App/FreePlayViews.swift:307  bare corner radius  cornerRadius: 22
App/FreePlayViews.swift:350  bare corner radius  cornerRadius: 22
App/FreePlayViews.swift:436  bare corner radius  cornerRadius: 22
App/FreePlayViews.swift:533  bare corner radius  cornerRadius: 22
App/GhostOverlay.swift:142  bare colour  .black
App/GhostOverlay.swift:208  bare colour  .black
App/GhostOverlay.swift:259  bare corner radius  cornerRadius: 20
App/LensCallouts.swift:217  bare colour  .black
App/LensCallouts.swift:345  bare corner radius  cornerRadius: 20
App/LensCallouts.swift:418  bare colour  .white
App/LensPlan.swift:102  bare corner radius  cornerRadius: 6
App/LensPlan.swift:116  bare colour  .black
App/Lessons/LessonViews.swift:158  bare corner radius  cornerRadius: 22
App/Lessons/LessonViews.swift:650  bare corner radius  cornerRadius: 48
App/Match/CallControl.swift:186  bare corner radius  cornerRadius: 14
App/Match/CallControl.swift:321  bare colour  .white
App/Match/MatchViews.swift:145  bare corner radius  cornerRadius: 22
App/Match/MatchViews.swift:1092  bare colour  Color(red:
App/Match/MatchViews.swift:1096  bare colour  Color(red:
App/Match/MatchViews.swift:1113  bare colour  Color.black
App/Match/MatchViews.swift:1119  bare colour  Color.black
App/Match/MatchViews.swift:1123  bare colour  Color.black
App/Match/TableGamePage.swift:153  bare corner radius  cornerRadius: 14
App/Match/TableGamePage.swift:173  bare corner radius  cornerRadius: 14
App/NotebookInfo.swift:161  bare corner radius  cornerRadius: 18
App/NotebookInfo.swift:240  bare corner radius  cornerRadius: 22
App/NotebookInfo.swift:281  bare corner radius  cornerRadius: 22
App/NotebookInfo.swift:305  bare corner radius  cornerRadius: 10
App/NotebookPanel.swift:496  bare colour  .black
App/NotebookPanel.swift:497  bare colour  .black
App/NotebookPanel.swift:498  bare colour  .black
App/NotebookStory.swift:159  bare colour  .black
App/NotebookStory.swift:160  bare colour  .black
App/NotebookStory.swift:267  bare corner radius  cornerRadius: 12
App/NotebookStory.swift:272  bare corner radius  cornerRadius: 12
App/NotebookStory.swift:330  bare corner radius  cornerRadius: 12
App/NotebookStory.swift:334  bare corner radius  cornerRadius: 12
App/OpeningHandover.swift:212  bare corner radius  cornerRadius: 22
App/OwnShotViews.swift:216  bare colour  .red
App/Phone/Blurb.swift:59  bare corner radius  let corner: CGFloat = 12
App/Phone/Blurb.swift:250  bare colour  .white
App/Phone/Blurb.swift:273  bare colour  .white
App/Phone/Blurb.swift:304  bare font size  .system(size: 7
App/Phone/Blurb.swift:305  bare colour  .white
App/Phone/Blurb.swift:387  bare colour  .white
App/Phone/Blurb.swift:394  bare colour  .black
App/Phone/PhoneAimPanel.swift:64  bare colour  .white
App/Phone/PhoneAimPanel.swift:107  bare corner radius  let corner: CGFloat = 24
App/Phone/PhoneAimPanel.swift:308  bare colour  .white
App/Phone/PhoneAimPanel.swift:343  bare colour  Color(red:
App/Phone/PhoneAimPanel.swift:425  bare corner radius  cornerRadius: 3
App/Phone/PhoneAimPanel.swift:427  bare corner radius  cornerRadius: 3
App/Phone/PhoneExplanation.swift:377  bare colour  .black
App/Phone/PhoneStrip.swift:352  bare colour  .white
App/Phone/PhoneTitleRow.swift:108  bare colour  .white
App/Phone/PhoneTitleRow.swift:112  bare colour  .black
App/Phone/PhoneTitleRow.swift:281  bare colour  .black
App/PlayTableLayer.swift:91  bare colour  Color.red
App/PlayTableLayer.swift:92  bare colour  Color.red
App/PlayTableLayer.swift:101  bare colour  Color.red
App/RetryWords.swift:249  bare corner radius  cornerRadius: 20
App/RideMap.swift:43  bare corner radius  cornerRadius: 16
App/RideMap.swift:56  bare colour  Color(red:
App/RideMap.swift:57  bare colour  Color(red:
App/RideMap.swift:89  bare corner radius  cornerRadius: 3
App/RideMap.swift:90  bare corner radius  cornerRadius: 1.5
App/RideMap.swift:91  bare corner radius  cornerRadius: 1.5
App/RideMap.swift:95  bare colour  .black
App/RideMap.swift:148  bare colour  .black
App/ScrubBar.swift:94  bare colour  Color.white
App/ScrubBar.swift:95  bare colour  Color.white
App/ScrubBar.swift:102  bare colour  .white
App/ScrubBar.swift:104  bare colour  Color.black
App/ScrubBar.swift:194  bare colour  .black
App/ScrubBar.swift:195  bare colour  .white
App/ScrubBar.swift:211  bare colour  .black
App/ShotPanel.swift:609  bare font size  .system(size: 15
App/ShotPanel.swift:664  bare corner radius  cornerRadius: 26
App/ShotPanel.swift:853  bare corner radius  cornerRadius: 26
App/ShowpieceView.swift:1000  bare corner radius  cornerRadius: 16
App/ShowpieceView.swift:1014  bare corner radius  cornerRadius: 16
App/ShowpieceView.swift:1122  bare colour  .black
App/ShowpieceView.swift:1125  bare colour  .black
App/Strike/CueAngleDial.swift:180  bare colour  Color(white:
App/Strike/Instrument.swift:61  bare colour  Color.black
App/Strike/Instrument.swift:190  bare corner radius  cornerRadius: 6
App/Strike/Instrument.swift:191  bare corner radius  cornerRadius: 6
App/Strike/Instrument.swift:214  bare corner radius  cornerRadius: 10
App/Strike/Instrument.swift:262  bare corner radius  cornerRadius: 16
App/Strike/Instrument.swift:263  bare corner radius  cornerRadius: 16
App/Strike/StrikeEntry.swift:225  bare colour  Color.white
App/Strike/StrikeEntry.swift:245  bare corner radius  cornerRadius: 24
App/Strike/StrikePanel.swift:113  bare corner radius  cornerRadius: 8
App/Stroke/StanceViews.swift:140  bare corner radius  cornerRadius: 14
App/Stroke/StanceViews.swift:155  bare corner radius  cornerRadius: 14
App/Stroke/StanceViews.swift:156  bare corner radius  cornerRadius: 14
App/Stroke/StanceViews.swift:159  bare corner radius  cornerRadius: 20
App/Stroke/StanceViews.swift:160  bare corner radius  cornerRadius: 20
App/Stroke/StrokeViews.swift:101  bare corner radius  cornerRadius: 20
App/Stroke/StrokeViews.swift:182  bare corner radius  cornerRadius: 22
App/Surfaces.swift:27  bare corner radius  cornerRadius: CGFloat = 24
App/TableAccessLayer.swift:437  bare colour  Color.white
App/TableAccessLayer.swift:611  bare colour  Color.white
App/TableList.swift:99  bare corner radius  cornerRadius: 12
App/TablePortraits.swift:174  bare corner radius  cornerRadius: 12
App/TargetBallBadge.swift:177  bare colour  Color(red:
App/TargetBallBadge.swift:194  bare colour  Color.black
App/TargetBallBadge.swift:207  bare colour  Color.black
App/TeachersLink.swift:45  bare corner radius  cornerRadius: 14
App/TitleScreen.swift:386  bare corner radius  cornerRadius: 28
App/TitleScreen.swift:417  bare corner radius  topLeadingRadius: 28
App/TitleScreen.swift:417  bare corner radius  topTrailingRadius: 28
App/TitleScreen.swift:966  bare corner radius  cornerRadius: 14
App/TitleScreen.swift:1096  bare corner radius  cornerRadius: 14
App/TrickPathThumb.swift:202  bare colour  Color(red:
App/TrickPathThumb.swift:204  bare colour  Color(red:
App/TrickPathThumb.swift:211  bare colour  Color(red:
App/TrickPathThumb.swift:238  bare corner radius  cornerRadius: 3.5
App/TrickPathThumb.swift:240  bare corner radius  cornerRadius: 2
App/TrickPathThumb.swift:241  bare corner radius  cornerRadius: 2
App/TrickPathThumb.swift:246  bare colour  .black
App/TrickPathThumb.swift:272  bare colour  Color.black
App/TrickShotViews.swift:221  bare corner radius  cornerRadius: 22
App/TrickShotViews.swift:620  bare corner radius  cornerRadius: 48
App/WhatIfOverlay.swift:114  bare colour  .black
App/WhatIfOverlay.swift:141  bare colour  .black
App/WhatIfOverlay.swift:148  bare colour  .black
App/WhatIfViews.swift:145  bare corner radius  cornerRadius: 22
App/WhatIfViews.swift:169  bare corner radius  cornerRadius: 22
App/WhatIfViews.swift:612  bare colour  .white

Summary by package (plans/26-Nov-2026-ui-rethink-plan.md)

Package 4, The shot console: 47 hits in 9 files
  App/AimGauges.swift: 24 (16 bare colour, 2 bare font size, 6 bare corner radius)  (also package 1)
  App/FreePlayViews.swift: 6 (1 bare colour, 5 bare corner radius)
  App/NotebookPanel.swift: 3 (3 bare colour)  (also package 8)
  App/OpeningHandover.swift: 1 (1 bare corner radius)
  App/ShotPanel.swift: 3 (1 bare font size, 2 bare corner radius)
  App/Strike/CueAngleDial.swift: 1 (1 bare colour)
  App/Strike/Instrument.swift: 6 (1 bare colour, 5 bare corner radius)
  App/Strike/StrikeEntry.swift: 2 (1 bare colour, 1 bare corner radius)
  App/Strike/StrikePanel.swift: 1 (1 bare corner radius)  (also package 1)

Package 5, The mode frame: 31 hits in 10 files
  App/Daily/DailyViews.swift: 3 (1 bare colour, 2 bare corner radius)
  App/EightBall/EightBallViews.swift: 4 (2 bare colour, 2 bare corner radius)
  App/Lessons/LessonViews.swift: 2 (2 bare corner radius)
  App/Match/CallControl.swift: 2 (1 bare colour, 1 bare corner radius)
  App/Match/MatchViews.swift: 6 (5 bare colour, 1 bare corner radius)
  App/Match/TableGamePage.swift: 2 (2 bare corner radius)
  App/NotebookInfo.swift: 4 (4 bare corner radius)
  App/OwnShotViews.swift: 1 (1 bare colour)
  App/Stroke/StanceViews.swift: 5 (5 bare corner radius)
  App/TrickShotViews.swift: 2 (2 bare corner radius)

Package 6, The upright phone's thumb dock: 33 hits in 10 files
  App/CaptionViews.swift: 4 (1 bare colour, 3 bare corner radius)  (also package 9)
  App/EightBall/EightBallPhoneBlurbs.swift: 2 (2 bare colour)
  App/FreePlayPhoneBlurbs.swift: 2 (2 bare colour)
  App/LensCallouts.swift: 3 (2 bare colour, 1 bare corner radius)
  App/Phone/Blurb.swift: 7 (5 bare colour, 1 bare font size, 1 bare corner radius)
  App/Phone/PhoneAimPanel.swift: 6 (3 bare colour, 3 bare corner radius)
  App/Phone/PhoneExplanation.swift: 1 (1 bare colour)
  App/Phone/PhoneStrip.swift: 1 (1 bare colour)
  App/Phone/PhoneTitleRow.swift: 3 (3 bare colour)
  App/ShowpieceView.swift: 4 (2 bare colour, 2 bare corner radius)  (also package 7)

Package 7, The front door and the sheets: 12 hits in 4 files
  App/Achievements/AchievementViews.swift: 2 (2 bare corner radius)
  App/ShowpieceView.swift: 4 (2 bare colour, 2 bare corner radius)  (also package 6)
  App/TableList.swift: 1 (1 bare corner radius)
  App/TitleScreen.swift: 5 (5 bare corner radius)

Package 8, The open folding phone: 3 hits in 1 files
  App/NotebookPanel.swift: 3 (3 bare colour)  (also package 4)

Package 9, The Lens notebook: 16 hits in 3 files
  App/CaptionViews.swift: 4 (1 bare colour, 3 bare corner radius)  (also package 6)
  App/FlightSideView.swift: 6 (2 bare colour, 4 bare corner radius)
  App/NotebookStory.swift: 6 (2 bare colour, 4 bare corner radius)

Package 1, Bugs a player sees (outside the before-launch clean-up, packages 4 to 9): 36 hits in 5 files
  App/AimGauges.swift: 24 (16 bare colour, 2 bare font size, 6 bare corner radius)  (also package 4)
  App/AimOverlay.swift: 5 (5 bare colour)
  App/GhostOverlay.swift: 3 (2 bare colour, 1 bare corner radius)
  App/Strike/StrikePanel.swift: 1 (1 bare corner radius)  (also package 4)
  App/TargetBallBadge.swift: 3 (3 bare colour)

Package 2, The design tokens (outside the before-launch clean-up, packages 4 to 9): 2 hits in 1 files
  App/BreakdownApp.swift: 2 (2 bare colour)

Package 3, The component kit (outside the before-launch clean-up, packages 4 to 9): 7 hits in 1 files
  App/ScrubBar.swift: 7 (7 bare colour)

Package 10, Achievements and sharing (outside the before-launch clean-up, packages 4 to 9): 1 hits in 1 files
  App/Clips/ClipViews.swift: 1 (1 bare corner radius)

Package 12, Ride (outside the before-launch clean-up, packages 4 to 9): 8 hits in 1 files
  App/RideMap.swift: 8 (4 bare colour, 4 bare corner radius)

Unowned (no package names the file): 44 hits in 15 files
  App/Clips/ClipOverlay.swift: 8 (6 bare colour, 2 bare corner radius)
  App/EveryWorldLook.swift: 1 (1 bare colour)
  App/EveryWorldOverlay.swift: 3 (2 bare colour, 1 bare font size)
  App/EveryWorldViews.swift: 5 (3 bare colour, 2 bare corner radius)
  App/LensPlan.swift: 2 (1 bare colour, 1 bare corner radius)
  App/PlayTableLayer.swift: 3 (3 bare colour)
  App/RetryWords.swift: 1 (1 bare corner radius)
  App/Stroke/StrokeViews.swift: 2 (2 bare corner radius)
  App/Surfaces.swift: 1 (1 bare corner radius)
  App/TableAccessLayer.swift: 2 (2 bare colour)
  App/TablePortraits.swift: 1 (1 bare corner radius)
  App/TeachersLink.swift: 1 (1 bare corner radius)
  App/TrickPathThumb.swift: 8 (5 bare colour, 3 bare corner radius)
  App/WhatIfOverlay.swift: 3 (3 bare colour)
  App/WhatIfViews.swift: 3 (1 bare colour, 2 bare corner radius)

Total: 204 hits in 56 files (109 bare colour, 5 bare font size, 90 bare corner radius)
```
