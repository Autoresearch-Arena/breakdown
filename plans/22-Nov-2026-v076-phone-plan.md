<!--
Author: Claude Opus 5.5 High
Date: 22-November-2026
PURPOSE: Build plan for Breakdown 0.7.6: every bug in plans/22-Nov-2026-phone-bug-hunt.md fixed, plus the phone Lens
         replay rebuilt so the moment being explained is shown large in the open space above a card that never covers
         it. Split into eight builder streams with disjoint files, a foundation commit, and a words pass after the merge.
SRP/DRY check: Pass - checked plans/ (the bug hunt is the list of what is wrong; this is how it gets fixed) and the
         0.7.5 plan's stream layout, which this follows.
-->
# 0.7.6: the phone shows the physics

## In plain words

The Boss looked at 0.7.5 on a regular iPhone. The explanation card climbed over the table, the ring and its label were
drawn across the card's words, the whole table stayed on screen while the moment being explained was a few points wide
at the bottom edge, and things went by too fast. The roll-along camera (Ride) did not make clear what you were looking
at or from where. A code-wide hunt then found over sixty more phone bugs (plans/22-Nov-2026-phone-bug-hunt.md, entries
numbered there; "#N" below means entry N of that file).

What he wants (his words): keep the plain-language sentence and make it look good; show the player this app is physics
central; come in on the action; on the phone some text may fold behind a tap ("a dot that you can tap and see it"), but
never shortchange the graphics: balls rolling, vectors, spin marks must be large and clear. He decides nothing here:
every bug in the list is fixed.

Version 0.7.6 (patch step only).

## How a guided Lens replay should feel on an upright phone after this

1. The replay slows as a moment comes. While it slows, the view glides in on the moment so that the balls involved fill
   the open space above the card (about three times larger than the whole-table view), and the moment sits in the
   middle of that space.
2. The clock stops on the moment. The card underneath shows the title, Continue at the title's right, and the plain
   sentences at full width in a room that never changes height and never covers the table. A caption longer than the
   room is split into pages at sentence ends; small page dots show there is more and can be tapped. Continue turns the
   page, then plays on. Each page gets its own reading time; nothing lets go after a fixed six seconds any more.
3. On Continue the balls leave slowly with the view still close, so the throw peeling off the line of centres, or the
   path bending, is actually watched. Then the view eases back out to the whole table as speed returns.
4. The physics drawings (line of centres, tangent, momentum triangle, throw lines, velocity arrows, spin marks) are never
   thinner or smaller than a readable size on screen, whatever the zoom.
5. The ring and the title label never land on the card or on the ball they name.

Reduce Motion: no glide; the view stays whole and the drawings carry the moment. A player's own pinch always wins: the
glide never moves a view the player has zoomed.

## Rules for every builder

- Write code only. Do not build, do not run tests, do not boot a simulator. The coordinator compiles once after the
  merge and fixes what breaks.
- Touch only your stream's files. If a fix needs a line in another stream's file, do not make it: write it under
  "Hand-offs" in your final report with the exact change.
- Every file you edit gets an "Edited:" line in its header (Claude Opus 5.5 High, 22-November-2026, 0.7.6 stream <name>,
  what changed). New files get the full header (CODING_STANDARDS.md). Comment the non-obvious.
- New on-screen words: write them as plain English string literals in code, whole sentences, no names of people, brands
  or sources (physics and generic shot names only). Do not edit App/Localizable.xcstrings: the words pass adds and
  translates every new key after the merge. List every new key in your report.
- Keep these true: Lens marks and the Ride camera are pure functions of the playback clock (scrubbing to a time always
  shows the same picture; LensScrubCheck and ShotCamera.selfTest pin it). Reduce Motion means no camera flight. A
  player's own zoom is never overridden. The first launch stays exactly as calm as 0.7.5 (racked pool table, one
  instruction, a normal-speed break, nothing played or pushed). The open folding phone, iPad and Mac keep their notebook
  layout; words never cover the table there either.
- Unit tests that pin exact caption sentences and titles (BreakdownTests/CaptionEngineTests.swift) must keep passing;
  update a test only when the behaviour change is the point, and say so.

## The foundation (done by the coordinator before the streams start)

- Version 0.7.6 in the project file.
- Caption.sentences (App/Captions.swift): the detail's sentences one by one; empty until stream card fills it.
- Pages of a held caption (App/ShowpieceModel.swift): `holdPage` (observed), `holdPageCount`,
  `setHoldPages(caption:weights:)`, `showHoldPage(_:)`. The card reports how it split the held caption (one weight per
  page, its reading length); the model shares the hold's reading time out between pages, moves `holdPage` as the time
  runs, and `nextBeat()` (Continue) turns the page before it ends the hold.
- `RidePlan.init(_:cueBall:)` (App/ShotCamera.swift) with the struck ball; the model passes it. `rideActive` is false
  when the plan is not rideable (#21, model half).

## Stream card: the explanation card and the phone layout

Files: App/CaptionViews.swift, App/Captions.swift, App/ShowpieceView.swift, App/Surfaces.swift (FittingScroll only if
needed; WrappingRow belongs to stream cards, so hand off any change there).

- Fill Caption.sentences wherever a caption's detail is built (Captions.swift): every sentence that is joined into
  `detail` goes into `sentences` in the same order. `detail` must stay byte for byte what it is today.
- CaptionStrip on an upright phone (#1, #2, #3, #9, #60):
  - A fixed room: the title line, then a fixed number of detail lines (four at the default text size; measure with the
    hidden sizer as today, cap at the current share of the screen). The room is what the camera frames above, so the
    card never grows over the table. Nothing inside it may overflow upward.
  - Continue sits on the title line, at its trailing end, so the sentences run the full width; it keeps its room for the
    whole guided replay (shown faded and disabled when not holding) so the words never re-wrap mid-read.
  - Pages: measure each sentence at the card's width (hidden copies, as the sizer does), pack whole sentences greedily
    into pages that fit the room, report them with model.setHoldPages(caption:weights:) (weight = the page's word
    count, characters / 6 for languages without spaces). Show page model.holdPage while holding, the last page after.
    A single sentence taller than the room scrolls inside the room. Show small page dots beside the title when there is
    more than one page; each dot is a button (model.showHoldPage) with a VoiceOver label "Page 2 of 3". VoiceOver still
    reads the whole detail.
  - The worked equation: decided by the caption (a headline beat's caption shows its worked line whether or not the hold
    is still on), one line, shrinking to fit (minimumScaleFactor), never wrapping mid-equation. Reserve its line in the
    room whenever the replay has headline beats or Show the maths is on, so the room does not change between captions.
  - Report the strip's glass frame (stage space) to leader.card, and clear it when no caption shows or the strip goes.
- CaptionLeader (#1, #8, #59): the ring is hidden under leader.card as the code already intends; the pill is clamped
  above leader.card's top (and below the title row as today). On a Throw caption (Captions.throwFacts not nil) the ring
  and pill go on the struck ball, not the faster ball. When neither side of the ring fits the pill, put it above the
  ring (or below when there is no room above), never on it; cap its width.
- Captions.swift: the hard-coded "2.5" in the strike sentence follows the player's number style (#61, Captions half).
- ShowpieceView bottom stack (#10, #11, #36, #45, #50):
  - Measure PlaybackControls' real height (onGeometryChange) and subtract it, not the fixed 124, from the cards' cap.
  - Pin the shot panel (Your shot) between the scrolling cards and the playback row instead of inside the scroll, so
    Shoot is never below the fold.
  - Close Your shot while the player's own shot plays (panelWaits gains the shot-playing case, see #45) and reopen it
    as the code already does when the balls stop.
  - Sideways (side column): always pin PlaybackControls under the column's scroll (delete the in-scroll copy), show the
    caption card first while a guided Lens replay plays, scroll to the shot panel when it opens, and clear leader.card
    when the card is scrolled out of view.

## Stream pacing: the guided replay's clock and the model

Files: App/PacePlan.swift, App/ShowpieceModel.swift, App/LensCallouts.swift, App/TrickShotMode.swift,
App/TrickSignature.swift.

- Reading time (#4): for ordinary guided replays the hold is the caption's full reading time (about three words a
  second plus a second; characters / 6 for languages without spaces), no six-second cap. Keep the cap, and the four
  beats, for the .firstLaunch style and for the menu backdrop (backdropDwell), so the first minute and the menu behind
  it are unchanged. Explanations off keeps its short pause.
- Two beats within a few hundredths of a second of each other on the same picture (#5): keep the more important one only
  (a Throw beat beats a plain first-hit beat). The Called Break: its signature also holds the called ball dropping
  (TrickSignature), so the shot's point is a stop.
- The Called Break's answer gets its guided Lens replay like every other trick (#22): drop the break guard in
  TrickShotMode (update, and recordingReplaced), with the pacing list set as for the others.
- Lens on but not guided (a fixed speed, or Ride on) (#6): show only the latest beat's caption, not every event's, so
  the card does not flicker.
- The Lens tips start on a beat after the strike, when the sliding trail exists (#7). The third tip's bubble anchors on
  the playback row's top, not the whole bottom stack's (#13): add an observed `playbackRowTop` to the model or read one
  that stream card publishes (coordinate in your report).
- Watch the intro closes Your shot as it starts (#56): requestShotPanel(.close) in watchBreak.
- The intro's melt status title is short ("The Lens") so it fits the title row (#58).
- The moment framing (stream camera) needs, for each beat, where it is and what it should show. Expose on PacePlan, as a
  pure function of the recording, `focusRegions`: one per beat, a rectangle on the table (metres, table coordinates)
  that holds what the beat is about: for a hit, both balls and about 0.25 m of each one's path after it; for a bend or
  skid-to-roll, the slide's path; for the strike, the cue ball and the first 0.3 m of its path; for a cushion, a pocket
  or a jaw, the ball and 0.2 m around it. Stream camera reads it through model.pacePlan.

## Stream camera: the moment framing, the zoom and the Ride camera

Files: new App/MomentFrame.swift, App/SignatureCloseUp.swift (retire it: delete the file and its call, or keep it empty;
the moment framing replaces it), App/TableCamera.swift, App/TableZoom.swift, App/TableStage.swift, App/CameraFraming.swift,
App/ShotCamera.swift, App/TableScene.swift.

- MomentFrame: during a guided replay (model.guided, explore or slowReplay stage, not the menu backdrop, not Ride, not
  Reduce Motion, hand zoom at the fitted view), a framing amount w(t) and a focus rectangle that are pure functions of
  the playback clock and model.pacePlan (beats and focusRegions). w rises smoothly over the approach to each beat
  (PacePlan.approach shot-seconds before it), is 1 at the beat and stays 1 for about 0.35 shot-seconds after it so the
  departure is watched close, then eases out over about 0.3 shot-seconds. Beats close together blend their rectangles
  instead of going out and in again.
- Apply in TableCamera.update after the fitted pose and before the hand zoom: find the cloth point Q under the centre of
  the free rectangle (free.inner), then move the camera and its target across by w * (P - Q), where P is the focus
  rectangle's centre, then scale the camera's distance about P by 1 / m, where m is the magnification that fits the
  focus rectangle in about 70 per cent of the free rectangle, between 1 and 3.5, blended by w. Moving the camera about
  P with its orientation kept leaves P at the free centre on screen. This is a multiplier on the fit, not a new fit, so
  the framing self-check (whole-table fit) is unchanged.
- The fixed-centre bug (#14): the hand zoom's close-up and double tap treat their offset as an absolute table point but
  apply it relative to the fitted look point. Check where a target really lands with -frameDebug and -pauseAt before
  changing the maths, then make a double-tapped ball land at the free rectangle's centre.
- Pinch, pan and double tap do nothing during a ride (#24).
- Ride (#18, #19, #20, #21):
  - The blend between the table camera and the ride camera turns orientations, not look directions: build each pose's
    rotation from its forward and its own up, slerp, and have TableCamera set the camera from the blended orientation.
    No more spin through straight down.
  - Every shot and every Replay eases in (engage back to 0 on load and when the clock jumps back to the start).
  - Upright, the ride lens is about 64 degrees across (the intended width), with the ridden ball in the lower third of
    the free space, not at the cards' edge.
  - RidePlan and the ride tracks follow plan.cueBall instead of ball 0 (ShotCamera load must pass it:
    `RidePlan(tl, cueBall: ...)`; the model's call sites are done).
- Expose for stream drawings: `TableCamera.pointsPerMetre(at:)` (screen points per table metre at a world point, from
  eye, forward and focal), read by the Lens drawing every frame. Keep it cheap.

## Stream drawings: the Lens marks at a readable size

Files: App/LensLayer.swift, App/LensContactGeometry.swift, App/GhostOverlay.swift (TablePathStroke too), App/LensTextures.swift.

- A screen-size floor for every Lens mark (#15, #16, #65): read TableCamera.pointsPerMetre (stream camera adds it; if
  it is missing at merge the coordinator wires it) at the mark's place, and never draw a line under 2 points wide, an
  arrowhead under 8 points, the contact drawing's lines under 40 points long, or the throw lines under 90 points long
  with their far ends at least 6 points apart for a throw of one degree or more (lengthen, never exaggerate the angle).
- Spin marks (#65): the slip belt and side-spin ring stay readable from overhead (lay the belt flat on the cloth or tip
  it toward the camera when the camera is near straight down), with the same floors.
- Jump height mark (#17): a ring on the ball's ground spot always a few points wider than the drawn ball, growing with
  height.
- The last try's contact mark (#40): at least 7 points radius on screen, its dot about a third of that.
- Violet what-if paths in Ride (#26): TablePathStroke.line skips points that do not project and starts a new subpath,
  instead of dropping the whole path.
- Everything stays a pure function of the clock (sizes may depend on the camera, which is itself clock-driven).

## Stream cards: trick, lesson, match, Behind the 8-Ball and free-play cards

Files: App/TrickShotViews.swift, App/TrickShots.swift, App/Lessons/LessonViews.swift, App/Lessons/Lessons.swift,
App/Match/MatchViews.swift, App/Match/MatchMode.swift, App/EightBall/EightBallViews.swift, App/FreePlayViews.swift,
App/Surfaces.swift (WrappingRow).

- The slim form during a Lens replay keeps what the replay is for (#64, #38, #41, #32, #34, #35): the trick's idea line
  (two lines at most) beside Your turn with no empty glass; the lesson's idea when paused on its key moment; a match
  ruling's own button whenever it waits for a tap (#32 freezes a match today: fix first); a foul's or a game-ending
  ruling's reason and points; the More menu (End match, Your name) and an open names editor; Behind the 8-Ball's slim
  heading shows the replayed try's number.
- Ball in hand card never shows on the computer's turn (#33).
- Eight-ball player rows (#37): name and group readable in every language (wrap or stack instead of cutting).
- WrappingRow (#39): an over-wide child is capped to the row's width and starts inside it.
- Pocket directions (#23): replace screen words (top-right, bottom-left...) in trick and lesson text with table words
  that hold however the phone is held (the far corner beyond the rack, the corner pocket on the cue ball's left...).
  These are changed English keys: list them for the words pass.
- "Cleared in one shot / in %lld shots" (#62, code half): one catalog string with a count, so the words pass can give it
  real plural forms.

## Stream what-if: the what-if card and the playback row

Files: App/WhatIfViews.swift, App/WhatIfFork.swift, App/WhatIfOverlay.swift, App/ScrubBar.swift, App/PlaybackControls.swift,
App/Stroke/StrokeViews.swift.

- A compact what-if card on an upright phone with a steady height (#25, #28): header and nudge row, a one-line result
  that opens on tap, the three actions in one row of icon-and-short-word buttons; it folds to this form during a guided
  Lens replay as other cards do (read lensReplayCompact).
- Nudge rows (#27): the label on its own line above minus, readout, plus; the readout may shrink a little.
- The what-if steps aside for ball in hand and the stroke result line steps aside for the what-if (#29).
- The scrub bar's parting diamond draws above the playhead (#30); the what-if button keeps its slot reserved so the scrub
  bar never changes width (#31).
- The speed button shows a short "Auto" in every language (#12): its own catalog key ("Speed: Auto", comment "Short
  label on the speed button; one short word") while the menu row and VoiceOver keep the full word.

## Stream aim: aiming and Your shot

Files: App/AimOverlay.swift, App/ShotPanel.swift, App/AimGauges.swift, App/CueAngleControl.swift, App/OpeningHandover.swift,
App/Stroke/StanceViews.swift.

- #42 side-spin fork labels placed along the line, never on each other or the contact picture.
- #43 one bridge mark only (remove the old flat ring).
- #44 the stance card's room is reserved while Your shot is open, so the table stops sliding as the aim swings.
- #46 one groove at the hand-over (the first-minute picture: check it stays as calm).
- #47 the shot panel's button row: cue angle falls back to icon and degrees; Shoot keeps a full-width row at large text.
- #48 the fine controls never cover the table on a regular phone (inline below the panel as the folding phone does, or a
  short sheet whose top the framing knows).
- #49 slider names and readouts on one line where they fit, stacked otherwise.
- #51 the power pill never under the finger: on the far side of the ball from the pull, clamped between title row and
  controls.
- #52 ghost ball, target ring and miss ring never under about 10 points radius on screen; contact dot scaled to match.
- #53 the calm-zone label fits at large text (caret only at accessibility sizes, or wraps to the bar's width).
- #61 the aim read-out follows the player's number style.

## Stream menu: the main menu

Files: App/TitleScreen.swift.

- #54 turning the phone keeps whatever menu screen was open: move the menu's open/closed states (how to play, options,
  tables, play list, the pending replace question) out of view @State into one small observable object owned by
  TitleScreen.swift (a shared instance), so both layouts' TitleScreen read the same state.
- #55 the main menu's Play is its own catalog key, "Play a game", with a translator comment saying it means playing a
  game against the computer; the list header uses the same key. (The words pass writes its translations.)
- #57 menu entry names wrap to two lines instead of ending in an ellipsis.

## The words pass (after the merge, coordinator plus helpers)

- Add every new key from the streams to the catalog and translate it into the eleven languages.
- #62 plural forms for every count string (Russian one/few/many/other, Arabic all six, the rest as their grammar needs).
- #63 Russian units in Cyrillic everywhere (м/с, м/с², см), and a check in scripts/translation-check.py that flags Latin
  units in Cyrillic text.
- The Boss asked for one more adversarial pass: every short string (buttons, chips, tabs, menu entries, one-word labels,
  status titles) in every language checked for meaning in its place (a game, not a media player; a physics word, not a
  false friend), for length where it sits, and for consistency with the same word elsewhere. A second set of eyes tries
  to knock down each proposed change before it is applied.

## After the merge

One iPhone build, one Mac build, the app tests, the package tests, BreakProbe verify, the translation check. Then the
first minute on a fresh install, and a guided Lens replay of The Called Break on the iPhone 17 Pro simulator, by the
coordinator. CHANGELOG entry, push to main (TestFlight ships it).
