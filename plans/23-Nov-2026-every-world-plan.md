<!--
Author: Claude Opus 5.5 High
Date: 23-November-2026
PURPOSE: Build plan for "Same shot, every surface" (slug every-world), one of the five 0.7.7 features built side by side
         in separate worktrees and merged by a coordinator. After the player's own shot, one tap plays the exact same
         stroke on all ten playing surfaces at once and fans the paths out over the table, with one plain sentence about
         the most striking difference; the player can pick one surface to watch its balls roll as ghosts beside the real
         ones, and tap through to switch to it. Written from a read of the 0.7.6 code on main for a developer who will
         write code only and not compile; the coordinator compiles once after the merge.
Edited: Claude Opus 5.5 High, 23-November-2026 (independent critic, every claim checked against the code: the Mac item
         lives in the Playback menu, not a Game menu, and takes Shift-Command-U because the clips plan claims
         Shift-Command-E; "Play on" is free play only and only when the attempt's table and generation are the live
         ones, so the switch really is the drawn line; the card never nests its own scroll; a compact card form for the
         narrow bottom stack and guided replays; the struck ball's "drops into a pocket" reads cueBallPocketed, not the
         scratch flag, which also counts flying off the table; ShotFacts' Drop and Contact types spelt out; the ice
         example and the ice test no longer assume a skid story the surface numbers do not give; fan paths thinned;
         Ride draws ghosts only; B skips while the replay plays and closes at rest; the three ShowpieceView step-aside
         swaps are the developer's, so the phone never shows two anchored blurbs; translator notes go in the comment:
         argument; no timing assertion in the tests.)
SRP/DRY check: Pass - checked plans/ (no earlier plan for this; the spec's status note lists nothing like it), the what-if
         fork (App/WhatIfFork.swift, WhatIfOverlay.swift, WhatIfViews.swift, WhatIfWords.swift: its gate, solve recipe,
         stale-drop token, tail clock, overlay pattern and anchored blurb are reused or mirrored, not rebuilt),
         ShotAttempt.resolved(on:surface:) (the other surfaces' attempts), ShowpieceModel.solverCopy and setSurface (the
         solve and the switch), TimelineFork and ShotFacts (the readings), TableSurface and PlaySurface (the numbers,
         names, symbols and summaries), BlurbPlacement, Blurb and BlurbLeader (the phone's words). The only new reading
         is how far a ball travelled and how much of that it skidded (BallTravel), which nothing in the code measures.
-->
# Same shot, every surface

## In plain words

After any of your own shots has come to rest, one tap on "Every surface" plays that exact stroke again on all ten
playing surfaces at once: standard cloth, tournament cloth, dive-bar felt, ice, glass, rubber, cork, carpet, sand and
the Moon. Your real shot stays on the table. Over it, the path of your cue ball on each of the other nine surfaces fans
out, each in its own colour, each ending in a small round tag with that surface's symbol. One plain sentence, pinned to
the path it talks about, says the most striking difference, for example "On Ice the cue ball travels much farther
than here" (the real sentence gives both distances), or "On Rubber the 3 drops; here it stayed out". Opening the
sentence adds the surface's own one-line explanation, the same one the Surface menu shows.

"Watch them roll" plays your shot again from the start with nine ghost cue balls rolling beside the real one, each on
its own surface, and the slow ones keep rolling after your real shot has stopped until each comes to rest. Tap a
surface (a chip on the phone, a row on the bigger screens) and only that surface is drawn strongly: the balls that
moved differently there roll as ghosts, and its own sentence takes the blurb. In free play, "Play on Ice" then switches
the game to ice and plays your shot again for real on it, so what you saw is exactly what you get.

It works after your own shot in free play, and after a judged try at a trick shot, a lesson or a Behind the 8-Ball
puzzle (in a trick shot it also says when another surface would have made the shot). In those three the fan is for
looking only: they are set on their own surface and judged on it, so "Play on" is free play's alone and the Surface
menu stays the way to change surface there. It works on all four tables.
It never opens by itself, never on a break, never in a match, never in the first minute. It makes no sound at all: the
ghosts roll silently. Nothing about it is hidden or unfinished.

## What exists today (read in the code, 0.7.6 on main)

- Surfaces are numbers only. `Packages/BreakdownCore/Sources/BreakdownAuthored/TableSurfaces.swift` (TableSurface.apply)
  writes sliding friction, rolling resistance, spin decay, the slate's bounce and grip, gravity for the Moon, and the
  cushions for the two real cloths. It never touches the table's shape. `App/PlaySurface.swift` keeps the names
  (title), the one-line explanations (summary, already translated into all twelve languages), the SF Symbols and the
  stored choice. `App/PlaySurfaceLook.swift` is how each bed looks.
- Tables are a separate choice (`App/TableKind.swift`: pool table, bumper pool, five-pin, bar billiards), applied before
  the surface. So "a surface whose table shape differs" does not exist: every surface plays on every table.
- The solve. `ShowpieceModel.solverCopy(_:table:surface:generation:)` (App/ShowpieceModel.swift, about line 3026) is a
  pure, nonisolated function: it writes a table, a surface and a physics generation into a copy of a shot's input.
  `PoolSolver.simulate(_:eventBudget:)` (Packages/.../BreakdownPhysics/Simulation.swift line 172) solves it and returns
  nil past the event budget; every shot also stops at 90 seconds of clock.
- The attempt. `App/ShotAttempt.swift`: a ShotAttempt keeps the input as handed to the solver before the table and
  surface numbers (with the stroke's drift already in it), the start layout, the seed, the table, the surface and the
  generation. `resolved(on:surface:)` makes the same attempt on another recording and surface (setSurface uses it).
  `path(of:)` samples one ball's path 60 times a second. `facts` gives ShotFacts.
- Switching surface. `ShowpieceModel.setSurface(_:)` stores the surface, solves `lastInput` again through
  `solve(_:classic:)`, which goes through `prepare`: the LIVE `physicsTable`, the new surface and `activeModelGeneration`
  (or the pinned default when `lastClassic`). It then loads the new recording, which replays from the start, and
  re-makes `currentAttempt` with `resolved(on:surface:)`. For a player's shot `lastInput` is the attempt's `input`
  (finishStrike commits `prepared.input` and records the attempt with the same value), so setSurface's solve equals the
  fan's `solverCopy(real.input, table: real.table, surface: s, generation: real.generation)` exactly when
  `real.table == model.physicsTable` and `real.generation == model.activeModelGeneration` (both true for a free-play
  shot still on screen; `canSwitch` checks them anyway). Every `load()` closes the what-if (`whatIfStorage?.close()`).
- The learn modes own their surface: LessonMode.begin forces `.cloth` through setSurface and puts the player's surface
  back at its end; EightBallMode sets the situation's surface and EightBallJudge gives the top rating only on it; a
  trick shot's judged verdict follows a re-solved recording (TrickShotMode.recordingReplaced moves judgedVersion) but is
  not judged again. So a switch from the fan inside them would leave a verdict about another surface on screen.
- The what-if fork (built in 0.7.5) is the model for this feature, end to end:
  - `App/WhatIfFork.swift`: `canOpen` (the player's own shot on screen and at rest; not a break, a match, the first
    minute, while solving, during Watch your best shot, the stroke drill, with the menu open, or while ball in hand is
    owed; in a trick shot, lesson or Behind the 8-Ball only the judged try); `isShowing` (open and still on the
    recording it opened on); the solve on a detached task with a session token so a late result is dropped; a spinner
    after 150 ms; the tail clock (`tailStart`, `clockMoved(from:to:)`, `clockHasMoved`) that lets a longer other future
    roll on past the real shot's end; announcements through `ShotNarration.announce`.
  - `App/WhatIfOverlay.swift`: a TimelineView plus Canvas over the table, projected each frame through `AimProjector`
    with `TablePathStroke` (paths, rings, the small pill label, all in App/GhostOverlay.swift); never takes touches; hidden
    from VoiceOver.
  - `App/WhatIfViews.swift`: WhatIfCard (the card slot below the table, the side column, the notebook), WhatIfPhonePanel
    (in the aiming panel's place in the upright phone's bottom bar), WhatIfPhoneBlurb (an anchored blurb with a leader,
    using BlurbPlacement.anchored and BlurbLeader from App/Phone/).
  - `App/WhatIfWords.swift`: whole translatable sentences, numbers in the game's language (AppLocale.numbers in
    App/NumberStyle.swift), ball names from TableWords.ballName with the attempt's table.
- `TimelineFork.find(real:alternate:start:cueBall:ballRadius:)` (Packages/.../BreakdownTimeline/TimelineFork.swift) gives
  changedBalls, finishGap and a parting marker between two recordings from the same start.
- `ShotFacts` (same folder) gives the first ball touched (`firstContact: Contact?`, read `.ball`), every drop
  (`objectBallsPocketed: [Drop]`, read `.ball`), `cueBallPocketed` (into a pocket or hole), `cueBallOffTable` and
  `cueBallScratched` (either of the two), pins down.
- `PoolSolver.simulate(_:)` (what every real shot and setSurface use) halts at 10,000 events and still returns a
  recording; `simulate(_:eventBudget:)` runs the same `run(limit:)` and returns nil instead. Under the limit the two
  give the identical recording.
- Nothing in the code measures how far a ball travelled or how much of that it skidded.
- Where the what-if is wired in, and where this feature hooks in beside it: ShowpieceView.stage (overlay, phone blurb),
  ShowpieceView.phoneBar (panel), the bottom stack and side column (card), NotebookPanel.cards (card), PhoneTitleRow's More
  menu, MacChrome's PLAYBACK menu (`CommandMenu("Playback")`, `playbackItems`, where "What If…" sits with
  Shift-Command-T), and twenty-one "step aside while a what-if shows" checks (Build step 12).
- Containers the card sits in already scroll: the bottom stack wraps its cards in `FittingScroll(maxHeight: cardsCap)`,
  the side column is a ScrollView, and the notebook pages scroll. WhatIfCard has a compact form (upright size classes
  outside the notebook, and any guided Lens replay through `\.lensReplayCompact`) and a full form.
- The Mac's Surface control is a `Picker("Surface", ...)` in MacChrome, not SurfaceMenuItems, so the Mac entry is the
  Playback item alone. The notebook's top bar shows SurfaceMenuButton (which holds SurfaceMenuItems) except while a
  ride is under way (`rideStatus != nil`), which never overlaps the fan's gate (balls at rest).
- Sound: `ShowpieceModel.fireSounds` only plays the real recording's events; overlays never call SoundBoard.
- Controller: App/ControllerInput.swift maps buttons; the what-if has no controller mapping of its own.
- Project file: `App` and `BreakdownTests` are file-system synchronised groups (PBXFileSystemSynchronizedRootGroup, with
  membership exceptions only for two README files). Any new .swift file under App/ joins the app target, and any new file
  under BreakdownTests/ joins the test target, with no project-file edit. New package files join their module by folder.
- Translations: `scripts/localization-merge.py` merges a pending JSON file (`{"keys": [...], "translations": [{"culture",
  "key", "text"}]}`, cultures es, fr, de, it, pt, pt-BR, ja, ko, zh-Hans, ru, ar) into App/Localizable.xcstrings;
  earlier batches left theirs in localization/pending/.

## The design

### What is computed

- Home is the surface the attempt was solved on (`real.surface`). Its recording is the attempt's own timeline: it is
  never solved again, so the home line is exactly the shot on screen.
- The other nine surfaces are solved from `real.input` with `solverCopy(real.input, table: real.table, surface: s,
  generation: real.generation)`. Same start, seed, stroke drift, table and generation: only the surface changes. In
  free play, with the attempt's table and generation still the live ones (`canSwitch` checks), this is exactly what
  `setSurface(s)` would solve, so "Play on Ice" plays the ice line that was drawn.
- Other tables: all ten surfaces on every table, because a surface never changes the table's shape and the solve is
  pinned to the attempt's own table. Bumper pool, five-pin and bar billiards get the fan too.
- A surface whose solve runs past the event budget (10,000 events, `WhatIfFork.eventBudget`) is not dropped silently:
  its chip or row says "This surface runs too long to show." and it is left out of the sentence.

### Making it fast

- One detached task at user-initiated priority runs a task group of nine child tasks, one per surface, so the solves use
  every core at once. Each child solves, then in the same child reads `TimelineFork.find` against the home recording and
  `WorldOutcome` (new, below), so nothing heavy is done on the main thread.
- Each surface lands on the main actor as soon as it is solved, and its line fades in then: the fan grows surface by
  surface instead of waiting for the slowest (usually the Moon or ice). The sentence appears when all nine have landed.
- On landing, the main actor only builds the attempt (`real.resolved(on:surface:)`), samples the cue ball's path once
  (`path(of:)`, then thinned by `EveryWorldFan.thin(_:)`: keep a point only when it is at least 5 mm from the last kept
  one, always keep the last; a Moon or ice path at sixty samples a second can hold thousands of points, and nine of
  them are projected every frame), and in a trick shot asks `TrickShotJudge.passes`. The overlay never re-samples per
  frame; each frame only projects the stored points and asks each ghost's state at one time.
- A spinner ("Working out every surface") shows only if nothing has landed after 150 ms, as the what-if does.
- The result is kept for the recording it was made on: closing and reopening on the same shot is instant. Any new
  recording (a new shot, a switch, Try again) drops it.
- A closed fan or a new recording bumps the session token; late landings are dropped whole. The task is also cancelled,
  but a solve already running finishes and is discarded (the solver does not check for cancellation).

### What is drawn (every layout)

- Nothing picked (the fan): for each other surface, the struck ball's whole path in that surface's colour, dotted, over a
  dark underlay so it reads on any cloth, ending in a small round tag (a dark disc, 9-point radius on screen, with the
  surface's SF Symbol in its colour). The home path is not drawn again: the real balls are on the table. The surface the
  sentence is about is drawn at full strength; the others at 55 per cent.
- A surface picked: its paths at full strength for up to three balls (the struck ball, the first ball it hit there, and
  the first ball whose drop differs from home, each only when TimelineFork lists it as changed, the what-if's rule), with
  hollow ghost balls on the clock and dashed rings where they stop; every other surface's struck-ball path at 15 per cent.
- Ghosts follow the replay clock. Before the clock moves they sit where they stopped. Once the real recording reaches its
  end the tail clock (wall time times the chosen speed) carries them on to the longest shown surface's end; a scrub back
  ends the tail. Same rules as WhatIfOverlay.ghostTime. With nothing picked, all nine struck-ball ghosts roll.
- Colours: one per surface, its bed's own colour family, kept off the Lens's sliding magenta and rolling cyan and the
  what-if violet. Ten hues cannot all be told apart on green cloth, so identity never rests on colour: every path ends in
  its symbol tag, only one path is strong at a time, and with Differentiate Without Colour on the faint paths are dashed
  long and the strong one solid. With Increase Contrast each colour has a brighter value.
- The paths never take touches. Picking is done in the words half (chips, rows, VoiceOver, controller), so aiming and
  the table's own gestures are untouched.
- Ride: while a ride is under way (`model.rideStatus != nil`, for example "Watch them roll" with Ride on) the camera is
  at ball height behind the real cue ball, where nine dotted lines and their tags would cross the view and blur what
  is seen and from where. Then the overlay draws only the hollow ghost balls (and, with a surface picked, its dashed
  rest rings); the paths and tags come back when the ride lands. The Ride status chip keeps saying which ball is
  ridden; the fan adds no words of its own on the table.
- No sound and no haptic while ghosts roll. A selection haptic on a pick when Vibration is on (GameSettings.hapticsOn),
  as the what-if's clicks.

### The sentence (one plain sentence, then the why)

The words are read from facts, never guessed. For each solved surface, `WorldContrast.key(home:world:)` returns the
first fact that holds, in this order; the sentence about the fan as a whole is the surface whose key comes earliest in
the order, the strongest within that key, and menu order breaks a tie:

0. Trick shots only (app side): the real try missed and this surface makes the shot. "On %@ this trick shot would
   have worked."
1. A ball drops here that stayed out at home (the first such ball): "On %@ %@ drops; here it stayed out."
2. The struck ball never settles into a roll: it skidded at least 90 per cent of a travel of at least 0.3 m, against at
   most 60 per cent at home. Strongest: the largest skid share. "On %@ %@ never settles into a roll: it skids almost all
   of its %@ m." This fires only when the recording says so; do not expect it from ice in general. By the surface
   numbers a free ball's skid share goes as rolling resistance over sliding friction, so on ice (0.002 over 0.025) a
   long free roll is mostly rolling, and a stun shot into a ball skids nearly all the way on cloth too.
3. The struck ball never reaches the ball it hit first at home: "On %@ %@ never reaches %@."
4. It meets a different ball first: "On %@ %@ meets %@ first, not %@." Or it reaches a ball when home touched nothing:
   "On %@ %@ reaches %@; here it touched nothing."
5. A ball that dropped at home stays out: "On %@ %@ stays out; here it dropped."
6. The struck ball's drop differs (ShotFacts.cueBallPocketed, NOT cueBallScratched, which also counts a ball that
   flew off the table): "On %@ %@ drops into a pocket; here it stayed up." or "On %@ %@ stays on the table; here it
   dropped." (A ball flying off on one surface and not the other falls through to items 7 and 8.)
7. It travels at least twice as far or at most half as far, and at least 0.3 m differently. Strongest: the largest ratio
   either way. "On %@ %@ travels %@ m; here it went %@ m."
8. It keeps moving at least twice as long, and at least 2 seconds longer. "On %@ %@ keeps moving for %@ seconds; here it
   stopped after %@."
9. Nothing above: per surface "Much the same as here."; for the fan as a whole "Every surface plays this shot almost
   the same way: it is over before the surface makes much difference."

Distances in metres with one decimal, seconds with one decimal, both written with AppLocale.numbers. Balls are named by
TableWords.ballName with the attempt's table, so the other tables name their own balls. Opened, the blurb (or card)
adds the shown surface's PlaySurface.summary as the second sentence: the plain reason, already in twelve languages.

### Phone held upright

- Entry: "Every surface" (symbol square.3.layers.3d) in the title row's More menu, just under What if, shown while the
  fan can open and is not showing. It is not added to the strip (its row is full, phone UI plan Part 3) and not to the
  scrub row (bug 31 keeps that row's width fixed).
- While open, the bottom bar shows EveryWorldPhonePanel in the aiming panel's place (the what-if's slot; the two never
  show together), regular glass, sized to its content and the same height whatever is picked, so the table never
  reframes:
  - Row 1: "Every surface" in the phone title font, then, right-aligned, "Play on Ice" (the white capsule, only while
    `canSwitch`: free play, a solved non-home surface picked) and Close (xmark in a 44-point circle drawn with
    PhonePanelControl, as WhatIfPhonePanel's).
  - Row 2: a horizontal scroll of ten chips, 44 high: a colour dot, the symbol, the surface's title. Home is marked
    "Played here" (a small caption under its title, and its VoiceOver value) with a 2-point white underline; tapping it
    means "show all", never a pick of its own. A picked chip has the 3-point underline in its colour and the selected trait. A chip
    still solving is at half strength; a too-long chip is at 35 per cent with its sentence saying so. Tapping the picked
    chip again unpicks it (back to the fan). The row scrolls the picked chip into view.
- The sentence is EveryWorldPhoneBlurb, an anchored blurb (phone UI plan Part 3: words are blurbs sized to their text,
  never cards): anchored to the end of the shown surface's struck-ball path (where it stopped, or where a pocket took
  it), above or below by BlurbPlacement.anchored, a 2-point leader in that surface's colour that follows the camera; with
  no room either side it docks at the top of the table area with no leader. Folded to two lines; a tap opens it to the
  surface's summary. Its two small buttons: "Watch them roll" and "Show this one" (picks the sentence's surface) or, once
  something is picked, "Show all" (Blurb draws at most two buttons). It keeps its place for the whole result and moves
  only when the shown surface changes or the table area changes. While it shows, the explanation blurb steps aside, as
  for the what-if: the developer swaps that one gate in ShowpieceView (Build step 13), so two anchored blurbs never
  overlap even before the coordinator's wider swap.
- The centre stays the action: only lines, rings and symbol tags are drawn there; the one name pill (TablePathStroke.label)
  goes at the end of the shown surface's path only when no blurb is anchored there (never two words on the table).
- Opening Your shot (the strip's primary action, or Y) closes the fan, as it closes the what-if.

### Phone sideways (side column) and the narrow bottom stack

- Entry: the Surface menu (SurfaceMenuButton in ScreenHeader) gets "Every surface" as its first item with a divider under
  it, shown while the fan can open. The keyboard shortcut works here too on a hardware keyboard (iPad).
- EveryWorldCard follows WhatIfCard in the side column and the bottom stack (only one of the two can show). Full form
  (side column, notebook): the title and Close; the sentence about the fan (or the picked surface) with its summary
  under it in the secondary colour; ten rows, each a 44-high button with the colour dot, symbol, title and that
  surface's own one-line sentence (checkmark on the picked one, "Played here" on home); then "Watch them roll", and
  "Play on Ice" as the prominent button when `canSwitch`. Glass card as WhatIfCard (`.glassCard(cornerRadius: 22,
  padding: 12)`). It does NOT wrap anything in its own FittingScroll or ScrollView: every container it sits in already
  scrolls (bottom stack FittingScroll, side column ScrollView, notebook pages), and a scroll inside a scroll fights.
- Compact form, on WhatIfCard's own rule (`lensReplayCompact`, or upright size classes outside the notebook: the narrow
  bottom stack, for example a closed Duo or a narrow iPad window): title and Close, the sentence folded to two lines
  (tap opens it to the summary), the same horizontal chip row as the phone panel (EveryWorldChipRow, shared), and one
  button row. Under a guided Lens replay (`lensReplayCompact`) the chip row is left out, as WhatIfCard's slim form
  leaves out its picker. Ten 44-point rows would take the table's height in the bottom stack.

### Open Duo, iPad and Mac (notebook)

- The table half shows only lines, rings and symbol tags: no pill, no blurb (the inlinePages environment value, as
  WhatIfOverlay already checks). All words are on the other half: EveryWorldCard in NotebookPanel.cards right after
  WhatIfCard.
- Entry: the notebook's top bar Surface button (SurfaceMenuButton, whose SurfaceMenuItems gain the first item) and, on
  the Mac, the Playback menu's "Every Surface…" right after "What If…", with Shift-Command-U. Checked against
  MacChrome and the four sibling plans: Command-E is Ride Camera, Command-T Try Again, Shift-Command-T What If,
  Shift-Command-E is claimed by the clips plan (Share Clip), Shift-Command-S by the make-it-again plan; U is used by
  nothing. The Mac's own Surface Picker is left alone.

### VoiceOver, controller, one finger

- VoiceOver: the overlay is hidden from VoiceOver; the panel or card is the whole feature in words. The panel is one
  container labelled "Every surface". Each chip or row is a button whose label is the surface's title and whose value is
  that surface's sentence (or "This surface runs too long to show."), selected trait when picked, hint "Shows this
  surface's paths". When all nine have landed, the fan's sentence is announced once through ShotNarration.announce;
  picking a surface announces its sentence. "Play on Ice" has the hint "Changes the playing surface to Ice and plays your
  shot again on it".
- Controller (hook in ControllerInput.press, Build step 11): while the fan shows, left and right on the d-pad pick the
  previous or next surface (skipping home and too-long ones, wrapping through "all"); A presses "Play on …" when
  `canSwitch`, otherwise A keeps its usual job; B keeps its usual job (skip to where the balls stop) while the replay
  is still running (`model.time < model.duration`) and closes the fan once the balls are at rest. A new row in the How
  to play mapping list says so.
- One finger: every control is a single tap; nothing needs a drag, a pinch or a long press.

### First minute and calm

- Never offered before the player's own first shot has come to rest (the what-if's gate already excludes the opening).
- Never opens by itself, never suggested, no badge, no sound.

## Build steps

New files (no other developer touches these):

1. `Packages/BreakdownCore/Sources/BreakdownTimeline/BallTravel.swift` (new).
   - `public struct BallTravel: Sendable, Equatable` with `public let distance: Double` (metres the ball's centre moved
     on the table plan until it stopped or a pocket took it), `public let skidding: Double` (the part of that in
     `.sliding` segments), `public let airborne: Double` (the part in `.airborne` segments), `public let stopTime: Double`
     (the end of its last segment that is not `.stationary` or `.spinning`, or its pocket time if earlier; 0 for a ball
     that never moved), `public let cushions: Int` (events of kind `.cushion` whose `balls.map(\.ball)` contains this
     ball, up to its pocket time), and
     `public var skidShare: Double { distance > 0 ? skidding / distance : 0 }`.
   - `public init(timeline: Timeline, ball: Int)`: for each segment of `timeline.segments[ball]`, clipped to the
     ball's `pocketTime`, add the integral of the plan-view speed |velocity| (from `segment.kinematics(at:)`) by
     composite Simpson's rule with 16 slices; skip `.stationary` and `.spinning` segments. A ball index outside the
     recording gives all zeros. Comment that straight segments (rolling, and sliding with no side spin) have a speed
     linear in time, for which Simpson's rule is exact, and a curving slide is well inside a millimetre at 16 slices.
2. `Packages/BreakdownCore/Sources/BreakdownTimeline/WorldContrast.swift` (new).
   - `public struct WorldOutcome: Sendable, Equatable`: `struckBall: Int`, `travel: BallTravel` (of the struck ball),
     `firstContact: Int?` (`facts.firstContact?.ball`), `dropped: [Int]` (object balls dropped, in order:
     `facts.objectBallsPocketed.map(\.ball)`; the property is `[ShotFacts.Drop]`, not indices), `struckPocketed: Bool`
     (`facts.cueBallPocketed`); a memberwise `public init(struckBall:travel:firstContact:dropped:struckPocketed:)` for
     the tests, and `public init(timeline: Timeline, start: [Vec2], cueBall: Int)` built from
     `ShotFacts(timeline:start:cueBall:)` and `BallTravel(timeline:ball: cueBall)`.
   - `public enum WorldContrast: Sendable, Equatable` with the cases of "The sentence" items 1 to 9 (item 0 is the app's):
     `gainsDrop(ball: Int)`, `neverRolls(distance: Double)`, `neverReaches(ball: Int)`, `meetsOther(ball: Int,
     insteadOf: Int)`, `reaches(ball: Int)`, `losesDrop(ball: Int)`, `struckDrops`, `struckStaysUp`, `travel(world: Double,
     home: Double)`, `lasts(world: Double, home: Double)`, `alike`. Each case has `var rank: Int` (its place in the order).
   - `public static func key(home: WorldOutcome, world: WorldOutcome) -> WorldContrast`: the first case that holds, with
     the thresholds as named static constants (`neverRollsShare = 0.9`, `homeRollsShare = 0.6`, `minTravel = 0.3`,
     `travelRatio = 2`, `minLonger = 2`), each with a one-line comment saying why.
   - `public static func strength(of c: WorldContrast, home: WorldOutcome, world: WorldOutcome) -> Double`: the "strongest
     within a key" measure (skid share for neverRolls, |log ratio| for travel and lasts, 0 otherwise).
   - `public static func headline(home: WorldOutcome, worlds: [WorldOutcome?]) -> (index: Int, contrast: WorldContrast)?`:
     over the non-nil worlds, the smallest rank, then the largest strength, then the lowest index (the caller passes the
     worlds in PlaySurface menu order, home excluded). Nil when no world solved. Returns `.alike` (index of the first
     solved world) when every key is `.alike`.
3. `App/EveryWorldFan.swift` (new): the state, mirroring WhatIfFork.
   - `@MainActor @Observable final class EveryWorldFan` with `@ObservationIgnored unowned let model: ShowpieceModel`.
   - `struct World { let surface: PlaySurface; let attempt: ShotAttempt; let fork: TimelineFork; let outcome:
     WorldOutcome; let cuePath: [Vec2]; let trickPasses: Bool? }` and `enum Slot { case solving, solved(World), tooLong }`.
   - State: `private(set) var isOpen`, `real: ShotAttempt?`, `openedOn = -1`, `home: PlaySurface?`,
     `slots: [PlaySurface: Slot]`, `picked: PlaySurface?`, `headline: (surface: PlaySurface, contrast: Headline)?` where
     `enum Headline { case trickMade, world(WorldContrast) }`, `showSpinner`, `landings` (bumped per landing, the
     overlay's resample trigger), `picks` (bumped per pick, the haptic trigger), `tailStart: Date?`, and
     `@ObservationIgnored private(set) var clockHasMoved`. `var solving: Bool` is any slot still `.solving`.
   - `var canOpen: Bool { model.whatIf.canOpen }`: the same gate, read, not copied (comment why it is the right gate).
   - `var isShowing: Bool { isOpen && model.timelineVersion == openedOn }`.
   - `var others: [PlaySurface]`: PlaySurface.allCases without home, in menu order.
   - `func open()`: guard canOpen; `model.requestShotPanel(.close)`; `model.whatIf.close()`; reuse the kept result when
     `cache?.version == model.timelineVersion`, else start a session (token += 1, every other surface `.solving`,
     `solve()`); `isOpen = true`; reset picked, tail and clockHasMoved.
   - `func close()`: as WhatIfFork.close (token += 1, cancel the task, clear the open state; keep the cache).
   - `func dropCache()` called from close-on-load (Build step 7), so a new recording never shows an old fan.
   - `private func solve()`: capture `real.input`, `real.table`, `real.generation`, `real.start`, `real.cueBall`,
     `real.timeline`, the ball radius (`real.timeline.table.ballRadius`), the session token and
     `WhatIfFork.eventBudget` as locals (keep the running task in `@ObservationIgnored private var task: Task<Void,
     Never>?`; token and cache are `@ObservationIgnored` too, as in WhatIfFork); then
     `task = Task.detached(priority: .userInitiated) { [weak self] in await withTaskGroup(of: Landing.self) { group in
     for s in jobs { group.addTask { EveryWorldFan.solveOne(...) } }; for await l in group { await self?.landed(l,
     session: session) } } }`. `Landing` is a Sendable struct (surface, Timeline?, TimelineFork?, WorldOutcome?).
     `nonisolated static func solveOne(input:table:surface:generation:start:cueBall:home:radius:budget:) -> Landing`
     is pure (the tests call it). A 150 ms timer sets showSpinner when nothing has landed, as WhatIfFork.start.
   - `private func landed(_:session:)`: drop a stale session; build the World (attempt by
     `real.resolved(on: tl, surface: s)`, `cuePath = Self.thin(attempt.path(of: attempt.cueBall))`, trickPasses by
     `TrickShotJudge.passes(shot.goal, attempt)` when `model.trickMode.isActive, let shot = model.trickMode.current`, as
     WhatIfFork.landed does), or `.tooLong`; bump landings; when no slot is `.solving`, work out the headline (item 0
     first when the real try missed, `TrickShotJudge.passes(shot.goal, real) == false`, then `WorldContrast.headline`),
     store the cache, and announce it.
   - `nonisolated static func thin(_ points: [Vec2], minStep: Double = 0.005) -> [Vec2]`: keeps the first point, every
     point at least `minStep` metres from the last kept one, and always the last point. Pure (tested).
   - `func pick(_ s: PlaySurface?)` (nil, or home, means all; a too-long or still-solving surface is ignored), announces
     the picked surface's sentence; `func step(by: Int)` for the controller; `var canSwitch: Bool`: `isShowing`, a
     solved non-home surface picked, free play only (`!model.trickMode.isActive && !model.lessonMode.isActive &&
     !model.eightBallMode.isActive`, see "What exists today": the learn modes own their surface and their verdict),
     `model.match == nil`, `!model.isSolving`, `!model.menuOpen`, and the switch would solve what was drawn:
     `real.table == model.physicsTable && real.generation == model.activeModelGeneration && real.surface ==
     model.surface` (comment why: setSurface solves through prepare with the live table and generation, and guards
     `s != surface` against the stored choice). `func switchToPicked()`: guard canSwitch, then
     `model.setSurface(picked)` (whose load closes the fan).
   - `func playAll()`, `func clockMoved(from:to:)`, the tail rules: copied in shape from WhatIfFork.playBoth and
     clockMoved, with the tail's end the longest shown world's duration.
   - `func ballsToDraw(_ w: World) -> [Int]`: the what-if overlay's rule (struck ball, first struck there or at home,
     first ball whose drop differs; only those in `w.fork.changedBalls`; at most three).
   - Helpers the views read: `world(_ s:) -> World?`, `sentence(for s:) -> String`, `fanSentence: String?`.
4. `App/EveryWorldWords.swift` (new), `@MainActor enum EveryWorldWords`: every string of "Words to translate", each a
   whole `String(localized:)` sentence with interpolated text (numbers formatted first with AppLocale.numbers, as
   WhatIfWords.number does; ball names by `TableWords.ballName(_:cueBall:table:)`). `static func sentence(_ c:
   WorldContrast, surface: PlaySurface, real: ShotAttempt) -> String`, `static func trickMade(_ s:) -> String`, the fixed
   lines, and `static func spoken(_ s:, fan:) -> String` for a chip's VoiceOver value. The translator notes under
   "Words to translate" go in each call's `comment:` argument (`String(localized: "...", comment: "...")`): the merge
   script's pending JSON has no comment field. The surface name is `surface.title` (already translated).
5. `App/EveryWorldLook.swift` (new): `extension PlaySurface { func fanColour(_ contrast: ColorSchemeContrast) -> Color }`
   with one normal and one brighter value per surface, in the bed's own family: cloth green (0.36, 0.80, 0.42), tournament
   blue (0.38, 0.52, 1.0), dive-bar olive (0.70, 0.72, 0.32), ice white-blue (0.86, 0.94, 1.0), glass silver (0.66, 0.70,
   0.76), rubber red (0.95, 0.32, 0.26), cork amber-brown (0.86, 0.58, 0.32), carpet wine (0.78, 0.30, 0.42), sand
   yellow (0.96, 0.84, 0.50), Moon grey (0.80, 0.80, 0.84); brighter values about 15 per cent nearer white. Comment that
   identity never rests on hue (symbol tags, one strong line) and why magenta, cyan and violet are avoided.
6. `App/EveryWorldOverlay.swift` (new): `struct EveryWorldOverlay: View` on WhatIfOverlay's pattern (TimelineView
   animation, Canvas, `AimProjector.CameraBox`, `TablePathStroke` for lines, rings and the one pill, allowsHitTesting
   false, ignoresSafeArea, accessibilityHidden). Samples picked-surface paths once per `fan.landings`/`fan.picked`
   change into @State; each frame projects stored points only. Draws per "What is drawn". The symbol tag: a filled dark
   circle then `ctx.resolve(Image(systemName: s.symbol))` tinted the surface colour, at the path's last point. Reads
   `\.inlinePages` (no pill in the notebook), `\.accessibilityDifferentiateWithoutColor`, `\.colorSchemeContrast`.
   `.onChange(of: model.time)` calls `fan.clockMoved(from:to:)`. While `model.rideStatus != nil` it draws the ghost
   balls (and a picked surface's rest rings) only, no paths, tags or pill (see "What is drawn", Ride). The ghost clock
   is WhatIfOverlay.ghostTime's rule with the cap at each world's own `timeline.duration`.
7. `App/EveryWorldViews.swift` (new): `EveryWorldMenuItem(model:divider: Bool = false)` (a Button with Label "Every
   surface", square.3.layers.3d, the menu hint as accessibilityHint; its body is empty unless `canOpen && !isShowing`,
   and with `divider: true` it adds a `Divider()` after the button inside the same condition, so the Surface menu never
   shows a stray divider), `EveryWorldChipRow` (the horizontal row of ten chips, shared by the phone panel and the
   compact card), `EveryWorldCard` (side column, bottom stack, notebook; full and compact forms as in the design, reading
   `\.lensReplayCompact`, `\.inlinePages` and the size classes exactly as WhatIfCard.compact does; no inner scroll),
   `EveryWorldPhonePanel` (bottom bar), and
   `EveryWorldPhoneBlurb` (anchored blurb). The phone panel reuses `PhoneAimPanel.corner` and `PhonePanelControl` for
   its glass, as WhatIfPhonePanel does; the blurb follows WhatIfPhoneBlurb's placement code with the anchor swapped for
   the shown surface's path end and the leader colour for the surface's colour (the placement maths stays in
   BlurbPlacement). `.sensoryFeedback(trigger: fan.picks)` with the Vibration setting. Animations off under Reduce Motion.
8. `localization/pending/v077-every-world.json` (new): `"keys"` (every English key below, exactly as the catalog will
   hold it: Swift turns each interpolation into %@) and `"translations"` for the eleven cultures, written natively (not
   word for word), placeholders kept in count and kind (positional %1$@ allowed where a language reorders). Also
   `localization/pending/v077-every-world-keys.json` (new): the same English keys alone, as a bare JSON array, which is
   what the merge script's `--keys` option reads. Do NOT edit App/Localizable.xcstrings.
9. `BreakdownTests/EveryWorldTests.swift` and `Packages/BreakdownCore/Tests/BreakdownCoreTests/WorldContrastTests.swift`
   (new): see Tests.

Hook points in shared files (small, each marked with a comment naming this plan):

Anchors below are the existing lines to search for, not line numbers: five worktrees will move the numbers.

10. `App/ShowpieceModel.swift`, in the "What if (WhatIfFork)" MARK block, right after the `var whatIf: WhatIfFork`
    accessor: `@ObservationIgnored private var everyWorldStorage: EveryWorldFan?`; `var everyWorld: EveryWorldFan`
    (made on first use, exactly the whatIf pattern, whose comment says creating it lazily must not count as a change);
    `var everyWorldIfMade: EveryWorldFan? { everyWorldStorage }`; and
    `var otherFutureShowing: Bool { whatIf.isShowing || everyWorld.isShowing }`.
    Which accessor where, and why: every VIEW (and otherFutureShowing, which views read) reads `everyWorld`, the
    creating accessor, because a read of the observation-ignored storage sets up no observation, so a view that first
    saw nil would never redraw when the fan opens. `everyWorldIfMade` is only for non-view code that must not create the
    fan: `load()`, `WhatIfFork.open()` and ShowpieceView's Your-shot onChange. The Mac menu reading `everyWorld.canOpen`
    creates the fan when the menu is built; that is intended (it is one small object) and must not be "fixed".
    In `load(_:showpiece:)`, right after `whatIfStorage?.close()`: `everyWorldStorage?.close();
    everyWorldStorage?.dropCache()`. Add one Edited line to the header. Nothing else in the model changes (setSurface
    already does the switch, and its load closes the fan).
11. `App/WhatIfFork.swift`, `open()`: right after `model.requestShotPanel(.close)`, `model.everyWorldIfMade?.close()`, so
    the two never show together. One Edited line in the header.
12. Step aside while the fan shows. The developer does the three swaps in ShowpieceView.swift (a file they edit anyway;
    Build step 13), so the phone never shows the explanation blurb and the fan's blurb at once, and the last-try ghost
    and stroke trace never draw under the fan. The other files are the coordinator's, after the merge: replace
    `model.whatIf.isShowing` with `model.otherFutureShowing` wherever it gates another card, blurb, primary action or
    overlay. Grep `whatIf.isShowing` under App/ and swap every hit EXCEPT in the WhatIf*.swift files, ScrubBar.swift (the
    parting diamond), PhoneTitleRow.swift (the What if menu item's own gate), and these three in ShowpieceView.swift:
    the `WhatIfOverlay` mount, the `WhatIfPhonePanel` branch in phoneBar and phoneBar's `.animation(... value:
    model.whatIf.isShowing)`. On main today that leaves eighteen code hits for the coordinator: GhostOverlay (1, the
    comparison's `shows`), FreePlayViews (3; the fourth match is the header comment), FreePlayPhoneBlurbs (4),
    TrickShotViews (3), LessonViews (3), EightBallViews (1), EightBallPhoneBlurbs (2) and StrokeViews (1). The sibling
    features add more after the merge (the achievements plan gates on `!model.whatIf.isShowing`; clips reads it for its
    source): judge each new hit the same way (a gate that steps aside for the what-if steps aside for the fan too; a read
    of the what-if's own result does not change). Until it is done the fan still works; mode cards just stay up beside
    it.
13. `App/ShowpieceView.swift` mounts (views read `model.everyWorld`, see step 10):
    - stage(...), the three step-aside swaps of step 12: in `if model.ghost != nil && !model.whatIf.isShowing {
      GhostOverlay(...) }`, in `if model.currentAttempt?.stroke?.trace.isEmpty == false && !model.whatIf.isShowing {`
      (StrokeTraceOverlay) and in `if !model.whatIf.isShowing { PhoneExplanationBlurb(...` replace
      `model.whatIf.isShowing` with `model.otherFutureShowing`. Nothing else in the file changes that token.
    - stage(...): right after the line `if model.whatIf.isShowing { WhatIfOverlay(model: model, bridge: bridge) }`, add
      `if model.everyWorld.isShowing { EveryWorldOverlay(model: model, bridge: bridge) }`.
    - stage(...), upright branch: right after the `WhatIfPhoneBlurb(model: model, bridge: bridge, tableArea: ...)` block
      and its three menu-hiding modifiers, `EveryWorldPhoneBlurb(model: model, bridge: bridge, tableArea:
      phoneTableArea(geo))` with the same three modifiers.
    - phoneBar: turn `if model.whatIf.isShowing { WhatIfPhonePanel(model: model) } else if showShotPanel {` into
      `... } else if model.everyWorld.isShowing { EveryWorldPhonePanel(model: model) } else if showShotPanel {`, and add
      `.animation(reduceMotion ? nil : .smooth, value: model.everyWorld.isShowing)` beside the what-if one.
    - bottomStack: `if !wide { EveryWorldCard(model: model) }` right after `if !wide { WhatIfCard(model: model) }`;
      sideColumn's card stack: `EveryWorldCard(model: model)` right after `WhatIfCard(model: model)`.
    - The Your-shot onChange: right after `if model.whatIf.isOpen { model.whatIf.close() }`,
      `model.everyWorldIfMade?.close()`.
    - SurfaceMenuItems (a struct with `let model`): add a stored `var offersEveryWorld = true` after `model`, so the
      memberwise init takes `SurfaceMenuItems(model:offersEveryWorld:)` and every existing `SurfaceMenuItems(model:)`
      call still compiles; before the ForEach, `if offersEveryWorld { EveryWorldMenuItem(model: model, divider: true) }`
      (the item and its divider show only while the fan can open). SurfaceMenuButton (ScreenHeader and the notebook's
      top bar) gets it through this, unchanged.
14. `App/NotebookPanel.swift` cards: `EveryWorldCard(model: model)` right after `WhatIfCard(model: model)`.
15. `App/Phone/PhoneTitleRow.swift` menuItems: after the What if block (`if model.whatIf.canOpen &&
    !model.whatIf.isShowing { ... }`), `EveryWorldMenuItem(model: model)`; and the Surface submenu passes
    `SurfaceMenuItems(model: model, offersEveryWorld: false)` so the item is not listed twice. The clips plan also adds
    its items right after the What if block; the coordinator keeps both (What if, Every surface, then the clip items).
16. `App/MacChrome.swift`, in the PLAYBACK menu's `playbackItems` (`CommandMenu("Playback")`; there is no Game-menu
    "What If…"), right after the "What If…" button and its two modifiers: `Button("Every Surface…") {
    model?.everyWorld.open() }.keyboardShortcut("u", modifiers: [.command, .shift]).disabled(!((model?.everyWorld.canOpen
    ?? false) && !(model?.everyWorld.isShowing ?? false)))`, with a one-line comment as the What If item has. Add
    "Every Surface… (Shift-Command-U)" to the header's list of Playback items (the PURPOSE comment near line 58).
17. `App/ControllerInput.swift`: in `press(_:)`, right after `if button != .menu, pageUp(model) { return }`, a block:
    when `let fan = model.everyWorldIfMade, fan.isShowing`, then `.left` calls `fan.step(by: -1)` and returns, `.right`
    `fan.step(by: 1)` and returns, `.a` calls `fan.switchToPicked()` and returns only when `fan.canSwitch` (else it falls
    through to the usual A), `.b` calls `fan.close()` and returns only when the balls are at rest (`model.time >=
    model.duration - 1e-6`; while the replay runs B keeps its usual skip). Up and down keep their jobs. In `mapping`, one
    new row after the D-pad row (strings in Words). Update the header's mapping comment.
18. Not touched: TableScene, ShotCamera, TableCamera, LensLayer, Captions, SoundBoard, GameSettings (no new setting:
    the fan is an action, not an option), Surfaces.swift, PlaySurface.swift, PlaySurfaceLook.swift, the package's
    Timeline, ShotFacts, TimelineFork, Simulation, ShotNudge and TableSurfaces, the Xcode project file (synchronised
    groups, see above), App/Localizable.xcstrings (the pending file instead).

For the coordinator after the merge (not the developer):

- Do Build step 12's swap in the eight files left to you, and judge the sibling features' new hits.
- Translations: run `python3 scripts/localization-merge.py localization/pending/v077-every-world.json --keys
  localization/pending/v077-every-world-keys.json` (the developer writes both files; the script reads
  `"translations"` from the first and a bare array of English keys from the second), then
  scripts/translation-check.py; build; run the package and app tests.
- Shortcuts: confirm the merged MacChrome has Shift-Command-U only once (this plan) and Shift-Command-E only once (clips).
- CHANGELOG, under 0.7.7: "Same shot, every surface. After your own shot, Every surface plays the exact stroke on all
  ten surfaces at once and fans the paths over the table, with one sentence on the most striking difference; pick one
  to watch its balls roll beside yours, and Play on it to switch. Why: the Boss asked for the same shot on every
  world (23-Nov-2026)." Credit the builder by model and effort.
- The spec's status note: add the fan to "Built" beside the what-if.

## Tests

Package, `WorldContrastTests.swift` (hand-built Timelines from a few BallSegments, no solver needed, plus one solved
shot through the package's own helpers):

- A ball rolling straight at constant deceleration: BallTravel.distance equals v squared over two a to a micrometre;
  skidding is zero.
- A sliding then rolling ball: skidding is the sliding segment's length; skidShare is between 0 and 1.
- A pocketed ball stops counting at its pocket time; a ball that never moved gives zeros; an index outside the
  recording gives zeros.
- key(home:world:) returns each case on a pair built for it, and `.alike` for identical outcomes.
- headline picks the earliest rank, then the strongest, then the lowest index; nil when every world is nil.
- WorldOutcome reads `dropped` as ball numbers (a hand-built pot of the 3 gives `[3]`) and `struckPocketed` from the
  pocket, not from a ball that flew off the table.

App, `EveryWorldTests.swift` (XCTest, as WhatIfTests. Its helpers `strike`, `freshModel`, `settle`, `solved` and
`freePlayShot` are `private` to WhatIfTests, so copy the ones needed into this file under the same names, plus a
`solvedFan` wait that polls until no slot is `.solving`; use `RideDemo.straightPot()` / `TestShots` for the shot):

- solveOne on the home surface reproduces the attempt's recording exactly (same motionHash), so solving through
  solverCopy is the same path the model takes. Once on the pool table and once on bumper pool (set the table with
  `playTable(.bumperPool)` first, restore `.standard` at the end), so a table mismatch cannot hide behind cloth.
- `EveryWorldFan.thin` keeps the first and last points and drops a run of points closer than 5 mm.
- On the straight pot, every one of the nine other surfaces either solves or is reported too long; none is missing.
- On the straight pot, ice's struck-ball travel is longer than home's and ice's key is not `.alike` (the surface
  numbers make ice roll for ages; no particular key is asserted, since the key is read from the recording).
- Every WorldContrast case produces a non-empty sentence, on the pool table and on bumper pool (ball names).
- canSwitch is false in a trick shot's, a lesson's and a Behind the 8-Ball situation's judged try even with a solved
  surface picked, and true in free play.
- The gate: offered after a free-play shot at rest; not while solving, on a break, with the menu open, in the opening,
  or in a match (mirrors the what-if tests).
- A landing after close() is dropped and leaves the model untouched (timelineVersion, currentAttempt, surface).
- Opening the what-if closes the fan, and opening the fan closes the what-if.
- Play on: after switching to a picked surface, the shot on screen has the same motionHash as that surface's World, and
  the fan is closed; the stored surface is the picked one (restore cloth at the end of the test).
- A trick shot's judged try: the fan never judges or marks the trick done (the what-if's test, repeated for the fan).
- Speed: log how long the nine solves of the straight pot take (a print, no assertion: a time bound is flaky on shared
  machines).

## Words to translate

All into localization/pending/v077-every-world.json, for es, fr, de, it, pt, pt-BR, ja, ko, zh-Hans, ru and ar, written
natively. Keys as the catalog holds them (%@ for each interpolation; numbers arrive as already formatted text):

- "Every surface"
- "Every Surface…" (Mac menu)
- "Shows your shot played on every surface at once" (menu hint)
- "Same stroke on every surface." (card's fixed line)
- "Working out every surface"
- "This surface runs too long to show."
- "Played here"
- "Watch them roll", hint "Plays your shot again with every surface's balls rolling beside it"
- "Show this one", "Show all"
- "Shows this surface's paths" (chip hint)
- "Play on %@", hint "Changes the playing surface to %@ and plays your shot again on it"
- "On %@ this trick shot would have worked."
- "On %@ %@ drops; here it stayed out."
- "On %@ %@ never settles into a roll: it skids almost all of its %@ m."
- "On %@ %@ never reaches %@."
- "On %@ %@ meets %@ first, not %@."
- "On %@ %@ reaches %@; here it touched nothing."
- "On %@ %@ stays out; here it dropped."
- "On %@ %@ drops into a pocket; here it stayed up."
- "On %@ %@ stays on the table; here it dropped."
- "On %@ %@ travels %@ m; here it went %@ m."
- "On %@ %@ keeps moving for %@ seconds; here it stopped after %@."
- "Much the same as here."
- "Every surface plays this shot almost the same way: it is over before the surface makes much difference."
- Controller row: control "D-pad, with Every surface open", action "Left and right pick a surface. In free play A plays
  your shot on it. Once the balls stop, B closes Every surface."

Translator notes, written in each `String(localized:comment:)` call's comment (the pending JSON carries only keys and
translations): the first %@ in the "On %@" sentences is a surface name from the Surface
menu (Ice, Moon, Dive-bar felt); the second is a ball name ("the cue ball", "the 3 ball", or another table's ball);
translations may reorder with positional placeholders. "m" is metres and follows the language's own symbol (Arabic
and Russian use theirs, as the existing captions do). No names of people, brands or places anywhere.

## Out of scope

- Breaks and matches (the what-if's gate excludes them: a break's sixteen balls make nine fans unreadable, and a match's
  shot belongs to the rules).
- Other tables' shapes on one surface, or a table switch inside the fan: only surfaces fan out.
- "Play on" inside a trick shot, a lesson or a Behind the 8-Ball situation: they are set and judged on their own
  surface, so the fan there is for looking; the Surface menu keeps working there as it does today.
- Saving, sharing or exporting the fan (the clips feature may later record it; see Risks).
- Achievements for using it (the achievements developer can read `everyWorld.isShowing` or the switch; nothing is added
  here for them).
- Any change to the surfaces' numbers, looks or the Surface menu's rows themselves.
- Any sound, music or Moon-specific audio.

## Risks

- Ten colours on green cloth. Mitigated by design (symbol tags, one strong line, dashes with Differentiate Without
  Colour); the Boss plays it himself on the TestFlight build.
- Long surfaces: ice and the Moon can run tens of seconds, so their solves are the slowest and their ghost tails long.
  The fan fills in progressively and the tail can be cut by any scrub; nothing waits on them. If a solve proves slow on
  device, lowering the event budget for the fan alone is a one-constant change.
- Merge conflicts: Build step 12's swap spans eight files outside ShowpieceView that the other features may also touch,
  which is why the coordinator does those after the merge rather than the developer.
- Shared lines with the other features: ShowpieceView.phoneBar and the stage's overlay list, the title row's More
  menu (clips inserts at the same spot), ControllerInput.press (make-it-again adds a button case; clips hooks
  pressCardButton), MacChrome's Playback menu (make-it-again and clips add items there too) and its shortcuts.
  Shift-Command-U is this plan's alone as of the four sibling plans; the d-pad block only acts while the fan shows.
- Clips to share: the fan is drawn in a SwiftUI Canvas over the 3D view. A clip recorder that captures only the 3D
  layer will not show it; the clips developer should know.
- Bullet time: the ghosts follow the model's clock, so a freeze on the hit holds them too. The tail clock (wall time
  times the chosen speed) starts only once the real clock reaches its end, after any freeze, so the two never run at
  once. If the bullet-time build ever holds the clock at the very end of a recording, the tail must not start until
  the hold lets go (clockMoved only starts it when `model.time` crosses the end, which a hold does not do).
- Behind the 8-Ball, lessons and trick shots name their own surface: the fan offers no switch there (canSwitch is free
  play only); the Surface menu behaves as it does today.
- "On Moon" reads oddly in English because the surface's title is "Moon"; the same is already true of the Lens captions.
  Left as is to keep one name per surface.
