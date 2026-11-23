<!--
Author: Claude Opus 5.5 High
Date: 23-November-2026
Edited: Claude Opus 5.5 High, 23-November-2026 (independent critic, every claim checked against the code: the answer is
        now the struck stroke itself, since free play's raised cue can pick the jump or masse cue and the chosen power
        is then not the launch speed; the saved direction is written back exactly, because CueStrike's init normalises
        it again; the Lens moments read the recording, with no shelf lookup and no unsafe mirror, so TrickSignature
        stays nonisolated; the saved-shot match uses the input's seed, not the attempt's serial seed; rename and delete
        work inside the row, as the match card's name editor does, since the app has no system alerts and they would
        cover the table on the open Duo; no haptic inside CardButtonRow, which builds its content twice; the catalog
        key "%@ into %@"; bed-hole rings guarded; How forgiving hidden in the notebook until the window is measured
        (hook N1); default names only for kinds the goal really asks for; tests made main-actor, given a test shelf
        and the right seed check; the Risks now name the real collisions with the other four plans.)
PURPOSE: Build plan for "Make it again" (0.7.7): after a lucky or great shot in free play, one tap keeps the table as it
         stood before the shot, what the shot did, and the exact stroke that did it, and turns it into the player's own
         challenge on a shelf called "Your shots" inside the Trick shots list. The challenge is played by the existing
         trick-shot mode and judged by the existing trick-shot judge; the saved stroke is the proof and the hint.
         Written for one developer working blind in their own worktree (no compile; the coordinator compiles once after
         the merge), from a read of the 0.7.6 code on main. Four other features are planned and built at the same time
         (bullet time on the hit, same shot on every surface, achievements, Lens clips to share); this plan keeps its
         code in new files and lists every edit to a pre-existing file as a numbered hook point.
SRP/DRY check: Pass - checked App/TrickShotMode.swift, TrickShotJudge.swift, TrickSignature.swift, TrickShots.swift,
         TrickPathThumb.swift, TrickShotViews.swift, ShotAttempt.swift, ShotHighlight*.swift, HighlightOffer.swift,
         HighlightWords.swift, FreePlayViews.swift, FreePlayPhoneBlurbs.swift, ShotPanel.swift (ShotOptionsItems),
         MacChrome.swift, ControllerInput.swift, NotebookInfo.swift (the dossier), TableWords.swift, Match/TableGameWords.swift, Match/MatchWords.swift,
         Match/MatchMode.swift (its save file pattern), ShowpieceModel.swift (striking, retry, kept strike, surfaces,
         tables, trick section, worth watching), the package's ShotInput, CueStrike, Timeline, TableSpec and ShotFacts,
         scripts/localization-merge.py and plans/. Nothing like a player-saved challenge exists. The flow, the judge,
         the card, the phone blurbs, the path drawing and the Lens replay are all reused; the only new logic is turning
         an attempt into a goal, storing it, re-proving it, and measuring how forgiving it is.
-->
# Make it again

## In plain words

You are knocking balls about in free play and something good happens: two balls drop off one hit, a ball banks in off
the rail, the cue ball kicks round and finds the last ball. On the small card that already names a great shot there is
now a button, Make it again. It is also in Shot options, after Undo last shot, for any shot that dropped a ball. One tap
keeps the table exactly as it stood before that shot (every ball where it was, the cloth, the table) and what the shot
did (which balls went into which pockets, which ball the cue ball touched first, and whether a ball came off a cushion).
The button then says Play it now.

The shot is now your own challenge, kept on a shelf called Your shots at the bottom of the Trick shots list. It plays
exactly like a trick shot: the balls are set up, the card says what to do in words ("Pot the 3 into the foot-left
corner pocket and the 6 into the left side pocket. Touch the 3 first."), the pockets and balls are ringed on the cloth,
Watch it plays your own stroke again exactly as you struck it (riding behind the cue ball, then slowly in the Lens),
and Your turn hands you the cue. The game knows the shot is possible because it kept your stroke and plays it again to
check. Made it says so; a miss says what to change, as every trick shot does. On the shelf you can play, rename and
delete each shot, and each row shows a small drawing of the line that worked and whether you have made it again.

What counts as made: the same balls in the same pockets, in any order, and the cue ball stays on the table. The cue ball
must touch the same ball first, so a combination stays a combination. If one of the balls came off a cushion on its way
in, it must come off a cushion again. Extra balls dropping is fine. Where the cue ball finishes does not matter.

Nothing new is pushed at the player. The first minute is untouched: the button only appears on a card that already
exists, or inside a menu, and saving makes no sound.

## What exists today (read in the code)

- **The trick-shot mode** (App/TrickShotMode.swift, class TrickShotMode). Holds `current: TrickShot?` and a phase (ready,
  watching, explaining, aiming, judged, offScript). `begin(_ shot:)` takes any TrickShot value, not only one from the
  library: it calls `model.enterTrickTable()`, lays the start out through `loadStart` (`model.loadTrickLayout` for a
  `.layout` setup) and points the cue at the nearest ball. `watch()` loads `shot.solution` into the controls and calls
  `model.shootNow()` with Ride on; `update()` moves watching on to explaining, keeps the answer's cue path, sets the pace
  signature from `TrickSignature.events(forTrick:in:captions:)` and starts the slow Lens replay; for the player's own
  try it checks `startsAtTrick(attempt)` (the attempt's start equals the layout) and judges with
  `TrickShotJudge.verdict(for:attempt:)`. `next()` walks `TrickShots.all`; a shot not in that list opens the list.
  `markDone` puts the id into `doneIDs`, stored comma-joined under "trickShotsDone", read by the menu's made count
  (TitleScreen.trickMark) and by `HighlightOffer.mayLinkTrick`.
- **The trick-shot types** (App/TrickShots.swift). `TrickShot` is a plain struct: id, number, title, hook, goalLine,
  setup (`.layout([Vec2])` or `.rack(seed:)`), solution (`TrickSettings`: aim degrees, power, tipUp, tipSide, optional
  elevation sine), goal (`TrickGoal`: drops of ball and optional pocket, cueZone, firstHit, secondHit, bank, side),
  usesBridge, idea, maths, difficulty, window (`TrickWindow`, half-widths either way), praise, pending, and the trailing
  defaulted `cueAngles`. Lessons build TrickShot values with the memberwise initialiser, so a new trailing field with a
  default changes no existing call.
- **The judge** (App/TrickShotJudge.swift). `failure(_ goal:, _ attempt:)` checks, in order: the side rule, the first
  ball touched, a carom's second ball, every drop with `pocket(of:in:)` (the first pocket event of that ball; order
  never matters), the bank (any rail cushion of that ball before it dropped), a scratch, the cue zone. `verdict` gives
  the praise on a make, else one line of advice ranked by how far each setting is from `shot.solution`, measured in
  `shot.window`; it adds the cue-angle line when the solution raises the cue. The judge needs nothing authored beyond a
  TrickShot value, so a player's own challenge is judged with zero new judging code.
- **The Lens replay's held moments** (App/TrickSignature.swift). `events(forTrick:in:captions:)` switches on the
  authored ids; the `default` case returns an empty list before the first-contact fallback is reached, so an unknown id
  gets a replay with no headline moments. `ShotMoments` (App/ShotHighlightJudge.swift) has the pieces: `firstContact`,
  `pocket(of:)`, `railAfterLastContact(of:)`, `signature(_:)` (keeps at most two captioned events).
- **The attempt** (App/ShotAttempt.swift). Every free-play shot is recorded by `ShowpieceModel.finishStrike` as a
  `ShotAttempt`: `start` (sixteen positions), `timeline`, the chosen `aim`, `power`, `tipUp`, `tipSide`, `elevation`,
  the `seed`, the effective `input` (a `ShotInput` with the player's stroke drift already applied, built with default
  `PoolParameters`, before the table and surface are written in), and the `surface`, `table` and `generation` it was
  solved on. `facts`, `firstStruck`, `cueBallScratched`, `pocketedObjectBalls`, `motionHash` are read from it.
  Note: `pocketedObjectBalls` reads `pocketTime`, which is also set for a ball that flew off the table; pocket events
  are the right source for "which pocket".
  Three traps, read in `ShowpieceModel.shootNow` (around line 874) and `App/Stroke/CueProfile.swift`:
  - `attempt.power` is the player's `shotPower`, the swing in house-cue units. The launch speed is
    `cueInHand.launchSpeed(forPower:)`, and in free play `cueChoice` picks the jump cue (cue raised to sine 0.5 or
    more) or the masse cue (raised past 20 degrees with side), whose launch speed differs from the power. Trick mode
    always uses the house cue (`cueChoice` returns `.standard` while `authoredModeUp`), where power IS the launch
    speed. So the chosen power is the wrong answer for a raised free-play stroke; `input.strike.speed` is right.
  - `attempt.aim`, `tipUp`, `tipSide` are the chosen settings; the stroke's drift (`StrokeDelivery.apply`) turns the
    direction and moves the side in `input.strike`. The struck values are the honest answer.
  - `attempt.seed` is the serial seed `shootNow` worked out; when a kept strike replaces the input, the attempt keeps
    that serial seed while `attempt.input.seed` is the kept input's. Only `input.seed` drives the solve.
- **`CueStrike`'s init normalises `direction` again** (Packages/BreakdownCore/Sources/BreakdownPhysics/Parameters.swift);
  dividing a unit vector by its computed length can move the last bit, so a stroke rebuilt through the init is not
  bit-for-bit the saved one. Rebuild through the init, then assign `strike.direction` the saved components directly
  (the property is `public var`).
- **Actor isolation.** The project is Swift 6.0 with no default actor isolation set (no
  `SWIFT_DEFAULT_ACTOR_ISOLATION` in the project file), so a plain enum or struct (TrickShotJudge, TrickSignature,
  ShotMoments, TrickPath) is nonisolated; ShowpieceModel, TrickShotMode, TrickPathCache, ShotNarration and GoalMarks
  are `@MainActor`. TrickSignature is called only from TrickShotMode, but is itself nonisolated.
- **Nothing in the physics package is Codable except `Vec2`.** `ShotInput`, `CueStrike`, `PoolParameters` and
  `Timeline` are `Sendable` only, and `ShotAttempt` is a plain struct holding a Timeline. A saved challenge therefore
  cannot encode an attempt or a recording. It stores plain numbers (start positions, the strike's direction, speed,
  tip, elevation and seed, the goal as integers) and rebuilds the input with `NextShot.shot(...)`, solved through
  `ShowpieceModel.solverCopy(_:table:surface:generation:)`, which is `nonisolated static` and pure.
- **An exact strike can already be fed to Shoot.** `ShowpieceModel.keptStrike` (internal, `@ObservationIgnored`, type
  `KeptStrike(input:delivery:controls:)`, memberwise init) replaces the built input in `shootNow()` when
  `keptStrike.controls == controlValues` and `pendingStroke == nil`; `loadTrickLayout` clears it (through
  `clearAttempts`). The what-if's Keep uses this. Watch it for a saved shot can use it with no model change.
- **Free play's surface and table versus trick mode.** `physicsTable` returns `.standard` whenever `onPoolTableOnly`
  (which includes `authoredModeUp`, true while `trickMode.current` is set), so a trick shot is always solved on the pool
  table. `physicsSurface` is always the chosen `surface`; trick shots already honour the Surface menu. `TableStage`
  rebuilds the table whenever `model.solvedTable` changes, so a solve on another table redraws it. In authored modes
  `strikeElevation` is the player's own angle (no automatic raise to clear a ball under the cue, which free play adds),
  and `activeModelGeneration` is the default generation. LessonMode and EightBallMode each keep a `surfaceBefore` and
  put the player's own surface back in `end()`; TrickShotMode keeps none (trick shots honour the Surface menu).
- **The notebook's dossier** (App/NotebookInfo.swift `NotebookDossier.trick`) shows "How forgiving" from
  `shot.window` at any phase but explaining, on iPad, Mac and the open Duo.
- **No system alerts anywhere in App/.** There is no `.alert(` or `.confirmationDialog(` in the app. Names are edited in
  place (App/Match/MatchViews.swift `PlayerNamesEditor`: "no sheet, so it works as part of the notebook panel on the
  open Duo") and the match's End confirmation lives in its card (`MatchMode.confirmingEnd`). A system alert is centred
  on the whole window, so on the open Duo it would cover the table's half.
- **`CardButtonRow`** (App/Match/MatchViews.swift) is a `ViewThatFits` of an HStack and a WrappingRow holding the same
  content, so every button in it is built twice; a `.sensoryFeedback` inside would be built twice too.
- **The worth-watching card** (App/FreePlayViews.swift `HighlightCard`, App/FreePlayPhoneBlurbs.swift
  `HighlightPhoneBlurb`, model `highlightCard`). Shown in free play after a remarkable shot at rest, under
  `HighlightOffer`'s frequency rule; gone at the first touch of aim, power, spin or cue angle. Buttons: Try the trick
  shot (sometimes), Watch it in the Lens, Close. The phone blurb draws at most two buttons (`Blurb` takes
  `buttons.prefix(2)`); its Watch it is the strip's primary action.
- **Shot options** (App/ShotPanel.swift `ShotOptionsItems`). One view shared by the shot panel's More menu on every
  layout and the upright phone's Shot options menu; in plain free play it offers Move cue ball, Undo last shot, the rack
  and Re-rack.
- **The trick-shot list** (App/TrickShotViews.swift `TrickShotList`). A NavigationStack with one List Section of the
  authored shots, each row with `TrickPathThumb` from `TrickPathCache` (solved once per run when the list first
  appears). It is a sheet on the phone and a notebook page (`inlinePages`) on iPad, Mac and the open Duo.
  `GoalMarks.draw` rings goal pockets with `table.pockets[k]`, which holds only the six edge pockets; a bed hole
  (pocket 6 and up on bar billiards and bumper pool) is skipped today. `TableSpec.holeCenter(pocket:)` covers both.
- **Path drawings.** `TrickPath.traced(_ tl:, start:)` (App/TrickPathThumb.swift) is `nonisolated static` and turns any
  recording into the drawing's data; the table size comes from the recording.
- **Words already in the catalog to reuse:** "the %lld" (MatchWords.balls), `TableGameWords.ball(_:kind:)` for the small
  tables, `TableWords.holePhrase(_:table:kind:)` ("the foot-left corner pocket", a bed hole by its name),
  `HighlightWords.title` and `line`, `PlaySurface.title`, `TableKind.title`, `TrickDifficulty.label`, "Close", "Cancel",
  "Made it!". Lists join with `.formatted(.list(type: .and).locale(AppLocale.numbers))`.
- **Saving to disk.** MatchMode writes JSON to Application Support/Breakdown/ with `.atomic` and logs a failure; the same
  pattern serves here.
- **Controller** (App/ControllerInput.swift). A, B, X, Y, menu, d-pad, shoulders, options and right stick click are
  used; the left stick click is free. The mapping is published in words for How to play.
- **The project file.** `App` and `BreakdownTests` are file-system synchronised root groups
  (`PBXFileSystemSynchronizedRootGroup`); any new .swift file in either folder joins its target with no project edit.
  The only exceptions are the two README.md files. So the build touches no project file.
- **Translations.** Twelve languages: en (source), ar, de, es, fr, it, ja, ko, pt, pt-BR, ru, zh-Hans.
  scripts/localization-merge.py merges `{"translations": [{"culture", "key", "text"}]}` into App/Localizable.xcstrings,
  checks placeholders, and with `--keys <plain JSON list>` adds every English key and reports gaps. It writes simple
  string units only, so the new words avoid plural forms. A `String(localized:)` with two string interpolations gets
  the key `%@ into %@` (never `%1$@ ...`); translations may use `%1$@` / `%2$@` to reorder (the catalog's own
  `%@ (%@)` entry is translated as `%1$@ (%2$@)`).
- **Tests.** `ModelFlowTests.prepareDevice` and `restoreDevice` are `private`; a new test file copies what it needs.
  `TestShots.attempt(start:timeline:_:)` rebuilds the input with seed 1 and the surface's numbers written in, so it is
  not the input a free-play stroke keeps.
- **The other four plans.** The achievements plan lists TrickShotMode under "Not touched" and reads
  `trickMode.doneIDs`; it does not edit `markDone`. The clips plan adds a button to HighlightCard's CardButtonRow, a
  blurb and items to FreePlayPhoneBlurbs, items at the end of MacChrome's `playbackItems` (Shift-Command-E) and a hook
  in ControllerInput's `pressCardButton`. The every-world plan adds a "step aside while it shows" gate to
  HighlightCard, HighlightPhoneBlurb and the trick card, a Shift-Command-E item to MacChrome and a block in
  ControllerInput's `press`.

## The design

### Decisions

1. **What can be saved.** A free-play shot (not a break) that is the recording on screen, at rest, struck with the pool
   cue ball (ball 0), on the default physics generation, that dropped at least one object ball into a pocket or bed
   hole, and in which the cue ball did not drop. On any table with holes: the pool table, bumper pool, bar billiards
   (five-pin has no holes, so nothing there qualifies). A shot already saved shows Play it now instead. The shelf holds
   at most 60 shots; when full the button is disabled and its hint says to delete one.
   Breaks are out (a break scatters fifteen balls; the same balls in the same pockets again is a lottery, not a shot).
2. **The goal.** Built from the recording, never from the player's intent:
   - `drops`: every object ball with a pocket event, each with that pocket (pocket-strict, any order).
   - `firstHit`: the first object ball the cue ball touched (`attempt.firstStruck`).
   - `bank`: the first dropped ball that came off a rail cushion after its last ball contact
     (`ShotMoments.railAfterLastContact(of:)`, captions not needed for this), else nil. A ball that merely rolled along
     the rail into the pocket before it was ever struck does not count, which is fairer than the judge's own weaker
     test; the original always passes the judge's test.
   - No cue zone, no side rule, no second hit.
   The judge's `failure` alone decides made or missed. The cue-angle line in its advice applies only when the saved
   stroke raised the cue, which is right: that stroke is the hint.
3. **The proof.** The exact effective strike is kept (drift included) with its seed. Watch it strikes exactly that
   (through `keptStrike`), so on the same build it plays out identically. When the shelf first opens in a run, each
   saved shot is solved once in the background: the drawing is made from that solve, and the goal is checked. If an
   update to the physics means the saved stroke no longer makes it, the row and the card say so plainly; the shot stays
   playable (never hidden).
4. **The settings shown as the answer.** `solution` is the stroke as it was actually struck, read from
   `input.strike`: aim in degrees from its direction (`atan2(y, x) * 180 / pi`, the model's own convention: `aimAtNearestBall` and the pointer aim
   set `aimDegrees` exactly so, in -180 to 180), power =
   its launch speed (`speed`, which with trick mode's house cue is exactly the power setting that launches the same),
   tip up, tip side (drift included), and elevation (which includes free play's automatic raise to clear a ball under
   the cue; nil when 0). Not the chosen settings: a raised free-play stroke may have used the jump or masse cue, whose
   launch speed is not its power, and the stroke's drift turned the aim and moved the side, so the chosen settings
   struck clean in trick mode would be a different shot. Advice compares the try with these; the window (Decision 5)
   is measured in the same units.
5. **How forgiving, and the difficulty.** When the shot is saved, and again when it is first played on a new build,
   a background task measures the window (never for the whole shelf at once): each of
   aim, power, tip up and side is pushed either way from the saved strike until the goal fails (doubling, then four
   halvings), and the smaller side is kept. The window is stored with the app build it was measured on and measured
   again on a new build. Until measured, a fallback window is used (aim 0.5 degrees, power 0.5 m/s, tip up 5 mm,
   side 3 mm). Difficulty from the aim window: at least 0.7 degrees Easy, at least 0.3 Medium, else Hard (the authored
   windows run from 0.10 to 1.56; unmeasured shows Medium). The fallback only steers the judge's advice: the notebook's
   How forgiving block is not shown for a saved shot whose TrickShot was built with the fallback (hook N1), so no
   made-up number is shown as a measurement.
6. **Surface and table.** A saved shot carries its table into trick mode through a new `TrickShot.table` field and one
   line in `physicsTable`. The surface is set through the model's ordinary `setSurface` when the shot begins (a call,
   not an edit; the same-shot-on-every-surface builder may change setSurface's insides, which is fine). The Surface menu
   then ticks the right cloth, and the player can change it as they can for any trick shot; on another cloth the saved
   stroke may miss, which is honest physics. The surface stays chosen after the shot, like any Surface menu choice.
   Coordinator note: this differs from LessonMode and EightBallMode, which keep a `surfaceBefore` and put the
   player's surface back in `end()`. Kept as planned (one fewer hook in TrickShotMode, and the menu shows the change);
   if the Boss finds it surprising, the fix is a `surfaceBefore` on the shelf, set after `begin` in `play`, and a
   one-line restore at the top of `TrickShotMode.end()` and of `begin` for a non-saved shot.
7. **Where it lives.** A second section, Your shots, at the end of the Trick shots list (sheet on the phone, notebook page
   on iPad, Mac and the open Duo). No new main-menu row: the Trick shots row already leads there. An empty shelf still
   shows its section with one line saying how to fill it.
8. **Made state is kept apart from the authored progress.** Saved shots have ids "own-" plus a UUID (no commas). Their
   makes are recorded on the shelf, never in `doneIDs`, so the menu's made count, the highlight card's trick link and the
   achievements builder's reading of `doneIDs` see only authored shots.
9. **Names.** The default name is the highlight's title when the shot was a remarkable kind the goal really asks for
   (`HighlightWords.title`, "A bank shot"), else "Saved shot" with the next number. The kinds about the cue ball's
   finish or a ball that did not drop (`.stopDead`, `.drawBack`, `.rimSkip`), and `.breakShot` and `.redPinAlone`
   (never saveable), get the plain name and the plain idea line, since the goal does not ask for a stop, a draw or a
   rim skip; `kindRaw` is stored as nil for them. Rename takes up to 40 characters; an empty name keeps the old.
   Names are the player's own words and are shown verbatim (never looked up in the catalog).
10. **After saving.** The button turns into Play it now (it begins the shot at once, leaving free play's rack as every
    route into trick shots does); VoiceOver hears "Saved to Your shots, in Trick shots." No sound and no haptic (the
    button sits in CardButtonRow, which builds its content twice, so a haptic there could fire twice; the button's
    change of words is the feedback).

### Phone upright

- The worth-watching blurb (`HighlightPhoneBlurb`): its two small buttons become, in priority order, Make it again (or
  Play it now once saved) when the shot can be saved, then Try the trick shot when offered, then Close. With both Make it
  again and Try the trick shot, Close is not drawn (two at most); the blurb still goes at the first touch of aim, power,
  spin or cue angle, as today. Watch it stays the strip's white primary action.
- Shot options (the aiming panel's menu): Make it again / Play it now after Undo last shot, for every saveable shot,
  remarkable or not.
- The challenge itself uses the trick shot's existing phone views (TrickPhoneBlurbs, PhonePrimaryAction.trick, the title
  row's name and idea): small blurbs sized to their text, the centre left to the table. The shelf is part of the Trick
  shots sheet.

### Phone sideways

- The side column hosts PlayCards, so `HighlightCard` shows Make it again there; the shot panel's More menu has the
  item. The challenge uses TrickShotCard in the column.

### Open Duo

- The table stays alone on its half. The highlight card, the trick card, and the Trick shots page with Your shots are on
  the words half (DuoPanel and the notebook pages, unchanged hosts). Rename and Delete happen inside the row itself
  (a name field in place, or the delete question with its two buttons in place), never as a system alert, which would
  be centred on the whole window and cover the table. This is the app's own way (the match card's name editor).

### iPad and Mac

- `HighlightCard` in the notebook carries the button; the shot panel's More menu has the item.
- Mac (and iPad with a keyboard): Playback menu gains "Make It Again" (Shift-Command-S), after Watch It in the Lens,
  enabled when the shot on screen can be saved; once saved the item reads "Play It Now".
- The list page gives each row a context menu (Rename, Delete) as well as its trailing options button; both open the
  same in-row editor or question as everywhere else.

### VoiceOver, controller, one finger

- Every new control is a labelled button with a hint. Each shelf row is one element whose label reads the name, the goal
  in words, made or not, and the cloth and table when not the defaults, with custom actions Rename and Delete.
- The goal line names every pocket in words, so nothing depends on seeing the rings.
- Controller: the left stick click saves the shot on screen (and does nothing when it cannot be saved); the mapping
  lists it. On the list page the system's controller focus reaches each row and its options button. The challenge card's
  A button already works (it presses TrickShotCard's prominent button through the trick mode).
- One finger: every action is one tap; nothing is dragged or held.

## Build steps

New files first, then the hook points. Every file gets the standard header (Author: Claude Opus 5.5 High; Date;
PURPOSE; SRP/DRY check), and every edited file gets an "Edited:" line at the top of its header naming 0.7.7 make it
again and this plan.

### New files

**1. App/OwnShot.swift** - the saved challenge as data, and turning an attempt into one. No views, no model access.

```swift
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation

/// This run's check of a saved stroke (never stored: a new build may change it).
enum OwnShotCheck: Equatable, Sendable { case checking, holds, changed }

/// One ball the challenge needs down, and the hole it went into (edge pocket 0-5, bed hole 6+j).
struct OwnDrop: Codable, Equatable, Sendable { let ball: Int; let pocket: Int }

/// The exact strike, as the solver took it (the stroke's drift already in it): a.input.strike and a.input.seed.
struct OwnStrike: Codable, Equatable, Sendable {
    let directionX: Double, directionY: Double, speed: Double, tipUp: Double, tipSide: Double, elevation: Double
    let seed: UInt64
}
// (No separate "chosen settings" type: the answer is the struck stroke, Decision 4.)

/// How far each setting can move either way and the shot still works, and the build it was measured on.
struct OwnWindow: Codable, Equatable, Sendable {
    let aim: Double, power: Double, tipUp: Double, tipSide: Double
    let build: String
    static let fallback = OwnWindow(aim: 0.5, power: 0.5, tipUp: 0.005, tipSide: 0.003, build: "")
}

struct OwnShot: Codable, Identifiable, Equatable, Sendable {
    static let idPrefix = "own-"
    static func isOwnID(_ id: String) -> Bool { id.hasPrefix(idPrefix) }

    let id: String                 // idPrefix + UUID().uuidString
    var name: String
    let saved: Date
    let tableRaw: String           // TableKind.rawValue
    let surfaceRaw: String         // PlaySurface.rawValue
    let generation: Int
    let start: [Vec2]              // sixteen
    let strike: OwnStrike
    let drops: [OwnDrop]
    let firstHit: Int?
    let bank: Int?
    let kindRaw: String?           // HighlightKind.rawValue when the shot was a named kind (Decision 9), else nil
    let motionHash: String         // String(attempt.motionHash, radix: 16): the save's fingerprint
    var window: OwnWindow?
    var made: Bool                 // false on save; written every time (no default: synthesised decoding needs the key)

    var table: TableKind? { TableKind(rawValue: tableRaw) }
    var surface: PlaySurface? { PlaySurface(rawValue: surfaceRaw) }
    var kind: HighlightKind? { kindRaw.flatMap(HighlightKind.init(rawValue:)) }

    /// The input as built (default PoolParameters, as ShowpieceModel.shootNow builds it), ball 0 struck, bit for bit:
    ///   var i = NextShot.shot(from: start, direction: Vec2(strike.directionX, strike.directionY), speed: strike.speed,
    ///                         tipUp: strike.tipUp, tipSide: strike.tipSide, seed: strike.seed,
    ///                         parameters: PoolParameters(), elevation: strike.elevation, ballIndex: 0)
    ///   i.strike.direction = Vec2(strike.directionX, strike.directionY)   // CueStrike's init normalised it again
    ///   return i
    var input: ShotInput { ... }

    /// The answer (Decision 4): the struck stroke in the controls' units.
    ///   TrickSettings(aim: atan2(strike.directionY, strike.directionX) * 180 / .pi, power: strike.speed,
    ///                 tipUp: strike.tipUp, tipSide: strike.tipSide,
    ///                 elevation: strike.elevation > 0 ? strike.elevation : nil)
    var solution: TrickSettings { ... }

    /// The goal the judge checks.
    var goal: TrickGoal { TrickGoal(drops: drops.map { TrickDrop(ball: $0.ball, pocket: $0.pocket) },
                                    firstHit: firstHit, bank: bank) }

    /// Why an attempt cannot be saved, or nil when it can.
    enum Refusal: Equatable { case isBreak, otherCueBall, otherPhysics, cueBallDropped, nothingDropped, unknownTable }
    static func refusal(for a: ShotAttempt) -> Refusal?
    //   a.isBreak -> .isBreak; a.cueBall != 0 -> .otherCueBall;
    //   a.generation != PoolParameters().modelGeneration -> .otherPhysics;
    //   TrickShotJudge.pocket(of: a.cueBall, in: a.timeline) != nil || a.cueBallScratched -> .cueBallDropped;
    //   drops(of: a).isEmpty -> .nothingDropped.
    //   (The table needs no check: five-pin has no holes, so it always gives .nothingDropped. .unknownTable is kept for
    //   a table or surface whose raw value does not round-trip, which make() also refuses.)

    /// Object balls with a pocket event, in the order they dropped, each with its pocket.
    static func drops(of a: ShotAttempt) -> [OwnDrop]
    //   for each pocket event e in a.timeline.events, in order (they are in clock order), where e.kind == .pocket,
    //   let b = e.balls.first?.ball, b != a.cueBall, NextShot.isOnTable(a.start[b]), b not already listed, and
    //   e.pocket is non-nil: OwnDrop(ball: b, pocket: e.pocket!). (The first pocket event of a ball is the one
    //   TrickShotJudge.pocket(of:in:) reads, so the judge sees the same pocket.)

    /// The first dropped ball that came off a rail after its last ball contact (a real bank), or nil.
    static func bankedBall(in a: ShotAttempt, drops: [OwnDrop]) -> Int?
    //   let m = ShotMoments(timeline: a.timeline, captions: [])
    //   drops.first { d in m.railAfterLastContact(of: d.ball) != nil }?.ball
    //   (Checked: ShotMoments' finders read events only; captions are used by signature(_:) alone.)

    /// The challenge made from an attempt that passed `refusal`. `kind` is the highlight judged on it (or nil);
    /// `number` is the shelf's count plus one, for the default name; `now` is the save time.
    static func make(from a: ShotAttempt, kind: HighlightKind?, number: Int, now: Date = Date()) -> OwnShot?
    //   nil when refusal(for:) != nil.
    //   strike: every field from a.input.strike (direction.x, direction.y, speed, tipUp, tipSide, elevation) and
    //   seed from a.input.seed (NOT a.seed: see What exists today).
    //   kindRaw: kind?.rawValue, except nil for .stopDead, .drawBack, .rimSkip, .breakShot, .redPinAlone (Decision 9).
    //   name: OwnShotWords.defaultName(kind: <that filtered kind>, number: number). made: false. window: nil.
    //   motionHash: String(a.motionHash, radix: 16). id: idPrefix + UUID().uuidString.

    /// The TrickShot the trick mode plays. Nil when the table or surface raw value is not known to this build.
    var trickShot: TrickShot? { ... }
    //   TrickShot(id: id, number: 0, title: name, hook: OwnShotWords.hook(self), goalLine: OwnShotWords.goalLine(self),
    //             setup: .layout(start), solution: solution,
    //             goal: goal, usesBridge: false, idea: OwnShotWords.idea(self), maths: nil, mathsSpoken: nil,
    //             difficulty: OwnShot.difficulty(window), window: TrickWindow(aim:, power:, tipUp:, tipSide:) from
    //             window ?? .fallback, praise: OwnShotWords.praise, pending: false, cueAngles: nil, table: table)

    static func difficulty(_ w: OwnWindow?) -> TrickDifficulty
    //   nil -> .medium; aim >= 0.7 -> .easy; aim >= 0.3 -> .medium; else .hard.
}
```

TableKind and PlaySurface are stored as raw strings so nothing has to add Codable to them. The format number lives on the
file (step 3), not on each shot.

**2. App/OwnShotProof.swift** - solving a saved shot, checking it, measuring its window, and arming Watch it. Pure and
`nonisolated` except `arm`.

```swift
enum OwnShotProof {
    /// The saved strike solved on its own table, surface and generation, exactly as the model would.
    nonisolated static func solve(_ own: OwnShot, input: ShotInput? = nil) -> Timeline?
    //   guard let table = own.table, let surface = own.surface
    //   PoolSolver.simulate(ShowpieceModel.solverCopy(input ?? own.input, table: table, surface: surface,
    //                                                 generation: own.generation))

    /// The attempt the model would record for that solve (for the judge).
    nonisolated static func attempt(_ own: OwnShot, input: ShotInput, timeline: Timeline) -> ShotAttempt
    //   let s = own.solution
    //   ShotAttempt(isBreak: false, breakSeed: 0, start: own.start, timeline: timeline, aim: s.aim,
    //               power: s.power, powerRange: PlayerShotSpeed.ordinary, tipUp: s.tipUp,
    //               tipSide: s.tipSide, elevation: s.elevation ?? 0, seed: input.seed, input: input,
    //               surface: own.surface ?? .cloth, table: own.table ?? .standard, generation: own.generation)
    //   (The judge reads only the recording here: goal.side is nil for a saved shot.)

    /// True when the saved strike still meets the goal (TrickShotJudge.failure is nil).
    nonisolated static func holds(_ own: OwnShot) -> Bool

    /// The same, also giving the solve, so one solve feeds the check and the drawing.
    nonisolated static func check(_ own: OwnShot) -> (holds: Bool, timeline: Timeline?)

    /// The window, measured as Decision 5 says. `build` is Bundle.main's CFBundleVersion (passed in, so tests can
    /// pass a fixed string).
    nonisolated static func measureWindow(_ own: OwnShot, build: String) -> OwnWindow
    //   For each control c in [aim, power, tipUp, tipSide] and sign s in [+1, -1]:
    //     first step: aim 0.05 deg, power 0.05 m/s, tipUp 0.0005 m, tipSide 0.0005 m
    //     cap:        aim 4 deg,   power 3 m/s,    tipUp 0.02 m,   tipSide 0.012 m
    //     d = step; pass = 0
    //     while d <= cap && passes(perturbed(c, s * d)): pass = d; d *= 2
    //     if d <= cap: bisect between pass and d four times (mid passes -> pass = mid, else d = mid)
    //     half(c, s) = pass > 0 ? pass : step / 2
    //   window value for c = min(half(c, +1), half(c, -1)).
    //   perturbed: aim rotates the strike direction by the angle (degrees to radians, rotate the unit vector);
    //   power adds to speed, never below 0.1; tipUp and tipSide add, clamped to +-0.8 * the table's ball radius
    //   (own.table!.parameters.ballRadius). Everything else in the input is unchanged (seed, positions, elevation).
    //   passes: solve(own, input: perturbed) then TrickShotJudge.failure(own.goal, attempt(...)) == nil.
    //   At most about 90 solves. Called only off the main actor.

    /// Watch it for a saved shot: arm the exact strike so the next shootNow plays it. Does nothing for an authored
    /// shot. Called by TrickShotMode.watch() right before model.shootNow(), after loadStart has put the solution in
    /// the controls (so the controls match the kept ones).
    @MainActor static func arm(_ shot: TrickShot, model: ShowpieceModel)
    //   guard OwnShot.isOwnID(shot.id), let own = OwnShotShelf.shared.shot(id: shot.id) else { return }
    //   model.pendingStroke = nil
    //   model.keptStrike = ShowpieceModel.KeptStrike(input: own.input, delivery: nil, controls: model.controlValues)
    //   (shootNow then strikes own.input exactly. The attempt it records keeps shootNow's own serial seed in
    //   `seed`; `input.seed` is the saved one, and it alone drives the solve.)
}

/// Plain (nonisolated) like TrickSignature, which calls it: it reads only the recording, never the shelf, so there is
/// no actor hop and no shared mirror to keep in step.
enum OwnShotSignature {
    /// The held moments of a saved shot's Lens replay: the cue ball's first contact, then, for the last object ball to
    /// drop in this recording, its cushion after its last contact when it banked, else its pocket. Empty for an id that
    /// is not a saved shot's. Called from TrickSignature's default case.
    static func events(forOwn id: String, in timeline: Timeline, captions: [Caption]) -> [Int]
    //   guard OwnShot.isOwnID(id) else { return [] }
    //   let m = ShotMoments(timeline: timeline, captions: captions)
    //   let first = m.firstContact(of: 0)
    //   let lastDrop = timeline.events.indices.last { timeline.events[$0].kind == .pocket
    //                                                 && timeline.events[$0].balls.first?.ball != 0 }
    //   let ball = lastDrop.flatMap { timeline.events[$0].balls.first?.ball }
    //   let second = ball.flatMap { m.railAfterLastContact(of: $0) } ?? lastDrop
    //   let found = m.signature([first, second]); return found.isEmpty ? m.signature([first]) : found
}
```

**3. App/OwnShotShelf.swift** - the shelf: storage, the save action, the checks, and starting a shot.

```swift
@MainActor
@Observable
final class OwnShotShelf {
    /// The app's shelf. A var (main-actor isolated, as the class is) only so tests can swap in a memory shelf and put
    /// this one back; nothing in the app assigns it.
    static var shared = OwnShotShelf(fileURL: OwnShotShelf.defaultURL)
    static let capacity = 60

    /// Saved shots, oldest first (the list shows them newest first).
    private(set) var shots: [OwnShot] = []
    // The check's state is OwnShotCheck (top level in OwnShot.swift, so the nonisolated words can name it).
    /// This run's check of each shot (not stored: a new build may change it).
    private(set) var proof: [String: OwnShotCheck] = [:]
    /// This run's drawing of each shot's saved stroke.
    private(set) var paths: [String: TrickPath] = [:]
    @ObservationIgnored private let fileURL: URL?
    @ObservationIgnored private var checksStarted = false

    /// nil keeps everything in memory (tests).
    init(fileURL: URL?)   // loads the file if there is one
    static var defaultURL: URL?   // Application Support/Breakdown/own-shots.json (MatchMode's folder)

    func shot(id: String) -> OwnShot?
    func trickShot(id: String) -> TrickShot?   // shot(id:)?.trickShot

    // MARK: Saving
    /// True when the shot on screen can be saved now (Decision 1) and is not saved yet and the shelf has room.
    func canSave(_ model: ShowpieceModel) -> Bool
    /// The saved shot that the attempt on screen already is, if any (same start, same seed, same motion hash).
    func savedShot(for model: ShowpieceModel) -> OwnShot?
    /// True when the shot on screen is one that could be saved but the shelf is full.
    func isFull(for model: ShowpieceModel) -> Bool
    /// Save the shot on screen. Returns the new shot or nil. Starts its check and window in the background.
    @discardableResult func save(from model: ShowpieceModel) -> OwnShot?
    /// Put a made shot on the shelf (nil when full): append, proof .checking, write, start its check. save(from:)
    /// ends with it; tests use it directly.
    @discardableResult func add(_ own: OwnShot) -> Bool
    /// True for a saved shot's TrickShot built before its window was measured (its window is the fallback): the
    /// notebook's How forgiving block is not shown for it (hook N1).
    func isUnmeasured(_ shot: TrickShot) -> Bool
    //   OwnShot.isOwnID(shot.id) && shot.window == TrickWindow(aim: f.aim, power: f.power, tipUp: f.tipUp,
    //   tipSide: f.tipSide) where f = OwnWindow.fallback

    // MARK: The shelf
    func rename(id: String, to name: String)   // trimmed, at most 40 characters, empty keeps the old name; writes
    func delete(id: String)                    // removes, drops its proof and path, writes
    func noteMade(id: String)                  // made = true, writes (called by TrickShotMode.markDone's hook)
    /// The shot after this one in the list's order (newest first), or nil after the last.
    func next(after id: String) -> OwnShot?
    /// Put a saved shot on the table in trick mode, on its own cloth (Decision 6).
    func play(_ own: OwnShot, model: ShowpieceModel)
    //   guard let shot = own.trickShot, let surface = own.surface else { return }
    //   model.trickMode.begin(shot)
    //   if model.surface != surface { model.setSurface(surface) }   // after begin: the table is still, nothing re-solves
    //   measureIfDue(own.id)
    //   (begin is TrickShotMode's own; it refuses nothing here, since a saved shot is never `pending`.)

    /// The checks and drawings, once per run, when the list first appears; a saved shot's own check starts on save.
    func startChecks()
}
```

Rules inside:

- `canSave(model)`: `model.freePlayUp` (hook M2) and `model.playerShotOnScreen` and `model.aimReady` and
  `!model.isSolving` and `!model.menuOpen` and `!model.replayingBest`, `let a = model.currentAttempt`,
  `OwnShot.refusal(for: a) == nil`, `savedShot(for:) == nil`, `shots.count < capacity`.
- `savedShot(for:)`: the shot whose `strike.seed == a.input.seed` (not `a.seed`, which after a kept strike is the
  serial seed) and `start == a.start`, and only for a shot passing both, `motionHash == String(a.motionHash, radix:
  16)`. The cheap checks come first because views and the Mac menu read this on every evaluation, and `motionHash`
  walks the whole recording.
- `save(from:)`: guard `canSave`; `kind` = `ShotHighlightJudge.judge(timeline: a.timeline, facts: a.facts, captions:
  model.captions, table: a.table, isBreak: false)?.kind` (the captions are the on-screen recording's, guaranteed by
  `playerShotOnScreen`); `OwnShot.make(from: a, kind:, number: shots.count + 1)`; `add(own)`;
  `ShotNarration.announce(OwnShotWords.savedAnnouncement)`. (`add` starts the check; the check's completion starts the
  window.)
- `check(id)` (private): in `Task.detached(priority: .utility)` run `OwnShotProof.check(own)` and, from its timeline,
  `TrickPath.traced(timeline, start: own.start)` (both nonisolated; the tracing samples the whole recording, so it
  stays off the main actor too), returning `(Bool, TrickPath?)`; back on the main actor, if the shot is still on the
  shelf, set `proof[id]` to `.holds` or `.changed` and `paths[id]`. One solve per shot; this is all the list needs.
- `measureIfDue(id)` (private), LAZY: called from `check(id)`'s completion when the shot was saved in this run and
  its proof came back `.holds` (so a fresh save is measured once its check is back, never while it is still
  `.checking`), and by `play(_:model:)` when a shot is played. When the shot's proof holds and
  `own.window?.build != currentBuild`, and no measurement of it is already running, run
  `OwnShotProof.measureWindow(own, build: currentBuild)` detached and store it on the shot (by id; the shot may have
  been deleted meanwhile, then drop it) and `write()`. Never from `startChecks()`, so a new build with a full shelf
  does not queue thousands of solves; until measured a shot uses `OwnWindow.fallback` and shows Medium. A shot played
  before its window arrives keeps the fallback for that visit (the TrickShot is built at `begin`).
  `currentBuild` = `Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""`.
- `startChecks()`: once per run; for every shot whose `proof[id]` is nil, `check(id)` one after another (a serial loop in
  one Task, as TrickPathCache does).
- File: `struct File: Codable { var format: Int; var shots: [OwnShot] }`, format 1. `write()` creates the folder and
  writes JSON `.atomic`; on failure NSLog and carry on (not fatal, as MatchMode). `load()` on init: missing file means
  empty; a file that will not decode, or a newer format, is moved aside to `own-shots-unreadable.json` (NSLog) and the
  shelf starts empty, so a later write never destroys it. Shots whose table or surface raw value is unknown are kept in
  the file and listed with a line saying this version cannot play them (never hidden). A shelf made with
  `fileURL: nil` never reads or writes a file.

**4. App/OwnShotWords.swift** - every word of the feature, in one place. All through `String(localized:comment:)` with
a translator comment; nothing glued from halves of a sentence. Imports Foundation, BreakdownRules (MatchKind, for
`TableGameWords.ball(_:kind:)`) and BreakdownTimeline (TableSpec, for `TableWords.holePhrase`).

```swift
enum OwnShotWords {
    static var makeItAgain: String            // "Make it again"
    static var playItNow: String              // "Play it now"
    static var makeItAgainMac: String         // "Make It Again"   (Mac menu, title case)
    static var playItNowMac: String           // "Play It Now"
    static var saveHint: String               // "Saves the balls as they stood before this shot as a challenge of your own, in Trick shots."
    static var playHint: String               // "Sets up your saved shot so you can make it again."
    static var fullHint: String               // "Your shots is full. Delete one in Trick shots to save another."
    static var savedAnnouncement: String      // "Saved to Your shots, in Trick shots."
    static var shelfTitle: String             // "Your shots"
    static var emptyFooter: String            // "After a shot that drops a ball, Make it again keeps it here as a challenge of your own."
    static var footer: String                 // "The game kept your stroke, so Watch it plays the way it went."
    static var madeAgain: String              // "Made again"
    static var notMadeYet: String             // "Not made again yet"
    static var checking: String               // "Checking the saved stroke…"
    static var changed: String                // "The saved stroke no longer makes it in this version. The shot may still be possible."
    static var unplayable: String             // "This version cannot set up this shot."
    static var rename: String, delete: String, nameField: String, save: String   // "Rename", "Delete", "Name", "Save"
    // Cancel is the catalog's existing "Cancel" (String(localized: "Cancel")); no new key, no property here.
    static var deleteQuestion: String         // "Delete this shot?"
    static var deleteDetail: String           // "It is removed from Your shots for good."
    static func options(_ name: String) -> String   // "Options for %@"
    static var praise: String                 // "Made it again: the same balls in the same pockets."
    static var plainIdea: String              // "Same start, same stroke, same result: there is no luck in the physics, so your own stroke is the answer."
    static var origin: String                 // "Your own shot, saved from free play."
    static func defaultName(kind: HighlightKind?, number: Int) -> String   // HighlightWords.title(kind) or "Saved shot %lld"
    static func ball(_ b: Int, table: TableKind) -> String
    //   .standard: String(localized: "the \(b)") (existing key); bumperPool / barBilliards / fivePin:
    //   TableGameWords.ball(b, kind: .bumperPool / .barBilliards / .fivePin)
    static func into(_ d: OwnDrop, table: TableKind) -> String
    //   String(localized: "\(ball(d.ball, table:)) into \(TableWords.holePhrase(d.pocket, table: table.parameters.tableSpec, kind: table))")
    //   catalog key "%@ into %@" (what Xcode writes for two string interpolations; translations may reorder with
    //   %1$@ / %2$@), comment: "One ball and the pocket or hole it must drop into, e.g. 'the 3 into the foot-left corner pocket'. Joined into a list."
    static func goalLine(_ own: OwnShot) -> String
    //   sentence 1: String(localized: "Pot \(list).") where list = drops.map { into($0, table:) } as a list
    //   sentence 2, when firstHit is set and is not the only dropped ball: String(localized: "Touch \(ball(firstHit)) first.")
    //   sentence 3, when bank is set: String(localized: "\(ball(bank)) must come off a cushion on the way.")
    //   joined with a single space. (Each is a whole sentence in the catalog.)
    static func hook(_ own: OwnShot) -> String      // origin + " " + goalLine(own)
    static func idea(_ own: OwnShot) -> String      // own.kind.map(HighlightWords.line) ?? plainIdea
    static func detail(_ own: OwnShot) -> String?
    //   parts: "Surface: %@" with PlaySurface.title when not .cloth; "Table: %@" with TableKind.title when not .standard;
    //   joined with " · "; nil when both are defaults.
    static func spokenRow(_ own: OwnShot, proof: OwnShotCheck?) -> String
    //   name, goalLine, madeAgain / notMadeYet, detail, the changed / unplayable line, each a sentence, joined by spaces.
    static var leftStickControl: String       // "Left stick click"
    static var leftStickAction: String        // "Saves the shot just played as a challenge of your own (Make it again), where the controller has this button."
}
```

The list joins use `.formatted(.list(type: .and).locale(AppLocale.numbers))`. Ball numbers inside "the %lld" are
formatted by the catalog in the game's language.

**5. App/OwnShotViews.swift** - every view of the feature.

- `struct MakeItAgainButton: View` (`let model: ShowpieceModel`) for HighlightCard's `CardButtonRow`. Shows nothing when
  neither `shelf.canSave(model)` nor `shelf.savedShot(for: model) != nil` nor `shelf.isFull(for: model)`. Otherwise a
  `.glass` button styled like the card's others (`Label(..., systemImage:)`, `.font(.headline)`, `.lineLimit(1)`,
  `.frame(minHeight: CallMetrics.buttonHeight)`):
  - can save: "Make it again", symbol "bookmark", hint `saveHint`, action `shelf.save(from: model)`;
  - saved: "Play it now", symbol "play.fill", hint `playHint`, action `shelf.play(saved, model: model)`;
  - full: "Make it again" disabled, hint `fullHint`.
  No `.sensoryFeedback` and no `.onAppear` side effects here: CardButtonRow builds its content twice (ViewThatFits).
  Read the shelf as `OwnShotShelf.shared` inside `body` (a computed property, not a stored `let`), so a test's swapped
  shelf and the app's are both observed.
- `extension MakeItAgainButton { static func blurbButton(_ model: ShowpieceModel) -> BlurbButton? }` - the same three
  states as a BlurbButton (the full state returns nil: a blurb cannot show a disabled button; Shot options still shows
  it).
- `struct MakeItAgainMenuItem: View` (`let model`) for ShotOptionsItems: a `Button` with `Label` in the same three states
  (disabled when full), nothing otherwise.
- `struct MakeItAgainCommand: View` (`let model: ShowpieceModel?`) for the Mac Playback menu: `Button(saved ?
  playItNowMac : makeItAgainMac)` with `.keyboardShortcut("s", modifiers: [.command, .shift])`, disabled unless it can
  save or is saved.
- `struct OwnShotsSection: View` (`let mode: TrickShotMode`) for TrickShotList's List:
  `Section { rows } header: { Text(shelfTitle) } footer: { Text(shots.isEmpty ? emptyFooter : footer) }`.
  Rows newest first (`ForEach(shelf.shots.reversed()) { own in OwnShotRow(own: own, mode: mode) }`, identity the
  shot's `id`). Each row (`OwnShotRow`, with `@State private var editing = false`, `@State private var draft = ""`,
  `@State private var askingDelete = false`) has three forms:
  - **Editing** (Rename chosen): a `TextField(nameField, text: $draft)` with `.textFieldStyle(.roundedBorder)`,
    `.autocorrectionDisabled()`, `.submitLabel(.done)`, `.onSubmit { shelf.rename(id:to: draft); editing = false }`,
    `.accessibilityLabel(rename)`, then two small buttons Save (same action) and Cancel (`editing = false`). The field
    takes focus when it appears (`@FocusState`), so VoiceOver and the keyboard land in it. `draft` starts as the name.
  - **Asking to delete**: the name (`Text(verbatim:)`, Theme.heading), `deleteQuestion` and `deleteDetail` (Theme.body),
    then a destructive `Button(delete, role: .destructive) { shelf.delete(id:) }` and `Button(cancel) { askingDelete =
    false }` (cancel is the existing "Cancel" key). VoiceOver focus moves to the question (`@AccessibilityFocusState`).
  - **Normal**, below.
  Rename and Delete anywhere (options menu, context menu, swipe, VoiceOver actions) only set `editing` or
  `askingDelete`; there is no `.alert` or `.confirmationDialog` (the app has none: on the open Duo a system alert is
  centred on the whole window and covers the table). In the normal form the row is an `HStack` of two SIBLINGS: first a `Button` (action `shelf.play(own,
  model: mode.model)`, disabled when `own.trickShot == nil`, `.buttonStyle(.plain)`, `.contentShape(Rectangle())`)
  whose label holds the leading status mark (checkmark.circle.fill in the accent when made, else the "bookmark"
  symbol), the name (`Text(verbatim:)`, Theme.heading), the goal line (Theme.body, secondary), the detail line when any
  (Theme.label, `palette.slide`), the proof line when checking or changed (Theme.label), and the thumb
  (`TrickPathThumb(path:)` from `shelf.paths[id]`, 96 by 48, or full width above the text at accessibility sizes,
  exactly as TrickShotList.row lays out its authored rows); then, beside that Button and NOT inside its label, a
  trailing `Menu` with an "ellipsis" label (44-point frame), `.accessibilityLabel(options(name))`, holding Rename and
  Delete. (A Menu placed inside a Button's label never receives its taps: the parent button swallows them. The
  authored rows can wrap everything in one Button only because they hold no control.) On the play Button:
  `.accessibilityElement(children: .combine)`, `.accessibilityLabel(spokenRow)`, `.accessibilityHint(playHint)`,
  `.accessibilityAction(named: rename)`, `.accessibilityAction(named: delete)`. On the whole HStack: `.contextMenu`
  with Rename and Delete.
  Swipe with `.swipeActions` (Delete, destructive) that sets `askingDelete` (the row's own question, as above).
  `.onAppear { shelf.startChecks() }` on the section's content (the footer counts, so an empty shelf still calls it;
  `startChecks` is a no-op after the first call).

### Hook points in pre-existing files

Each is small and named so the coordinator can merge by hand if two features touch the same function.

**M1. App/ShowpieceModel.swift, `physicsTable`** (around line 3114). First line inside the getter:

```swift
if let own = trickModeStorage?.current, own.table != .standard { return own.table }
```

A saved shot on bumper pool or bar billiards is solved, drawn and judged on that table. Authored shots and lessons keep
`.standard` (their `table` is the default).

**M2. App/ShowpieceModel.swift, `freePlayUp`** (around line 3624): `private var freePlayUp` becomes `var freePlayUp`
(internal), for `OwnShotShelf.canSave`. No other model change: `keptStrike`, `KeptStrike`, `pendingStroke`,
`currentAttempt`, `playerShotOnScreen`, `aimReady`, `isSolving`, `menuOpen`, `replayingBest`, `captions`, `surface`,
`setSurface` and `controlValues` are already internal.

**T1. App/TrickShots.swift, `struct TrickShot`**: after `cueAngles`, add

```swift
/// The table this shot is played on: the pool table for every authored shot and lesson; a saved shot of the
/// player's own (Make it again, 0.7.7) keeps the table it was made on. Last, with a default, so no existing call changes.
var table: TableKind = .standard
```

**T2. App/TrickShotMode.swift, `watch()`**: the strike line becomes

```swift
if shot.isBreak { model.breakNow() } else { OwnShotProof.arm(shot, model: model); model.shootNow() }
```

**T3. App/TrickShotMode.swift, `next()`**: right after `guard let shot = current else { ... }`:

```swift
// A saved shot of the player's own walks the shelf, not the authored list (0.7.7, make it again).
if OwnShot.isOwnID(shot.id) {
    if let n = OwnShotShelf.shared.next(after: shot.id) { OwnShotShelf.shared.play(n, model: model) } else { listOpen = true }
    return
}
```

**T4. App/TrickShotMode.swift, `markDone(_:)`**: first lines:

```swift
// A saved shot's make is kept on the shelf, never in doneIDs (the authored progress) (0.7.7).
if OwnShot.isOwnID(shot.id) { celebrations += 1; OwnShotShelf.shared.noteMade(id: shot.id); return }
```

This keeps a saved shot out of `doneIDs`, which the menu's made count, the highlight card's trick link and the
achievements plan's sweep all read (that plan does not edit TrickShotMode, so nothing else lands in this function).

**T5. App/TrickSignature.swift, `events(forTrick:in:captions:)`**: the `default:` case becomes

```swift
default:
    // A saved shot of the player's own (0.7.7): its first contact, then the last ball down (its bank, else its
    // pocket). Read from the recording alone, so this stays a plain nonisolated call. Any other unknown id still
    // gets an empty list, as before.
    return OwnShotSignature.events(forOwn: id, in: timeline, captions: captions)
```

**V1. App/TrickShotViews.swift, `TrickShotList.body`**: inside `List { ... }`, after the authored `Section`, add
`OwnShotsSection(mode: mode)`.

**V2. App/TrickShotViews.swift, `GoalMarks.draw`**: the pocket loop becomes

```swift
for k in pockets {
    // holeCenter is nil for a hole this table lacks; it must come first, as it is what keeps bedHoles[j] in range.
    guard let centre = table.holeCenter(pocket: k) else { continue }
    let j = k - TableSpec.edgePocketCount
    let radius: Double
    if j >= 0 {
        radius = table.bedHoles[j].captureRadius
    } else {
        guard k < table.pocketCaptureRadius.count else { continue }
        radius = table.pocketCaptureRadius[k]
    }
    if let p = TablePathStroke.ring(at: centre, radius: radius + 0.012, proj) { ...the same two strokes... }
}
```

(Checked: `BedHole.captureRadius` and `TableSpec.holeCenter(pocket:)` are public in
Packages/BreakdownCore/Sources/BreakdownTimeline.) On the pool table `holeCenter` gives `pockets[k]` for 0 to 5, so
authored shots and lessons draw exactly as before.

**F1. App/FreePlayViews.swift, `HighlightCard.details`**: first item inside `CardButtonRow { ... }`:
`MakeItAgainButton(model: model)`. The card can then carry three buttons (four once the clips plan adds Share clip to
the same row); `CardButtonRow` (App/Match/MatchViews.swift) already falls back from one row to a wrapping row when they
do not fit (the sideways phone's column, the Duo's words half) and stacks them at the accessibility text sizes, so no
layout change is needed. The card is hidden while the table is cleared (`highlightCard` needs `!tableCleared`), so a
shot that pots the last ball is saved from Shot options or the Mac menu instead.

**F2. App/FreePlayPhoneBlurbs.swift, `HighlightPhoneBlurb.buttons(_:)`**: becomes

```swift
var out: [BlurbButton] = []
if let save = MakeItAgainButton.blurbButton(model) { out.append(save) }
if offer.canTryTrick { out.append(BlurbButton(String(localized: "Try the trick shot")) { model.tryHighlightTrick() }) }
out.append(BlurbButton(String(localized: "Close")) { model.dismissHighlight() })
return out   // Blurb draws the first two
```

**S1. App/ShotPanel.swift, `ShotOptionsItems.body`**: inside `if freePlay { ... }`, right after the Undo last shot
button: `MakeItAgainMenuItem(model: model)`.

**C1. App/MacChrome.swift, `playbackItems`**: after the Watch It in the Lens button: `MakeItAgainCommand(model: model)`.
Add "Make It Again (Shift-Command-S)" to the PURPOSE's list of Playback items.

**C2. App/ControllerInput.swift**: add `case leftStick` to the Button enum; register
`if let stick = pad.leftThumbstickButton { buttons.append((stick, .leftStick)) }` beside the right stick; in `press`,
`case .leftStick: if OwnShotShelf.shared.canSave(model) { OwnShotShelf.shared.save(from: model) }`; add a Mapping row
(`OwnShotWords.leftStickControl`, `OwnShotWords.leftStickAction`) after the right stick's; add the line to the PURPOSE's
mapping table. The new `case .leftStick:` branch is required: `press` switches over every case.

**N1. App/NotebookInfo.swift, `NotebookDossier.trick(_:)`**: after `switch mode.phase { ... }`, one line:

```swift
// A saved shot's window is not measured yet: show no made-up numbers (0.7.7, make it again).
if OwnShotShelf.shared.isUnmeasured(shot) { showsWindow = false }
```

**Not touched:** App/Localizable.xcstrings (see Words to translate: translations go in a JSON file the coordinator
merges, so five builders never edit the catalog at once), GameSettings.swift (no new setting; the shelf has its own
file), TableScene.swift, PhoneTitleRow.swift, PhoneStrip.swift, the project file, CHANGELOG.md, ROADMAP.md and the spec
(the coordinator writes the 0.7.7 entries and bumps the version, patch step only).

## Tests

New file **BreakdownTests/OwnShotTests.swift**, XCTest, `@testable import Breakdown`, `import BreakdownPhysics`,
`import BreakdownTimeline`, in the style of TrickShotJudgeTests, using TestShots and the authored layouts. The class is
`@MainActor final class OwnShotTests: XCTestCase` (the shelf is main-actor; plain calls to the nonisolated helpers are
fine from there). Shelves in tests are `OwnShotShelf(fileURL: nil)` (memory only, never the player's file). A test that
goes through a hook which reads `OwnShotShelf.shared` swaps it: `let saved = OwnShotShelf.shared;
OwnShotShelf.shared = OwnShotShelf(fileURL: nil); defer { OwnShotShelf.shared = saved }`, then `add(_:)` its shot.

One private helper builds attempts exactly as a free-play stroke keeps them (never `TestShots.attempt`, which rebuilds
the input with seed 1 and the surface's numbers already in it):
`freePlayAttempt(_ input: ShotInput, table: TableKind = .standard, surface: PlaySurface = .cloth) -> ShotAttempt`:
`let g = PoolParameters().modelGeneration`; `let tl = PoolSolver.simulate(ShowpieceModel.solverCopy(input, table:
table, surface: surface, generation: g))`; aim from the direction in degrees, power `input.strike.speed`, tip and
elevation from the strike, `seed: input.seed`, `input: input`, `powerRange: PlayerShotSpeed.ordinary`, `start:
input.positions`, `isBreak: false`, `breakSeed: 0`. A trick's answer becomes an input with `NextShot.shot(from:
layout, direction: Vec2(cos(a), sin(a)), speed: s.power, tipUp: s.tipUp, tipSide: s.tipSide, seed: 1, elevation:
s.elevation ?? 0)` (default parameters).

1. `testAPotBecomesAChallenge`: `freePlayAttempt(RideDemo.straightPot())` (seed 7, default parameters). `OwnShot.refusal`
   is nil; `make` gives one drop (ball 1, the pocket of its pocket event), `firstHit == 1`, `bank == nil`, table
   standard, surface cloth, id starting "own-", `strike.seed == 7`, and `own.input`'s strike direction, speed, tips,
   elevation and seed equal the original input's exactly (`==` on the doubles: the direction is written back).
2. `testTwoBallsAnyOrderSamePockets`: the follow-train answer (TrickShots.shot(id: "follow-train")) through
   `freePlayAttempt`; `make` gives two drops in drop order. Then hand-made recordings (TestShots.recording) with
   the cue ball touching the first ball and the two balls dropping in the same pockets in the reverse order: the judge
   says made; one ball in a different pocket: `.wrongPocket`; the cue ball dropping too: `.scratch`.
3. `testRefusals`: a break attempt (`TestShots.attempt(start:timeline:_:isBreak: true, breakSeed: 11)` on
   `TestShots.breakShot()`) is `.isBreak`; a stroke far too soft to pot (the straight pot's input at a tenth of the
   speed, through `freePlayAttempt`) is `.nothingDropped`; a hand-made recording with a cue-ball pocket event is
   `.cueBallDropped`; an attempt with `generation: 1` is `.otherPhysics`.
   Also the solution: a raised stroke saved from an input with elevation 0.6 and speed 4 gives `solution.power == 4`
   and `solution.elevation == 0.6` (the struck values, not any chosen power).
4. `testRoundTripsThroughJSON`: encode and decode an OwnShot made in test 1 with JSONEncoder / JSONDecoder; equal.
   The same for the shelf's file struct with two shots.
5. `testTheSavedStrokeProvesTheShot`: `OwnShotProof.holds(own)` is true for test 1's and test 2's shots, and the
   re-solved recording's motion hash equals the saved one (`String(attempt.motionHash, radix: 16)`).
6. `testABankIsNeededOnlyWhenTheBallCameOffARail`: the cross-bank answer gives `bank` equal to its goal's bank ball;
   the straight pot gives nil.
7. `testTheWindowHoldsTheShot`: `measureWindow` on the straight pot (build "test"): every half-width is above zero;
   the strike moved by half the aim window either way still passes; moved by the aim cap plus one degree fails.
8. `testTheTrickShotCarriesTheTableAndJudgesTheOriginalMade`: `own.trickShot` has the own id, `table` from the shot,
   setup `.layout(start)`, the goal, the praise; `TrickShotJudge.verdict(for:attempt:)` on the original attempt is made
   with `OwnShotWords.praise`. A bumper-pool shot (an OwnShot built by its memberwise init with `tableRaw:
   "bumperPool"`, `surfaceRaw: "cloth"`, `generation: PoolParameters().modelGeneration`, the start and strike of
   `TableKind.bumperPool.openingShot` (its start layout and default shot, ball 0), `drops: [OwnDrop(ball: 1, pocket:
   6)]`, `firstHit: 1`, `bank: nil`) gives `trickShot?.table == .bumperPool`; the goal need not hold for this test. `OwnShotShelf(fileURL: nil).isUnmeasured(own.trickShot!)` is true until a window
   is set, false after.
9. `testSignatureHoldsTheHitAndThePocket`: for test 1's recording, with `CaptionEngine.make(from: tl, surface: .cloth)`,
   `TrickSignature.events(forTrick: own.id, in: tl, captions:)` is non-empty, at most two, all captioned, and includes
   the cue ball's first contact; for an id without the prefix ("no-such-shot") it is empty, as before. (No shelf needed:
   the signature reads the recording only.)
10. `testShelfRulesInMemory`: on `OwnShotShelf(fileURL: nil)` with shots put in through `add(_:)`: rename trims and caps
    at 40 characters and ignores an empty name; delete removes the shot and its proof; `noteMade` sets made;
    `next(after:)` walks newest first and gives nil after the last; `add` refuses a sixty-first shot.

Add to **BreakdownTests/ModelFlowTests.swift**? No: a new file keeps the merge clean. Add a model flow test in
**BreakdownTests/OwnShotFlowTests.swift** (`@MainActor final class OwnShotFlowTests: XCTestCase`). ModelFlowTests'
`prepareDevice` / `restoreDevice` are private, so copy the pattern: keep and put back `GameSettings.seenOpeningKey`,
`TableKind.storageKey` and `PlaySurface.storageKey` (setSurface writes it), set `seenOpeningKey` true before making the
model, and swap `OwnShotShelf.shared` for a memory shelf as above (both restored in a defer).

11. `testPlayingASavedBumperPoolShotSolvesOnBumperPool`: a new ShowpieceModel; test 8's bumper-pool OwnShot added to
    the swapped shared shelf and played through `OwnShotShelf.shared.play(own, model:)`: then
    `model.physicsTable == .bumperPool`, `model.solvedTable == .bumperPool`, `model.trickMode.current?.id == own.id`,
    and the layout equals `own.start`; after `trickMode.watch()` there is a current attempt with `table == .bumperPool`.
    Then `trickMode.end()` and `model.physicsTable` is back to the player's table.
12. `testWatchItStrikesTheSavedStrokeExactly`: test 1's shot (cloth, pool table) added to the swapped shared shelf and
    played on a new model; after `trickMode.watch()`: `model.currentAttempt?.input.seed == own.strike.seed` (NOT
    `.seed`, which is shootNow's serial seed), `String(model.currentAttempt!.motionHash, radix: 16) == own.motionHash`
    (the kept strike played it bit for bit), and `model.surface == .cloth`.

The package needs no change and no new package test.

## Words to translate

New English keys (the catalog key is the English text). The builder writes two files and does not edit
App/Localizable.xcstrings:

- `localization/pending/v077-make-it-again-keys.json`: a plain JSON list of the keys below (the form
  `localization-merge.py --keys` reads).
- `localization/pending/v077-make-it-again-translations.json`: `{"translations": [{"culture", "key", "text"}]}` for all
  eleven languages (ar, de, es, fr, it, ja, ko, pt, pt-BR, ru, zh-Hans), each written as a native speaker of that
  language would say it in a game, not word for word; placeholders kept (positional `%1$@` / `%2$@` may be reordered).

The coordinator runs `python3 scripts/localization-merge.py localization/pending/v077-make-it-again-translations.json
--keys localization/pending/v077-make-it-again-keys.json` and `scripts/translation-check.py` after the merge.

Keys (with the translator comment to put in code):

| Key | Comment |
|---|---|
| Make it again | Button: saves the shot just played as the player's own challenge. Short. |
| Play it now | Button: sets up the shot the player just saved. Short. |
| Make It Again | Mac Playback menu item, title case. |
| Play It Now | Mac Playback menu item, title case. |
| Saves the balls as they stood before this shot as a challenge of your own, in Trick shots. | VoiceOver hint. |
| Sets up your saved shot so you can make it again. | VoiceOver hint. |
| Your shots is full. Delete one in Trick shots to save another. | Hint on a disabled button. "Your shots" is the shelf's name. |
| Saved to Your shots, in Trick shots. | Spoken to VoiceOver after saving. |
| Your shots | Section title in the Trick shots list: challenges the player saved. |
| After a shot that drops a ball, Make it again keeps it here as a challenge of your own. | Footer of an empty section. |
| The game kept your stroke, so Watch it plays the way it went. | Section footer. "Watch it" is the trick card's button. |
| Made again | Row status. |
| Not made again yet | Row status. |
| Checking the saved stroke… | Row status while the game replays the stroke in the background. |
| The saved stroke no longer makes it in this version. The shot may still be possible. | Row and card note after a physics update. |
| This version cannot set up this shot. | Row note for a shot saved on a table this version lacks. |
| Rename | Row action. |
| Delete | Row action. |
| Name | Text field placeholder when renaming a saved shot. |
| Save | Confirms a rename. |
| Delete this shot? | Question shown inside the row before a saved shot is deleted. |
| It is removed from Your shots for good. | Line under that question, inside the row. |
| Options for %@ | VoiceOver label of a row's options button; %@ is the shot's name. |
| Made it again: the same balls in the same pockets. | Shown when the player makes their saved shot. |
| Same start, same stroke, same result: there is no luck in the physics, so your own stroke is the answer. | The idea line for a saved shot that was not a named kind. |
| Your own shot, saved from free play. | First sentence on a saved shot's card. |
| Saved shot %lld | Default name of a saved shot; %lld counts saved shots. |
| %@ into %@ | One ball and the pocket or hole it must drop into, e.g. "the 3 into the foot-left corner pocket". Items are joined into a list. Translations may reorder with %1$@ / %2$@. |
| Pot %@. | %@ is a list such as "the 3 into the foot-left corner pocket and the 6 into the left side pocket". |
| Touch %@ first. | %@ is a ball, e.g. "the 3": the cue ball must touch it first. |
| %@ must come off a cushion on the way. | %@ is a ball, e.g. "the 6": it must bank in. Sentence start; capitalise as the language needs. |
| Surface: %@ | Detail line; %@ is a playing surface name. |
| Table: %@ | Detail line; %@ is a table name. |
| Left stick click | Controller mapping, How to play. |
| Saves the shot just played as a challenge of your own (Make it again), where the controller has this button. | Controller mapping, How to play. |

Reused, already translated: "the %lld", "Close", "Cancel", "Try the trick shot", "Made it!", HighlightWords' titles and
lines, the surface and table titles, the difficulty labels, TableWords' pocket and hole phrases, TableGameWords' ball
words. "%@ must come off a cushion on the way." starts with a ball phrase in lower case ("the 6"); in code capitalise
its first letter with the game's locale (`prefix(1).uppercased(with: AppLocale.numbers) + dropFirst()`), as no
language here starts that sentence with a lower-case article.

## Out of scope

- Breaks, and shots that drop nothing (a great position shot, a jump that only touched a ball, five-pin's pins). A
  later version could add the cue ball's finish as a goal (TrickGoal.cueZone exists).
- Sharing a saved shot with someone else, or exporting it as a clip or a link: the Lens clips feature may pick it up
  later; proofs are only promised on the same build and machine (the spec's milestone-one repeatability).
- A Your shots row on the main menu, and achievements for saved shots (the shelf's `noteMade` is the place an
  achievements hook would read; the coordinator decides).
- Editing a goal by hand, or loosening it (any pocket).
- Going back to the free-play rack after Play it now (it leaves the rack as every trick-shot entry does; Undo does not
  span it).
- Bed holes in the small path drawings (TrickPathThumb draws the table outline and edge pockets only), and the small
  tables' own ball colours there (the drawing uses pool colours on a fixed cloth green).
- A launch flag or store screenshot scene for the shelf.

## Risks

- **Merge collisions with the other four plans (all hand-mergeable; none claims the same slot).**
  - FreePlayViews `HighlightCard`'s CardButtonRow: the clips plan adds Share clip there too, so the card can carry four
    buttons; the row wraps. The every-world plan adds its "step aside" gate to the card's `if`.
  - FreePlayPhoneBlurbs: the clips plan adds ClipPhoneBlurb to PlayPhoneBlurbs and a button to TableClearedPhoneBlurb,
    not to HighlightPhoneBlurb, so F2's two slots are this plan's alone; every-world adds its gate to the blurb's `if`.
  - MacChrome `playbackItems`: C1 sits after Watch It in the Lens; clips appends after What If (Shift-Command-E) and
    every-world adds Every Surface (Command-Shift-E). Shift-Command-S collides with neither; the two other plans
    collide with each other on Shift-Command-E, which the coordinator settles.
  - ControllerInput: C2 adds a `Button` case, its registration, its `press` branch and a Mapping row; clips hooks
    `pressCardButton`, every-world adds a block in `press`. Different lines of the same switch.
  - TrickShotViews: V1 (the list) and V2 (GoalMarks) here; every-world adds its gate to the trick card.
  - TrickShotMode (T2 to T4) and TrickSignature (T5): no other plan edits them.
- **Trick mode on the small tables has not been played before.** Authored modes assume the pool table in places that
  are not obviously table-bound: the stroke's calm zone for authored modes, the bridge, Reach's stance, the cue's
  clearing, the Ride camera's framing, and the goal rings for bed holes (V2 fixes the rings). The coordinator should
  play one saved bumper-pool and one bar-billiards shot after the merge.
- **The level cue in the player's own tries.** Free play raises the cue automatically to clear a ball under it; trick
  mode does not. The saved solution carries the struck elevation, so the judge's cue-angle advice says "Raise the cue
  more" when that matters, and Watch it plays the raised strike exactly; but Your turn starts level (as every trick shot
  does) until the player raises it.
- **The surface changes the player's stored choice.** Playing a shot saved on ice sets the Surface menu to ice and it
  stays after; this is visible and the same as choosing it in the menu, but unlike lessons and situations, which put
  the player's surface back on leaving (Decision 6 has the fix if wanted). Play it now calls setSurface only after
  `begin`, on a still table, so nothing is solved again.
- **Physics updates.** A saved stroke may stop making its shot on a new build or another device. The check says so on
  the row and the window is measured again; nothing is deleted or hidden.
- **Background work.** Each check is one solve per shot per run, at utility priority, one after another. A window is up
  to about ninety solves, measured only when a shot is saved or played, once per build. A long Moon shot is the slowest
  case; it never blocks the table.
- **The phone blurb's two-button cap.** With Make it again and Try the trick shot both offered, Close is not drawn; the
  blurb still goes at the first touch of the controls, as today.
- **Main-actor rules.** `OwnShotSignature` is plain and reads only the recording, so TrickSignature (nonisolated)
  calls it with no hop. Everything that reads `OwnShotShelf.shared` (arm, T3, T4, N1, the views, the Mac menu, the
  controller) is already on the main actor. The detached solves use only Sendable values (OwnShot, ShotInput,
  Timeline, TrickPath) and only nonisolated code (OwnShotProof, TrickShotJudge, PoolSolver, ShowpieceModel.solverCopy,
  TrickPath.traced).
- **Exactness.** Watch it is bit for bit only because `own.input` writes the saved direction back after CueStrike's
  init and the JSON keeps every double exactly (Swift's encoder writes the shortest round-trip form). Test 12 guards it.
- **Bar billiards' whites are all alike.** Their ball words are "a white", so a goal line on bar billiards can read
  "Pot a white into the 200 hole" while only one particular white counts. Sighted players have the ring on that ball;
  a VoiceOver player has only the words. Accepted for now; the coordinator may prefer to make bar billiards' goal
  any-white later.
- **Left stick click while aiming.** The left stick turns the aim, and some players press it by accident while
  pushing; that saves the shot on screen. Harmless (the shot can be deleted, and nothing is lost), and VoiceOver says it
  was saved.
- **Highlight judge needs the on-screen captions.** `save(from:)` requires `playerShotOnScreen`, so `model.captions`
  belong to the attempt; if a future change saves from elsewhere, pass captions made with CaptionEngine instead.
