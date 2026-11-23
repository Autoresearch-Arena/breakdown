<!--
Author: Claude Opus 5.5 High
Date: 23-November-2026
Edited: Claude Opus 5.5 Medium, 23-November-2026 (independent critic: every claim checked against the 0.7.6 code. Fixed
         the calm gate, which blocked the end note forever because a finished Lens replay stays "guided"; the toast's
         timer and VoiceOver line moved from the view into the book, so a layout change cannot restart or repeat them;
         the replay now also puts back the shot's surface, ball in hand after a scratch and a cleared table's Rack again;
         the strike direction is written back unnormalised so a kept shot solves to the same motion; the test-launch
         gate covers every scripted strike flag; the date follows the game's number locale; list drawings are solved
         lazily off the main thread; "new" dots survive the visit that clears them; jaw and rattle checks keep to one
         pocket; "Combination", "Carom" and "%lld/%lld" are already translated; new lines say "cue ball" as the game
         does; the book tests keep the model alive and skip the progress sweep; the coordinator's simulator walk-through
         is cut to the fresh-install first minute; each touched shared file gets its "Edited:" header line.)
PURPOSE: Build plan for Breakdown 0.7.7's Achievements: a list of physically interesting things the player has done
         (a dead stop, a draw, a massé, a jump over a ball, a rattle, a bank, a kick, a combination, a carom, a big
         break, running a rack, beating the computer, every lesson and trick shot, every table and surface), each with a
         name, one plain sentence, an icon, the date it was earned and, once earned, the player's own shot replayed in
         the Lens. Written for one developer working blind in their own worktree (no compiling; the coordinator compiles
         once after the merge): it names every new file, type and function, every small hook in a shared file, the tests,
         and the words to translate. Replaces the spec's "Physics Journal" idea, which the Boss asked to be an
         achievements list.
SRP/DRY check: Pass - checked plans/ (no earlier achievements or journal plan; the spec's Physics Journal is unbuilt) and
         the code that already reads remarkable shots (App/ShotHighlightJudge.swift's ShotMoments and detect, reused,
         never copied), replays a kept shot (ShowpieceModel's showKeptRecording and watchBestShot, followed), draws a
         shot small (App/TrickPathThumb.swift's TrickPath.traced, reused), and stores progress (TrickShotMode and
         LessonMode done lists, EightBallMode medals, App/Match/MatchRecord.swift, all read, none changed).
-->
# 0.7.7: Achievements

## In plain words

The Boss liked the "physics journal" idea but wants it to be an achievements list. This plan builds that.

What the player sees. A new entry in the main menu, Achievements, with a small count beside it (how many are earned;
its little symbol changes while some are new since the list was last opened). It opens a list in five groups: Shots, Games, Lessons, Trick shots and
Behind the 8-Ball. Every achievement is always listed, earned or not. An earned one shows its icon lit, its name, one
plain sentence about the physics, the date, and a small drawing of the player's own shot that earned it (the path the
cue ball took, coloured the way the Lens colours sliding and rolling). An unearned one shows its name dimmed with a short
hint on how to earn it, and, where it is a collection (every lesson, every surface), how far along the player is.

Tapping an earned one opens it: a bigger drawing of the shot, the sentence, the date, and "Watch it in the Lens". That
button takes the player to the table and surface the shot was played on and replays their own shot slowly under the Physics Lens,
stopping on the moments that made it special, exactly the way a trick shot's answer is explained. When it ends, a small
note says "That was your bank shot" with a button back to the list; the balls stay where that shot left them, ready to
play on.

How they are earned. Nobody has to tell the game. Every shot the player strikes, in any mode, is read from its own
recording, the same reading that already finds remarkable shots for "Watch your best shot". Collections (lessons, trick
shots, wins against the computer, tables, surfaces) are read from the progress the game already keeps. Shots the game
plays for the player (a trick's or lesson's answer, a hint, the computer's turn) never count.

How it feels. When one is earned, a small note appears only after the balls have stopped: an icon, "Achievement
earned" and its name. No sound, no vibration, no pop-up to close; it fades by itself after a few seconds and never
covers the middle of the table. Nothing appears during the first-launch opening; anything earned there waits quietly
in the list, not even marked new, so the first menu a new player sees carries no "new" sign.

What is decided here, not asked. Achievements are kept on the device only in this version. Reporting them to Game Center
would need new signing settings, store setup and per-achievement art in twelve languages, and its sign-in banner at
launch would break the calm first minute; every achievement gets a permanent name now, so Game Center can be added later
without changing anything the player has earned.

## What exists today (read in the code, 0.7.6)

- The project: App/ and BreakdownTests/ are file-system synchronised folders in Breakdown.xcodeproj (the only
  exceptions are two README files). A new Swift file anywhere under App/ (sub-folders included, as App/Match/ and
  App/Lessons/ already are) is in the app target, and one under BreakdownTests/ is in the test target. The project file
  needs no edit for this feature. There is no entitlements file and no entitlements build setting, which is part of why
  Game Center waits.
- Reading a shot: App/ShotHighlightJudge.swift. ShotMoments holds every event finder (first contact, rails before it,
  take-off and landing, the bank's cushion, pockets, rim skips, pins, posts, secondContact for a carom's second ball).
  ShotHighlightJudge.detect(timeline:facts:captions:table:isBreak:) returns every remarkable moment of a shot (jump,
  curve, thrown in, combination, kick, bank, two at once, drawn back, stopped dead, too fast for the pocket, bumper cup,
  red pin alone), each with up to two captioned "signature" events a guided Lens replay holds on. For a break it
  returns only a breakShot moment. App/ShotHighlight.swift has HighlightKind; App/HighlightWords.swift has each kind's
  title and one-sentence physics line, already translated.
- Where a shot lands: ShowpieceModel.finishStrike (App/ShowpieceModel.swift) loads the solved recording, records the
  ShotAttempt (start, settings, timeline, surface, table, physics generation, input) and, last, calls
  judgeHighlight(tl, isBreak:). judgeHighlight bails in trick shots, lessons, situations, the drill and the opening;
  achievements must not (the Boss wants them in any mode), so they get their own call beside it.
- Who struck: strike() is the one door for every stroke. The computer's stroke comes through strikeStaged with
  MatchMode.computerActing set true around breakNow/shootNow. A trick's Watch it, a lesson's Watch and a Behind the
  8-Ball hint set their mode's phase to .watching and then call shootNow (authored modes solve synchronously). The
  showpiece and the menu backdrop never go through strike. Free play and matches solve on a background task, so the
  stroke's owner must be captured in strike(), not read in finishStrike.
- Replaying a kept shot: watchBestShot puts a kept ShotAttempt on screen with showKeptRecording (private; writes back
  the input, table, surface and generation it was solved from, then load), sets the signature (setPaceSignature) and
  calls replay(withLens: true). watchHighlight holds Ride for a guided replay with holdRideForGuidedReplay.
  watchBreak is the template for a route into play from the menu (closes lists, ends modes, leaves a match saved,
  closes the menu).
- Saving: everything is UserDefaults. TrickShotMode keeps "trickShotsDone" (doneIDs), LessonMode "lessonsDone"
  (doneIDs, passedCount), EightBallMode "eightBallMedals" (medals), App/Match/MatchRecord.swift a Codable record of
  games against the computer per game and level with a lenient decoder and load(from:)/save(to:) that take a
  UserDefaults (the pattern to copy). MatchMode.sittingGames counts games finished this sitting. Nothing stores which
  surfaces or tables have been played.
- Recordings are not Codable (Timeline, ShotInput, CueStrike and PoolParameters are not; only Vec2 is). A shot can only
  be kept as its recipe and solved again. ShowpieceModel.solverCopy(_:table:surface:generation:) is the pure,
  nonisolated way to build the solver's copy; ShotAttempt.motionHash fingerprints a recording.
- Drawing a shot small: App/TrickPathThumb.swift. TrickPath.traced(_:start:) turns any recording into the trick list's
  little table drawing (TrickPathThumb), sliding magenta, rolling cyan, in the air dashed white. It follows ball 0 as
  the striker.
- The menu and its pages: App/TitleScreen.swift mainList builds MenuRow entries, with a Mark ("3/6") on Learn, Trick
  shots and Behind the 8-Ball. How to play, Options and Tables are NotebookPage cases (App/NotebookPanel.swift) shown
  by three exhaustive switches: TitleScreen.menuSheet, ShowpieceView.pageSheet and NotebookPanel.content. On the
  notebook (open Duo, iPad, Mac) they are pages of the panel; on phones a sheet. While the menu or a page from it is up,
  GameControllerInput leaves the table alone and the system's controller focus drives the page.
- Words on screen: the upright phone uses Blurb (App/Phone/Blurb.swift), small and sized to its text, never a card; the
  docked blurbs sit under the title row in ShowpieceView.phoneDock, whose measured bottom moves the camera's table area.
  The sideways phone's column and the notebook use cards (glassCard). ShotNarration.announce (App/TableAccessLayer.swift)
  speaks a line to VoiceOver.
- Words in twelve languages: new player text goes through String(localized:) or view literals; translations reach
  App/Localizable.xcstrings through scripts/localization-merge.py from a file in localization/pending/.
- Numbers and dates follow the game's language, not only the phone's region: App/NumberStyle.swift's
  AppLocale.numbers is the locale every number on screen is written in. The menu's existing marks interpolate small
  integers straight into String(localized:) ("%lld/%lld", "%lld of %lld"), which this feature copies.
- Who already creates what. ShowpieceView's body reads model.trickMode, model.lessonMode, model.eightBallMode and
  model.whatIf on the first render (phoneChrome's animations, PhoneStrip's arguments, the bottom bar), so all four are
  built at launch already and their inits only read UserDefaults. Reading them from the book creates nothing new; the
  model-side reads in H6 still go through the private optional storage, since they run inside strike() and every frame.
- Test launches that strike without a mode phase or computerActing: StoreScene.requested and the flags -retryCases,
  -retryDemo, -yourBreakDemo, -yourShotDemo, -aimDemo, -aimDemoRack, -rackShoot, -aimScript, -jumpDemo, -rideDemo,
  -eightPlay and -eightJudgeCheck (ShowpieceView.onAppear, EightBallMode.playAsTry and the model's scripted scenes).
  -rackShoot exists for the store video, so an achievement note must never appear under these.
- A finished guided Lens replay stays "guided": guided is true whenever chosenRate is nil, the Lens is on and the pace
  plan has beats, paused or ended alike. Only aimReady (clock at the end) and holding tell whether it is still playing.
- The Table cleared card (tableCleared) needs shotsThisRack > 0, and chimeTableClearedIfDue plays its chime once per
  rack; startHighlightRack re-arms it. A loaded recording whose cue ball dropped is put on the head spot by
  adoptLayout; finishStrike then sets ball in hand (ballInHand = .anywhere, placementDue = true) when object balls are
  left.
- Two other 0.7.7 plans also keep a shot as a Codable recipe: the clips plan's ClipShotRecord
  (App/Clips/ClipShotRecord.swift) and make-it-again's OwnShot. Each solves through ShowpieceModel.solverCopy the same
  way. This plan keeps its own AchievementShot (it also needs the struck settings and the signature); see Risks.

## The catalogue

Forty-odd achievements in five groups with today's content (the seventeen shots below, five games, one per lesson
and their capstone, one per playable trick shot and theirs, one for Behind the 8-Ball). Every count on screen is read
from the catalogue, never written in (nor in code or tests), so a trick shot or lesson added later brings its own
achievement. Each has a permanent id (lowercase, dashes; a future Game Center id is "breakdown." plus
it), an SF Symbol, a name, one sentence and a hint. Names are generic physics and shot names only.

Shots (from the recording of any shot the player strikes, any mode, any table):

| id | name | earned when | from |
|---|---|---|---|
| dead-stop | Dead stop | detect returns stopDead | existing |
| draw-back | Draw back | detect returns drawBack | existing |
| masse-curve | Massé curve | detect returns curve | existing |
| jump-clear | Over the top | detect returns jump and the cue ball passed over another ball in the air | new check |
| thrown-in | Thrown in | detect returns throwIn | existing |
| combination | Combination | detect returns combination | existing |
| kick | Kick shot | detect returns kick | existing |
| bank | Bank shot | detect returns bank | existing |
| carom | Carom | the struck ball met one ball, then a different one, and that second ball dropped | new check |
| two-at-once | Two at once | detect returns multiPot | existing |
| jaw-in | In off the jaw | a ball touched a pocket's jaw or point after its last ball contact and still dropped in that same pocket | new check |
| rattle-out | Rattled out | a ball touched one pocket's jaws or point twice or more after its last ball contact and stayed up | new check |
| too-fast | Too fast to drop | detect returns rimSkip | existing |
| big-break | Big break | a break on the pool table sent three or more object balls down | new check |
| run-rack | Run the rack | free play, pool table: a break that dropped a ball without a scratch, then every shot dropped one without a scratch, until no object ball was left | new tracker |
| bumper-cup | Off a bumper | detect returns bumperCup | existing |
| red-pin | The red pin alone | detect returns redPinAlone | existing |

Games: beat-easy, beat-medium, beat-hard (won at least one game against the computer at that level, any game, from
MatchRecord's per-level tally); every-table (a shot struck on each TableKind); every-surface (a shot struck on each
PlaySurface, the Moon included).

Lessons: lesson-<lesson id> for each of Lessons.all (named with the lesson's own title), and every-lesson.

Trick shots: trick-<trick id> for each TrickShots.all entry that is not pending (named with the trick's own title), and
every-trick (every playable one).

Behind the 8-Ball: every-escape (a medal on every EightBallSituations.all spot).

Symbols (all present in SF Symbols on iOS 26): dead-stop "stop.circle", draw-back "arrow.uturn.backward.circle",
masse-curve "point.topleft.down.curvedto.point.bottomright.up", jump-clear "arrow.up.and.down.circle", thrown-in "wind",
combination "link.circle", kick "arrow.turn.up.right", bank "arrow.triangle.swap", carom "arrow.triangle.branch",
two-at-once "circle.grid.2x1.fill", jaw-in "smallcircle.filled.circle", rattle-out "circle.dotted", too-fast
"hare", big-break "burst", run-rack "checkmark.seal", bumper-cup "circle.circle", red-pin "pin", beat-* "person.2",
every-table "square.grid.2x2", every-surface "square.stack.3d.up", lesson-* and every-lesson "graduationcap",
trick-* and every-trick "wand.and.sparkles", every-escape "8.circle.fill". If a name draws blank on the coordinator's
first run, swap it for "star.circle"; the id never changes.

## The design

### Earning, the same on every device

- Only the player's own strokes count: not the computer's, not a mode's demonstration, not a store or test launch.
- A shot can earn several at once (a bank that also throws); each is earned once, forever, with its first shot kept.
- Collections are checked whenever the progress they read changes; the shot on screen is kept as their replay when it
  is the player's own and is what finished the collection (the lesson's passing shot, the trick's make, the winning
  shot of a game the player potted out). Otherwise the collection has no single shot, and its page shows its progress
  picture instead (below).
- On the first launch of 0.7.7 a returning player's existing progress (lessons, tricks, medals, wins) is earned at once,
  quietly, with no notes on screen, dated that day and marked new.
- During the first-launch opening (until the opening hands over) anything earned is kept quietly, already marked seen,
  with no note on screen, so the first menu shows no "new" sign. The first minute stays exactly as it is.
- Nothing is earned or saved under a test launch (the store scenes and every scripted-strike flag listed above).

### The note when one is earned (the "toast")

- Waits until the balls are at rest and the clock is at the shot's end (aimReady, which also means no replay is
  playing), no beat is being held, nothing is being placed, no what-if is showing, the computer is not lining up, the
  menu is closed and the opening is over. Not "not guided": a finished Lens replay stays guided until something else
  loads, so that test would hold the note back for good. Then shows one at a time, for four seconds of calm each, and
  fades. Never a button; nothing to dismiss; no sound; no haptic.
- The book, not the view, owns the timing: it counts the four seconds in its per-frame step (only while the gate
  holds, so a replay or the menu pauses the count) and speaks the line once when a note first shows. The view only
  draws what the book says is showing, so turning the phone or folding the Duo neither restarts nor repeats a note.
- Content: the achievement's symbol in the accent colour, a small caption "Achievement earned", and the name.
  VoiceOver hears "Achievement earned: Bank shot" once, through ShotNarration.announce.
- Reduce Motion: a plain fade (Blurb.transition is already a fade with a slight scale; use .opacity alone then).
- After an achievement replay ends, the same place shows the end note instead: "That was your Bank shot." with one small
  button, "Achievements", which opens the menu on the list. It goes when anything else is loaded or struck. VoiceOver
  hears its sentence once when it appears.

### Phone upright

- The note is a Blurb sized to its words (never a card), trailing-aligned, directly under the docked blurbs. It sits in
  phoneChrome after the dock, not inside it, so the dock's measured bottom does not change and the camera never reframes
  when a note comes or goes. It covers at most the far rail's corner, never the centre. Ride's map sits bottom-left and
  is unaffected.
- The Achievements list and an achievement's page open as the page sheet the menu already uses for Tables.

### Phone sideways (side column)

- The note is the first card in the column's card stack (a slim glassCard with the symbol, caption and name).
- The list and page open as the same page sheet.

### Open Duo, iPad and Mac (the notebook)

- The note is the first card in NotebookPanel.cards, on the panel's half. Nothing is drawn over the table half.
- The list and an achievement's page are a notebook page (a new NotebookPage case), like Tables, on the panel's half.
- With the notebook put away (Mac or iPad, table only), the note is the first card of the stage's own card stack.

### The list page (AchievementList)

- A NavigationStack with a List, sections in the order Shots, Games, Lessons, Trick shots, Behind the 8-Ball. Toolbar:
  Close. Footer: one sentence, "Every shot you play is read for these, in any mode."
- Row, earned: the symbol (accent colour), the name (heading), the sentence (one line, folding), and on the trailing
  side the shot's drawing (TrickPathThumb, 64 points wide) when the achievement kept a shot, else the progress picture.
  A small dot beside the name while it is new. The drawing is solved lazily off the main thread when the list first
  opens (the TrickPathCache pattern) and fills in as it arrives; a row keeps its room meanwhile.
- Row, not earned: the symbol and name dimmed, the hint, and for collections "4 of 6" with the progress picture.
- Opening the list sweeps the collections once (so a game won just before the menu opened is counted) and marks
  everything as seen, so the menu's mark loses its "new" state. The ids that were new are captured first, so their dots
  still show for this visit and go on the next.
- Earned rows are buttons that push the achievement's page; unearned rows are plain, readable rows (not disabled
  buttons, so VoiceOver reads them as text).

### An achievement's page (AchievementDetail)

- Large drawing of the kept shot (TrickPathThumb, full width, the table's own aspect), name, sentence, "Earned 12 Nov
  2026" (date formatted in AppLocale.numbers, the game's number locale), and the main button "Watch it in the Lens".
- If the shot, solved again, no longer matches what was recorded (the physics changed in a later version), one line
  under the button: "Played again with today's physics, so it may not end the same way." The replay still plays.
- A collection without a kept shot shows its progress picture large: a grid of the items (lesson titles, trick titles,
  table and surface names with their own symbols, the three levels), each ticked or empty. No button; in its place
  the line "No single shot to replay for this one."
- The large drawing reads book.drawings[id] like a row does, and calls book.startDrawings() on appear if it is
  missing (a page opened straight from the end note's list before the rows' solves finished).
- "Watch it in the Lens": solve first (a small progress spinner on the button while it solves, off the main thread),
  then close the page (onClose, which sets the page to nil) and only then call the model's watchAchievementShot. The
  order matters: in the notebook the panel shows a set page whatever the menu is doing, so a page left set would hide
  the replay's words and controls. This is a route into play like Watch the intro: the
  menu closes, a trick shot, lesson, situation or the drill is left, a match is left saved (Continue match brings it
  back), the table and surface the shot was played on become the chosen table and surface (stored, as the Tables list
  and Surface menu store them), and the shot replays slowly in the Lens, holding its signature moments. Ride is held for
  the replay and comes back after, as for Watch it in the Lens on a free-play shot. Afterwards the table is ready to play
  on: a scratched cue ball is in hand, and a shot that cleared the table shows Table cleared with Rack again (no chime:
  the chime is for clearing a rack, not for watching one).

### VoiceOver, controller, one finger

- Every row is one combined element: "Bank shot. Earned 12 November 2026. The ball left the cushion at its mirror
  angle, into the pocket." or "Kick shot. Not earned yet. Send the cue ball off a cushion first, then into a ball." The
  drawings are hidden from VoiceOver (TrickPathThumb already is). The menu row's mark speaks "12 of 44 earned, 3 new".
- Controller: the list and page are reached only from the menu, and the menu stays open behind them exactly as it does
  behind Tables and Options (the end note's button opens the menu first, too), so GameControllerInput's existing gate
  (menu open: leave the table alone) already gives the system's controller focus the page; no new case is needed there; the List rows and the page's button are standard focusable buttons. The end note's
  "Achievements" button is a side offer, not a card's main button: A keeps its table meaning, and the Menu button opens
  the menu, where Achievements is a row. GameControllerInput (App/ControllerInput.swift) is not changed.
- One finger: everything is a tap. No gestures.

## Build steps

New folder App/Achievements/. Every new file gets the standard header (Author: Claude Opus 5.5 High or the builder's
own model and effort, Date, PURPOSE, SRP/DRY check). All new types are @MainActor where they touch the model; the pure
parts are nonisolated value types so the tests can call them anywhere.

### New files

1. App/Achievements/Achievement.swift, the catalogue.
   - enum AchievementGroup: String, CaseIterable { shots, games, lessons, tricks, escapes }, with a translated `title`
     ("Shots", "Games", "Lessons", "Trick shots", "Behind the 8-Ball").
   - enum AchievementProgressKind { none, lessons, tricks, escapes, levels, tables, surfaces } (what picture a
     collection draws).
   - struct Achievement: Identifiable, Equatable { id: String, group, symbol: String, progress: AchievementProgressKind }
     plus computed `name`, `sentence`, `hint` read from AchievementWords (below), so the catalogue holds no words.
   - enum Achievements { static var all: [Achievement] } built in group order: the seventeen shot ids in the table's
     order, the five games ids, one per Lessons.all lesson then every-lesson, one per playable TrickShots.all shot then
     every-trick, then every-escape. static func achievement(id:) -> Achievement?. Ids are built from content ids
     ("lesson-" + lesson.id, "trick-" + shot.id) and never from titles.

2. App/Achievements/AchievementWords.swift, every word (the HighlightWords pattern).
   - static func name(_ a: Achievement) -> String, sentence(_:), hint(_:). Shot achievements that map to a HighlightKind
     reuse HighlightWords.line(kind) for the sentence (already translated; do not write new sentences for them), with
     one exception: jump-clear uses its own new sentence ("The cue ball left the cloth and flew over a ball in its
     way."), because it is narrower than any jump. Carom, jaw-in, rattle-out, big-break and run-rack have no
     HighlightKind and use their new sentences. Lesson and
     trick achievements use the lesson's or trick's own title as the name and one shared sentence and hint each, with
     no placeholder needed. All other words are listed under Words to translate. Every line through
     String(localized:), with a translator comment where the word is ambiguous ("Kick shot: a pool shot where the cue
     ball hits a cushion before any ball").
   - Formatted lines: earnedOn(_ date: Date) -> "Earned \(day)" where day is
     date.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted).locale(AppLocale.numbers)) (the game's number
     locale, App/NumberStyle.swift; never the bare .formatted default); progress(done:total:) -> "\(done) of \(total)"
     (the existing "%lld of %lld" key); menuMark(earned:total:) "\(earned)/\(total)" (the existing "%lld/%lld" key, as
     trickMark builds it); menuSpoken(earned:total:new:) ("%lld of %lld earned, %lld new", or "%lld of %lld earned" when
     new is zero); toastSpoken(name:) "Achievement earned: \(name)"; replayEnded(name:) "That was your \(name)."
   - static func menuSymbol(new: Int) -> String: "checkmark.circle.fill" when nothing is new, "sparkles" while
     something is (MenuRow.Mark has only a symbol, a short text and a spoken text; the eye sees the new state as the
     symbol change, VoiceOver hears the count).

3. App/Achievements/AchievementShot.swift, the kept shot (the recipe) and solving it again.
   - struct AchievementShot: Codable, Equatable, Sendable. Fields: isBreak, breakSeed (UInt64), start ([Vec2]),
     direction (Vec2), speed, tipUp, tipSide, elevation (Double), ballIndex (Int), seed (UInt64), parametersVersion
     (Int, the input's own parameters.version: 1 for racks and breaks, 2 otherwise), surface and table (their raw value
     Strings), generation (Int), the attempt's aim, power, powerLow, powerHigh, settingTipUp, settingTipSide,
     settingElevation (Doubles, ShotAttempt's settings as struck), motionHash (UInt64), signature ([Int]).
   - init?(attempt: ShotAttempt, signature: [Int]): copies attempt.input (positions, strike, seed,
     parameters.version), attempt.surface/table/generation, the settings, attempt.motionHash. Nil if the input has no
     balls.
   - func input() -> ShotInput: PoolParameters() with version = parametersVersion, then NextShot.shot-equivalent
     ShotInput(parameters:positions:strike: CueStrike(direction:speed:tipUp:tipSide:elevation:ballIndex:), seed:).
     Then write the stored direction back over the one CueStrike's init made: `strike.direction = direction` (a public
     var). CueStrike.init normalises its direction, and normalising an already unit vector can move its last bit
     (Vec2.normalized divides by a computed length), which would give a different recording and a false "played again
     with today's physics". Elevation needs no write-back: the init's clamp leaves an in-range value unchanged.
   - nonisolated func solve() -> (attempt: ShotAttempt, sameAsEarned: Bool)? : nil when the stored surface or table raw
     value is unknown; otherwise ShowpieceModel.solverCopy(input(), table:, surface:, generation:), PoolSolver.simulate,
     then a ShotAttempt built with the stored settings (stroke nil), input = input() (the base input, as the model keeps
     it), the stored surface, table and generation; sameAsEarned = attempt.motionHash == motionHash. ShotAttempt is
     implicitly Sendable (an internal struct whose stored properties are all Sendable: Timeline, ShotInput, PlaySurface,
     TableKind, StrokeDelivery), so it may come back from Task.detached; if the Swift 6 compiler disagrees, return the
     Timeline from the detached task and build the ShotAttempt on the main actor.
   - extension TrickPath { nonisolated static func traced(_ tl: Timeline, start: [Vec2], striker: Int) -> TrickPath? }:
     the same as TrickPath.traced but with `cue: stretches(of: striker, in: tl)` (nil when empty), `objects` built from
     every ball index b in 0..<min(start.count, tl.ballCount) with b != striker and NextShot.isOnTable(start[b]) (ball 0
     included when it is not the striker), and `balls` exactly as traced builds them. Uses TrickPath.stretches(of:in:)
     and the memberwise init, both internal. With striker 0 it must return the same value as traced(_:start:). Kept
     here, not in TrickPathThumb.swift, so that shared file is not touched.

4. App/Achievements/AchievementJudge.swift, pure detection (no model, no UserDefaults).
   - struct AchievementShotContext: the recording (Timeline), ShotFacts, captions, table (TableKind), isBreak, freePlay
     (no match, no authored mode, no drill), the attempt (ShotAttempt).
   - enum AchievementJudge:
     - static func shotAchievements(_ c: AchievementShotContext) -> [(id: String, signature: [Int])]. Calls
       ShotHighlightJudge.detect once and maps kinds to ids (stopDead dead-stop, drawBack draw-back, curve masse-curve,
       throwIn thrown-in, combination combination, kick kick, bank bank, multiPot two-at-once, rimSkip too-fast,
       bumperCup bumper-cup, redPinAlone red-pin; breakShot maps to nothing; jump maps to jump-clear only when
       clearsBall below is true), each with the highlight's signatureEvents. Then the new checks, each reading the
       recording (never ShotFacts.pocketed alone, so a hand-made test recording works). Carom uses ShotMoments' helpers
       (firstContact, secondContact, other(in:than:), pocket(of:), lastContact(of:atOrBefore:), signature); ShotMoments
       has no cushion-event helper and its `events`, `names` and `leads` are private, so the jaw, knuckle and drop scans
       loop over `m.timeline.events` directly (a pocket or cushion event's ball is `event.balls.first?.ball`). Do not
       add helpers to ShotHighlightJudge.swift: it is not a file this feature touches.
       - clearsBall(m, timeline, cue): from the take-off (ShotMoments.takeOff(of:minimumUp: ShotHighlightJudge.jumpSpeed))
         to its landing (m.landing(of:after:), or the recording's end), sample the clock 60 times with
         timeline.state(ball:at:); at any sample where the cue ball's state.height is above zero and some other ball
         that started on the table and is not pocketed at that time (its state.pocketed is false) is within one ball
         radius (timeline.table.ballRadius) of it across the cloth, it went over that ball.
       - carom: first = m.firstContact(of: cue), second = m.secondContact(of: cue); the other ball in second differs
         from the other ball in first, and that second ball dropped at or after the second contact (m.pocket(of:)).
         Signature m.signature([first, second]).
       - jaw-in: for each pocket event (m.pockets()), its ball's cushion events (kind .cushion, the ball first in
         event.balls) with edge .jaw or .knuckle and event.pocket equal to the drop's own pocket index, after that ball's
         last ball contact (m.lastContact(of:atOrBefore:), or from the start) and before the drop; one or more.
         Signature m.signature([jaw, drop]). Stop at the first ball that qualifies.
       - rattle-out: a ball with two or more jaw or knuckle events on the same pocket (same event.pocket) after its
         last ball contact and no pocket event of its own. Signature m.signature([first jaw, second jaw]).
       - big-break: isBreak, table .standard, three or more object balls dropped (pocket events whose ball is not the
         cue). Signature: the first two drops. (detect returns only a break moment for a break, so this reads the
         events itself.)
       For a break only big-break is read (detect returns only a break moment for a break, and the rack's scatter
       would otherwise read as caroms and jaw touches on every break). Ids come back in catalogue order, each once. Earning never depends on the signature: an empty signature only
       means the replay holds the ordinary beats.
     - struct RunTracker: Codable-free value, `running: Bool`. mutating func note(isBreak:, poolRack: Bool,
       dropped: Int, scratched: Bool, objectBallsLeft: Int) -> Bool (true when run-rack is earned). A break starts a run
       when poolRack, at least one dropped and no scratch; a later shot keeps it when poolRack, at least one dropped and
       no scratch, else ends it; the run is earned when it is running and no object ball is left. poolRack is freePlay
       and table .standard.
     - struct AchievementProgress: lessonsDone, tricksDone, escapesWon (Set<String>), levelsBeaten (Set<String>,
       ComputerLevel raw values), tablesPlayed, surfacesPlayed (Set<String>). static func earned(_ p:) -> Set<String>:
       lesson-<id> per done lesson, every-lesson when all Lessons.all are done, trick-<id> per done playable trick,
       every-trick when all playable are done, every-escape when every situation has a medal, beat-<level> per beaten
       level, every-table when every TableKind is played, every-surface when every PlaySurface is played.
       func count(_ kind: AchievementProgressKind) -> (done: Int, total: Int) for the pictures.

5. App/Achievements/AchievementRecord.swift, the save (the MatchRecord pattern).
   - struct AchievementRecord: Codable, Equatable. static let storageKey = "achievements" (kept here, as TrickShotMode
     and LessonMode keep their own keys; GameSettings is not touched). static let currentFormat = 1; var format.
   - struct Earned: Codable, Equatable { date: Date, shot: AchievementShot?, seen: Bool }.
   - var earned: [String: Earned], var tablesPlayed: [String], var surfacesPlayed: [String], var seeded: Bool (the
     first-launch quiet pass has run).
   - A lenient init(from:) with decodeIfPresent for every field (an older or newer save still loads; an Earned whose
     shot fails to decode keeps its date with shot nil).
   - static func load(from defaults: UserDefaults = .standard) -> AchievementRecord; func save(to: UserDefaults = .standard).
   - mutating func earn(_ id: String, on date: Date, shot: AchievementShot?, seen: Bool) -> Bool: false and no change
     when already earned.

6. App/Achievements/AchievementBook.swift, the live object the model owns.
   - @MainActor @Observable final class AchievementBook. `@ObservationIgnored unowned let model: ShowpieceModel`
     (the trickMode pattern), `defaults: UserDefaults` (injected for tests, .standard in the app), `readsProgress: Bool`
     (true in the app; tests pass false so no sweep reads the machine's own lesson, trick or medal lists),
     `private(set) var record`, `private(set) var toasts: [String]` (ids waiting to be shown), `private(set) var
     shownToast: String?` and `private(set) var shownReplayEnd: String?` (what the views draw; stored, and written only
     when they change, so no view re-renders every frame), `private(set) var drawings: [String: TrickPath]`,
     `private(set) var pageRequests = 0`, `@ObservationIgnored var run = RunTracker()`, `@ObservationIgnored var
     strikeByPerson = true`, `@ObservationIgnored var lastPersonShot: (shot: AchievementShot, version: Int)?`,
     `@ObservationIgnored var stamp: [Int] = []`, `@ObservationIgnored var toastClock = 0.0`,
     `@ObservationIgnored var drawingsStarted = false`.
   - static let enabled: Bool (read once): false when StoreScene.requested is not nil or the launch arguments contain
     any of "-retryCases", "-retryDemo", "-yourBreakDemo", "-yourShotDemo", "-aimDemo", "-aimDemoRack", "-rackShoot",
     "-aimScript", "-jumpDemo", "-rideDemo", "-eightPlay", "-eightJudgeCheck" (every scripted strike; a test launch never
     earns, never shows a note and never writes the save). Do not gate on the model's strokeDue instead: a calm keyboard
     or controller stroke does not set it, so real shots would stop earning.
   - init(model:defaults:readsProgress:) with defaults .standard and readsProgress true: loads the record; when enabled
     and readsProgress, schedules the first sweep with Task { @MainActor in self.sweep(quiet: !self.record.seeded) } so
     nothing changes during a view update, then sets seeded and saves.
   - func strikeStarted(byPerson: Bool): stores it (called from strike()).
   - func noteShot(_ c: AchievementShotContext, version: Int, quiet: Bool): returns at once unless enabled and
     strikeByPerson. Builds the shot's AchievementShot (signature from the first detected moment, for collections),
     sets lastPersonShot, adds the table and surface raw values to the record, runs AchievementJudge.shotAchievements
     and the RunTracker (dropped = object-ball pocket events, scratched = facts.cueBallScratched, objectBallsLeft = balls
     other than facts.cueBall whose facts.resting position is on the table), earns each new id with its own signature
     (the shot rebuilt with that id's signature) and puts its drawing in `drawings` at once from the live recording
     (TrickPath.traced(c.timeline, start: c.attempt.start, striker: c.attempt.cueBall)), then calls sweep(quiet:) when
     readsProgress. Saves once, and only when something changed (a new id, or a new table or surface).
   - func sweep(quiet: Bool): returns unless enabled. Builds AchievementProgress from model.lessonMode.doneIDs,
     model.trickMode.doneIDs, model.eightBallMode.medals keys (the public accessors; ShowpieceView already builds all
     three at launch, see What exists today), MatchRecord.load(from: defaults) (levels with tally(level).won > 0), and
     the record's tables and surfaces; earns every id in AchievementProgress.earned not yet earned. The kept shot is
     lastPersonShot.shot only when lastPersonShot.version == model.timelineVersion (the player's own shot is what is on
     screen), else nil. Saves when something was earned.
   - func frame(_ rawDt: Double): every frame from the model (never while the menu is open: advance returns first).
     1. Reads model.achievementStamp (through the model's optional storage); when it differs from `stamp`, stores it
        and, when readsProgress, sweeps (quiet while model.openingStage != .none).
     2. The calm gate, `calm`: model.openingStage == .none, !model.menuOpen, model.aimReady, !model.holding,
        !model.placingCueBall, !model.whatIf.isShowing, model.computerTurnStage == .none. Not !model.guided (a finished
        Lens replay stays guided; see What exists today).
     3. End note: the id in model.achievementReplayID while model.achievementReplayVersion == model.timelineVersion and
        calm, else nil. Written to shownReplayEnd only when it differs; when it turns non-nil, ShotNarration.announce(
        AchievementWords.replayEnded(name:)).
     4. Toast, only while shownReplayEnd is nil: when calm and toasts is not empty, shownToast = toasts[0] (on change
        only; when it turns non-nil, toastClock = 0 and ShotNarration.announce(AchievementWords.toastSpoken(name:))),
        then toastClock += rawDt; at four seconds remove toasts[0] and set shownToast to nil (the next one shows on a
        later frame). When not calm, shownToast = nil and the clock keeps its value, so the same note comes back and
        finishes its time when calm returns, without a second announcement (remember the last announced id). Behind
        the menu frame never runs (advance returns first), so the note simply stays as it was, hidden with the rest of
        the table's chrome (phoneChrome, the side column and the bottom stack are all hidden behind the menu, and the
        notebook shows the menu instead of its cards); it finishes its time after Continue. That is the intended
        behaviour; openMenu is not changed.
   - Earning (private func earn(_ id:, shot:, quiet:)): writes the record with seen = quiet && model.openingStage !=
     .none (earned during the opening is never "new"; the first launch's quiet sweep of old progress stays new); unless
     quiet, appends the id to toasts.
   - func openList(): model.openMenu() then pageRequests += 1 (ShowpieceView turns that into the page).
   - func listOpened() -> Set<String>: when readsProgress, sweep(quiet: true) (a game won just before the menu opened
     is counted); returns the ids that are new, then marks everything seen and saves. Also starts the drawings.
   - func startDrawings(): first time only (drawingsStarted). For each earned id with a kept shot and no drawing, one
     after another: `await Task.detached(priority: .utility) { shot.solve().flatMap { TrickPath.traced($0.attempt.timeline,
     start: shot.start, striker: shot.ballIndex) } }.value`, stored in `drawings` (the TrickPathCache pattern; rows fill
     in as each arrives).
   - var earnedCount, newCount, total; func earned(_ id:) -> AchievementRecord.Earned?;
     func progress(of: Achievement) -> (done: Int, total: Int)?.
   - func replayShot(_ id: String) async -> (ShotAttempt, [Int], Bool)? : solves the kept shot on a detached task
     (Task.detached(priority: .userInitiated) { shot.solve() }), returns the attempt, the signature (the stored one when
     sameAsEarned; when not, AchievementJudge run on the new recording for that id, with facts
     ShotFacts(timeline:start:cueBall:) and captions CaptionEngine.make(from: tl, surface:, strike: shot.input().strike,
     table:, striker: shot.ballIndex), the same call ShowpieceModel.load makes, so the event indices match the model's
     captions after the load; or empty) and sameAsEarned.

7. App/Achievements/AchievementViews.swift, every view.
   - AchievementList(model:onClose:): the list page described above, with `@State private var newOnOpen:
     Set<String> = []` and .onAppear { newOnOpen = book.listOpened() } (rows show their dot from newOnOpen, not from
     the record, so the dots survive the visit that clears them), the notebook's Mac minimum size handled as
     TrickShotList does (inlinePages), Close in the cancellation slot. Rows read book.drawings[id]; a row whose drawing
     is still being solved keeps a blank frame of the same size.
   - AchievementRow (private), AchievementDetail(model:achievement:onClose:), AchievementProgressPicture(kind:progress:)
     (a LazyVGrid of small ticked or empty marks with the item's name; table and surface items use TableKind.symbol and
     PlaySurface.symbol and their titles).
   - enum AchievementToastStyle { case blurb, card }.
   - AchievementToast(model:style:): one view for every layout. Draws book.shownReplayEnd first, else book.shownToast,
     else nothing (EmptyView, no height). No timer and no announcement here: the book's frame step owns both, so a
     remount on rotation or fold cannot restart or repeat them. `.blurb` (upright phone) is a Blurb(accessibilityText:
     buttons:) { symbol, "Achievement earned", name } sized to its text; `.card` is a slim glassCard with the same
     content. The end note uses the same shape with the sentence and one BlurbButton "Achievements" (a plain bordered
     button in the card form) calling book.openList(). Transition Blurb.transition, or .opacity with Reduce Motion, with
     its own .animation(reduceMotion ? .easeInOut(duration: 0.2) : .smooth, value: the shown id), since the parents'
     animations are keyed to other values.
   - The menu's mark's three parts (symbol, text, spoken) come from AchievementWords (menuSymbol, menuMark,
     menuSpoken); MenuRow and MenuRow.Mark are private to TitleScreen.swift, so TitleScreen builds the Mark itself (T3).

### Hook points in shared files (small and listed, for the merge)

ShowpieceModel.swift (six small insertions):
- H1, beside trickModeStorage: `@ObservationIgnored private var achievementsStorage: AchievementBook?` and
  `var achievements: AchievementBook` made on first use, exactly as trickMode.
- H2, strike(), first line inside: `achievements.strikeStarted(byPerson: achievementStrikeIsPersons)` (before the solve
  starts; the computer's computerActing and the modes' .watching are still set here).
- H3, finishStrike(), after judgeHighlight(tl, isBreak: s.isBreak): when currentAttempt and shotFacts are both set,
  build AchievementShotContext(timeline: tl, facts: shotFacts, captions: captions, table: solvedTable, isBreak:
  s.isBreak, freePlay: achievementFreePlay, attempt: currentAttempt) and call achievements.noteShot(context, version:
  timelineVersion, quiet: openingStage != .none). Comment that, unlike judgeHighlight, it runs in every mode.
- H4, advance(_ rawDt:), after chimeTableClearedIfDue(): `achievements.frame(rawDt)` (the real seconds, not the clamped
  physics step). advance returns early while the menu is open, which is right: nothing is earned or shown there.
- H5, a new section right after abandonBestReplay(): `private(set) var achievementReplayVersion: Int?`,
  `private(set) var achievementReplayID: String?` and `func watchAchievementShot(_ attempt: ShotAttempt, signature:
  [Int], id: String)`, which does, in this order: closeAllLists(); abandonBestReplay(); endPoolTableModes();
  strokeDrillStorage?.end(); lessonModeStorage?.end(); cancelPendingSolve(); leaveMatch(); endPlacement(); ballInHand =
  .none; undoStep = nil; startHighlightRack(); clearedChimePlayed = true (a replayed clearing shot shows Table cleared
  silently); if tableKind != attempt.table, set tableKind and store it under TableKind.storageKey (as playTable does);
  if surface != attempt.surface, set surface, store it under PlaySurface.storageKey and surfaceVersion += 1 (as
  setSurface does, but without its re-solve: the load below puts the shot on screen; lessonModeStorage?.end() above
  has already put back any lesson surface, so this comes after it); menuOpen = false; gameInProgress = true;
  panelAfterBreakDue = false; requestShotPanel(.close); clearAttempts() (drops the ghost, comparison, retry seed and
  kept what-if strike, bumping ghostVersion); shotsThisRack = 1 (so a shot that left no object ball gets the Table
  cleared card and its Rack again; tableCleared needs a count above zero; its code comment must say so, since it counts a
  shot nobody struck here, and that undoStep is nil so Undo cannot act on it); showKeptRecording(attempt, input:
  attempt.input, classic: false, surface: attempt.surface, table: attempt.table, generation: attempt.generation);
  if attempt.cueBallScratched and an object ball is left on `layout` (the test finishStrike uses), ballInHand =
  .anywhere and placementDue = true, as finishStrike does after a free-play scratch; achievementReplayVersion =
  timelineVersion; achievementReplayID = id; holdRideForGuidedReplay(); setPaceSignature(signature); replay(withLens:
  true); lensReplayStartedByPlayer = true. Order matters: load (inside showKeptRecording) gives back any held Ride and
  clears the signature, so the hold and the signature come after it. It records nothing (no record(), no undo step),
  as watchBestShot. The kept attempt becomes currentAttempt, so Try again retries the replayed shot from its start.
- H6, beside authoredModeUp (so they read the private optional storage and never create a mode on a strike or a frame):
  - `var achievementStrikeIsPersons: Bool`: false when match?.computerActing is true, or trickModeStorage,
    lessonModeStorage or eightBallModeStorage has phase == .watching (each mode sets .watching before its Watch or hint
    strikes, and authored modes solve synchronously, so the phase is still set inside strike()); true otherwise.
  - `var achievementFreePlay: Bool`: match == nil && !authoredModeUp && strokeDrillStorage?.isActive != true.
  - `var achievementStamp: [Int]`: [lessonModeStorage?.doneIDs.count ?? -1, trickModeStorage?.doneIDs.count ?? -1,
    eightBallModeStorage?.medals.count ?? -1, match?.sittingGames ?? -1].

ShowpieceView.swift (four):
- V1, phoneChrome: right after `phoneDock` and its onGeometryChange, insert `AchievementToast(model: model, style:
  .blurb).frame(maxWidth: .infinity, alignment: .trailing)`. Not inside phoneDock, so the dock's measured bottom (and
  the camera) never move for it.
- V2, sideColumn: first line of the cards VStack (before WhatIfCard): `AchievementToast(model: model, style: .card)`.
- V3, bottomStack(geo:wide:)'s FittingScroll cards (the big window with the notebook put away): first line
  `if !wide { AchievementToast(model: model, style: .card) }`.
- V4, pageSheet: `case .achievements: AchievementList(model: model, onClose: { page = nil })`, and beside the
  shotPanelRequest onChange: `.onChange(of: model.achievements.pageRequests) { _, _ in page = .achievements }`. The
  same `page` state feeds the notebook (NotebookPanel's binding) and the phone's sheet, so this one line serves both.

NotebookPanel.swift (four):
- N1, NotebookPage gains `case achievements`.
- N2, content(size:): `case .achievements: AchievementList(model: model, onClose: { self.page = nil })`.
- N3, cards: first line `AchievementToast(model: model, style: .card)`.
- N4, the TitleScreen made in content(size:): add `onAchievements: { page = .achievements }`.

TitleScreen.swift (three):
- T1, a property `var onAchievements: (() -> Void)? = nil` beside onTables.
- T2, menuSheet: `case .achievements: AchievementList(model: model, onClose: { state.sheet = nil })`.
- T3, mainList: after the Tables row, `MenuRow(title: "Achievements", line: "Physics you have pulled off, with the
  shot that did it.", symbol: "rosette", mark: achievementMark) { openPage(.achievements, inline: onAchievements) }`,
  with achievementMark a private computed property, the way trickMark is built: `MenuRow.Mark(symbol:
  AchievementWords.menuSymbol(new: b.newCount), text: AchievementWords.menuMark(earned: b.earnedCount, total: b.total),
  spoken: AchievementWords.menuSpoken(earned: b.earnedCount, total: b.total, new: b.newCount))` with b =
  model.achievements.

Every shared file touched also gets one "Edited:" line in its header (CODING_STANDARDS: update the header each time a
file is touched), naming the builder's model and effort and "0.7.7 achievements hooks"; the coordinator keeps the five
features' lines side by side.

Not touched: FreePlayViews.swift, GameSettings.swift, ControllerInput.swift, TableScene.swift, TableStage.swift, the
title row and phone strip (PhoneTitleRow.swift, PhoneStrip.swift), MatchMode, TrickShotMode, LessonMode, EightBallMode,
TableKind.swift, PlaySurface.swift, TrickPathThumb.swift, ShotHighlightJudge.swift, HighlightWords.swift, MatchRecord.swift,
MacChrome.swift (it holds a NotebookPage binding but no switch over it), the project file. Localizable.xcstrings is
changed by the coordinator's merge of the pending file, not by hand. CHANGELOG.md gets one entry (see Coordinator
steps).

### Coordinator steps (after the merge)

- Merge localization/pending/v077-achievements.json with scripts/localization-merge.py, then run
  scripts/translation-check.py.
- Compile both targets once; run the package tests and the app tests listed below.
- No screenshot walk-through or review round: the Boss tests the build himself. The one check before shipping is the
  standing one, the first minute played on a fresh install: the opening shows no note, and the first menu shows the
  Achievements row with no "new" sign.
- CHANGELOG.md is a shared file: the builder writes one entry, "### Achievements", at the top of a "## [0.7.7]" block
  (creating the block if the worktree has none), plain words first; the coordinator stacks the five features' entries
  under one 0.7.7 heading.

## Tests

App tests, new files in BreakdownTests/ (in the test target by the synchronised folder):

- AchievementJudgeTests.swift (solving through TestShots, as ShotHighlightJudgeTests does):
  - Each trick answer earns its shot achievement: stop-dead earns dead-stop, bridge-draw draw-back, masse-curve
    masse-curve, jump-over jump-clear (this one also proves clearsBall), throw-it thrown-in, combo-chain combination,
    two-rail-kick kick, cross-bank bank, follow-train two-at-once.
  - The soft plain pot from ShotHighlightJudgeTests earns nothing.
  - The first player break (TestShots.breakShot()) earns big-break exactly when three or more object balls dropped,
    and nothing else (no bank or combination from the scatter).
  - Hand-made recordings (TestShots.recording plus LensEvent cushion events with edge .jaw): a jaw touch then a pocket
    of the same ball earns jaw-in; two jaw touches and no pocket earn rattle-out; one jaw touch and no pocket earns
    neither.
  - A hand-made carom: cue meets ball 1, then ball 2, then ball 2's pocket event: carom; the same with ball 1 twice: no
    carom.
  - RunTracker: break drops one, two shots each drop one, last leaves none: earned on the last; a shot that drops
    nothing ends the run; a scratch ends it; a break that drops nothing never starts one; not on another table.
  - AchievementProgress.earned: every-lesson only when every Lessons.all id is done (drop one: not earned);
    every-trick ignores pending tricks; beat-hard only from a hard win; every-surface needs every PlaySurface case.
    Counts come from the content lists, never written into the test.
  - TrickPath.traced(_:start:striker:) with striker 0 equals TrickPath.traced(_:start:) on the stop-dead answer.
- AchievementRecordTests.swift: a record survives a save and load through a throwaway UserDefaults suite; a stored
  record missing fields (only "earned") still loads; earn twice keeps the first date and shot; AchievementShot from a
  real attempt (TestShots.attempt) solves back to the same motionHash (sameAsEarned true) and reports false when its
  generation is changed. (TestShots.attempt's input already carries the standard table's and the surface's numbers;
  AchievementShot keeps only the parameters' version and solverCopy writes the same table and surface numbers in the
  same order TestShots.solve does, so the hashes agree.) Also a shot whose stored direction is a unit vector rebuilt
  through input() keeps that exact direction (the write-back after CueStrike's normalising init).
- AchievementBookTests.swift (@MainActor, as ModelFlowTests): each test keeps `let model = ShowpieceModel()` in a
  local for its whole body (the book holds it unowned; a temporary would be freed at once and the first read would
  crash), then builds `AchievementBook(model: model, defaults: suite, readsProgress: false)` with a throwaway suite made
  per test and removed after. readsProgress false means no sweep runs, so nothing is read from the machine's own lesson,
  trick or medal lists; the tests never read the model's own `achievements` accessor. They call book.noteShot with
  contexts built from TestShots recordings, not the model's strike. Cases: the cross-bank answer earns bank and puts
  "bank" in toasts; after strikeStarted(byPerson: false) the same shot earns nothing; a quiet shot earns without
  queuing; listOpened returns the new ids and then newCount is zero; with model.menuOpen true (a fresh model starts on
  the menu unless the launch skips the title; skip the case when TitleScreen.launchSkipsTitle) book.frame(0.1) leaves
  shownToast nil. Collection results are tested pure through AchievementProgress.earned, above.

Package tests: none. Nothing in Packages/BreakdownCore changes.

## Words to translate

The builder writes localization/pending/v077-achievements.json in the same shape as
localization/pending/v075-whatif.json (a "keys" list of the English lines and a "translations" list of culture, key and
text), with every line below in all eleven languages (es, fr, de, it, pt, pt-BR, ja, ko, zh-Hans, ru, ar), written
natively, placeholders kept. Names are generic physics and shot names; no people, brands or sources.

Already in the catalogue and reused (no new entry): every HighlightWords sentence, "Thrown in", "Two at once",
"Off a bumper", "The red pin alone", "Trick shots", "Behind the 8-Ball", "Lessons", "Close", "%lld of %lld",
"%lld/%lld", "Combination" and "Carom" (both already the Behind the 8-Ball shot-type names, same meaning), "Watch it in
the Lens", HighlightWords.watchHint, every lesson, trick, table and surface title. (Checked in the catalogue on 23
November 2026; all eleven languages present. Do not put these in the pending file: the merge would overwrite
translations that already ship.)

New:
- Menu and page: "Achievements"; "Physics you have pulled off, with the shot that did it."; "Every shot you play is
  read for these, in any mode."; "Shots"; "Games"; "Not earned yet"; "Earned %@";
  "%lld of %lld earned, %lld new"; "%lld of %lld earned"; "No single shot to replay for this one."; "Played again with
  today's physics, so it may not end the same way."
- Note: "Achievement earned"; "Achievement earned: %@"; "That was your %@."
- Names: "Dead stop"; "Draw back"; "Massé curve"; "Over the top"; "Kick shot"; "Bank shot"; "In off the jaw"; "Rattled out"; "Too fast to drop"; "Big break"; "Run the rack"; "Beat the computer: Easy";
  "Beat the computer: Medium"; "Beat the computer: Hard"; "Every table"; "Every surface"; "Every lesson";
  "Every trick shot"; "Every way out".
- New sentences: "The cue ball left the cloth and flew over a ball in its way."; "The cue ball glanced off one ball
  into another, and that one dropped."; "The ball touched the pocket's jaw and still fell in."; "The ball bounced between the
  pocket's jaws and stayed on the table."; "Three or more balls went down from one break."; "From your break to an
  empty table, every shot dropped a ball."; "You won a game against the computer at this level."; "You played a shot on
  every table."; "You played a shot on every surface, the Moon included."; "You passed this lesson."; "You passed every
  lesson."; "You made this trick shot."; "You made every trick shot."; "You won a medal on every spot."
- Hints: "Hit a ball full and firm so the cue ball stops on the spot and the ball drops."; "Strike low on the cue ball so it
  spins back after the hit."; "Raise the cue steeply and hit off centre so the cue ball bends before it reaches a ball.";
  "Raise the cue and hit down on the cue ball to hop it over a ball."; "Cut a ball softly so friction at the contact turns
  it into the pocket."; "Send one ball into another so the second one drops."; "Send the cue ball off a cushion first,
  then into a ball."; "Drop a ball off a cushion."; "Glance the cue ball off one ball so it knocks a second ball in.";
  "Drop two balls with one stroke."; "Drop a ball that touches the side of the pocket on its way in."; "Hit the
  pocket's jaws hard enough that the ball bounces out."; "Roll a ball over a hole faster than it can fall in.";
  "Break the rack hard and square."; "In free play, break and then drop a ball with every shot until the table is clear,
  without losing the cue ball."; "On the bumper pool table, play a ball off a bumper into a cup."; "On the five-pin table,
  knock down only the red pin."; "Win a game against the computer at Easy."; "Win a game against the computer at
  Medium."; "Win a game against the computer at Hard."; "Play a shot on each table in Tables."; "Play a shot on each
  surface in the Surface menu."; "Pass this lesson in Learn."; "Pass every lesson in Learn."; "Make this trick shot in
  Trick shots."; "Make every trick shot."; "Win a medal on each spot in Behind the 8-Ball."

The game says "cue ball" everywhere (well over a hundred catalogue lines; "the white" appears only for bumper pool's
own white and yellow balls), so these lines do too.
Translator notes to carry in the comments: "Kick shot" is the pool shot that reaches a ball off a cushion; "Carom" is
the cue ball glancing off one ball into another; "Over the top" is a jump over a ball; "Rattled out" is a ball bouncing
in a pocket's mouth without falling; "Run the rack" is clearing the table without missing.

## Out of scope

- Game Center. Decided against for 0.7.7 (no entitlements file today, a signing and store setup the coordinator cannot
  finish blind, art and store text per achievement in twelve languages, and a launch sign-in banner against the calm
  first minute). Later, as its own plan: an entitlements file and the project's entitlements setting, the forty-odd
  achievements entered in App Store Connect with ids "breakdown." plus the id here, art, and one small
  AchievementReporter that AchievementBook calls when it earns (optional, behind an Options switch that is off by
  default, so sign-in is asked for only when the player turns it on).
- Sharing an achievement's shot as a clip (the Lens clips feature may offer it from the page later; nothing here
  prevents it).
- Syncing across devices (iCloud), resetting achievements, streaks, rewards, points.
- A Mac Game menu item for Achievements (the Mac reaches it from the menu page in the notebook).
- Earning from shots watched rather than played, and from the what-if's other future.

## Risks

- Merge collisions. NotebookPage and its three switches are the hot spot if another feature adds a page; ShowpieceModel's
  finishStrike end, strike's first lines and advance's end are where other features may also hook. Every hook here is
  one line or one short section, inserted where named, so the coordinator can keep both sides.
- Replaying a kept shot depends on the solver giving the same recording again. On the same build it does (the retry
  check proves it); after a physics change it may not, which the page says in one line and the replay still plays. The
  kept shot stores its own surface, table and generation, never today's settings.
- The base input's parameters are rebuilt as the defaults with the stored version. That is how every player stroke and
  break is built today (NextShot.shot and the rack's version 1); if a mode ever builds strokes on other parameters, the
  motionHash check catches it.
- The jump-over threshold (one ball radius across the cloth while airborne) is a first guess; the jump-over trick test
  proves it on the real answer. If that test fails, widen to 1.5 radii and note it in the file.
- Two achievements from the existing judge (and the moments it drops when no event is captioned) inherit its choices;
  this is deliberate, so a shot is never "remarkable" in one place and not the other.
- The route into play from Watch it leaves a trick shot or lesson the way every other menu route does; a match stays
  saved. This matches Watch the intro, and the page says nothing about it because the menu's Continue row already shows
  what will be left.
- Performance: one extra pass of detect and a few event scans per shot, the same scale as judgeHighlight; the per-frame
  stamp is four integers and the views observe only the book's stored shown ids, never the clock. The list's drawings
  are solved one at a time on a utility task, the TrickPathCache pattern, so opening the list never waits. The save is
  a few kilobytes even with every achievement earned, and is written only when something changed.
- Three recipes for one kept shot. The clips plan's ClipShotRecord and make-it-again's OwnShot each also store a shot's
  positions, strike, seed, table, surface and generation and solve it through solverCopy. They are built side by side,
  so each keeps its own type for this merge; folding them into one shared recipe is a later tidy-up the coordinator can
  note, not a blocker.
- Upright phone: the note sits at the top right of the table area, and the Lens explanation blurb (PhoneExplanationBlurb,
  anchored by BlurbPlacement) can sit near the top too when the shot ended there. The note is small, trailing and gone
  in four seconds; if the two are ever seen to overlap, the fix is to have BlurbPlacement treat the note's frame as an
  obstacle, not to move the note into the dock (which would reframe the camera).
- finishStrike's last line is also the bullet-time plan's hook point (one call after judgeHighlight each), and that
  plan also hooks advance, inside its explore case rather than at the end. Order between the two calls in finishStrike
  does not matter.
