<!--
Author: Claude Opus 5.5 High
Date: 21-November-2026
PURPOSE: Every bug and loose end found by the code review of build 31 (version 0.6.6), in the order to fix them:
         what the Boss would hit first comes first, VoiceOver comes last. The work order for 0.6.7.
SRP/DRY check: Pass - follows plans/21-Nov-2026-award-gaps-order-plan.md (the batch that produced 0.6.6); each item
         names the files to change and points at the plan that first asked for the behaviour instead of repeating it.
-->
# Bugs and loose ends after 0.6.6

## In plain words

Build 31 put a lot of new work in at once, and none of it had been played before it shipped. A read of the whole code
afterwards found real bugs, mostly where the new pieces meet: the stroke, zooming, matches, lessons and the Lens. This
plan lists every one in the order the Boss would run into them playing the game the way it was recommended to him.

Targets: iPhone 17 Pro and later, iPad, and the Mac. Older phones do not matter. There are no playtests, slow-device
measurements or hands-on VoiceOver and controller sessions in this plan. VoiceOver work is last; controller work is
just before it.

How it ships: as last time. Builders split by file so no two touch the same file, write code only, and one build at the
end is compiled, tested and fixed. Then version 0.6.7 goes to TestFlight with one push.

## Part 1. The stroke and the first minute

1. **The first instruction is wrong on touch.** The hand-over card says "Drag to aim, pull back, let go", but on a phone
   letting go plays nothing; only a push forward through the cue ball does. The shot panel's hint under it says to tap
   Break, and How to play still teaches pull-then-tap. Fix: one instruction per input that matches the code ("Pull back
   from the white ball, then push through it" on touch; "pull back and let go" with a pointer), used in the hand-over,
   the hint and How to play. Hide the panel hint during the hand-over so one line teaches. Draw the groove faintly
   behind the cue ball before the first touch. Label the power bar's calm mark the first few times it shows. Add a
   Controls page to How to play (push, bridge finger, practice strokes, tap to aim, pinch, pan, double tap).
   Files: OpeningHandover.swift, ShotPanel.swift, TitleScreen.swift (How to play), AimGauges.swift.
2. **The pull-back has timing traps.** A forward push fires after a tiny backswing, lifting the finger keeps the power
   from the deepest point instead of where the finger is, the contact click plays even when the shot is refused, and
   with a pointer a forward release still fires although the code promises it is a change of mind. Fix: require a real
   backswing before a push can play; on lift without a push, set power from where the finger is; with a pointer, treat
   a forward release as a change of mind; click only after the shot is accepted; when a shot is refused, say why on the
   card. Files: Stroke/StrokeTracker.swift, Stroke/StrokeGesture.swift, PointerAim.swift.
3. **The first break is scolded, then buried.** The calm zone ends where the break range starts, so every break,
   even a tapped one, earns "Swinging hard: the tip landed left". The menu then lands on the last frame of the replay
   with Continue highlighted, not Learn. Fix: give the break its own calm zone part-way up the break range; end the
   first break with one short card (what the break did, "Learn the shots" prominent, "Keep playing" reopens Your
   shot) before the menu; for a player with no lesson passed, highlight Learn even when Continue is offered.
   Files: Stroke/StrokeModel.swift, OpeningHandover.swift, TitleScreen.swift.
4. **A touch stroke drifts silently.** Even inside the calm zone a finger that stays in the drawn groove turns the cue
   enough to miss a long pot, and nothing says so; keyboard and controller get no drift there at all. Fix: treat a
   stroke inside the groove as straight (take off the groove's half-width first); show the result line whenever the
   drift changed what happened (first ball, pot made or missed), in either zone; in the replay, draw the aimed line
   beside the struck line at the cue ball; offer the Straight stroke drill from that line.
   Files: Stroke/StrokeModel.swift, Stroke/StrokeWords.swift, Stroke/StrokeViews.swift, Captions.swift, LensLayer.swift.
5. **The bridge finger has nowhere sensible to go.** It only counts if it lands after the stroke finger, its mark sits
   on top of the groove, and a long bridge only ever costs (the plan promised a higher calm top). Fix: accept the
   bridge in either order (a touch joined by a second within a moment, or a resting finger while another reaches the
   cue ball, is the bridge, never an aim or a stroke); draw the mark beside the groove; give a long bridge the promised
   benefit or change the plan and the words; add a bridge slider to the fine controls.
   Files: Stroke/StrokeGesture.swift, Stroke/StrokeModel.swift, AimOverlay.swift, ShotPanel.swift.
6. **During the opening every visible button secretly skips it.** The skip layer sits on top of Continue and Menu, so
   both skip the whole intro, and the slow replay holds up to nine long beats. Fix: put the skip layer under the header
   and bottom controls; show "Tap to skip" on the phone; hold three or four beats on the first launch (the strike, the
   first hit, one skid-to-roll) so the opening and the player's own break each stay well inside a minute.
   Files: ShowpieceView.swift, OpeningHandover.swift, PacePlan.swift.

## Part 2. Touch and zoom on the table

7. **Zooming while aiming moves the aim or plays the shot.** Every touch starts as an aim the moment the finger lands,
   so the first finger of a pinch or pan swings the aim to itself, a touch during the replay skips to the end before
   the pinch is seen, and a double tap also snaps the aim to a ball. Fix: on touch-down save aim and power; if a
   second finger or a double tap follows, restore them and hand the touch to zoom; start the aim or stroke only once
   the finger has moved past the slop or stayed alone a moment; size the cue-ball grab circle from the ball's size on
   screen; let a pinch during the replay zoom without skipping it. Files: AimOverlay.swift, TableZoom.swift,
   Stroke/StrokeGesture.swift.
8. **Your shot hides the replay of your own shot.** Play, pause, scrub and replay live in a row that only shows while
   the shot panel is closed, and an ordinary shot never closes it. Fix: a slim playback row under the shot panel
   whenever one of the player's shots is on screen (or Replay beside Try again); after a break, reopen the shot panel
   when the balls stop. Files: PlaybackControls.swift, ShowpieceView.swift, ShotPanel.swift.

## Part 3. Free play and lessons

9. **"No rack: place the balls" lays out balls nobody can move.** The model can lift any ball (beginPlacingBall) but
   nothing calls it. Fix: in free play a touch on any object ball lifts it, and the cue ball's drag, red tint,
   legality check and Place it button put it down; the same with a pointer. Files: AimOverlay.swift, FreePlayViews.swift.
10. **Lessons 1 to 3 open with a pulsing card about a rest they never use.** Their lines put the bridge hand past the
    reach ladder's sitting reach, so the stance card says Rest. Fix: re-author stop, follow and draw (and curve and
    jump if needed) on lines a standing player reaches, re-run the lesson authoring and the content check. Separately,
    draw the 3D rest whenever the stance is Rest, in every mode. Files: Lessons/Lessons.swift, BreakProbe
    LessonAuthoring.swift, TableStage.swift.
11. **Lesson targets are finer than the controls that must hit them.** The tip bands are a few points wide on a small
    picture, snap-to-centre swallows part of the stop band, and the power range grew to 13 m/s on a straight pull, so
    the soft speeds every lesson uses get a sliver of the pull. Fix: curve the pull so soft and medium speeds get most of
    its length; enlarge the tip picture while a band is up, or snap a dot released inside a band to its middle; keep
    snap-to-centre out of any band; in steps not about power, let the pull play without moving power; give the pass
    shot's Try again a "Back to the lesson's stroke" choice. Files: AimGauges.swift, Stroke/StrokeGesture.swift,
    Lessons/LessonMode.swift, ShowpieceModel.swift.
12. **The Pencil's tilt overrides a lesson's locked cue angle.** Fix: put the lock on the model's cue angle like the
    other shot values; outside a lock let the Pencil change the angle only when tilted past a writing grip.
    Files: Stroke/StrokeGesture.swift, ShowpieceModel.swift.

## Part 4. Matches and the computer

13. **In eight-ball a stroke with no call silently does nothing.** Fix: if a stroke goes through with no call, play it
    with the suggested call and show that call on the ruling card; with no suggestion, refuse before the stroke starts
    and pulse the call card with "Call your shot first". Same for Return, the Mac menu and the controller.
    Files: Stroke/StrokeGesture.swift, ShowpieceModel.swift, Match/CallControl.swift, MacChrome.swift.
14. **Every break in a match replays the whole slow-motion opening and leaves the Lens on.** Fix: in a match a break
    plays at real speed in the ordinary view; keep the full opening for first launch, practice and Watch the intro;
    offer "Watch it in the Lens" on the ruling card; while a match shot plays, a "See the ruling" button so a paused
    replay never leaves the player waiting. Files: ShowpieceModel.swift, Match/MatchViews.swift.
15. **A match stops for a Continue tap after every shot, the computer's too.** Fix: routine rulings ("keep shooting",
    the computer's ordinary turns) settle by themselves after a short beat into a line in the turn banner; keep the
    card for fouls, choices, a hand-over on a shared device and the end of the game. Files: Match/MatchMode.swift,
    Match/MatchViews.swift.
16. **The computer's turn feels like a freeze, and the person's controls stay live on its ball.** Thinking starts only
    after the ruling card is dismissed, then it strikes instantly. Fix: start thinking as soon as its turn is known,
    while the card is up; grey out the person's shot controls on its turn; stage its stroke (aim line swings to its
    choice, cue draws back a beat, then strikes). Files: Match/MatchOpponent.swift, Match/MatchMode.swift,
    ShowpieceModel.swift, ShotPanel.swift.
17. **The easy computer plays like a cagey expert with a shaky hand.** All levels search the same way and the easy
    one, with the widest wobble, refuses most pots and plays safe. Fix: easy always shoots its best-looking pot, never
    plays a deliberate safety and ignores position; medium plays safe only when nothing reasonable is on; hard keeps
    today's search. Then tune the wobble until easy loses to a careful beginner. Files: Match/MatchOpponent.swift.
18. **One save slot, no way out, a muddled record.** A new match silently throws away the saved one, the Continue row
    never says which game, there is no way to end a match, the Mac's New Free Game deletes the match while Practice
    keeps it, and the win mark counts Player 1 and mixes in games against the computer. Fix: name the saved game on the
    Continue row; ask before replacing it; End match on the match card; New Free Game keeps the match like Practice;
    one game window on iPad as on the Mac; show records only for games against the computer, per level.
    Files: Match/MatchMode.swift, Match/MatchRecord.swift, TitleScreen.swift, MacChrome.swift, BreakdownApp.swift.
19. **The Mac menu bar only starts two-player games and says "Watch the Break".** Fix: the Game menu mirrors the Play
    list (Continue Match, each game for two players or against the computer at each level, bar billiards alone, Learn,
    the stroke drill, Watch the Intro). File: MacChrome.swift.

## Part 5. The three table games

20. **Bar billiards ends while its own banner says whites are left.** After time is up the game ends when the tray is
    empty, but the banner counts whites still on the bed and the rules page says play goes on. Fix: make code, banner,
    rules page and the time-up line say the same thing, with a test that has several whites on the bed. Give nine-ball's
    illegal break its own foul words and add the fouled break to the eight-ball rules page.
    Files: BreakdownRules/Tables/BarBilliardsRules.swift and tests, Match/MatchViews.swift, Match/TableGameWords.swift.
21. **The three tables are played with pool balls the words do not describe.** Bar billiards' "whites" are numbered
    pool balls, bumper pool's sides are solids against stripes and the "marked ball" has no mark, and the target badge
    says Solid or Stripe. Fix: each table gets its own ball set (plain whites and a red for bar billiards; white, yellow
    and red for five-pin; red and white with a spot on each marked ball for bumper pool), re-dressed when the table
    changes, with the badge and the match icons using the same set and each table's own words.
    Files: BallTextures.swift, TableScene.swift, TargetBallBadge.swift, Match/MatchViews.swift.

## Part 6. The physics the Lens shows

22. **The Lens is blank or wrong on the jump and the curve, its two best moments.** A ball in the air leaves no trail
    and no landing ring, nothing is captioned about the take-off, height or landing, a raised strike is captioned as
    "adds backspin" whatever it did, and the bend of a curve is never named. Fix: draw airborne segments as their own
    trail at the ball's height with a dot on the cloth under it and a landing ring; caption take-off, top of flight with
    its clearance, and landing from the recorded numbers; caption the bend (which way, how many degrees before it
    rolls); choose the strike's spin words from the recorded spin against the direction of travel, and for a raised
    strike state the cue's speed and angle. Files: LensLayer.swift, Captions.swift.
23. **The stance card promises strokes the game does not play.** "Cue raised over the 5" only makes the stroke wobblier:
    the solver still strikes level and the 3D cue passes through the ball; "Rest" draws no rest. Fix: work out the
    least angle that clears the nearest ball under the whole cue and use it for both the 3D cue and the strike's
    elevation, so a jacked-up stroke dips and swerves as on a real table; show the mechanical bridge model whenever the
    stance is Rest; stop the drawn pull-back short of the bridge; draw the bridge mark as a flat ring in the 3D scene.
    Files: Stroke/Reach.swift, ShowpieceModel.swift, CueRig.swift, TableStage.swift, AimOverlay.swift.
24. **The aim guide hides squirt and ignores throw.** With side spin the guide quietly bends to the real path, even with
    the guide off, and the 3D cue points elsewhere with no label; throw is never shown or captioned, so a soft cut aimed
    on the guide misses. Fix: draw the cue's line and the ball's line as a labelled fork when side spin turns the ball
    half a degree or more; with the guide off, draw only the cue's line; add a throw caption from the recorded event and
    mark the line of centres beside the real departure in the Lens; at full assist, draw the object-ball line from the
    solver's own impact so it includes throw. Files: AimOverlay.swift, AimGeometry.swift, Captions.swift, LensLayer.swift.
25. **A miscue's direction is a dice roll.** The same miscue played twice goes two ways, which breaks the "same shot,
    same result" promise. Fix: make the turn a function of the stroke (away from the side the tip slid off, growing with
    how far past the grip it was); re-run the content check. Files: BreakdownPhysics/Simulation.swift, the cue-strike
    tests.
26. **The rail takes most of the spin a ball brings in.** Draw, stun and roll come back within a few millimetres of each
    other and the order reverses at 1 m/s; the slow-ball "comes off steeper" effect passes by under a degree. Fix: add
    the rebound order and a minimum size for the steeper effect as bands in the sweep, sweep rail grip and the bed's
    friction too, and re-tune. If nothing passes, move to the coupled rail the spec described (cloth grips during the
    rail impulse). Make the rail caption say what the rail did to the spin. Files: BreakProbe RealWorldCases.swift and
    RealWorldSweep.swift, BreakdownPhysics/Parameters.swift and Impacts.swift, Captions.swift, then re-author.
27. **Surface numbers and words the tuning made untrue.** The notebook and cards show raw rail numbers that no longer
    mean what a ball keeps, and tournament cloth now reads "skids about 1 times as far". Fix: show rails as what a ball
    keeps at a stated pace, worked out with the solver's own rail routine; word a ratio that rounds to one as "the same as
    cloth"; re-tune tournament cloth slicker and livelier and dive-bar grabbier and deader than standard; re-check the
    four Behind the 8-Ball situations on those cloths. Files: NotebookInfo.swift, EightBall/EightBallViews.swift,
    Captions.swift, PlaySurface.swift.
28. **A skipped pocket looks like a drop, and a settled jam has no mark.** Fix: give the rim skip its own shape (a broken
    ring or a short arrow across the hole) and the settled jam its own mark, as the miscue has. File: LensLayer.swift.
29. **The jam guard now steps into an ordinary break.** On the new physics one ordinary test break chatters two balls
    hundreds of times and gets settled, and its caption says "0.0". Fix: run the jam and break sweeps on the default
    physics, find what pins the pair and fix that rather than the guard, save the jam fixtures, put that break back in
    the untouched-shots check, print the energy with a sensible unit. Files: BreakdownPhysics/Simulation.swift,
    JamGuardTests.swift, Captions.swift.

## Part 7. Behind the 8-Ball

30. **Five escapes are narrower than the aim control can set.** Their aim windows are a few hundredths of a degree while
    the aim steps in quarter degrees. Fix: re-lay those situations until every escape's aim window is at least half a
    degree and holds two aim steps; re-walk windows and ratings; make the escape authoring check fail any window
    narrower than the smallest aim step. Files: EightBall/EightBallSituations.swift, BreakProbe EightBallAuthoring.swift.

## Part 8. Mac and iPad pointer

31. **Pointer and Pencil hover keep rewriting the aim.** Moving the pointer to the Shoot button or the tip picture drags
    the aim with it. Fix: hover draws a faint preview line; a click or press-drag on the cloth sets the aim; a set aim
    never moves when the pointer leaves; the same for the Pencil; scroll turns by the camera's sign like the arrow keys;
    no release-to-shoot while a ball is lifted. File: PointerAim.swift.
32. **Zoom has no keyboard or menu route on the Mac.** Fix: Zoom In, Zoom Out and Actual Size in the View menu with the
    usual shortcuts, arrow keys pan while zoomed, and move Play and Pause off the bare space bar or take it only while
    the table has focus. Files: MacChrome.swift, TableZoom.swift.

## Part 9. Look and sound

33. **The moulded pocket sits inside the old one instead of replacing it.** The code-built wall, black floor and a metal
    band on the cloth are still there, and the other developer's better corner pocket never reached the app. Fix:
    export that pocket through the Blender export-and-verify route, make a matching side pocket, fit both to the
    solver's jaws and capture circles, take the band off the cloth and end the built wall where the liner begins; give
    bar billiards' holes their rings. Files: TableBuilder.swift, TableRoom.swift, Tools/blender, App/Models.
34. **The lit lamp hangs where no camera looks.** It fades out in every normal view and stays above the Ride frame.
    Fix: give the room one deliberate moment: open the intro low under the lamp with the shade at the top of the frame,
    then rise to the table. Files: ShotCamera.swift, TableCamera.swift, TableRoom.swift.
35. **The cue ball is plain ivory, so spin is invisible outside the Lens.** The other developer made a spotted cue ball.
    Fix: draw its marks onto the cue ball's picture (the ball already turns with its recorded spin) so draw, stun and
    follow show in the ordinary view. File: BallTextures.swift.
36. **The proudest moments make no sound.** Passing a lesson, making a trick shot or winning a medal gets a glow and a
    buzz but no sound. Fix: a made-it sound from SoundBoard timed to the glow, bigger for a gold medal and the sixth
    lesson. Files: SoundBoard.swift, FeelMapping.swift, Lessons/LessonViews.swift, TrickShotViews.swift,
    EightBall/EightBallViews.swift.

## Part 10. Release and store

37. **The Mac app has no icon and no way to ship.** Fix: one layered icon from the system's icon tool for iPhone, iPad
    and Mac with light, dark, clear and tinted looks, built round one idea that reads at the smallest size (for example
    the cue ball with its amber-to-cyan trail), no text; add a Mac archive-and-upload step to scripts/testflight.py so
    one push ships both; drop the unused file-access entitlement. Files: App/Assets.xcassets, scripts/testflight.py.
38. **The upload gate skips the app's tests and the translation check, and checks copied numbers.** Fix: add the app
    tests on one simulator and scripts/translation-check.py to the pre-upload checks; move the authored trick, lesson
    and escape answers into one package library both the app and BreakProbe read, so no copy can drift.
    Files: scripts/testflight.py, TrickShots.swift, Lessons/Lessons.swift, EightBall/EightBallSituations.swift, BreakProbe.
39. **The store page sells last week's game.** Fix: rewrite the listing in every language around what the game is now
    (the table that shows its physics, six lessons, real games against a friend or the computer, the stroke), correct
    the counts, drop "new" from Behind the 8-Ball, and change the menu's own intro line to match.
    Files: store/listing/*.json, TitleScreen.swift.
40. **Every store picture and the preview video show the old game.** Fix, after Parts 1 to 9: launch flags for the new
    scenes (a match with "Why that shot", a lesson at its key moment, a scored table game, the stroke drill, a Ride view
    showing the room), then re-shoot iPhone, iPad, Mac and both folding-phone sets and the video.
    Files: scripts/store-shots.sh, store/screenshots.
41. **The store record is missing what review asks for.** A privacy policy page and a support page on the studio site,
    the age-rating and privacy answers, availability, reviewer notes. Fix: publish both pages and fill in the record.

## Part 11. Controller, large text and translations

42. **Controller play stops after the first shot.** A break closes the shot panel and nothing on the controller reopens
    it, presses Continue, places ball in hand or makes a call. Fix: one button presses the main button of whatever card
    is up, another opens and closes Your shot, the d-pad moves ball in hand and steps the call, the menu button opens
    the menu; show the mapping in How to play. File: ControllerInput.swift.
43. **Large text cuts off the eight-ball call row.** Fix: use the cards' row-or-column helper there and let the turn
    banner wrap. Files: Match/CallControl.swift, Match/MatchViews.swift.
44. **French and Russian switch between formal and informal, Arabic has slips, the Lens tips say orange and blue.**
    Fix: one informal register per language, a register check in the translation script, the legend's colour words
    (amber, cyan, dashed, solid) in the tips. Files: Localizable.xcstrings, scripts/translation-check.py, LensCallouts.swift.
45. **The stroke drill counts non-touch shots as perfect.** Fix: say on the card that the drill measures a finger
    stroke and leave non-touch shots out of the record; add an Options switch to shoot with the button only.
    Files: Stroke/StrokeDrill.swift, GameSettings.swift.

## Part 12. VoiceOver (last)

46. Lessons cannot be followed without sight: speak the tip as an amount and whether each control is inside its band,
    announce the idea and the verdict, write voice versions of the step lines.
47. Announcements talk over each other: one queue for everything spoken, one ruling sentence, the stance folded into
    the end-of-shot summary.
48. Step through the shot disappears while aiming: add it to the Aim element's actions.
49. The three new tables speak like a pool table: their own ball names, cups, holes, pegs and pins as elements.
50. The spoken aim, the target badge and Aim to pot ignore the side-spin push: one shared helper for what the guide shows.
51. The first-minute line speaks only to touch: choose it by the input in use and announce it.

## Part 13. What the first version of this plan dropped (added 21-Nov-2026, Claude Opus 5.5 High)

The review had seven readers. Checking all their findings against Parts 1 to 12 found these left out:

52. **Later launches open on a still table, and the menu never names the next step.** The planned silent replay of the
    opening behind the dimmed menu was never built, and the highlighted entry only ever says Learn or Play. Fix: on
    later launches play the opening's slow Lens replay behind the dimmed menu on its own clock with no table sounds (the
    music plays), and highlight the next step from stored progress ("Next: Lesson 2, Follow", then that lesson's trick
    shot, then a match against the easy computer). Files: TitleScreen.swift, ShowpieceModel.swift.
53. **Two teaching aids misfire.** The Lens tips first appear over a finished break whose trails have faded, or on a
    lesson's key moment on top of the lesson's own card; See the contact is an unlabelled crosshair sharing its symbol
    with two other controls and, pressed, stops the replay with nothing saying what to look at. Fix: show the tips on
    the first guided hold of a Lens replay the player started, hold the beat while they show, keep other cards back;
    give See the contact its words where there is room, its own symbol, and an on-screen line on arrival ("Stopped at
    the first hit. The faint ball is your last try.", the second sentence only when a last try exists).
    Files: LensCallouts.swift, RetryWords.swift, ShotPanel.swift.
54. **The uploaded folding-phone store pictures state physics the game no longer does.** "Then take it to a real
    table" gives an aim, speed, tip and cloth numbers from before the retune. Replace that set first, before the rest
    of item 40.
55. **The opening shows no maths.** Its first held beat is a footnote about off-centre hits (the opening break is struck
    slightly low), and every equation is hidden unless Show the maths is on. Fix: hold the headline moments (the cue
    ball handing its speed to the rack, skid turning into roll) and show their equations with the event's own numbers
    on those beats even with Show the maths off; strike the opening break at centre height. Correct the spec's status
    note, which calls the Lens section finished and does not list the what-if fork as missing.
    Files: PacePlan.swift, CaptionViews.swift, Rack.swift (with a re-check of the opening), docs spec.
56. **The look was never seen, and four pieces are likely wrong by reading the code.** Fix in code: give the hand-built
    meshes tangent data so the close-up cloth relief can show; switch ball pictures per ball by its own size on screen
    instead of all sixteen at once; check which way the reflection picture maps and lay the lamp's window along the
    table; light the far wall so the low Ride view is not a void. Add the look to 0.6.6's not-checked line in the
    changelog. Files: TableMeshes.swift, TableDetail.swift, TableBuilder.swift, TableRoom.swift, CHANGELOG.md.
57. **The cues and rest never reached the game, although the Boss decided they should** (cues only ever added, the
    game picks the cue for the shot and says clearly that it did). Fix: export the other developer's cues and the
    swan-neck rest through the Blender export-and-verify route; list them in the cue profiles with their weights; pick
    the cue per shot (jump cue for a jump, massé cue for a steep massé, break cue for a break, house cue otherwise) and
    name the pick on the stance card; the rest model is the one drawn when the stance is Rest. Power stays swing speed,
    so a heavier cue sends the ball faster at the same swing. Files: Stroke/CueProfile.swift, Stroke/StanceViews.swift,
    CueRig.swift, App/Models.
58. **Zoom has no screen-reader route** (VoiceOver, so last): "Zoom in on the cue ball" and "Zoom out" actions on the
    table element. File: TableAccessLayer.swift.

The other table games' rules stay as built until the Boss says otherwise (the decision below), so nothing waits on it.

## How 0.7.0 is built (added 21-Nov-2026)

The Boss asked for version 0.7.0: everything added in 0.6.6 plus every fix above. The plan is ordered by what the Boss
hits first; the work is cut by file, so each file has exactly one builder.

1. A short foundation step writes docs/v07-contracts.md and the small shared types every seam needs: how a touch is
   handed between aim, stroke, bridge and zoom; the shot-refusal reason the card shows; routine versus card-worthy
   rulings; each table's ball set; the cue pick; and every new model call the views will use, with its exact name.
2. Builders run in parallel, each in its own worktree and branch, code only, no compiling, owning these files:
   - physics: the solver, BreakProbe, package tests, PlaySurface.swift, Stroke/Reach.swift and the authored shots
     (TrickShots.swift, Lessons/Lessons.swift, EightBall/EightBallSituations.swift). Items 10 (lines), 23 (the clearing
     angle), 25, 26, 27 (cloth tuning), 29, 30, 38 (one shared library), 55 (opening strike). This one builder may run
     the package tests and BreakProbe, because tuning and re-authoring need them: physics changes first, then every
     authored shot re-authored and the content check passing.
   - touch: StrokeTracker, StrokeGesture, AimOverlay, TableZoom. Items 2, 5, 7, 9, 11 (pull), 12, 13 (refuse before the
     stroke), 23 (the drawn pull-back), 32 (pan keys).
   - gauges and pointer: AimGauges, PointerAim, AimGeometry. Items 1 (calm mark), 11 (tip picture), 24, 31, 50.
   - stroke model: StrokeModel, StrokeWords, StrokeViews, StrokeDrill, GameSettings. Items 3, 4, 5 (long bridge), 45.
   - model: ShowpieceModel, ShotAttempt, PacePlan. Items 6, 8, 11 (pass shot), 12, 13, 14, 16, 23 (strike), 40 (launch
     flags), 52, 55 (beats).
   - match: Match/*, the bar billiards rules and tests, BreakdownApp.swift. Items 13 (call card), 14, 15, 16, 17, 18,
     20, 21 (words and icons), 43.
   - menu: OpeningHandover, TitleScreen, ShowpieceView, PlaybackControls, ShotPanel, MacChrome, FreePlayViews,
     RetryWords, NotebookPanel. Items 1, 3, 6, 8, 9 (Place it), 16 (grey out), 18, 19, 32 (menus), 39 (menu line),
     52, 53 (See the contact).
   - lens: LensLayer, Captions, LensCallouts, CaptionViews, NotebookInfo, EightBallViews, LensTextures. Items 4, 22,
     24, 26 (caption), 27 (words), 28, 29 (caption), 44 (tip words), 53 (tips), 55 (equations).
   - look: BallTextures, TableScene, TargetBallBadge, TableBuilder, TableRoom, TableMeshes, TableDetail, ShotCamera,
     TableCamera, TableStage, SurfaceTextures, the pocket in Tools/blender and App/Models. Items 21, 23 (bridge ring),
     33, 34, 35, 56.
   - equipment: CueProfile, StanceViews, CueRig, the cues and rest in App/Models. Items 10 and 23 (the rest), 23 (the
     3D cue's angle), 57.
   - sound and lessons: SoundBoard, FeelMapping, Haptics, LessonMode, LessonViews, TrickShotMode, TrickShotViews.
     Items 11 (lesson side), 36.
   - access and controller: ControllerInput, TableAccessLayer, TableWords, VoiceSynth, the translation check, and the
     existing translations in the string catalog. Items 42, 44 (register), 46 to 51, 58.
   - release: scripts/testflight.py, the entitlements, store/listing, the icon, scripts/store-shots.sh, the spec's
     status note. Items 37, 38 (upload gate), 39, 40 (scene list), 54.
3. The coordinator merges every branch, merges the new strings, compiles once (iPhone, Mac, package tests, app tests),
   fixes what breaks, runs the content check, writes the 0.7.0 changelog and pushes to main, which ships to TestFlight.
4. Then the store: the support and privacy pages, the store record, and every picture and the video re-shot.

## Decision for the Boss

The rule sheets for bumper pool, five-pin and bar billiards were built without your yes. Three questions: may a
bumper-pool player choose which of their own balls to strike (today it is a fixed order); how long should a five-pin
game run (first to 60 today); and should bar billiards offer a longer or untimed clock beside today's fifteen minutes.

## Not in this plan

Playtests with newcomers, slow-device measurements, a real-table measuring session, and hands-on VoiceOver or
controller sessions. Ideas held for later rather than bugs: a "what-if" fork in the Lens (nudge a shot and see the
other future), a daily challenge, the other developer's cues and rests with an automatic cue pick, and a computer
opponent for the three table games.
