<!--
Author: Claude Opus 5.5 High
Date: 23-November-2026
PURPOSE: Build plan for version 0.7.7's "bullet time on the hit": on a rare or powerful ball-to-ball contact in normal
         play (Lens off), the clock stops for a moment at the touch, the camera swings round the two balls low over the
         cloth while the line of the push, the tangent and the split of their speeds hang in the air between them, then
         time lets go. Written to be built blind by one developer in their own worktree, alongside four other 0.7.7
         features, and merged by the coordinator: new code lives in new files, and every edit to a shared file is a
         short, listed hook point. Read from the 0.7.6 code (ShowpieceModel, TableScene, TableCamera, ShotCamera,
         LensLayer, LensContactGeometry, ShotHighlightJudge, HighlightOffer, Haptics, SoundBoard, GameSettings, the
         status slots in PhoneTitle, ShowpieceView and NotebookPanel) and the package's ShotFacts, Timeline and LensEvent.
SRP/DRY check: Pass - checked ShotHighlightJudge.swift (its ShotMoments event finders and thresholds are reused, never
         copied, as its header asks), HighlightOffer.swift (the rarity bookkeeping is mirrored in shape, not shared,
         because the rules differ), LensContactGeometry.swift and LensLayer.swift (the 0.7.4 contact drawing is reused by
         giving it a second owner, not redrawn), ShotCamera.swift (mix, frameInFreeSpace, rideFov and rideNear are
         reused) and PacePlan.swift (the guided hold; bullet time is a separate, shorter hold that never runs with it).
Edited: Claude Opus 5.5 High, 23-November-2026 (independent review against the 0.7.6 code: hard-break speed raised to
         fit the 7 to 16 m/s break range; the clock-jump test fixed to SoundBoard.follow's real allowance; frame() moved
         ahead of the stage switch so leaving the table ends a freeze; the freeze only begins on the contact itself; the
         arming gate now closes for Ride and the Lens; one cancel line in scrub(to:); bloom kept on the moved contact
         drawing; Float types, imports, the haptic's hum, the Feel footer, the en catalog entries and the tests made
         exact; post and pin clearance for the low camera; merge notes for the clips feature's SceneClock).
-->
# Bullet time on the hit

## In plain words

Once in a while, when a shot has a moment worth stopping for, the game stops it. The cue ball has just reached the
ball it is going to hit; the two balls touch; and time stands still. You feel a firm buzz in your hand and hear the
click of the two balls. The camera drops down to the cloth and swings round the two touching balls. In the air between
them appear three things: a dashed line through both centres (the way the push goes), a finer line across it (the
tangent, the way a glancing ball slides off), and arrows showing how the speed is shared out between the two balls. A
short line of words at the top names the moment, for example "The kiss that sends it in". Less than two seconds later,
time lets go, the balls fly apart, and the camera rises back to the table as the shot plays out.

It happens on the moments people remember: a near-full-power break, a thin cut that drops, a jump shot landing on its
ball, the end of a curving masse shot, and a kiss or combination that sends a ball into a pocket. It never happens more
than once in a shot, never during the opening or the first break of a new player, never while the Lens is on or Ride
is riding, and the ordinary moments are rationed so it stays special. The break only freezes when it is struck near
the top of the power range and is the hardest break of the session so far; an ordinary break never does. A switch in Options, "Freeze the big hits", turns it off. With Reduce Motion on, time
still stops and the lines still appear, but the camera does not move. Nothing has to be pressed: it ends by itself.

## What exists today (read in the code)

The project: both App and BreakdownTests are file-system synchronised folders in Breakdown.xcodeproj (the App folder
has only two README files excepted). Any new Swift file put in App/ joins the app, and any new file in BreakdownTests/
joins the tests, with no edit to the project file. This plan does not touch the project file; the coordinator bumps
MARKETING_VERSION to 0.7.7 once for the whole batch.

The clock and its owners (App/ShowpieceModel.swift):
- advance(_:) runs every frame. In the ordinary table stage (.explore) the clock has three owners today: the ride's
  rewind (rideAct == .rewind), guided pacing (guided: Lens on and not riding; stepGuided holds on beats with its own
  real-time counter), and otherwise advanceRide(dt) (the ride's acts) or, when that returns false, the plain step:
  displayRate = chosenRate times Ride's slow-motion curve, then step(dt).
- step(_:) moves time forward and calls fireSounds(from:to:), which plays every event crossed in that frame as sound
  and touch (FeelMapping.cues, SoundBoard.play, Haptics.play). Scrubbing sets time directly and never makes a sound.
- Nothing can hold the clock in plain explore today: holding needs guided, and the ride's hold needs its acts.
- advance returns before the stage switch whenever menuOpen is true (openMenu also sets playing false), so nothing in
  the switch runs behind the menu. scrub(to:) sets playing false, sets time directly, then resetPacing and
  settleRideActsAfterJump; skipToResult does the same to the end. replay(withLens:) sets time 0 and playing true.
- SoundBoard.follow (the only "is this playback or a jump?" test in the app) treats a forward step as playback when it
  is at most rate x (1/20) x 1.5 + 1e-4: the frame step is clamped to 1/20 of a second, so the allowance uses that
  ceiling, not the current frame's dt.
- PlayerShotSpeed.rackBreak is 7 to 16 m/s and the break panel's default is 10 m/s at the strike (TestShots.breakInput
  says so), which arrives at the rack at a little under 10 m/s.
- finishStrike(_:prepared:settings:undo:) puts every live strike on screen (the player's, the computer's in a match,
  trick-shot and Behind the 8-Ball attempts): load(tl), stage .explore, time 0, playing, real speed, and last of all
  judgeHighlight(tl, isBreak:), which runs ShotHighlightJudge only once openingStage is .none and outside the authored
  modes and the drill. freePlayBreaksStruck counts free-play breaks so the break card never comes on the first one.
- startHighlightRack() is called on every fresh rack, new table, match or mode (HighlightOffer.startRack and friends).
- shotFacts (private) and shotFactsOnScreen (internal) hold the package's ShotFacts reading of the recording on screen;
  captions hold CaptionEngine's captions (Caption.id is the event index).
- rideActive, rideAct, guided, melt, menuOpen, timelineVersion, solvedTable, match, whatIfStorage, lessonModeStorage,
  strokeDrillStorage are all there to gate on.

The moments (App/ShotHighlightJudge.swift, App/ShotHighlight.swift, App/HighlightOffer.swift):
- ShotMoments is the one set of event finders over a recording: firstContact(of:), contacts(of:), lastContact(of:
  atOrBefore:), other(in:than:), takeOff(of:minimumUp:), landing(of:after:), strikeCurl(of:), largestBend(of:
  atOrBefore:), railAfterLastContact(of:), pocket(of:), time(_:). Its header says nothing else should grow a copy.
- ShotHighlightJudge holds the thresholds this plan reuses: jumpSpeed 0.5 m/s, curveDegrees 10, curveCurl 0.1.
- HighlightOffer is the rarity bookkeeping for the "worth watching" card: rare kinds always, common kinds once per rack
  and a three-shot gap, the computer's shots only for rare kinds (offersComputerShot). Bullet time mirrors that shape.

The drawing (App/LensContactGeometry.swift, App/LensLayer.swift):
- ContactGeometry.at(event) lays out one ball-to-ball hit: the contact point, the unit line of centres (striker into
  object), the tangent, which ball struck which, the incoming speed and both outgoing speeds, whether the struck ball
  was already moving, and the square-hit test.
- LensLayer draws it (0.7.4, "see the hit"): the dashed line of centres, the tangent (finer dashes, or dots with
  Differentiate Without Colour), the momentum triangle (incoming arrow paper white, both outgoing arrows cyan, head to
  tail so it closes) and the square mark, faded in over a quarter second of real time, posed every frame with the 0.7.6
  screen floors, faded out when the hold ends. It is driven by heldEvent, which TableScene sets from the guided hold.
- The catch for bullet time: the drawing's parent, contactRoot, is a child of LensLayer.root, whose opacity is the melt
  and which is switched off below a hair of melt; and applyContact opens with "guard m > 0.02". Bullet time runs with
  the Lens off (melt 0), so today the drawing could never show for it. The line of centres is also hidden whenever the
  Lens's throw lines already draw it, and those live under root too. fingerprint() and LensScrubCheck leave the
  contact drawing out on purpose (it follows real time, not the clock).
- The glow: LensLayer.init calls the private static enableBloom(on: root), which puts BloomComponent(scope:
  .hierarchical) and a BloomOptionsComponent on root, so the contact drawing glows today only because it sits under
  root. Every contact part uses the Lens's ModelSortGroup(depthPass: nil) and an UnlitMaterial.
- TableFrame.world(_ p: Vec2, height: Float) and TableFrame.ballRadius are Float; TableSpec (timeline.table) is Double
  and has posts and pins, each with center, radius and height (Double).

The camera (App/TableCamera.swift, App/ShotCamera.swift, App/TableScene.swift, App/TableStage.swift):
- TableCamera.update builds the fitted pose, the moment framing, the hand zoom, then asks the ride for an override
  (ShotCamera.override), then the lamp shot, then applies it. TableScene owns the TableCamera and the ShotCamera, and in
  updateCamera sets zoom.rideHold = shotCamera.flying so a pinch never fights the ride.
- ShotCamera.mix blends two camera shots by heading and tilt separately (the 0.7.6 fix for the picture flipping
  through straight down); frameInFreeSpace turns a view so its target lands in the measured free space (at a fixed
  ballPlace of 0.72 down it); rideFov gives the ride's wide lens for the screen shape; rideNear is the close near plane.
- TableStage's per-frame closure advances the model, sets table.lensHeldEvent and table.rideCue from the model, calls
  table.apply, then table.updateCamera. TableScene.apply sets each ball body's opacity to 1 - 0.55 x melt.
- TableCamera.reduceMotion is the Reduce Motion switch every camera move honours.

Sound and touch (App/SoundBoard.swift, App/SoundStage.swift, App/Haptics.swift, App/FeelMapping.swift):
- Only contacts sound; a travelling ball makes no sound at all (0.7.6). SoundStage.stretch stretches a cue's internal
  delays in slow motion, clamped at a quarter speed, so at the slow approach a break's trailing scatter clicks come up
  to four times further apart (a few hundredths of a second); that is right for slow motion and is left alone.
- Haptics.play(cues) plays a pattern per feel cue; its engine is private and absent on the Mac and simulator. Its only
  event builder is the private static tap(_:_:at:) (a transient); playEvents(_:) checks the engine and the Vibration
  option. Adding a
  new FeelKind would force edits to the exhaustive switches in SoundBoard.voice(for:) and Haptics.events(for:), so this
  plan does not add one.

Words and status (App/Phone/PhoneTitle.swift, App/ShowpieceView.swift, App/NotebookPanel.swift):
- The ride names its acts in the title row's status slot (model.rideStatus): PhoneTitle.line on the upright phone,
  the header row's RideTitleChip and the stageTitle glass label in ShowpieceView (the sideways column and the big
  window with the notebook put away), and NotebookTopBar on the open Duo, iPad and Mac (the words half).
- Options live in GameSettings.swift (keys default to on through the private flag(_:); OptionsSheet's Feel section is
  written Section("Feel") { ... } with Sound, then Vibration inside an #if os(iOS) block, and has no footer).
- The header row (ScreenHeader in ShowpieceView) is shown only off the upright phone; its stage label uses lineLimit(2)
  and its height feeds headerBottom, which feeds the camera's free space.
- The Localizable catalog's keyed strings (for example "Title: Break") carry an explicit "en" stringUnit holding the
  English default beside the eleven translations; the source language is en.
- VoiceOver announcements use AccessibilityNotification.Announcement(...).post() (ShotPanel, TableAccessLayer).

## The design

### What triggers it (decided from the recording, once, at the strike)

The freeze is always on a ball-to-ball contact, because the drawing it shows is the geometry of two balls touching. The
brief's "jump landing" is therefore the contact the jumping ball makes after it took off (whether in the air or after
it came down), not the landing on the slate itself. Every kind also needs the struck ball to be at rest before the
contact (ContactGeometry.objectWasMoving false), because only then does the momentum triangle close and "the split of
their speeds" show; a kiss between two moving balls is out of scope.

Kinds, in priority order (the first that matches wins; at most one per shot):
1. Jump hit (rare): the struck ball took off at ShotHighlightJudge.jumpSpeed or faster, and the freeze is on its first
   ball-to-ball contact at or after that take-off.
2. Curve hit (rare): the judge's own curve test (strikeCurl at least curveCurl, and the largest bend before the first
   contact at least curveDegrees); the freeze is on that first contact.
3. Kiss (rare): an object ball dropped (pocket, cup or bed hole), its last contact before the drop was not the struck
   ball's first contact (so it was a second ball, a combination or a carom off another ball), the ball it sent in was
   at rest, the ball that struck it was moving at least 0.3 m/s, and it met no straight rail between that contact and
   its drop. The first such drop in drop order wins.
4. Hard break (common, breaks only): on a break nothing else is read (as the judge does). The struck ball's speed into
   its first contact is at least 13 m/s: the break range is 7 to 16 m/s at the strike and the panel's default is 10,
   so only a break in the top part of the range qualifies and the default break never does.
5. Big cut (common): the struck ball's first contact, on a ball at rest, at a cut angle of 55 degrees or more (the angle
   between the striking ball's incoming direction and the line of centres; a half-ball hit is about 30), at least
   0.8 m/s into the hit, and that ball dropped straight from this contact (its last contact before the drop is this one
   and no straight rail came between).

Rationing (so it stays special):
- Rare kinds freeze every time they happen.
- A big cut freezes at most once per rack, and only when at least four shots have passed since the last freeze of any
  kind.
- A hard break freezes only when it is the hardest frozen break of the session by at least 0.3 m/s (the first one that
  qualifies sets the mark), and in free play never on the session's first break (the same rule the break card keeps).
- A shot the computer played in a match or table game freezes only for a rare kind.
- Never: during the opening or the new player's first break (openingStage not .none), in a lesson, in the stroke drill,
  with a match clock running (bar billiards: the slow approach would cost the player clock time), with the what-if
  fork open, with the Lens on or coming on, with Ride riding or any ride act running, during a guided replay, with the
  option off, or with the launch flag -noBulletTime (for screenshot runs). These are checked twice: once at the strike
  (so a freeze that cannot play never uses up the ration) and every frame (so one that starts and is then overtaken
  ends at once).
- The menu: opening it mid-freeze pauses the freeze exactly as it pauses the shot (openMenu sets playing false and
  advance does nothing behind the menu); the status words are hidden with the rest of the header. Continue and play
  carry on from where it was. Anything chosen from the menu that puts a new recording on the table ends it on the next
  frame (the version changes).
- Only on the live play-through of a freshly struck shot. A Replay, a scrub, a rewind or any jump of the clock ends it
  for that recording; the Lens replay is where a shot is studied again.

### The beat (real time, outside the clock)

1. Slow in: while armed, playback eases down from the chosen speed to an eighth of it over the last 0.12 seconds of
   clock before the contact, so the eye sees the ball arrive. The clock is capped at exactly the contact time, so the
   frame that reaches it crosses the contact event and fireSounds plays its click (or the break's crack) and its tap.
   No other sound is ever added.
2. Freeze, 1.8 seconds of real time (1.2 under Reduce Motion). At its first frame: a firm haptic (one new small entry
   point in Haptics, not a new feel cue), the status words appear, and VoiceOver hears one sentence. The two touching
   balls turn a little glassy (about two-thirds opaque) so the lines through them read. The contact drawing fades in
   over a quarter second, lifted to the height of the balls' centres so it hangs in the air between them. Pausing
   during the freeze pauses its counter; resuming carries on.
3. Camera, within the freeze: the first fifth blends from wherever the table camera is to a low view just above the
   ball tops, 15 degrees short of directly behind the striking ball; the next three-fifths swing it 75 degrees round
   the contact, rising as it goes, to a view side-on to the line of centres from the side the striking ball will not
   leave towards, about 25 degrees above the cloth (where the lines on the cloth plane read); the last fifth holds
   still. The contact is kept in the middle of the free space. The lens is the ride's wide lens.
4. Let go: the status words go, time speeds back up from an eighth to full speed over the next 0.3 seconds of clock,
   the drawing fades out as LensLayer already fades a hold's drawing, and the camera blends back to the table camera
   over 0.6 seconds of real time, by ShotCamera.mix, ending exactly on the table camera's own pose. If anything ends
   the freeze early (the Lens, Ride, a scrub, a Replay, a new shot, leaving the table for the intro, the option), the
   camera eases back over 0.35 seconds from where it was, never cuts.

### Upright phone

The table keeps the whole centre; nothing is laid over it except the drawing in the scene itself. The words are the
title row's status line (PhoneTitle.line), the same small status the ride's acts use, one short line sized to its
text, for the length of the freeze. No card, no blurb in the centre, no button.

### Phone sideways (the side column) and the big window with the notebook put away

The words appear as the status label in the header row, the same glass label the opening's stage title uses, beside
the back button, kept to one line (shrinking a little if a language needs it) so the header never changes height
mid-freeze and the free space the camera frames into stays still. The camera frames the contact in the measured free
space, as everywhere.

### Open Duo, iPad and Mac (the notebook)

The table half shows only the table, the drawing and the camera move. The words go to the notebook half: the
NotebookTopBar's title reads the status line for the length of the freeze, then goes back to the mode's name. The
closed Duo is the upright phone.

### VoiceOver, controller, one finger, Reduce Motion, Differentiate Without Colour

- VoiceOver: at the freeze, one announcement: the kind's status line, then "Time stops at the hit. The dashed line is
  the push between the centres, the finer line is the tangent, and the arrows share out the speed." The status slots
  already read as status. The shot's own spoken summary after it plays out (ShotNarration) is unchanged.
- Controller and one-finger play: nothing to press, ever; the freeze ends by itself. Any control that already moves the
  clock (scrub, Replay, play and pause) behaves as described above. The Options toggle is a standard toggle.
- Reduce Motion: the freeze, the haptic, the words and the drawing all happen; the camera does not move at all, and
  the freeze is shorter (1.2 seconds).
- Differentiate Without Colour: the drawing's own rule applies (the tangent as dots).
- The hand zoom ignores pinches, pans and double taps while the bullet camera has any say (as it does for the ride).

## Build steps

Every new file starts with the standard header (Author: Claude Opus 5.5 and your effort level, Date, PURPOSE, SRP/DRY
check). Every shared file you edit gets one "Edited:" line at the top of its header naming 0.7.7 bullet time and this
plan, and nothing else in the header changes (five developers add such lines; the coordinator keeps them all). Do not
compile; the coordinator compiles once after the merge. Do not edit CHANGELOG.md: put your changelog paragraph (What,
Why, Author) at the end of your report to the coordinator, who writes the 0.7.7 section once.

Imports (each new file mirrors its nearest sibling): BulletTimePick.swift and BulletTimeBudget.swift as
ShotHighlightJudge.swift (Foundation, BreakdownLensModel, BreakdownTimeline; add BreakdownPhysics only if a type from
it is used); BulletTime.swift adds SwiftUI to those (Observation and AccessibilityNotification come with it);
BulletTimeCamera.swift as ShotCamera.swift plus BreakdownLensModel and BreakdownTimeline (Foundation, CoreGraphics,
simd). Both test files mirror ShotHighlightJudgeTests.swift (@testable import Breakdown, BreakdownLensModel,
BreakdownPhysics, BreakdownTimeline, XCTest).

### New files

1. App/BulletTimePick.swift: the trigger judge. Pure, no views, no model.
   - enum BulletKind: String, CaseIterable, Sendable, cases in priority order: jumpHit, curveHit, kiss, hardBreak,
     bigCut. var isRare: Bool (true for jumpHit, curveHit, kiss).
   - struct BulletMoment: Equatable, Sendable: kind; event (Int, index into timeline.events, a ball-to-ball contact);
     time (Double, that event's clock time); striker and object (Int, from ContactGeometry); incomingSpeed (Double,
     m/s, the striker's speed into the hit).
   - enum BulletTimePick with the constants breakSpeed = 13.0, cutDegrees = 55.0, cutSpeed = 0.8, kissSpeed = 0.3,
     each with a doc comment saying what it is and why (breakSpeed: the break range is PlayerShotSpeed.rackBreak, 7 to
     16 m/s, and the default break of 10 must never qualify); and
     static func candidates(timeline: Timeline, facts: ShotFacts, captions: [Caption], isBreak: Bool) -> [BulletMoment]
     (every kind that qualifies, at most one per kind, in BulletKind order) and
     static func pick(timeline:facts:captions:isBreak:) -> BulletMoment? { candidates(...).first }.
     Build ShotMoments(timeline:captions:) once; cue = facts.cueBall; first = m.firstContact(of: cue).
     A private helper moment(_ kind:, _ i: Int?) -> BulletMoment? returns nil unless i is a valid index whose event
     gives a ContactGeometry with objectWasMoving false; otherwise fills the moment from that geometry.
     - isBreak: return moment(.hardBreak, first) when the geometry's striker is cue and its incoming length is at least
       breakSpeed; else nil. Nothing else is read on a break.
     - jumpHit: if let up = m.takeOff(of: cue, minimumUp: ShotHighlightJudge.jumpSpeed), the first index in
       m.contacts(of: cue) whose time is at least m.time(up).
     - curveHit: (m.strikeCurl(of: cue) ?? 0) >= ShotHighlightJudge.curveCurl, first exists, and m.largestBend(of: cue,
       atOrBefore: m.time(first)) has abs(degrees) >= ShotHighlightJudge.curveDegrees; the moment is on first.
     - kiss: for drop in facts.objectBallsPocketed: c = m.lastContact(of: drop.ball, atOrBefore: drop.time); require c
       != first, geometry.object == drop.ball, incoming length >= kissSpeed, m.railAfterLastContact(of: drop.ball) ==
       nil. First that passes.
     - bigCut: on first, geometry.striker == cue; the object dropped (facts.pocketed.first { $0.ball == object });
       m.lastContact(of: object, atOrBefore: that drop's time) == first; m.railAfterLastContact(of: object) == nil;
       incoming length >= cutSpeed; cutAngle(geometry) >= cutDegrees.
     - static func cutAngle(_ g: ContactGeometry) -> Double: degrees between g.incoming.normalized and g.normal
       (acos of their dot product, clamped to -1...1). g.normal points from the striking ball into the struck one, so
       a full, straight-on hit is near 0 degrees and a thin cut is large (a half-ball hit about 30, a very thin one
       towards 90). "At least cutDegrees" therefore means thin.
   - The rare kinds are tried before the common ones, in the enum's order; candidates keeps every non-nil one in that
     order (so the tests can see when two kinds qualify) and pick takes the first.

2. App/BulletTimeBudget.swift: the rationing, a pure value type like HighlightOffer.
   - struct BulletTimeBudget: Equatable with static let cutGap = 4 and breakBeatBy = 0.3; private(set) shotsNoted;
     lastFreezeShot: Int?; cutUsedThisRack: Bool; hardestBreak: Double? (session-long).
   - mutating func noteShot(); mutating func startRack() (clears cutUsedThisRack only).
   - mutating func shouldPlay(_ m: BulletMoment, computerShot: Bool, freePlay: Bool, freePlayBreaks: Int) -> Bool:
     computerShot and not rare: false. Rare: true. hardBreak: false in free play when freePlayBreaks < 2; true only when
     hardestBreak is nil or m.incomingSpeed >= hardestBreak + breakBeatBy, and then hardestBreak becomes that speed.
     bigCut: false if cutUsedThisRack or (lastFreezeShot exists and shotsNoted - lastFreezeShot < cutGap); else sets
     cutUsedThisRack. Every true answer sets lastFreezeShot = shotsNoted. Say in its doc that a yes uses the moment up,
     so ask only when the freeze can really play (the same warning HighlightOffer carries).

3. App/BulletTime.swift: the run, owned by the model. @MainActor @Observable final class BulletTime.
   - struct BulletGate: open (Bool), computerShot (Bool), freePlay (Bool), freePlayBreaks (Int). The model fills it.
     freePlay must mean exactly what the break counter means (no match, no authored mode, no drill), so the
     first-free-play-break rule never reads a count it does not belong to.
   - struct BulletCue: Equatable, for the scene: moment; hold (0 to 1 through the freeze, real time; 1 once letting
     go); release (0 during the freeze, then 0 to 1 over cameraBackSeconds); reduceMotion (Bool, read at the freeze's
     start); var drawing: Bool { release < 0.5 }; func glass(for ball: Int) -> Float: 0 unless ball is the moment's
     striker or object, else 0.6 times (1 - release) times min(1, hold / 0.15).
   - Constants: holdSeconds 1.8, reducedHoldSeconds 1.2, approachClock 0.12, releaseClock 0.3, slowest 0.125,
     cameraBackSeconds 0.6. And static let disabledByLaunch = launch arguments contain "-noBulletTime".
   - Observed: private(set) var shown: BulletMoment? (set for the freeze only); var statusWords: String? { shown.map {
     BulletWords.status($0.kind) } }.
   - Not observed (@ObservationIgnored): the armed moment, the version it was armed for, phase (enum: idle, armed,
     holding, releasing, done), holdElapsed, releaseElapsed, lastClock, lastAllowance, budget (BulletTimeBudget), and an effects
     closure (BulletMoment) -> Void defaulting to the real effects (Haptics.shared.freeze(strength:) with strength
     min(1, incomingSpeed / 4), then AccessibilityNotification.Announcement(BulletWords.spoken($0.kind)).post()); tests
     replace it with a recorder. The cue's reduceMotion is read from TableCamera.reduceMotion when the freeze begins.
   - func startRack(): budget.startRack().
   - func arm(timeline:facts:captions:isBreak:version:gate:) with facts: ShotFacts?: cancels anything running, then
     budget.noteShot(); if gate.open, the option is on and not disabledByLaunch, facts is non-nil, pick(...) returns a
     moment and budget.shouldPlay(...) agrees, it calls arm(moment:version:).
   - func arm(moment: BulletMoment, version: Int) (internal; also the tests' way in): phase armed with that moment and
     version, lastClock 0, lastAllowance .infinity (so the first frame() after arming can never read as a jump, in the
     app or in a test that arms at clock 0 and calls frame at 0.5). No option, launch flag or budget check here.
   - func cancel() (internal: the model's scrub hook calls it): phase done, shown nil. frame() uses it too.
   - func cap(clock: Double, version: Int) -> Double: the moment's time while armed or holding for this version and
     clock is not past it; .infinity otherwise. (In the model, frame() runs before step() each frame and only begins the
     freeze once the clock already sits on the contact, so the cap has done its work by then; keeping it while holding
     is a guard. The clock only ever moves forward through it, so fireSounds crosses the contact exactly once.)
   - func rateFactor(at clock: Double) -> Double: 1 when idle or done. Armed: slowest + (1 - slowest) x
     smooth((moment.time - clock) / approachClock). Releasing: slowest + (1 - slowest) x smooth((clock - moment.time) /
     releaseClock). smooth is the 0-to-1 smoothstep, clamped.
   - func frame(_ dt: Double, clock: Double, playing: Bool, rate: Double, version: Int, allowed: Bool) -> Bool (true
     while the freeze holds the clock; rate is the speed the player chose, chosenRate ?? 1). Idle or done: return false
     at once. Otherwise, in order: a version other than the armed one, or allowed false, ends everything (cancel). A
     jump of the clock ends everything: backwards by more than 1e-9, or forwards by more than lastAllowance, where
     lastAllowance was stored by the previous call as max(1, rate) x (1/20) x 1.5 + 1e-4. That is SoundBoard.follow's
     own test: model.advance clamps every step to 1/20 of a second, so the ceiling is used, never this frame's dt (the
     step being checked was taken with the previous frame's dt, and a long frame followed by a short one would
     otherwise read as a jump and throw the freeze away). Armed: if clock >= moment.time - 1e-9, the freeze begins only
     when the clock is sitting on the contact (clock <= moment.time + 1e-6, which the cap guarantees for playback) and
     playing; a clock already past the contact (a skip to the result, a scrub forward within the allowance) sets phase
     done instead, and a paused clock on the contact waits. Begin the freeze: phase holding, holdElapsed 0, shown =
     moment, effects(moment). Holding: if playing, holdElapsed += dt; when it reaches the hold length, phase releasing,
     releaseElapsed 0, shown = nil; return true while still holding. Releasing: releaseElapsed += dt; done once
     releaseElapsed >= cameraBackSeconds and (clock >= moment.time + releaseClock or not playing: a shot that ends, or
     a pause, inside the let-go must not leave a cue standing). Store lastClock = clock and lastAllowance at the end of
     every call that did not cancel. cancel() sets phase done and shown nil (the camera eases itself back; see
     BulletTimeCamera).
   - var cue: BulletCue?: non-nil while holding or releasing.
   - enum BulletWords (in this file, like RideWords in RideStage.swift): static func status(_ kind:) -> String and
     static func spoken(_ kind:) -> String, every string through String(localized:defaultValue:comment:) with the keys
     listed under Words to translate. spoken is one localized sentence with one placeholder: key "Freeze: Spoken",
     defaultValue written as an interpolation of status(kind) followed by the drawing sentence (so its format is "%@.
     Time stops at the hit. ..."), never two pieces joined with +.

4. App/BulletTimeCamera.swift: the camera override. @MainActor final class BulletTimeCamera.
   - func set(cue: BulletCue?, timeline: Timeline, frame: TableFrame): called by TableScene each frame before the camera
     moves. When cue is non-nil, works out (once per moment, cached with the BulletMoment itself as the key, not the
     event index alone, which a later recording can share) the orbit: the contact point C in table metres, the bearings
     b0 and b1 described next, the ball radius R (Double, timeline.table.ballRadius) and timeline.table for the
     clearances. Guard timeline.events.indices.contains(moment.event) first (the scene's recording can differ from
     the model's for a frame, as applyContact already guards heldEvent), then ContactGeometry.at(timeline.events[
     moment.event]); if either fails, no orbit and the shot passes untouched.
     - n = geometry.normal, t = geometry.tangent. The side the striker leaves along the tangent: sign of
       strikerOut.dot(t); if its size is under 0.05 m/s, the sign of incoming.dot(t); if that is under 0.05 too, +1.
       End bearing b1 (unit, table plan, from C towards the eye) = minus that sign times t: side-on to the line of
       centres, on the side the striker does not head for. Start bearing b0 = b1 turned 75 degrees towards -n (the
       turn whose 2D cross product with -n is positive; -n is exactly a right angle away, so b0 ends up 15 degrees
       short of directly behind the striker).
   - static func orbitPlan(centre: Vec2, b0: Vec2, b1: Vec2, swing s: Double, radius R: Double, table: TableSpec)
     -> (eye: Vec2, height: Double), pure, all in Double table metres: bearing = b0 turned towards b1 by s x 75 degrees;
     eye = centre + bearing x 13R; height above the cloth = R x (2.2 + 4.8 x smooth(s)). Rails: let outside be how far
     the eye's plan point lies outside the cloth rectangle 0...table.length by 0...table.width (0 inside); height =
     max(height, railClear x smoothstep(0, 0.05, outside)) with static let railClear = 0.11 m (the rail top's 0.075
     plus a ball's width), so a contact near a cushion is never seen through the rail, and the lift is continuous as the
     swing crosses the cushion line. Posts and pins (bumper pool, five-pin, bar billiards), the same way: for each of
     table.posts and table.pins, let gap = distance from the eye's plan point to its center minus its radius; height =
     max(height, (its height + 2R) x (1 - smoothstep(0, 0.05, gap))), so the eye rises over an obstacle it would sit
     inside, continuously. A pool table has none, so nothing changes there.
   - static func shot(eye: Vec2, height: Double, centre: Vec2, frame: TableFrame, free: FramingRect, size: CGSize)
     -> CameraShot: position = frame.world(eye, height: Float(height)), target = frame.world(centre, height:
     frame.ballRadius) (the balls' centre height; both world calls take Float), fov = ShotCamera.rideFov(size), near =
     ShotCamera.rideNear, then ShotCamera.frameInFreeSpace(shot, free: free, size: size, place: 0.5) (see the hook in
     ShotCamera below) so the contact sits in the middle of the free space.
   - static func weights(hold: Double, release: Double) -> (blend: Double, swing: Double), pure: blend =
     smooth(hold / 0.2) x (1 - smooth(release)); swing = smooth((hold - 0.2) / 0.6). At hold 0 the blend is 0; at
     release 1 the blend is 0, so the handback ends exactly on the table camera's pose.
   - private(set) var flying: Bool; and func override(_ shot: CameraShot, free: FramingRect, size: CGSize,
     reduceMotion: Bool) -> CameraShot: with Reduce Motion (or the cue's own reduceMotion) return shot untouched and
     flying false. With a cue: w = weights(...).blend; the orbit shot at that swing; remember it and w as lastShot and
     lastWeight (Float); return ShotCamera.mix(shot, orbit, Float(w)); flying = w > 0.001. With no cue but lastWeight >
     0 (an early end): lower lastWeight by real dt / 0.35 (ProcessInfo.processInfo.systemUptime against a stored
     lastTick, like ShotCamera's engage; dt clamped to 0.1) and return ShotCamera.mix(shot, lastShot, lastWeight);
     flying while it is above zero. Otherwise the shot untouched. CameraShot is not Equatable; nothing here needs it.

### Hook points in shared files (each listed, each small)

5. App/ShowpieceModel.swift (six hooks):
   a. Stored property, beside the ride's: let bulletTime = BulletTime() with a one-line comment pointing at this plan.
      (A let of an @Observable class: views that read model.bulletTime.statusWords are tracked through it.)
   b. finishStrike, as the last line after judgeHighlight(tl, isBreak: s.isBreak):
      bulletTime.arm(timeline: tl, facts: shotFacts, captions: captions, isBreak: s.isBreak, version: timelineVersion,
      gate: BulletGate(open: openingStage == .none && lessonModeStorage?.isActive != true && strokeDrillStorage?.isActive
      != true && match?.state.clockRemaining == nil && whatIfStorage?.isOpen != true && !rideActive && melt < 0.02 &&
      meltTarget == nil, computerShot: match.map { $0.isComputer($0.state.turn) } ?? false, freePlay: match == nil &&
      !authoredModeUp && strokeDrillStorage?.isActive != true, freePlayBreaks: freePlayBreaksStruck)).
      (The turn is still the shooter's here: the ruling comes after the shot plays out. load() has just built the new
      ridePlan, so rideActive is this shot's. !rideActive and the Lens terms are here so a freeze that could never
      play, with Ride on or the Lens up, does not use up a big cut or set the hardest break; the frame gate below
      repeats them for changes after the strike. freePlay is the same test judgeHighlight uses before it counts
      freePlayBreaksStruck.)
   c. advance(_:): one line immediately before switch stage (after the menuOpen early return and after the pauseAt
      defer), so it runs on every frame the table runs, whatever the stage:
      let bulletHolds = bulletTime.frame(dt, clock: time, playing: playing, rate: chosenRate ?? 1, version:
      timelineVersion, allowed: stage == .explore && GameSettings.bulletTimeOn && !guided && !rideActive && rideAct ==
      .none && melt < 0.02 && (meltTarget ?? 0) < 0.5 && whatIfStorage?.isOpen != true)
      (meltTarget is set the moment the Lens is asked for, so a freeze ends on the tap, before the melt moves; a
      meltTarget of 0, the Lens on its way out or a plain Replay's first frame, does not count as the Lens coming.
      stage == .explore ends a freeze when Watch the intro or the cold open takes the table, which would otherwise
      leave a stale cue steering the camera through the intro, because nothing else in the switch would call frame.)
      It must stay unconditional and outside the switch, so the cancel path runs on every frame (a freeze holding when
      the player taps the Lens is ended by the next frame even though the guided branch then owns the clock). Do not
      move it inside a branch or a case when merging. Behind the menu advance returns earlier, so the freeze simply
      pauses there (openMenu sets playing false); that is intended.
      Then in case .explore, in the plain branch, inside if !advanceRide(dt) { ... }, wrap the existing two lines:
      if bulletHolds { displayRate = 0 } else { displayRate = (chosenRate ?? 1) x (rideActive ? ridePlan.rateFactor(at:
      time) : 1) x bulletTime.rateFactor(at: time); if playing { step(dt) } }. The guided and rewind branches are
      untouched. Note finishStrike's own meltTarget: it sets meltTarget = nil when the Lens is off, so the gate holds
      for a normal shot; if a merge changes that line, keep the gate reading "the Lens is neither in nor coming".
   d. step(_:): time = min(duration, time + dt x displayRate, bulletTime.cap(clock: old, version: timelineVersion)),
      where old is the time before the step (already in a local). fireSounds then crosses the contact exactly once.
   e. startHighlightRack(): add bulletTime.startRack().
   f. scrub(to:): first line, bulletTime.cancel(). A scrub ends the freeze for this recording whatever its size (a
      slow drag can move the clock by less than the playback allowance, which frame() alone would not notice).
   Nothing else in the model changes: replay, skipToResult, load and the menu need no hook, because frame() notices
   the version change, the clock jump, a clock past the contact or the gate closing on its next call. A new shot is
   cancelled twice over on purpose: load() bumps timelineVersion (frame() cancels on it) and arm() cancels before it
   arms. Keep both.

6. App/TableStage.swift (one line): in the per-frame closure, beside table.lensHeldEvent = model.heldCaption?.id
   (before table.apply, which reads it for the glassy balls): table.bulletCue = model.bulletTime.cue.

7. App/TableScene.swift (four hooks):
   a. Properties: var bulletCue: BulletCue? (set by TableStage each frame) and private let bulletCamera =
      BulletTimeCamera().
   b. init: right after root.addChild(lens.root), add root.addChild(lens.heldRoot) (see LensLayer below).
   c. apply(...): the body opacity line becomes 1 - 0.55 x max(m, bulletCue?.glass(for: b) ?? 0).
   d. updateCamera(...): before camera.update, bulletCamera.set(cue: bulletCue, timeline: timeline, frame: frame); pass
      bullet: bulletCamera to camera.update; zoom.rideHold = shotCamera.flying || bulletCamera.flying; and before
      lens.apply, lens.bulletEvent = (bulletCue?.drawing == true) ? bulletCue?.moment.event : nil and lens.bulletLift
      = frame.ballRadius.

8. App/TableCamera.swift (two lines): update(...) gains a last parameter bullet: BulletTimeCamera? = nil; right after
   the ride override builds shot (before the lamp shot), if let bullet { shot = bullet.override(shot, free: freeNow,
   size: size, reduceMotion: reduce) }.

9. App/ShotCamera.swift (one parameter): frameInFreeSpace(_:free:size:) gains a last parameter place: Double =
   ShotCamera.ballPlace (written qualified), used where ballPlace is used now. Every existing caller is unchanged.

10. App/LensLayer.swift (the contact drawing gets a second owner; the Lens itself is unchanged):
    a. New let heldRoot = Entity(), documented as the contact drawing's parent, outside root so it can show with the
       Lens off. In init, root.addChild(contactRoot) becomes heldRoot.addChild(contactRoot), and right after the
       existing bloomActive = Self.enableBloom(on: root) add _ = Self.enableBloom(on: heldRoot): the bloom is
       hierarchical, so without it the moved drawing would lose the glow it has today under root and the guided Lens
       hold would look different. fingerprint() is not touched: it never covered the contact drawing, and the root's own opacity it hashes is unchanged, so
       LensScrubCheck compares exactly as before.
    b. New var bulletEvent: Int? and var bulletLift: Float = 0 (TableScene sets them each frame), and a private var
       contactIsBullet = false (true while the drawing on screen was posed for bulletEvent).
    c. applyContact: the opening guard becomes guard m > 0.02 || bulletEvent != nil || contactIsBullet else {
       cutContact(); return }. The owner branch reads if let i = heldEvent ?? bulletEvent (the rest of its condition
       unchanged) and sets contactIsBullet = (heldEvent == nil) on every frame it runs, before setContactOpacity and
       poseContact, so the owner can never be stale. The fall-through guard becomes guard (heldEvent ?? bulletEvent) ==
       nil, contactShown != nil, contactRoot.isEnabled else { cutContact(); return }. The fade-out keeps the owner it
       had (contactIsBullet is left alone there), so a bullet drawing fades out lifted and at full strength even if the
       Lens starts to come in meanwhile.
    d. setContactOpacity takes the melt: the opacity set on contactRoot is the fade times (contactIsBullet ? 1 : m),
       while contactOpacity keeps the bare fade (the fade arithmetic is unchanged). This reproduces exactly what the
       Lens showed before, when root's melt opacity multiplied it.
    e. poseContact: every height it uses (the 0.01 of the pointsPerMetre probe, 0.0095, 0.0094, 0.011 and 0.0105; not
       the 0.0003 inside an arrow, which is local to the arrow) gets contactLift added, where contactLift =
       contactIsBullet ? bulletLift - 0.01 : 0 (so the parts that sat a centimetre above the cloth now sit at the balls'
       centres, and the screen floors are measured there), and
       centresLine.isEnabled = contactIsBullet || CaptionEngine.throwFacts(e) == nil (with the Lens off there are no
       throw lines to draw the line of centres instead).
    f. cutContact() also sets contactIsBullet = false.
    g. Header: a paragraph under CONTACT GEOMETRY saying the drawing now has two owners, the guided hold (heldEvent,
       Lens in, multiplied by the melt) and bullet time (bulletEvent, any melt, lifted to the balls' centres).

11. App/Haptics.swift (one method): func freeze(strength: Double): a firm transient, Self.tap(0.7 + 0.3 x strength,
    0.6, at: 0), and a short low hum after it built inline as CHHapticEvent(eventType: .hapticContinuous, parameters:
    [intensity 0.3, sharpness 0.1 as CHHapticEventParameter values, as tap builds them], relativeTime: 0.02, duration:
    0.3), both passed to playEvents (which already checks the engine and the Vibration option). CoreHaptics is
    already imported there.

12. App/GameSettings.swift (three pieces): static let bulletTimeKey = "optionBulletTime"; static var bulletTimeOn:
    Bool { flag(bulletTimeKey) } (defaults to on, as every option); and in OptionsSheet an @AppStorage(bulletTimeKey)
    private var bulletTime = true, a Toggle("Freeze the big hits", systemImage: "pause.circle", isOn: $bulletTime) at
    the end of the Feel section, after the #endif of the iOS-only Vibration block so the Mac has it too. The section
    is written Section("Feel") { ... } today, which cannot take a footer: rewrite it as Section { the three toggles }
    header: { Text("Feel") } footer: { Text(the footer sentence below) }, the same form the Physics Lens section uses
    (the "Feel" key already exists, so the header's words do not change). BulletTime.arm reads GameSettings.bulletTimeOn, and the allowed expression in hook 5c
    reads it too, so switching it off mid-freeze ends the freeze on the next frame.

13. App/Phone/PhoneTitle.swift (one line): in line(for:), right after the ride's status line: if let words =
    model.bulletTime.statusWords { return Line(title: words, isStatus: true) }.

14. App/ShowpieceView.swift (one small block and one line), in ScreenHeader: after the stageTitle label block, the
    same glass label for model.bulletTime.statusWords when it is non-nil (same font, padding, glass, opacity
    transition, and .accessibilityLabel("Status: \(words)"), which reuses the existing "Status: %@" key), but with
    .lineLimit(1) and .minimumScaleFactor(0.8) instead of two lines: the header's height feeds headerBottom and so the
    camera's free space, and a label wrapping onto a second line mid-freeze would move the frame. Plus one line beside
    the other animation modifiers at the end of the row: .animation(.easeOut(duration: 0.25), value:
    model.bulletTime.statusWords), so the label fades as the stage title's does.

15. App/NotebookPanel.swift (one line): NotebookTopBar's title starts with if let words = model.bulletTime.statusWords
    { return words }.

16. App/Localizable.xcstrings: the eight keys below, each with all eleven translations written natively, state
    "translated". The six "Freeze" keys also get an "en" stringUnit holding the English default, as every keyed
    entry in the catalog has (see "Title: Break"); without it English would show the key. The two Options literals
    are their own English and need no "en" entry, as the other option strings have none. Insert each at its alphabetical place among the keys, as Xcode sorts them, so the merge with the other
    features' new keys is a few small separate blocks. The catalog is JSON: no header.

Not touched: the project file (synchronised folders), FreePlayViews, PhoneStrip, SoundBoard, SoundStage, FeelMapping,
PacePlan, ShotHighlightJudge, HighlightOffer, ShotFacts and the package (nothing in the package changes).

## Tests

All in the app's test target (XCTest, @testable import Breakdown), built on TestShots, the same way
ShotHighlightJudgeTests builds its shots (TestShots.shot(from:_:), TrickShots.shot(id:), ShotFacts(timeline:start:
cueBall:), CaptionEngine.make(from:surface:)). Every test that depends on a threshold prints the measured number in its
failure message, so the coordinator can retune from one run.

BreakdownTests/BulletTimePickTests.swift:
- The trick answers read as their kinds: "jump-over" gives jumpHit, "masse-curve" gives curveHit, "combo-chain" gives
  kiss; in each the moment's event is a ball-to-ball contact, ContactGeometry.at of it is non-nil with
  objectWasMoving false, and the moment's time equals that event's time.
- The jump's moment is the struck ball's first contact at or after its take-off (check against ShotMoments directly).
- The soft plain pot gives nil. Copy its layout from ShotHighlightJudgeTests.testASoftPlainPotIsNothingSpecial: r =
  PoolParameters().ballRadius, pocket = Vec2(2.54, 1.27), way = Vec2(0.34, 0.27).normalized, 16 places all
  ShotFacts.offTable, start[1] = pocket - way x 0.8, start[0] = start[1] - way x 0.4, aim = atan2(way.y, way.x) in
  degrees, TrickSettings(aim: aim, power: 1.0, tipUp: 0.4 x r, tipSide: 0). Solve and read it with a private play
  helper written as that file's play(_:_:) is (TestShots.shot(from:_:), ShotFacts(timeline:start:cueBall: 0),
  CaptionEngine.make(from:surface: .cloth)).
- "cross-bank" never gives kiss or bigCut (a rail comes between the contact and the drop).
- A built thin cut gives bigCut. Same pocket and way as above; start[1] = pocket - way x 0.5; the ghost ball g =
  start[1] - way x 2r; the cue's line d = way turned 60 degrees counter-clockwise (about Vec2(-0.15, 0.99)); start[0]
  = g - d x 0.6 (about (2.19, 0.33), on the cloth); aim = atan2(d.y, d.x) in degrees; power 2.0, no tip. First assert
  the 1 drops (the message says to move it nearer the pocket if not), then assert bigCut and that cutAngle of its
  geometry is at least 55 (print it).
- The same layout with d turned 20 degrees instead gives nil (a full-ish pot is not a big cut).
- Breaks, solved with TestShots.solve(TestShots.breakInput(speed:)) and ShotFacts(cueBall: 0) from the input's
  positions, as ShotHighlightJudgeTests reads its breaks: speed 15 with isBreak true gives hardBreak; speed 10 (the
  panel's default) gives nil, printing the incoming speed it measured; speed 15 with isBreak false never gives
  hardBreak. Build them with a copy of ShotHighlightJudgeTests' private breakShot() taking a speed (input =
  TestShots.breakInput(speed:), ShotFacts from input.positions).
- Priority: for every laid-out trick answer, pick equals candidates.first, candidates is in BulletKind order with no
  kind twice, and every candidate's event is a ball-to-ball contact with objectWasMoving false.

BreakdownTests/BulletTimeRunTests.swift (@MainActor):
- Budget: rare kinds every time; a big cut once per rack, refused within four shots of the last freeze, allowed again
  after startRack and the gap; a hard break refused on the first free-play break, allowed on the second, refused unless
  0.3 m/s harder than the hardest frozen one; the computer's shots get rare kinds only.
- Run, with a hand-made BulletMoment at clock 0.5 armed through arm(moment:version:), version 1, and a recording
  effects closure; dt 1/120 per call unless a test says otherwise:
  - cap is the moment's time before it and infinity after; rateFactor is 1 far before, about 0.125 at the contact,
    and back to 1 at releaseClock after.
  - frame at the contact time begins the freeze exactly once (effects called once), returns true for holdSeconds of
    summed dt while playing, does not count while paused, then returns false and shown goes back to nil.
  - A clock jump (backwards, or forwards past max(1, rate) x 1.5 / 20 + 1e-4), a version change or allowed false ends
    it at once and shown is nil; a second play through the same clock after that never freezes again.
  - Uneven frames are not a jump: a step of 0.05 s of clock (one clamped long frame) followed by a call with dt 1/120
    keeps it armed.
  - A clock that arrives past the contact (frame called at 0.45, then at 0.52, a step of 0.07 inside the 0.0751 allowance at rate 1) never freezes and
    ends it (effects never called).
  - A pause during the let-go ends it once cameraBackSeconds have passed, and cue is then nil.
  - cue is nil before the freeze, hold climbs 0 to 1, release climbs 0 to 1 after, and cue is nil once done.
- Camera (pure functions):
  - weights: blend is 0 at hold 0, 1 from hold 0.2 to the end of the freeze, and exactly 0 at release 1; swing is 0
    before hold 0.2, 1 from hold 0.8.
  - orbitPlan: on an open-table contact the eye stays 13 radii from the contact in plan, its height is 2.2 radii at
    swing 0 and 7 radii at swing 1, the bearing turns 75 degrees in total and only one way, and the eye height never
    drops below the ball tops. With the contact 3 cm from a cushion, any eye point outside the cloth is at least
    railClear high once it is 5 cm out, and the height never jumps between two swing values 0.01 apart.
  - On a five-pin or bumper layout (a TableSpec with one post of radius 0.02 and height 0.05 placed on the swing's
    path), the height where the eye's plan point is inside the post is at least the post height plus 2R.
  - override with reduceMotion true returns the given shot unchanged at every hold and release value (CameraShot is
    not Equatable: compare position, target, fov and near field by field). Set the cue first with set(cue:timeline:
    frame:) on TestShots.straightPot() and its first contact.
- LensLayer (@MainActor): a LensLayer made on its own and set up as SelfCheckTests.testLensScrubIsExact does
  (buildStatic(ballCount:frame:table:), then rebuild(timeline:frame:), on TestShots.straightPot()) has heldRoot outside
  root (heldRoot is not root and has no parent chain through root); after apply(time:melt: 0, aim: nil, timeline:frame:
  ballVisible: all true) with bulletEvent set to the straight pot's first contact (ShotMoments firstContact of the cue
  ball), heldRoot holds an enabled child; with bulletEvent nil, melt 0 and nothing shown before, it holds none
  enabled; fingerprint() for the same clock is the same with and without bulletEvent set.

## Words to translate

All new player-facing words. The six built in code are keyed with a "Freeze" prefix so they sit together in the
catalog; the two in the Options sheet are SwiftUI literals, so their English text is their key, as every other option's
is. Write each natively in
the eleven languages (ar, de, es, fr, it, ja, ko, pt, pt-BR, ru, zh-Hans). No numbers, no names, no brands. The status
lines must stay short (at most about 35 characters in English, and as short as natural in each language) because they
sit on one line in the title row.

- "Freeze the big hits" (Options toggle; when on, time stops for a moment on a rare ball-to-ball hit).
- "On a rare hit, time stops for a moment and the camera swings round the two balls to show the push between them."
  (footer under the Feel options).
- "Freeze: Break", default "All the speed goes into the rack". Comment: status line in the title row while a hard break
  is frozen at the moment the cue ball meets the rack.
- "Freeze: Jump", default "Down from the jump, onto the ball". Comment: status line while a jump shot is frozen as the
  jumping ball meets its ball.
- "Freeze: Curve", default "The curve ends on the ball". Comment: status line while a curving (masse) shot is frozen at
  its hit.
- "Freeze: Kiss", default "The kiss that sends it in". Comment: status line while frozen on the touch between two balls
  that decides a pocket.
- "Freeze: Cut", default "A thin cut that still sends it in". Comment: status line while a thin cut is frozen at the
  hit, just before the struck ball drops.
- "Freeze: Spoken", default "%@. Time stops at the hit. The dashed line is the push between the centres, the finer
  line is the tangent, and the arrows share out the speed." Comment: spoken by VoiceOver when the freeze begins; the
  placeholder is one of the status lines above. Every translation keeps the one placeholder.

## Out of scope

- A kiss between two moving balls (the momentum triangle does not close on it; the freeze needs it).
- Freezing on a landing on the slate, a cushion, a pocket or a pin (no two balls touch there).
- Bullet time with the Lens on, during Ride or a guided replay, on a Replay, or on a scrubbed shot.
- A power pot, a bank or a draw as triggers (the card already offers those; adding them would make freezes common).
- Any new sound: no whoosh, no slow-motion sound, no sound while anything travels. Contact sounds only, as now.
- A count or list of freezes seen (the achievements feature may read BulletTimePick later; nothing here records it).
- Recording the freeze into a shared clip. The Lens clips feature can rebuild it from the recording alone: the moment
  from BulletTimePick.pick, the camera from BulletTimeCamera.orbitPlan, weights and shot, all pure. The coordinator
  should tell the clips developer these names; this plan adds nothing for them.

## Risks

- Thresholds are set from reading, not from measured solves (the developers do not compile). The break speed, the cut
  angle and the kiss speed may need one retune after the coordinator's test run; the tests print what they measured.
- Draw order with the Lens off: the contact parts keep the Lens's ModelSortGroup(depthPass: nil), so with the warm
  table fully drawn they may show over a rail, a prop or a ball that stands in front of them from the low camera. The
  lines reach a few ball widths either side of the contact, so this is mostly on contacts near a cushion. If it reads
  wrong on device, shorten the reach in bullet time; never hide the lines.
- At the start of the swing the eye is 15 degrees off directly behind the striking ball, which partly covers the
  contact; the glassy balls and the swing's first fifth (still blending in from the table camera) are what keep it
  readable. If it reads as blocked on device, start the swing further round (a smaller turn than 75 degrees); keep the
  end bearing.
- The slow approach and slow let-go stretch a live shot by under a second. A player who dislikes it has the option.
- The drawing's parent moves out of the Lens root. The plan keeps the Lens's own picture identical (the melt is
  multiplied in by hand, the fingerprint is untouched), but the coordinator should look at one guided Lens replay hold
  on a hit after the merge to confirm the drawing still fades with the melt.
- The lines run through the balls' centres; with the balls only two-thirds opaque the lines inside them may read as
  shadows. If they look wrong on device, lower the lift to just above the ball tops; do not hide the lines.
- A low camera near a cushion: the rail-clear lift is written in, but a contact in a pocket's jaws may still show the
  rail edge. Accept it, or shorten the distance; never cut.
- The 3D cue's follow-through: it only shows at the start of the clock and the freeze is at the first contact or later,
  so it should be gone; check the jump shot, where the contact can come early.
- Store screenshot runs that pin the clock (-pauseAt, -lensDebugTime) can meet a freeze on the way; the coordinator
  passes -noBulletTime in those scripts if a shot changes.
- Merge: five features add header lines and stored properties to ShowpieceModel and a line beside rideCue in
  TableStage; this plan's hooks are each one line or one short block, named above, so they merge by hand in minutes.
  If another feature also edits LensLayer's contact drawing, the coordinator merges this plan's applyContact changes
  first, since they only widen its gate and add an owner.
- Merge with the clips feature: it swaps ProcessInfo.processInfo.systemUptime for its SceneClock.now in applyContact,
  TableCamera, ShotCamera and others, so a clip renders on its own clock. If it lands, the coordinator makes the same
  one-word swap at BulletTimeCamera's early-end ease. A clip's own TableScene never has a bulletCue (nil by default),
  so bullet time never appears in a clip unless the clips feature asks for it later.
- Merge with the achievements feature: it adds a call at the end of advance and one after judgeHighlight in
  finishStrike; this plan's advance line sits before switch stage and its finishStrike line is also after
  judgeHighlight. Order between the two finishStrike lines does not matter.
