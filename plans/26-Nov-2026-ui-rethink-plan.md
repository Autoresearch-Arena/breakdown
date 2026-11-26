<!--
Author: Claude Opus 5.5 Medium
Date: 26-November-2026
PURPOSE: The ranked plan that brings every screen of Breakdown into the one design language
         (26-Nov-2026-design-language.md): a plain summary for the Boss first, then the work packages in order, each
         naming its screens and files, what done looks like, and which packages can be built at once without
         touching the same files. Built from the six area reviews of 26 November (system, front door, play, Physics
         Lens, modes, phone) and the screenshots in store/review/design.
SRP/DRY check: Pass - the rules (colours, type, components, layouts) live only in the design language page; this
         page only orders the work and assigns files. Mockups: store/review/design/mockup-*.png.
-->
# The UI rethink: bringing every screen into one design

## For the Boss, in plain words

**What is wrong.** The physics underneath is the best thing in the game, but the frame around it was built by many
hands and it shows. Each device has its own swing bar, its own main button and its own playback bar. Each mode has
its own card, its own way of saying how hard something is, and sometimes its own name for the same shot. The pink
that is meant to mean "the ball is sliding" is also used for fouls, headings and try counts, so the one lesson the
Lens teaches gets muddled. Options looks like the phone's Settings app. On the upright iPad half the screen is empty
black. On the phone, cards sit on top of the table and buttons are split between the top corner and the bottom.

**What it will feel like after.** One instrument laid beside a real table. The table is always the biggest thing on
the screen and nothing sits on it on the big screens. Every panel is the same calm dark surface. Every number looks
the same and carries a real unit. Each colour means one thing, on the cloth and in the panel. The main button is
always the same cyan pill in the same place, and it always has a word on it. Every mode uses the same card, so
learning one mode teaches you all of them. The first minute is the table, one sentence and the Break button.

**Before launch** (packages 1 to 9): the four bugs a player would see, the colour and type rules, the shared kit,
the shot console, the mode card, the phone's thumb dock, the folding phone's split, the front door and the sheets,
and the Lens notebook.
**After launch** (packages 10 to 12): achievements with "Try it", the share picture from the real table, the
shot-name glossary across lessons and tricks, and Ride's new camera.

Three mockups show the target: `store/review/design/mockup-menu-ipad.png`,
`store/review/design/mockup-aiming-ipad.png` and `store/review/design/mockup-aiming-iphone.png`.

## The order and who can build at once

| Wave | Packages | Built at once? |
| --- | --- | --- |
| 1 | 1 Bugs a player sees, 2 The design tokens | Yes: they touch different files |
| 2 | 3 The component kit | Alone: everything after builds on it |
| 3 | 4 Shot console, 5 Mode frame, 7 Front door and sheets, 9 Lens notebook | Yes: file lists below do not overlap |
| 4 | 6 Upright phone dock, 8 Open folding phone | Yes, after 4 and 5 land (they place what those built) |
| 5 | 10, 11, 12 | After launch, any order |

A file is owned by one package per wave. If a builder needs a file owned by another package in the same wave, they
leave a note in that package's plan instead of editing it.

## Work packages

### 1. Bugs a player sees (must, wave 1)

Screens: Mac aiming in a narrow window, Mac and iPad after a shot, upright iPad break, iPhone Lens opening.
Files: App/AimOverlay.swift, App/GhostOverlay.swift, App/TargetBallBadge.swift, App/Strike/StrikeReading.swift,
App/Strike/StrikePanel.swift, App/AimGauges.swift (tick labels only), App/LensLayer.swift, App/LensTextures.swift.

- Aim marks re-project whenever the table view changes size; the ghost ring stays on the cue ball at narrow, wide and
  full-screen widths.
- Any aim change on the table, a new rack or a turn change ends the planned-against-delivered reading.
- The "physics" band and "what you set" card never overlap: one stack that scrolls together.
- Scale labels thin out so none touch ("11 12" never prints as "1112").
- The dark squares behind the Lens balls become round soft masks, or go.

Done when: each of the five is fixed and has a check in the existing test target; the store Lens frame is re-shot
after the square fix.

### 2. The design tokens (must, wave 1)

Files: App/Theme.swift, App/NumberStyle.swift, App/BreakdownApp.swift (window tint only).

- Palette gets the roles in the design language: panel, panelSunken, paper2, paper3, contact (strike and impact
  merged), pocket, warning. Delta yellow is retired. Friction stays magenta; nothing else does.
- One text scale by role and one figure family (lead, control, inline) with grey units, floor at caption size. The
  rounded figure fonts, the phone blurb fonts and the extra small figure fonts become aliases that point at the new
  ones, then are deleted in package 3.
- One precision rule per unit in NumberStyle; "s" for every time; "m/s²" on gravity.
- Spacing steps and the three corner radii as named values.
- Cyan as the window tint, so switches and links stop being system green and blue.

Done when: Theme holds every value in the design language, and the old names still compile as aliases.

### 3. The component kit (must, wave 2, alone)

Files: new App/Kit folder (PrimaryButton, SecondaryButton, QuietButton, PanelCard, ModeCard, ResultCard,
RulingCard, Scoreboard, FigureTile, FigureText, Chip, ProgressChip, ListRow, SectionLabel, SheetPage, ShotReel,
SwingBar), plus App/PlaybackControls.swift and App/ScrubBar.swift (folded into ShotReel), App/Strike/NumberTile.swift
(folded into FigureTile).

- Each component exactly as the design language describes it, with a preview of every state.
- Glass is used only in the floating-control style; everything else is the panel surface.
- A short lint script in scripts/ fails the build log (not the build) on a bare colour, bare font size or bare corner
  radius in App outside Theme and Kit, so later builders cannot drift.

Done when: every component exists, the old aliases from package 2 are deleted, and the lint lists what packages 4 to
9 must clear.

### 4. The shot console (must, wave 3)

Screens: iPad aiming (both ways up), Mac aiming, first launch on big screens, playback on big screens.
Files: App/ShotPanel.swift, App/AimGauges.swift, App/CueAngleControl.swift, App/Strike/ (package 1 is merged by then),
App/MacChrome.swift, App/FreePlayViews.swift, App/OpeningHandover.swift, App/NotebookPanel.swift and
App/NotebookGeometry.swift (the upright iPad column; package 8 takes them over in wave 4).

- One console: state strip, live figures band, controls in a row (Tip, Cue angle, Swing, Bridge), action column
  (Shoot as a tall cyan capsule, Try again as a secondary capsule the same width).
- One name: "Your strike" everywhere.
- The shot reel shows only after a shot; while aiming it is a "Last shot" button.
- The planned-against-delivered comparison lives in a "Last shot" card, not in the live figures.
- First launch: the table, one card beside it with the sentence, tip picture, swing in m/s and Break. The Lens, Ride
  and Aim tabs and the step list appear after the first shot. The title is "Break" on every device.
- Rename the bottom tab "Your shot" to "Aim".

Done when: mockup-aiming-ipad.png is what the iPad sideways looks like; the upright iPad has no empty band; the Mac
has one place for the modes.

### 5. The mode frame (must, wave 3)

Screens: shot of the day, trick shots, behind the 8-ball, lessons, drills, the table games, their lists and results.
Files: App/TrickShotViews.swift, App/EightBall/EightBallViews.swift, App/Lessons/LessonViews.swift,
App/Daily/DailyViews.swift, App/Daily/DailyMenuRow.swift, App/Match/MatchViews.swift, App/Match/TableGamePage.swift,
App/Match/CallControl.swift, App/Match/MatchWords.swift, App/Match/OpponentWords.swift, App/Match/TableGameWords.swift,
App/NotebookInfo.swift (cloth card), App/OwnShotViews.swift, App/Stroke/StanceViews.swift.

- Every mode fills in the one mode card, result card and ruling card.
- Difficulty is five dots on every mode, lesson and table game. The magenta tags go.
- Every match has the scoreboard strip; "Computer" once, with its level as a badge.
- The three lists use the one list row with a table drawing; row text in paper and paper2, never cyan.
- The ball chips in the call row wrap; the chosen pocket is a selected chip; "Call it" is the only primary.
- The cloth card spells its figures out ("Sliding friction 0.15, Rolling resistance 0.015, Gravity 9.81 m/s²"),
  names the edge by table ("Cushions", "Bumpers") and has its own cloth icon.
- "How forgiving" tiles on every card that sets up a shot.

Done when: a screenshot of each mode's card could be swapped with any other's and only the words and figures change.

### 6. The upright phone's thumb dock (must, wave 4)

Screens: every upright iPhone screen while playing.
Files: App/Phone/ (all), App/FreePlayPhoneBlurbs.swift, App/EightBall/EightBallPhoneBlurbs.swift,
App/Match/MatchPhoneBlurbs.swift, App/CaptionViews.swift, App/LensCallouts.swift, App/CameraFraming.swift (phone
framing only), App/ShowpieceView.swift (phone dock only).

- Three zones: title row, the whole table, the thumb dock. The camera frames to the top of the dock.
- The top-left card holds no buttons; every action moves to the dock, primary right, one secondary beside it.
- One word strip of fixed height above the scrub row: two lines and a worded "More" that opens the pull-up sheet.
- The real-table recipe becomes one line that opens the sheet; the table keeps its full frame.
- The title row says only what is being played.
- The aiming sheet grows out of the dock and the camera reframes above it.
- First shot shows only the hint, the tip picture, the swing bar with its figure, and Break; the cue never runs into
  the status bar.

Done when: mockup-aiming-iphone.png is what the phone looks like; no caption sits on the ball it describes.

### 7. The front door and the sheets (must, wave 3)

Screens: main menu on every device, Tables, Options, Achievements (layout only), Lessons list, How to play.
Files: App/TitleScreen.swift, App/FrontDoor.swift, App/TableList.swift, App/GameSettings.swift,
App/Achievements/AchievementViews.swift, App/TableZoomMenu.swift, App/ShowpieceView.swift (the stage layout on big
screens; package 4 leaves its stage needs as notes here, and package 6 takes the file over in wave 4).

- Big screens: the table fills the stage, the menu is the side column (mockup-menu-ipad.png); upright iPad gets a
  full-width bottom panel with no dead band.
- Menu: Shot of the day, Play, Trick shots, Behind the 8-ball, Lessons; then three tiles: Achievements, How to play,
  Options. "Watch the intro" moves into How to play. No "Today" heading.
- Progress chips: one design, inside the row, hidden until something is earned.
- Every sheet uses the sheet page: ground, serif title, "Done" top right in cyan.
- Options in four groups, cyan tint, one "Show all tips again" row, version at the foot.
- Tables: full-width cards with picture, name, one sentence and a line of real figures (bed in m, ball in mm,
  pockets or pins); every card opens a table page with Play.
- Toolbar icons carry their words on big screens; the grid becomes "Menu".

Done when: no screen in the app shows system grey, system blue or system green.

### 8. The open folding phone (must, wave 4)

Files: App/LayoutFlags.swift, App/NotebookPanel.swift, App/NotebookGeometry.swift, plus a hinge check added to the
three label layers already fixed in package 1 (AimOverlay, TargetBallBadge, GhostOverlay; package 1 is merged by
then, so no clash).

- On a hinge the table half draws marks only; every label moves to the top line of the panel.
- Capture open, half-open and closed postures and add them to store/review/design.

Done when: the open capture shows no word on the table half.

### 9. The Lens notebook (must, wave 3)

Screens: Lens on every device, the notebook, the scrub ticks, the legend.
Files: App/NotebookStory.swift, App/Captions.swift, App/CaptionViews.swift (big-screen chip only; package 6 takes it
over in wave 4), App/PacePlan.swift, App/FlightSideView.swift.

- One current beat drives the chip, the highlighted row and the scrub tick.
- Repeats fold into one row ("The path bends, 7 times, up to 15°"); pots and paced beats are bold headline rows.
- The short sentence for the path bend carries the cause.
- The strike beat's zoom keeps the arrow tip and the first ball in frame.
- The legend chip opens a full key (arrow, ring, burst); short sliding stretches draw solid.
- The jump side view shows peak height and clearance in cm.
- One name: "Physics Lens".

Done when: the opening break's notebook fits on one screen without scrolling past repeats.

### 10. Achievements and sharing (after launch)

Files: App/Achievements/AchievementWords.swift, App/Daily/DailyShare.swift, App/Clips/ClipShare.swift,
App/Clips/ClipViews.swift.
Summary band, one-line unearned entries, the real threshold on each shot achievement, "Try it". One share picture
drawn from the real table for every result, with the serif wordmark and the mode's real-unit figure.

### 11. One glossary of shot names (after launch)

Files: App/Lessons/Lessons.swift, App/TrickShots.swift, App/Achievements/Achievement.swift,
App/Localizable.xcstrings.
Stop, follow, draw, throw, massé, jump: one name each across lessons, achievements and captions; trick shots keep
their playful title and name the technique in the meta line; sentence case everywhere.

### 12. Ride (after launch)

Files: App/RideStage.swift, App/RideOverlay.swift, App/RideMap.swift, App/ShotCamera.swift.
A low chase camera with the ridden ball large in the lower third, the coming path on the cloth, a slim caption with
one figure, the map shown only in Ride with a word on it. Re-shoot the Ride and Jump store frames.

## What is not seen yet and must be captured before launch

iPad achievements, how to play, options, tables and lessons list; any Mac screen beyond aiming; the open folding
phone in all three postures; the phone turned sideways. Each package captures the screens it changes.
