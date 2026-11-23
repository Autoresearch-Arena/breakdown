<!--
Author: Claude Opus 5.5 High
Date: 23-November-2026
PURPOSE: Build plan for Lens clips to share (version 0.7.7, the highest priority of the five features planned on 23
         November): one tap after a shot worth watching makes a short video of it (the shot at full speed, the melt into
         the Physics Lens, a rewind, the explained replay with a plain sentence per moment, the game's contact sounds and
         a quiet end card) ready for the photo library or the share sheet. Written for a developer who builds it blind in
         a worktree without compiling; the coordinator compiles once after merging the five features.
SRP/DRY check: Pass - checked plans/ (nothing on clips, video or sharing), App/ (no video, AVAssetWriter, share sheet or
         offscreen render anywhere; the only RealityKit view is TableStage's RealityView), and reuses TableScene,
         PacePlan, CaptionEngine, FeelMapping, VoiceSynth, NumberStyle, HighlightWords and ShotNarration instead of
         copying them. Every shared-file change is a small, named hook listed in "Shared files touched".
Edited: Claude Opus 5.5 High, 23-November-2026 (independent critic: checked every claim against the 0.7.6 code. Fixed the
         TableScene clock line and anchored every clock swap by function, not line; the offer split into a cheap check
         and a build-on-tap source so captions are not rebuilt every frame; three model properties instead of four;
         the strike and first hit found by event kind; the cut pace plan named as the one the clip uses; the ring
         anchored on the ball (LeaderState's rule, one new hook in CaptionViews.swift) and projected with
         CameraFraming.project; the clamp kept in the sound helpers; warm-up frames on the clip's clock; the writer's
         start order; the frame and sound rules at a part's first frame; the tail and the forty-second cap made exact;
         sentences never cut off and held up to six seconds; A never starts a clip and never takes a shot from the
         open panel; the Mac items take an optional model; a ready clip no longer blocks a new one; no product names in
         the plain words; risk lines for the lighting, the other features' clocks, assets, metadata and the photo line.)
-->
# Lens clips to share

## In plain words

After a shot worth watching, the player taps "Share clip". The game makes a short film of that shot without stopping
play: a small note with a progress bar says it is making the clip, and a Cancel button stops it. About as long as the
clip itself later, the note says "Your clip is ready" with a Share button, which opens the device's usual share sheet:
save it to the photo library, send it in a message, pass it to a nearby device, and the rest.

The film is the game's own hook, told in about twenty-five seconds and never more than forty:

1. The shot at full speed on the warm table, with its real contact sounds.
2. A short pause, then the table melts into the Physics Lens: paths, arrows and spin marks appear where the balls went.
3. The shot rewinds, silently, the paths drawing back to the start.
4. The shot plays again slowly in the Lens and stops on up to four moments. At each one the camera comes in close, a
   ring marks the ball, and a small note gives the moment's name and one plain sentence, the same words the game shows,
   always whole (never cut off) and held long enough to read.
5. A quiet end card: the shot's name (for example "Bank shot" or "What if") and the game's name. No music, no slogans.

It is upright, phone-shaped, by default on a phone, and wide by default on an iPad or Mac; the other shape is one more
choice in the menu. The words are in the language the game is showing, numbers written the way that language writes
them. Only contacts make sound (the click, the rail, the drop), exactly as in play: nothing sounds while a ball rolls,
and the Moon sounds like everywhere else.

It is offered after a remarkable shot once its Lens replay has been watched, from the cleared table for the rack's best
shot, from the what-if card for the other future, from the More menu for any shot of the player's that has come to rest,
and from the Mac's Playback menu. Nothing is offered during the first minute, and nothing pops up by itself.

The film is made from the recorded shot, frame by frame, not by recording the screen: the same shot always makes the
same film, at full quality, whatever else is on screen, on iPhone, iPad and Mac alike.

Not in this version: opening a shared shot back in the game (the film quietly carries the shot's settings so that can
come later), and putting bullet time or the Ride camera into the film.

## What exists today (read in the code, 0.7.6)

- How the table is drawn. TableStage.swift hosts one RealityView. Inside it, TableScene (TableScene.swift) owns a root
  entity with the warm table (TableBuilder), the Lens (LensLayer), the camera rig (TableCamera, a PerspectiveCamera with a
  45 degree vertical field of view) and the balls. Every frame TableStage calls model.advance, then
  TableScene.apply(time:melt:rate:aim:cueAim:stroke:ride:bridgeMark:) (balls, table fade, cue), then sets moment and
  rideCue and calls TableScene.updateCamera(melt:request:ride:) (camera, then the Lens drawn for this view). Every ball
  transform comes from the recorded Timeline, so any clock time can be drawn exactly, in any order.
- A second table can be built: TableScene(timeline:surface:table:) needs nothing but the recording, and
  load(_:version:kind:cueBall:) plus installEnvironment() finish it. An entity has one parent, so the live table's root
  cannot be lent to another renderer.
- RealityKit's offscreen renderer is in the SDK (RealityFoundation, iOS 18 and macOS 15, so within our 26.0 targets):
  RealityRenderer with entities, activeCamera, cameraSettings (colorBackground, antialiasing .multisample4X), lighting,
  CameraOutput(.singleProjection(colorTexture:)) and updateAndRender(deltaTime:cameraOutput:whenScheduled:onComplete:...),
  all on the main actor. Checked in the iPhoneOS 27.2 SDK's RealityFoundation interface.
- Wall-clock easing in the scene. These read ProcessInfo.processInfo.systemUptime every frame and would make a
  frame-by-frame render depend on how fast it runs (line numbers as of 0.7.6, a hint only; Step 1 anchors each by its
  function): TableCamera.update (eased free rectangle and the launch pull-back, about line 212), TableCamera.cueIntro and
  introHolding (the lamp shot, about 127 and 139), ShotCamera.override (Ride's engage, about 268), MomentFrame.focus (the
  moment framing's gate, about 286), TableZoom.apply (the hand zoom's ease, about 266), LensLayer.applyContact (the held
  hit's drawing fade, about 1308) and TableScene.apply (Ride's table floor, about 304). No other clock is read anywhere
  in the scene (no Date, CACurrentMediaTime or ContinuousClock in TableScene, TableCamera, ShotCamera, LensLayer, CueRig,
  TableDetail, MomentFrame, TableZoom, TableBuilder or CameraFraming). The launch pull-back lasts
  CameraFraming.introSeconds (1.8 s) from the camera's first update.
- Shared state the scene writes: TableCamera.update calls SoundStage.listen (the live sound's panning);
  TableScene.updateCamera writes RideLive.shared (the title-row map); MomentFrame.blurbShare is a static the phone's
  explanation blurb sets. TableScene.load runs the -lensSelfTest and -rideSelfTest checks when those flags are set.
  TableBuilder.installEnvironment marks the startup gate's "scene built", which is idempotent (StartupGate.sceneIsBuilt).
- Assets the table reads synchronously while it is built: TableBuilder.makeTable reads the wood, pocket wall, cloth and
  bedImageNow(for:) pictures, makeBall reads ballImage(number:); the scene's constructor starts a Task for the cloth's
  close-up normal only when clothDetailNormalIfReady() is nil, and dress(_:) puts a real cloth's picture on in a Task.
- The ring the game draws on a held moment's ball: LeaderState.anchor(of:in:) (CaptionViews.swift, private) picks the
  ball a caption is about (the thrown ball for a Throw caption, else the faster ball of a hit) at its place at the
  playback time, and falls back to the event's point (a pocket, or a ball already gone). LensEvent.point alone is the
  contact point between two balls, not a ball. CameraFraming.project(_:position:target:size:fovDegrees:) is the
  projection the camera's own checks use.
- The explained replay. CaptionEngine.make(from:surface:strike:table:striker:) (Captions.swift) builds one Caption per
  event: title, detail, sentences (the detail split at sentence ends), figures (value, unit, label), already in the game's
  language with numbers by AppLocale.numbers (NumberStyle.swift). PacePlan(captions:timeline:style:signature:)
  (PacePlan.swift) picks the beats (strike, first hit, signature beats, the physics a shot is remembered for), their
  reading time (readingTime, dwell(for:)), focusRegions for the moment framing, and rate(at:), the slow-near-beats speed
  curve. ShowpieceModel.stepGuided holds a beat by stopping the clock and counting real time.
- The cold open (ShowpieceModel.advance): full-speed break, freeze 0.6 s, melt over 2.4 s at the frozen moment, rewind
  over 1.0 s, slow guided replay. The clip follows the same order.
- Sound (SoundBoard.swift, VoiceSynth.swift, FeelMapping.swift, SoundStage.swift). Voices are synthesised by
  VoiceSynth.buildBank() into plain Float samples (VoiceBank: voice, strength layer, variant), deterministic from fixed
  seeds. ShowpieceModel.fireSounds turns the events crossed in a frame into cues with FeelMapping.cues(for:), and
  SoundBoard.fire picks the voice (private voice(for:), rail and landing tones from SurfaceSound), the strength layer, a
  seeded variant never the same twice in a row, a volume from VoiceBook.level and the strength with a seeded jitter, a
  pan from SoundStage.pan, and stretches small delays in slow motion (SoundStage.stretch). The strength is clamped to 0
  to 1 before both the layer and the volume. fireSounds(from:to:) sounds only when the clock moved forward (b > a), and
  counts an event stamped exactly 0 as crossed when the step starts at 0. Since 0.7.6 there is no rolling sound and no
  reverb (the reverb node is attached but carries nothing): only contacts sound, through a limiter. No sound is
  Moon-specific. SoundStage is a @MainActor enum; VoiceBook, FeelMapping, VoiceSynth and SurfaceSound are not isolated
  (the project sets no default actor isolation; Swift 6.0).
- Shots worth watching (ShowpieceModel, "Worth watching"): judgeHighlight stores a JudgedHighlight (the ShotHighlight,
  its recording's version, the controls as left) privately, with the private flags highlightDismissed (closed, or a
  control touched) and highlightWatched; highlightCard and highlightOnOffer read them with many conditions (after a
  watch the card stays only while it still offers "Try the trick shot"); watchHighlight replays it; bestShot (private)
  keeps the rack's best for "Watch your best shot". model.captions is the caption list of the recording on screen. Words are
  HighlightWords.title(kind) and line(kind). The phone shows HighlightPhoneBlurb and TableClearedPhoneBlurb
  (FreePlayPhoneBlurbs.swift) with PhonePrimaryAction.freePlay; other layouts show HighlightCard and TableClearedCard
  inside PlayCards (FreePlayViews.swift), which ShowpieceView mounts in the bottom stack, the side column and the
  notebook (NotebookPanel).
- What-if (WhatIfFork.swift): model.whatIf.isShowing and whatIf.result?.alternate, the other future as a ShotAttempt.
- ShotAttempt (ShotAttempt.swift): the timeline, start, aim, power, tip, elevation, seed, input (before the table's and
  surface's numbers), surface, table, generation, stroke, and motionHash. Neither it nor ShotInput is Codable (only Vec2
  is). ShowpieceModel.solverCopy(_:table:surface:generation:) rebuilds the solver's input from those.
- The cue's follow-through: TableStage.stroke(for:) builds a CueStroke from model.currentAttempt and
  model.strokeUsesBridge.
- Phone layout rules (plans/22-Nov-2026-phone-ui-plan.md): on the upright phone the only glass is the two title-row
  circles (Back, More), the strip and the aiming panel; words are blurbs (Blurb.swift, at most two small buttons); the
  strip has one primary action (PhonePrimaryAction). The More menu is PhoneTitleRow.menuItems. Other layouts have the
  round glass Surface button in ScreenHeader (ShowpieceView.swift) and in the notebook's top bar (NotebookPanel.swift).
- Mac: MacChrome.swift's Playback menu (literal string titles, picked up by the catalog), whose model is an optional
  @FocusedValue (every item is written model?.…). Command-E is the Ride Camera toggle; Shift-Command-E is free.
  Controller: ControllerInput.pressA calls pressCardButton first (the main button of the card on screen) and only then
  continues a held moment, shoots from the open panel (shoot) or opens the panel; so anything pressCardButton claims
  takes A away from the shot. It deliberately does not press the highlight card's "Watch it".
- No photo library keys in Breakdown-Info.plist or the build settings. The iOS share sheet's Save Video needs
  NSPhotoLibraryAddUsageDescription, or the app is stopped by the system when the player taps it.
- How files reach the target: Breakdown.xcodeproj uses file-system synchronised groups. App is a
  PBXFileSystemSynchronizedRootGroup whose only exceptions are EightBall/README.md and Tables/README.md; BreakdownTests is
  one with none. Any new .swift file under App (subfolders included, such as the new App/Clips) or under BreakdownTests
  joins its target with no project edit. Do not put a README or other stray file in App/Clips: it would be copied into
  the app. The one project edit is the photo key below.

## The design

### What the clip is (decided)

- Shapes: upright 1080 by 1920 pixels; wide 1920 by 1080. 30 frames a second. Video H.264 High profile, average 6
  megabits a second, a key frame every 30 frames, standard high-definition colour. Sound AAC, 44.1 kHz stereo, 128
  kilobits. A typical clip is about 25 seconds and about 19 megabytes; the longest possible is about 37 seconds.
- Default shape: upright on iPhone (the Duo included), wide on iPad and Mac. ClipShape.standard decides it.
- The scene is framed on a canvas in points at three pixels per point (upright 360 by 640 points, wide 640 by 360), so the
  Lens drawings' size floors, which are in points, come out as large as on a phone. The camera's free space leaves a band
  for the words: upright, header edge 24 points and controls edge 490 (a 150-point band at the bottom); wide, header 16 and
  controls 264 (a 96-point band).
- The timeline of the clip, in output seconds (ClipScript, below):
  1. Lead: 0.5 s still on the first frame, warm table. The camera's own launch pull-back (1.8 s) starts here and
     finishes early in the full-speed part, as it does when the game opens.
  2. Full speed: clock 0 to the shot's end at real speed for the first 6 s of the clock, then faster (3 times, or more so
     this part never exceeds 9 s). Contact sounds.
  3. Pause: 0.4 s on the last frame.
  4. Melt: 1.8 s, the melt eased from 0 to 1 at the last frame (the camera swings overhead, the paths appear). Silent.
  5. Rewind: 1.2 s, the clock eased from the end back to 0 with the Lens up. Silent.
  6. Explained replay: the kept beats (at most four), the clock moving at the cut plan's rate(at:) times a speed-up k (1
     or more), stopping on each beat for its clip dwell (its reading time, between 2.5 and 6 s, the game's own floor and
     the old first-launch ceiling). The moment framing is allowed throughout this part. After the last beat the clock
     plays to the end, faster if needed so the tail takes at most 4 s (rate max(rate(at:) * k, remaining clock / time
     left of the 4 s)), then holds 0.5 s. Contact sounds as the clock crosses them, stretched in slow motion as the game
     does. This part (holds, tail and its 0.5 s hold included) is held to 22 s: k grows by a quarter at a time up to 4;
     if it still does not fit, the lowest-ranked beat that is not the strike or a signature beat is dropped and k starts
     again (once only the strike and signature beats are left, the latest signature beat goes next), down to two beats; if two beats at k 4 still do not fit, k keeps growing by a quarter until it does (the
     holds alone are at most 12 s, so this always ends). The whole clip is therefore at most about 37 s, under the
     40 s hard cap, which ClipScript.make asserts.
  7. End card: 2.2 s, faded in over the first 0.5 s over the last Lens frame. Silent.
- Beats kept (ClipScript.chooseBeats): from the PacePlan built for the clip, in this order of priority: headline
  (signature) beats, the strike (the beat whose event kind is .cueStrike; PacePlan may have dropped it for a hit on the
  same picture, so never assume it is beats[0]), the first beat whose event kind is .ballBall, then the others by caption
  importance; at most four, then put back in clock order. The plan is cut to those with PacePlan.keeping(_:) (a hook,
  below). The cut plan is the only plan the clip uses after that: its rate(at:) drives the replay, and it is the plan in
  the moment framing's request, so the speed curve, the words and the camera all follow the same four.
- Words on a beat: a small dark rounded note (not glass: glass cannot be drawn into a video): the caption's title with its
  lead figure after it ("Throw · 2.1°"), then the caption's first sentence (sentences.first, else detail), whole: up to
  five lines upright and four wide, and when it needs more the text scales down (minimumScaleFactor 0.75) rather than
  being cut with an ellipsis; the hold is its reading time (above), so the sentence can be read. It fades in over 0.25 s
  as the hold starts and out over 0.4 s after it ends. A thin white ring sits on the ball the caption is about (the same
  rule as the game's ring, LeaderState's anchor: the thrown ball for a Throw caption, else the faster ball of a hit, at
  its place at the held clock; the event's point only for a pocket or a ball already gone), sized from the ball's
  on-screen size, with a 2-point leader from the note's top edge when the ring is above it. The Lens contact drawing for
  a held hit comes from the scene itself (lensHeldEvent).
- End card: the ground colour, the shot's title (if any) in the heading font, the word "Breakdown" larger beneath it
  (written verbatim, never translated: it is the name), and a short line half magenta, half cyan (the Lens colours, as
  the strip's underline). No web address, no slogan, no sound.
- Sound: only the cues FeelMapping.cues(for:) gives for events crossed by the clip's clock (all contacts), during the full
  speed part and the explained replay, crossed by fireSounds' own rule (a forward step from a to b sounds events after a
  up to b, and an event at exactly 0 when a is 0). Nothing is triggered during the lead, the pause, the melt, the rewind,
  a held beat (its own contact sounds on the frame the clock arrives, as in the game, and simply rings out; a beat at
  clock 0, the strike, sounds as the clock leaves it, exactly as in the game) or the end card. The clip always carries these sounds, whatever the Sound option says (the option is
  about this device playing sound; the clip is a film for someone else).
- Reduce Motion: the clip follows it as the game does (TableCamera.reduceMotion holds one near-overhead angle and the
  moment framing is off). Nothing extra.

### Phone upright

- Start: after a remarkable shot, once its "Watch it" offer is used or closed and the controls are still as the shot left
  them, the strip's primary action (the white capsule) reads "Share clip"; one tap makes the default clip. The More menu
  has "Share clip" and "Share wide clip" whenever a shot of the player's has come to rest (in a what-if: "Share the other
  future" and its wide twin). The cleared table's blurb gets a second small button, "Share your best shot", beside "Watch
  your best shot". No new glass circle on the upright phone (the phone plan allows only Back and More).
- Progress and result: a docked blurb (ClipPhoneBlurb, in PlayPhoneBlurbs): "Making your clip" with a thin progress bar
  and one small button, Cancel; then "Your clip is ready" with Share and Close; or a one-line reason with Try again and
  Close. Sized to its words, at the top of the table area like every docked blurb.

### Phone sideways, iPad, Mac, the open Duo

- Start: a round glass share button (the system share symbol) beside the round Surface button, in ScreenHeader and in the
  notebook's top bar, whenever a shot of the player's has come to rest (or a what-if result shows). A tap makes the
  default shape; a long press (on the Mac, holding the click) shows both shapes, and the Mac's Playback menu has both.
  The highlight card gets a third button, "Share clip"; the cleared-table card gets "Share your best shot" beside "Watch
  your best shot". While a clip is being made every start is hidden; once it is ready or has failed, starting another
  closes it first (its file is deleted unless the share sheet is still open).
- Progress and result: ClipCard, a slim card in PlayCards (so on the open Duo and iPad it lives in the notebook half, never
  over the table): the same words and buttons as the phone blurb. Where the cards go slim during a guided Lens replay
  (lensReplayCompact), ClipCard keeps its title row and the progress bar and drops its sentence, as the other cards do;
  its buttons come back when the replay ends.
- Mac menu bar, Playback: "Share Clip…" (Shift-Command-E) and "Share Wide Clip…" or "Share Upright Clip…" (the other
  shape), enabled exactly when the share button shows.
- Share opens the system sheet: on iPhone and iPad an activity sheet (on iPad a popover anchored at the bottom middle of
  the window), on the Mac the sharing picker anchored the same way. Saving to the photo library is the sheet's own save
  option.

### VoiceOver, controller, one finger

- Every new control is an ordinary button with a label and hint: the share button "Share clip", hint "Makes a short video
  of this shot, ready to share". The progress bar carries its value (the system speaks the percentage). ShotNarration
  announces "Making your clip" at the start and "Your clip is ready" at the end.
- Controller: A presses the clip card's (or blurb's) main button when it is up, nothing above it in pressCardButton's
  order claimed A, and the aiming panel is not open: Share when ready, Close after a failure. A never starts a clip (the
  phone's "Share clip" primary is a tap, like "Watch it", which A does not press either): pressCardButton runs before the
  shot, so a clip start on A would take A away from shooting after every watched highlight. With the panel open A
  shoots as before. The share sheet itself is the system's.
- One finger: everything is a single tap.

## Build steps

All new code goes in a new folder, App/Clips. Every new file carries the standard header (Author: your model name and
effort, Date, PURPOSE, SRP/DRY check). Read Apple's documentation for RealityRenderer, AVAssetWriter,
AVAssetWriterInputPixelBufferAdaptor, AVAudioFile, AVAssetExportSession (the async export(to:as:)), CIContext and
CIImage(mtlTexture:options:) before writing against them (CODING_STANDARDS section 9); the SDK interfaces are in
Xcode's iPhoneOS SDK under RealityFoundation and AVFoundation.

### Step 1. One clock for the scene's own easing (new file, then one-line hooks)

New App/Clips/SceneClock.swift:
- @MainActor enum SceneClock with a private static var pinnedNow: TimeInterval?, a static var now: TimeInterval (the
  pinned value, else ProcessInfo.processInfo.systemUptime), and static func pinned<T>(at t: TimeInterval, _ body: () throws
  -> T) rethrows -> T that sets pinnedNow, runs body, and puts the old value back with defer.
- Comment: the clip renderer pins virtual time around its own scene's apply and updateCamera, so every wall-clock ease in
  that scene runs on the clip's clock; the live scene never runs inside that synchronous scope (one main actor), so it is
  never affected.

Hooks (replace ProcessInfo.processInfo.systemUptime with SceneClock.now, nothing else on the line). Each is found by its
function and the statement it sits in, not by line number: bullet time edits TableCamera.update, ShotCamera and
TableScene.updateCamera in another worktree at the same time, so numbers will move. 0.7.6 line numbers are given as a
hint only.
- TableCamera.swift, three reads: in cueIntro(_:), `lampStart = ProcessInfo.processInfo.systemUptime` (about 127); in the
  introHolding getter, `return ProcessInfo.processInfo.systemUptime - start < Self.lampLength` (about 139); in
  update(melt:clock:duration:request:frame:ride:zoom:moment:), `let now = ProcessInfo.processInfo.systemUptime`, the line
  just before the smoothFree ease (about 212).
- ShotCamera.swift: in override(position:target:fov:free:size:reduceMotion:), `let now = …` just before the engage step
  (about 268).
- MomentFrame.swift: in MomentFrame.focus(clock:request:handAtFit:frame:reduceMotion:), its first line `let now = …`
  (about 286).
- TableZoom.swift: in apply(position:target:pivot:fitPivot:tableHalf:reduceMotion:), `let now = …` (about 266). Leave
  takeDoubleTap's read alone (about 248): it times a real gesture.
- LensLayer.swift: in applyContact(melt:timeline:frame:), `let now = …` (about 1308).
- TableScene.swift: in apply(time:melt:rate:aim:cueAim:stroke:ride:bridgeMark:), `let now = …` just before floorStep,
  the Ride table floor (about 304; the original plan said 263, which is wrong).
- Leave StrokeGesture.swift's reads alone (real touches).
Add one "Edited:" header line to each of these files naming plans/23-Nov-2026-clips-plan.md.

### Step 2. Hooks so a second scene can render offscreen (shared files)

- TableCamera.swift: add var reportsListener = true; guard the SoundStage.listen call in update with it. Add var
  cameraEntity: Entity { camera } (the PerspectiveCamera, for RealityRenderer.activeCamera).
- TableScene.swift: add var isOffscreen = false { didSet { camera.reportsListener = !isOffscreen } }; in updateCamera,
  skip RideLive.shared.update when isOffscreen; in load, skip the -lensSelfTest and -rideSelfTest checks when
  isOffscreen (so a test run never logs them twice). Add var cameraEntity: Entity { camera.cameraEntity } (camera is the
  private TableCamera; tableCamera already exposes it, so this is only a convenience).
- PacePlan.swift: add func keeping(_ indices: [Int]) -> PacePlan returning a copy with only beats[i] and focusRegions[i]
  for those indices (valid ones, sorted), momentTimes and style unchanged. Comment it as the clip's hook.
- SoundStage.swift: add nonisolated static func pan(_ p: Vec2, frame f: TableFrame, right r: SIMD3<Float>) -> Float (the
  body of today's pan, without the stored state) and nonisolated static func stretch(_ delay: Double, rate: Double) ->
  Double (today's body with rate as a parameter); the existing pan(_:) and stretch(_:) call them. Behaviour identical.
  Nonisolated, so the clip's sound plan can run off the main actor.
- SoundBoard.swift, in VoiceBook (nonisolated, at the top of the file): static func voice(for kind: FeelKind, surface s:
  SurfaceSound) -> Voice (the body of SoundBoard.voice(for:), which then calls it with surfaceSound); static func
  clampedStrength(_ s: Double) -> Double (min(1, max(0, s)), today's first line of the strength handling in fire);
  static func layerIndex(strength s: Double, count: Int) -> Int (min(count - 1, Int(clampedStrength(s) *
  Double(count))), so a strength above one never indexes past the last layer); static func volume(_ kind: FeelKind,
  strength s: Double, jitter: Double) -> Double (level(kind) * (0.15 + 0.85 * clampedStrength(s)) * jitter); static func
  pickVariant(count: Int, last: Int?, random: inout SoundRandom) -> Int (next() % count, moved on by one when it equals
  last and count > 1). SoundBoard.fire calls the four helpers in place of its inline code, in the same order of random
  draws (variant pick first, then jitter), so the live game sounds exactly as before.
- TableStage.swift: split stroke(for:) into static func stroke(of shot: ShotAttempt?, modeUsesBridge: Bool) -> CueStroke
  (today's body) and the existing stroke(for:) calling it with model.currentAttempt and model.strokeUsesBridge.
- ShowpieceModel.swift, one new block at the end of the "Worth watching: the rack's best shot" section, just before
  "// MARK: Worth watching: the end of Watch the intro" (it needs the private judgedHighlight and bestShot), marked
  "Lens clips (0.7.7, plans/23-Nov-2026-clips-plan.md)". Three read-only properties:
  - var highlightOnScreen: ShotHighlight? : while replayingBest, bestShot's highlight; else judgedHighlight's highlight
    when its version equals timelineVersion; else nil. Whatever the card is doing.
  - var highlightControlsUntouched: Bool : judgedHighlight exists, its version equals timelineVersion, and controlValues
    equals its controls.
  - var bestShotForClip: (attempt: ShotAttempt, highlight: ShotHighlight)? : bestShot's two, nil when none.
  (The "Watch it still on offer" test needs no new property: it is the existing highlightOnOffer != nil.)
  No behaviour change; nothing else in the model is touched.
- CaptionViews.swift (the ring's anchor, so the clip's ring sits on the same ball as the game's): split LeaderState's
  private static anchor(of:in:) into static func anchor(of caption: Caption, timeline: Timeline, time: Double) ->
  SIMD3<Float>? (today's body with model.timeline and model.time as parameters; internal, not private) and the existing
  anchor(of:in:) calling it with model.timeline and model.time. Behaviour identical.

### Step 3. The shape and the source (new files)

App/Clips/ClipShape.swift:
- enum ClipShape: Sendable { case upright, wide }.
- pixelSize (1080x1920, 1920x1080); canvas (360x640, 640x360 points); pixelsPerPoint 3.
- framingRequest: FramingRequest(size: canvas, safe: FramingInsets(), headerBottom: 24 or 16, controlsTop: 490 or 264).
- captionBand: CGRect in points (upright y 490 to 640, wide y 264 to 360); captionMaxWidth 320 or 440 points;
  captionLines 5 or 4 (the sentence scales down to fit rather than being cut; see the design).
- static var standard: .upright on iOS when UIDevice.current.userInterfaceIdiom is .phone, else .wide (always .wide on
  macOS). var other: the opposite shape.

App/Clips/ClipSource.swift:
- struct ClipSource: what one clip is made from, values only, so the live game can move on while it renders. Fields:
  timeline, surface (PlaySurface), table (TableKind), striker (Int, the struck ball), strike (CueStrike?), stroke
  (CueStroke), title (String?, already translated), signature ([Int], event indices), captions ([Caption]),
  record (ClipShotRecord?, the candidate) and motionHash (UInt64?, the attempt's, for the record check).
- init(attempt: ShotAttempt, title: String?, signature: [Int], modeUsesBridge: Bool, captions: [Caption]? = nil):
  captions as given, else CaptionEngine.make(from: attempt.timeline, surface: attempt.surface, strike:
  attempt.input.strike, table: attempt.table, striker: attempt.input.strike.ballIndex) (the same call ShowpieceModel.load
  makes); stroke from TableStage.stroke(of: attempt, modeUsesBridge:); record ClipShotRecord(attempt:) and motionHash
  attempt.motionHash (ClipMaker writes the record into the file only after its check, Step 7). Built only when the player taps a start, never while a view is drawn: CaptionEngine.make walks every
  event of the recording.
- This is the entry contract for other features: an achievement replay or any list row that holds a ShotAttempt calls
  ClipMaker.shared.start(ClipSource(attempt:title:signature:modeUsesBridge: false), shape: .standard). Nothing here reads
  another feature's types.

@MainActor enum ClipOffer in the same file (when the game offers a clip, read by every entry point). Views, menus and the
primary action call only the cheap Bool checks every time they draw; a ClipSource is built only inside start, on a tap.
- private static func attempt(_ m: ShowpieceModel) -> (attempt: ShotAttempt, whatIf: Bool)? : nil when
  ClipMaker.shared.isMaking, m.menuOpen, m.openingStage != .none or m.isSolving. Then: a what-if showing with a result
  (m.whatIf.isShowing, m.whatIf.result?.alternate) gives that attempt, whatIf true. Otherwise m.aimReady and
  m.playerShotOnScreen with m.currentAttempt give that attempt, whatIf false. Else nil. Reads stored state only.
- static func available(_ m) -> Bool : attempt(m) != nil, and the attempt's timeline has a beat-worthy shot
  (timeline.duration > 0.3, PacePlan's own still-table test). This is what every button, menu row and the Mac item read.
- static func isWhatIf(_ m) -> Bool : attempt(m)?.whatIf == true (for the menu wording).
- static func source(_ m) -> ClipSource? : built from attempt(m). What-if: title WhatIfWords.title, no signature,
  captions built by the init. The shot on screen: title HighlightWords.title(kind) of m.highlightOnScreen (nil when there
  is none), signature its signatureEvents (else []), modeUsesBridge m.strokeUsesBridge, captions m.captions (already
  built for exactly this recording, so nothing is recomputed).
- static func bestShotAvailable(_ m) -> Bool : m.bestShotForClip != nil, !ClipMaker.shared.isMaking, m.tableCleared.
- static func bestShot(_ m) -> ClipSource? : from m.bestShotForClip when bestShotAvailable, title HighlightWords.title of
  its highlight, signature its signatureEvents, modeUsesBridge false, captions built by the init.
- static func afterWatch(_ m) -> Bool : m.match == nil, m.highlightOnScreen != nil, m.highlightOnOffer == nil (Watch it
  was used or the card closed), m.highlightControlsUntouched, !m.whatIf.isShowing and available(m) (the phone's primary
  action).
- static func start(_ m, shape: ClipShape = .standard) and startBestShot(_ m, shape:) : build the source, then
  ClipMaker.shared.start(source, shape:).

### Step 4. The script (new file, pure, the main test surface)

App/Clips/ClipScript.swift:
- struct ClipFrame: Equatable { clock: Double; melt: Double; rate: Double (playback rate for sound stretch, 0 when the
  clock is held or moving backwards); sounds: Bool (crossed events sound on this frame); heldEvent: Int? (the beat's
  event while holding); caption: Int? (index into the kept beats whose note shows); captionOpacity: Double;
  momentAllowed: Bool; endCard: Double (0 to 1); part: Part } with enum Part { lead, fullSpeed, pause, melt, rewind,
  replay, endCard }.
- struct ClipBeat: Equatable { beat: PaceBeat; dwell: Double; title: String; figure: String?; sentence: String }.
- struct ClipScript { let frames: [ClipFrame]; let beats: [ClipBeat]; let plan: PacePlan; var duration: Double }. plan
  is the CUT plan (cut below), never the full one: the replay's rate(at:) and the moment framing's request both read it.
- Constants, named and commented: fps 30, lead 0.5, realTimeFor 6.0, fullSpeedCap 9.0, pause 0.4, melt 1.8, rewind 1.2,
  beatLimit 4, minDwell 2.5, maxDwell 6.0, replayBudget 22, tailCap 4, tailHold 0.5, captionIn 0.25, captionOut 0.4,
  endCard 2.2, endFade 0.5, speedStep 1.25, speedMax 4, hardCap 40.
- static func chooseBeats(_ plan: PacePlan, timeline: Timeline, limit: Int) -> [Int] : indices into plan.beats by the
  priority in the design (headline beats first; then the beat whose event, timeline.events[beat.caption.id].kind, is
  .cueStrike, if PacePlan kept one; then the first beat whose event kind is .ballBall; then by caption.importance
  descending, ties by time), capped, then sorted ascending. Never assume beats[0] is the strike.
- static func make(timeline: Timeline, captions: [Caption], signature: [Int]) -> ClipScript? :
  1. plan = PacePlan(captions:timeline:style: .standard, signature:); nil when !plan.hasBeats; kept =
     chooseBeats(plan, timeline:, limit: beatLimit); cut = plan.keeping(kept).
  2. Each ClipBeat: title = caption.title; figure = caption.figures.first?.text (optional; ClipCaptionView lays the two
     out side by side with a middle dot, as Blurb's title slot does, so no new format string is needed); sentence =
     caption.sentences.first ?? caption.detail; dwell = min(maxDwell, max(minDwell, cut.dwell(for: title + " " +
     sentence))) (the join is only for counting reading time, never shown).
  3. Emit frames part by part at 1/30 s steps, exactly as in the design. Lead frames: clock 0, sounds false. Full-speed
     frame j shows the clock reached after (j + 1) / 30 s of that part, so its first frame has already moved and carries
     the strike's sound (rate 1 up to clock 6, then max(3, (duration - 6) / 3); its last frame is exactly the
     recording's end). Melt and rewind use the smoothstep x*x*(3-2x) as the cold open does. The replay part starts from
     clock 0 and copies stepGuided's rule, on the cut plan: move by (1/30) * cut.rate(at: clock) * k, and if that would
     pass the next kept beat, stop exactly on it; that arrival frame keeps its rate and sounds, and starts the hold; then
     hold for its dwell (frames with the same clock, rate 0, sounds false, heldEvent set); the first frame that moves off
     a beat sounds again (a beat at clock 0, the strike, is heard here, as in the game). After the last beat the tail
     rule in the design. The end card frames repeat the last replay frame's clock and melt.
  4. Fit: build the replay part with k = 1; while it is longer than replayBudget, k *= speedStep up to speedMax; then drop
     a beat as the design says (cut the plan again with keeping) and retry from k = 1; with two beats left, let k keep
     growing. Make the whole fitting a loop over a pure helper, replayFrames(plan:beats:k:) -> [ClipFrame]. Finally
     assert duration <= hardCap (a debug assertion; the fitting above makes it true).
  The same inputs always give the same frames. A still table (no beats) makes no clip: return nil, and ClipOffer never
  offers one (playerShotOnScreen already excludes still tables; guard anyway).

### Step 5. Words, ring and end card on the frame (new file)

App/Clips/ClipOverlay.swift (@MainActor):
- struct ClipCaptionView: View (title in Theme.heading, sentence in Theme.body, white text, 10-point padding,
  RoundedRectangle corner 12 filled black at 62 per cent with a white 12 per cent hairline; width up to
  shape.captionMaxWidth; lineLimit shape.captionLines with .minimumScaleFactor(0.75), so a long first sentence shrinks
  instead of ending in an ellipsis; fixedSize vertically). struct ClipEndCardView: View (the end card as designed, filling the
  canvas, background the palette's ground; use Text(verbatim: "Breakdown")).
- Both rendered once each with ImageRenderer(content:) at scale 3, with .environment(\.dynamicTypeSize, .large), the
  palette environment the app uses, and .environment(\.layoutDirection, ...) right-to-left when
  Locale.Language(identifier: Bundle.main.preferredLocalizations.first ?? "en").characterDirection is right-to-left (Arabic).
  Cache the caption image per beat index.
- static func project(_ world: SIMD3<Float>, eye: SIMD3<Float>, forward: SIMD3<Float>, canvas: CGSize) -> CGPoint? : nil
  when dot(world - eye, forward) is 0.01 or less (behind or at the eye, which CameraFraming.project does not guard);
  else CameraFraming.project(world, position: eye, target: eye + forward, size: canvas, fovDegrees: 45) (the same
  projection the camera's own checks use; 45 is TableCamera's fixed vertical field of view, private there, so name it as
  a constant here with a comment pointing at TableCamera.fov; the clip never rides, so the field of view never changes).
  Points, origin top left. eye and forward come from scene.tableCamera after updateCamera.
- The ring's ball: LeaderState.anchor(of: caption, timeline: source.timeline, time: frame.clock) (the CaptionViews hook,
  Step 2), so it sits on the same ball as the game's ring.
- func frameImage(base: CIImage, frame: ClipFrame, script:, camera: TableCamera, tableFrame: TableFrame, timeline:) ->
  CIImage : composes, in pixels (CI's origin is bottom left: convert y), the caption image at the bottom of the caption
  band centred, with opacity through CIColorMatrix's alpha vector; while holding, the ring at the projected anchor (radius
  max(14, 1.7 * ball radius * camera.pointsPerMetre(at: the anchor)) points, 2-point white line at 90 per cent) and the leader, drawn into a
  small CGContext covering just their bounding box; then the end card over everything at frame.endCard.

### Step 6. The renderer (new file)

App/Clips/ClipRenderer.swift (@MainActor final class ClipRenderer):
- init(source: ClipSource, shape: ClipShape, script: ClipScript).
- func renderVideo(to url: URL, progress: @MainActor (Double) -> Void) async throws -> [SIMD3<Float>] (the camera's right
  vector per frame, for the sound's pan).
  1. Warm the pictures the table needs so no frame shows a bare bed: await StartupAssets.shared.environment(),
     bedImage(for: source.surface), clothDetailNormal(), compactBallImages(). (The wood, pocket wall and ball pictures
     makeTable and makeBall read synchronously are already drawn: a clip is only ever offered after the live table has
     been built.)
  2. scene = TableScene(timeline: source.timeline, surface: source.surface, table: source.table); scene.isOffscreen = true;
     scene.load(source.timeline, version: 1, kind: source.table, cueBall: source.striker); await scene.installEnvironment().
  3. renderer = try RealityRenderer(); renderer.entities.replaceAll([scene.root]) (the collection's interface lists
     append(contentsOf:) and replaceAll, not a single-entity append); renderer.activeCamera = scene.cameraEntity;
     renderer.cameraSettings.colorBackground = .color(the ground colour as a CGColor, 0.02, 0.03, 0.05);
     renderer.cameraSettings.antialiasing = .multisample4X. Leave tone mapping and renderer.lighting at their defaults (the
     image light is the component installEnvironment put on the root, with a receiver on every model but the floor; see
     Risks for the floor).
  4. Metal: one MTLDevice; one colour texture of shape.pixelSize, .bgra8Unorm_srgb, usage render target and shader read,
     private storage; output = try RealityRenderer.CameraOutput(.singleProjection(colorTexture:)). One CIContext(mtlDevice:)
     with sRGB working space.
  5. The writer (step 7) gives an IOSurface-backed, Metal-compatible 32BGRA pixel buffer pool; each composed frame is drawn
     into a pool buffer with ciContext.render(_:to:bounds:colorSpace:), all on the GPU (no copy through the CPU).
  6. Three warm-up renders of frame 0, discarded (late material swaps land). Each one runs exactly the per-frame sequence
     below with i = 0, inside SceneClock.pinned(at: 0): the camera's launch pull-back and its eases start their clock at
     the first update, so a warm-up outside the pin would start them on the device clock and the whole clip would stay
     pulled back.
  7. For each frame i (f = script.frames[i]): try Task.checkCancellation(); keep the old MomentFrame.blurbShare, set it
     to 0.5;
     SceneClock.pinned(at: Double(i) / 30) { scene.lensHeldEvent = f.heldEvent; scene.apply(time: f.clock, melt: f.melt,
     rate: max(f.rate, 0), aim: nil, cueAim: nil, stroke: source.stroke, ride: false); scene.moment =
     MomentRequest(allowed: f.momentAllowed, plan: script.plan); scene.updateCamera(melt: f.melt, request:
     shape.framingRequest, ride: false) }; put blurbShare back; record the camera's right (cross(scene.tableCamera.forward,
     (0, 1, 0))); render with try await withCheckedThrowingContinuation { c in do { try renderer.updateAndRender(deltaTime:
     1/30, cameraOutput: output, onComplete: { _ in c.resume() }) } catch { c.resume(throwing: error) } } (the do and catch
     sit inside the continuation, so a render that throws at once resumes with its error instead of waiting forever for an
     onComplete that never comes); base = CIImage(mtlTexture:options: sRGB) flipped vertically;
     compose with ClipOverlay.frameImage; append to the writer at CMTime(value: i, timescale: 30); progress(0.9 * (i + 1) /
     count); await Task.yield(). Each frame awaits the GPU and the writer, so the main actor is free between frames and the
     game stays responsive (a frame's main-actor work is a few milliseconds).
  8. Release: renderer.entities.removeAll(); drop the scene.
- The renderer never touches the live model, the live scene, SoundStage's stored state or RideLive.

### Step 7. Writing the file (new files)

App/Clips/ClipWriter.swift:
- @MainActor final class ClipVideoWriter: AVAssetWriter(outputURL:, fileType: .mp4); one AVAssetWriterInput (video, the
  settings in the design, expectsMediaDataInRealTime false); an AVAssetWriterInputPixelBufferAdaptor with 32BGRA, the
  pixel size, kCVPixelBufferMetalCompatibilityKey true and IOSurface properties. start() calls startWriting() and then
  startSession(atSourceTime: .zero) (the adaptor's pixelBufferPool is nil until both have run); func nextBuffer() throws ->
  CVPixelBuffer (from the adaptor's pool; throws if the pool is nil), func append(_ buffer:, frame:) async throws (waits for isReadyForMoreMediaData
  with Task.sleep of 5 ms, never a busy loop; throws the writer's error if it fails), finish() async throws, cancel()
  (cancelWriting and delete the file).
- enum ClipAudioWriter: static func write(left: [Float], right: [Float], to url: URL) throws : AVAudioFile(forWriting:
  settings: AAC 44.1 kHz stereo 128 kbps, commonFormat .pcmFormatFloat32, interleaved false), written in chunks of 32768
  frames of a stereo AVAudioPCMBuffer. Runs off the main actor.
- enum ClipMuxer: static func mux(video: URL, audio: URL, metadata: [AVMetadataItem], to url: URL) async throws : an
  AVMutableComposition with the video track and the audio track over the video's duration, exported with
  AVAssetExportSession(asset:presetName: AVAssetExportPresetPassthrough), metadata set, try await export(to:as: .mp4).
  Passthrough: nothing is encoded twice. Two passes on purpose: one AVAssetWriter with a video and an audio input that
  are not real time waits for the inputs to interleave, and the audio cannot be written before the pictures (its pan
  needs each frame's camera).

App/Clips/ClipSound.swift (pure, nonisolated):
- struct ClipSound: Equatable, Sendable { time: Double (output seconds); voice: Voice; layer: Int; variant: Int; volume:
  Double; pan: Float }.
- static func plan(frames: [ClipFrame], timeline: Timeline, surface: PlaySurface, rights: [SIMD3<Float>],
  variants: (Voice, Int) -> Int) -> [ClipSound] (takes the frames, all plain values, so nothing main-actor crosses into
  the detached task) : walk the frames; for frame i with frame.sounds and its clock b above the previous frame's clock a
  (for i = 0, a = 0), take the events with (time > a, or a <= 0 and time <= 0) and time <= b, exactly fireSounds' rule, cues = FeelMapping.cues(for:), and for each cue: voice VoiceBook.voice(for:surface: SurfaceSound(
  surface)), layer VoiceBook.layerIndex, variant VoiceBook.pickVariant with one SoundRandom(seed: VoiceBook.playSeed) for
  the whole clip and a last-variant memory per voice, volume VoiceBook.volume(kind, strength, jitter: 1 +
  VoiceBook.levelJitter * random.signed()), pan SoundStage.pan(point, frame: TableFrame(timeline.table), right:
  rights[i]) (0 without a point), time = i / 30 + SoundStage.stretch(cue.delay, rate: frame.rate). The variants closure
  gives the bank's variant count for a voice and layer (so the plan is testable without building the bank).
- static func mix(_ sounds: [ClipSound], bank: VoiceBank, duration: Double) -> (left: [Float], right: [Float]) : 44 100
  samples a second; each sound's samples added at its start with an equal-power pan (left gain cos((pan + 1) * pi / 4),
  right gain sin of the same); afterwards, if the loudest sample passes 0.89, everything is scaled down to 0.89 (one gain
  for the whole clip, so nothing pumps). Nothing beyond duration.
- The bank: a static, built once per launch by Task.detached { VoiceSynth.buildBank() } on first use (the same pure build
  SoundBoard runs; same seeds, same sounds).

App/Clips/ClipShotRecord.swift:
- struct ClipShotRecord: Codable, Equatable, Sendable: format (1), positions [Vec2], direction Vec2, speed, tipUp,
  tipSide, elevation (Double), ballIndex (Int), seed (UInt64), parametersVersion (Int, attempt.input.parameters.version:
  the player's break is built with version 1, a shot with the default 2), table and surface (their raw values),
  generation (Int), isBreak (Bool). init(attempt:) reads attempt.input and its table, surface and generation. (A
  make-it-again plan may add its own saved-shot type; see Risks.)
- func solve() -> Timeline? : ShotInput(positions:strike:seed:) with default PoolParameters and its version set to
  parametersVersion, through
  ShowpieceModel.solverCopy(_:table:surface:generation:) and PoolSolver.simulate; nil for an unknown table or surface.
- func metadataItem() -> AVMetadataItem : an AVMutableMetadataItem in the QuickTime metadata key space, key
  "breakdown.shot", the record as a UTF-8 JSON string.
- At clip time ClipMaker re-solves the record on a detached task and keeps it only when the result's motion matches the
  attempt's motionHash; otherwise the clip carries no record. Opening a record is not in this version.

### Step 8. The maker (new file)

App/Clips/ClipMaker.swift (@MainActor @Observable final class ClipMaker, static let shared):
- enum Phase: Equatable { idle; making(progress: Double); ready(ClipResult); failed(ClipFailure) }; ClipResult { url,
  shape, title, duration }; enum ClipFailure { leftScreen, couldNotMake } with their sentences.
- var phase; var isMaking (phase is .making); var isIdle (phase is .idle; the cards and blurb show while !isIdle, every
  offer hides while isMaking, nothing else is tested); the running Task; the last request (source, shape) for Try
  again; var sharing (true while the share sheet is open, cleared by its completion handler or delegate).
- func start(_ source: ClipSource, shape: ClipShape) : ignored while making; a ready or failed clip is closed first; script =
  ClipScript.make(...) (nil, a recording with no beat to hold: phase = .failed(.couldNotMake), so a tap never silently
  does nothing; available only tests the cheap duration rule, not the captions); phase = .making(0); ShotNarration.announce(String(localized: "Making your
  clip")); the Task runs:
  ClipRenderer.renderVideo into a temporary video file; then off the main actor ClipSound.plan, the bank, the mix
  and ClipAudioWriter; the record check; ClipMuxer.mux into the final file; phase = .ready; announce
  String(localized: "Your clip is ready").
  Any thrown error other than cancellation: phase = .failed(.couldNotMake), temporary files deleted.
- Files: FileManager.default.temporaryDirectory/Clips; the final name Breakdown-clip-yyyyMMdd-HHmmss.mp4 (letters, digits
  and dashes only; the DateFormatter's locale is en_US_POSIX so the digits are always 0 to 9). The Clips folder is
  emptied when the maker is first used after launch.
- func cancel() : cancels the Task; the renderer's next frame throws; the writer cancels; files deleted; phase idle.
- func close() : phase idle; deletes the clip unless sharing (a share still in progress keeps its file; the next launch's
  clean-up removes it). func retry() : start again with the last request.
- func share() : ClipSharePresenter.present(url, onDone:) for a ready clip, sharing true until onDone.
- iOS only: observe UIApplication.didEnterBackgroundNotification; while making, cancel and set .failed(.leftScreen) (the
  GPU may not draw in the background). The Mac keeps going.

App/Clips/ClipShare.swift (@MainActor enum ClipSharePresenter):
- static func present(_ url: URL, onDone: @escaping @MainActor () -> Void).
- iOS: UIActivityViewController(activityItems: [url]); its completionWithItemsHandler calls onDone; on iPad its popover's
  sourceView is the root view, sourceRect a point at the bottom middle, no arrow; presented from the top-most presented
  view controller of the foreground scene's key window.
- macOS: NSSharingServicePicker(items: [url]).show(relativeTo: a small rectangle at the bottom middle of the key window's
  content view, of: that view, preferredEdge: .minY); a small delegate object calls onDone when a service finishes or the
  picker closes without one.

### Step 9. The views (new file) and their hooks

App/Clips/ClipViews.swift:
- ClipShareButton(model:) : the round glass share button for ScreenHeader and the notebook bar. Shown when
  ClipOffer.available(model). A Menu with primaryAction (tap: the standard shape; long press, on the Mac a held click:
  both shapes), label Image(systemName: "square.and.arrow.up") sized like SurfaceMenuButton's, .buttonStyle(.glass),
  .buttonBorderShape(.circle), .menuIndicator(.hidden), .hoverHighlight(), accessibility label and hint as designed.
- ClipMenuItems(model:) : for the phone's More menu: "Share clip" and "Share wide clip" (or "Share upright clip" when the
  standard is wide), or "Share the other future" and its wide twin in a what-if. Shown when ClipOffer.available(model).
- ClipCard(model:) : for PlayCards: shows while ClipMaker is not idle; glassCard like TableClearedCard; title row with
  the share symbol; making: ProgressView(value:) and Cancel; ready: Share (glassProminent) and Close; failed: the reason,
  Try again and Close. Reads @Environment(\.lensReplayCompact): when compact, the title row and progress bar only (as
  TableClearedCard and HighlightCard do). ShotNarration announcements come from the maker, not the view.
- ClipPhoneBlurb(model:) : for PlayPhoneBlurbs: the same three states as a Blurb (the content form for the progress bar:
  Blurb(accessibilityText:buttons:) with a ProgressView inside; the slots form for ready and failed), at most two buttons.
- ClipCommandItems(model: ShowpieceModel?) : for MacChrome's Playback menu, whose model is an optional @FocusedValue (the
  file writes every item as model?.…; do the same): Divider, "Share Clip…" with .keyboardShortcut("e", modifiers:
  [.command, .shift]) and the other-shape item, both disabled when the model is nil or !ClipOffer.available(model).
  Literal titles (Button("Share Clip…")) so the catalog picks them up, as the rest of the file does.
- enum ClipController { static func pressA(_ model:) -> Bool } : ready: share, true; failed: close, true; else false. It
  never starts a clip (see the design: pressCardButton runs before the shot).
- extension PhonePrimaryAction { static func clip(_ model:) -> PhonePrimaryAction? } : "Share clip" (hint as the
  button's) when ClipOffer.afterWatch(model).

Hook points in shared files (each one line or a few, marked with a comment naming this plan):
- FreePlayViews.swift: PlayCards adds ClipCard(model: model) after IntroEndCard. HighlightCard's CardButtonRow adds a
  glass "Share clip" button when ClipOffer.available(model) (calls ClipOffer.start). TableClearedCard's best-shot row (the
  CardButtonRow under `if model.canWatchBestShot`) adds "Share your best shot" when ClipOffer.bestShotAvailable(model)
  (calls ClipOffer.startBestShot).
- FreePlayPhoneBlurbs.swift: PlayPhoneBlurbs adds ClipPhoneBlurb(model: model) first in its Group (a running clip is the
  newest thing). TableClearedPhoneBlurb's buttons add "Share your best shot" as the second button when on offer.
  PhonePrimaryAction.freePlay checks PhonePrimaryAction.clip(model) after the "Watch it" case and before the intro's end.
- Phone/PhoneTitleRow.swift: menuItems adds ClipMenuItems(model: model) right after the What if item.
- ShowpieceView.swift: ScreenHeader adds ClipShareButton(model: model) just before the SurfaceMenuButton / RideTitleChip
  branch.
- NotebookPanel.swift: the top bar adds ClipShareButton(model: model) before the same branch.
- MacChrome.swift: playbackItems adds ClipCommandItems(model: model) at the end (after What If…).
- ControllerInput.swift: pressCardButton adds `if shoot == nil, ClipController.pressA(model) { return true }` just before
  the "Free play, every ball potted: Rack again" check (shoot is the class's own property, set while the aiming panel
  is open: with the panel open A keeps shooting); add the A line in the mapping comment.

### Step 10. Words, the photo key, the self-test, the changelog

- Localizable.xcstrings: every string in "Words to translate", for all eleven languages besides English, written
  natively, with comments for translators.
- New App/InfoPlist.xcstrings (a string catalog Xcode uses for Info.plist values): NSPhotoLibraryAddUsageDescription in all
  twelve languages.
- Breakdown.xcodeproj/project.pbxproj: INFOPLIST_KEY_NSPhotoLibraryAddUsageDescription = "Saves the clips you make to
  your photo library."; in the app target's Debug (B100000E) and Release (B100000F) build settings only. (The coordinator
  moves MARKETING_VERSION to 0.7.7 for the whole batch.)
- App/Clips/ClipSelfTest.swift: launch flag -clipSelfTest makes an upright clip of the opening shot on screen at launch
  (add init(timeline:surface:table:title:) to ClipSource for a recording with no attempt: captions by the same
  CaptionEngine.make call, stroke CueStroke(), striker from the recording's cue strike, record and motionHash nil) and
  logs CLIP-SELFTEST with frame count, duration, file size, track count and pixel size, then PASS or FAIL. Log only, no
  screenshots. It is the first run that shows the colour-format and upside-down risks, so it must really run.
  ClipSelfTest.runIfAsked(model) runs once: ClipCard and ClipPhoneBlurb (one of them is mounted on every layout) each
  wrap their body as TableClearedCard does, Group { if visible { card } }, and attach to that always-present Group, only
  when the flag is set, a .task that calls runIfAsked. The hook must sit outside the visibility branch: at launch the
  maker is idle, so anything inside the branch never mounts. No shared-file hook of its own.
- CHANGELOG.md: under a "## [0.7.7] - 23-November-2026 (not yet shipped)" heading (the coordinator merges the five
  features' headings), a "Lens clips to share" entry: what, why, how, author with effort.

## Shared files touched

Every pre-existing file the build edits, and why. Everything else is new, in App/Clips, BreakdownTests and
App/InfoPlist.xcstrings.

- App/ShowpieceModel.swift: three read-only properties (highlightOnScreen, highlightControlsUntouched, bestShotForClip)
  in one marked block before "Worth watching: the end of Watch the intro", because the highlight and best shot are
  private.
- App/PacePlan.swift: keeping(_:), a copy with only the clip's beats and their focus regions.
- App/TableScene.swift: isOffscreen (no RideLive write, no sound listener, no repeated self-test logs), cameraEntity,
  and one SceneClock swap (in apply, the Ride table floor).
- App/TableCamera.swift: reportsListener guarding SoundStage.listen, cameraEntity, and three SceneClock swaps.
- App/ShotCamera.swift, App/MomentFrame.swift, App/TableZoom.swift, App/LensLayer.swift: one SceneClock swap each, so the
  clip's own scene eases on the clip's clock.
- App/SoundStage.swift: pure pan and stretch overloads the clip's sound plan calls; the live ones call them.
- App/SoundBoard.swift: five pure VoiceBook helpers (voice for a cue, the strength clamp, layer, volume, variant pick)
  shared by the live board and the clip's mixer; the live sound is unchanged.
- App/CaptionViews.swift: LeaderState's ring anchor split into a static function of the timeline and the clock, so the
  clip's ring sits on the same ball as the game's; the live ring is unchanged.
- App/TableStage.swift: stroke(of:modeUsesBridge:) split out of stroke(for:) so a clip draws the same cue follow-through.
- App/FreePlayViews.swift: ClipCard in PlayCards; "Share clip" on the highlight card; "Share your best shot" on the
  cleared-table card.
- App/FreePlayPhoneBlurbs.swift: ClipPhoneBlurb in PlayPhoneBlurbs; "Share your best shot" on the cleared-table blurb;
  the strip's "Share clip" primary action after a watched highlight.
- App/Phone/PhoneTitleRow.swift: the clip rows in the More menu.
- App/ShowpieceView.swift: the round share button in ScreenHeader (sideways phone, iPad, Mac).
- App/NotebookPanel.swift: the round share button in the notebook's top bar (open Duo, iPad, Mac).
- App/MacChrome.swift: the Playback menu's clip items.
- App/ControllerInput.swift: A presses a ready clip's Share (or a failed one's Close) when the aiming panel is not open;
  A never starts a clip.
- App/Localizable.xcstrings: the new words in twelve languages.
- Breakdown.xcodeproj/project.pbxproj: NSPhotoLibraryAddUsageDescription in the app's Debug and Release settings (the
  share sheet's Save Video needs it). No file-membership edits: App and BreakdownTests are synchronised folders.
- CHANGELOG.md: the 0.7.7 entry.
- GameSettings.swift and PhoneStrip.swift are not touched.

## Tests

App tests in BreakdownTests (XCTest, @testable import Breakdown, the TestShots helpers). New files join the target by
themselves.

- ClipScriptTests.swift
  - The break (TestShots.breakShot with CaptionEngine.make) and the straight pot (TestShots.straightPot): duration at most
    40 s; the parts appear in order lead, fullSpeed, pause, melt, rewind, replay, endCard, each at least once.
  - First frame: clock 0, melt 0. Full speed: the clock rises by exactly 1/30 per frame while under 6 s of clock; the part
    lasts at most 9 s. The rewind ends at clock 0 with melt 1. The end card lasts 2.2 s.
  - Holds: for every kept beat there is a run of frames at exactly its time with heldEvent equal to its caption id, as long
    as its dwell (to a frame); dwell between 2.5 and 6.
  - The strike is chosen by its event kind: for the straight pot the kept beats include the beat whose event is
    .cueStrike when the full plan has one, and a full plan whose first beat is not the strike (a hand-made recording
    with a frozen-ball hit, TestShots.recording) does not get its first beat treated as the strike.
  - The cut plan: script.plan.beats equals the kept beats (same count, same times), and every replay frame's clock step
    agrees with script.plan.rate(at:) times k.
  - Tail: the frames after the last beat reach the recording's end within 4 s, then hold 0.5 s.
  - The full-speed part's first frame has a clock above 0 and sounds true.
  - At most four beats; a signature event given to make is among them; they are in clock order.
  - Silence: sounds is false on every lead, pause, melt, rewind and end card frame, and on every held frame after the
    arrival frame (the frame that reaches a beat carries its sound and starts the hold).
  - Determinism: make twice with the same inputs gives equal scripts.
  - A recording with no beats (TestShots.recording of a still cue ball) gives nil.
  - PacePlan.keeping keeps the chosen beats and their focus regions, same count, same order.
- ClipSoundTests.swift
  - With a constant right vector and a fixed variants closure, the plan of the break has its first sound on the full speed
    part's first frame (the strike, crossed from clock 0), every time within the clip, none during rewind, melt, end
    card; sorted times. A replay that holds the strike at clock 0 sounds it on the first frame that leaves the beat.
  - The cues of the full-speed part equal FeelMapping.cues over the same events (same kinds and strengths).
  - mix with a tiny hand-made VoiceBank (a few samples per voice): output length is duration times 44 100; peak at most
    0.89; zero after the last sound's samples end; a sound panned fully right has a silent left.
  - VoiceBook helpers: layerIndex at strengths 0, 0.5, 1 and 1.5 with four layers (0, 2, 3, 3: the clamp); volume at
    strength 1.5 equals volume at 1; pickVariant never repeats the last pick when there are two or more variants.
- ClipOverlayTests.swift
  - project: a point straight ahead lands in the middle; a point on the top edge of the 45 degree vertical field of view
    lands at y 0; a point behind the eye gives nil; for a point in view it equals CameraFraming.project.
- ClipWriterTests.swift (no RealityKit): ten solid-colour CIImages through ClipVideoWriter at the upright size, one second
  of a test tone through ClipAudioWriter, ClipMuxer with a ClipShotRecord's metadata; the file opens as an AVURLAsset with
  one video track of 1080 by 1920 and one audio track, duration about 1/3 s, and the metadata item reads back as the same
  record.
- ClipShotRecordTests.swift: encode and decode give an equal record; solve() of the straight pot's record (TestShots.attempt)
  gives the same motionHash as the attempt; a break attempt built from TestShots.breakInput (parameters version 1) keeps
  parametersVersion 1 and also solves to the same motionHash.
- ClipOfferTests.swift (in the style of ModelFlowTests): a fresh model during the first launch's opening offers nothing;
  after a player's shot comes to rest available is true and source gives captions equal to model.captions; while
  ClipMaker is making, available is false.

No package tests change: nothing in Packages/BreakdownCore is touched.

## Words to translate

New keys in App/Localizable.xcstrings (English shown; every one needs ar, de, es, fr, it, ja, ko, pt, pt-BR, ru,
zh-Hans, written natively):

- "Share clip" (button, menu row, the phone's primary action)
- "Share wide clip"
- "Share upright clip"
- "Share the other future" (what-if)
- "Share the other future, wide" / "Share the other future, upright"
- "Share your best shot"
- "Makes a short video of this shot, ready to share" (hint)
- "Making your clip"
- "Your clip is ready"
- "Share"
- "The clip could not be made."
- "The clip stopped because the game left the screen."
- Mac menu: "Share Clip…", "Share Wide Clip…", "Share Upright Clip…"

Reused, already translated: "Cancel", "Close", "Try again", "What if", the highlight titles.

New App/InfoPlist.xcstrings: NSPhotoLibraryAddUsageDescription, "Saves the clips you make to your photo library."

"Breakdown" on the end card is the game's name and is written verbatim, not translated.

## Out of scope

- Opening a shared shot back in the game (the clip carries the shot's settings for that later).
- Bullet time, the Ride camera or the same shot on other surfaces inside the clip (ClipScript's parts can take a new part
  later).
- Music, a voice-over, a watermark or a web address.
- Square or other shapes, frame rates above 30, high dynamic range.
- A direct save-to-photo-library button (the system sheet already saves).
- Clips of the computer's shots in a match beyond what the menu offers for a shot on screen.
- Any change to how the live game looks or sounds.

## Risks

- RealityRenderer's colour texture format: the plan uses .bgra8Unorm_srgb. If the coordinator's first run shows the
  renderer refusing it or a dark picture, switch to .rgba16Float with the CIImage colour space set to extended linear sRGB;
  the rest is unchanged.
- CIImage(mtlTexture:) is upside down relative to the texture; the plan flips it. If the coordinator's self-test clip
  is upside down, drop the flip.
- The clip's picture may differ slightly from the RealityView (tone mapping, exposure). Accepted; leave both defaults.
- A second table costs memory for the time a clip renders (its meshes; the pictures are shared). It is released at once.
- Shared-file merges: the one-line SceneClock swaps in TableCamera, ShotCamera and MomentFrame sit where bullet time may
  also edit; they are single-line replacements, so the coordinator re-applies them after the other change if they clash.
  Localizable.xcstrings will conflict between features as JSON; merge by key.
- A make-it-again feature may add its own saved-shot type; if so the coordinator keeps one and points the other at it
  (ClipShotRecord is small and only written into the clip's metadata).
- Some apps strip a video's metadata on sharing; the shot record is a bonus, never relied on. If ClipWriterTests shows the
  QuickTime-key-space item does not survive an .mp4 passthrough export, write the final file as .mov (AVFileType.mov,
  file name ending .mov); the share sheet and the photo library take either.
- Lighting: the live RealityView also lights everything with the system's default environment; RealityRenderer has no
  such default (renderer.lighting.resource is nil). Everything with a model gets the table's own image light through its
  receiver, but the floor is left without one on purpose, so it may look darker in the clip. If the first clip shows a
  dark floor or a dull table, set renderer.lighting.resource to the same StartupAssets environment; the rest is unchanged.
- Other features' clocks: bullet time adds a camera whose early end eases in system uptime. The clip never sets a
  bullet cue, so it does not run there; but if the coordinator merges a new systemUptime read into the scene's per-frame
  code, it should read SceneClock.now too, or a clip could drift with the device's speed.
- Assets: the pictures the table reads synchronously (wood, pocket wall, balls) are drawn at launch and already in use by
  the live table, which a clip always comes after; the warm list covers the ones fetched on demand.
- The photo line: the project sets both GENERATE_INFOPLIST_FILE and INFOPLIST_FILE (Breakdown-Info.plist), so the build
  setting's English line is merged into the Info.plist whatever happens to the catalog. If App/InfoPlist.xcstrings is
  not picked up on the first run, saving is never blocked; the permission line is only untranslated, and the coordinator
  fixes the catalog's membership.
- The "Share clip" primary action on the upright phone takes the slot "Your shot" uses while the controls are untouched
  after a watched highlight. The aiming panel usually comes back open after a replay (it steps aside and returns), and
  any drag on the table to aim touches the controls and gives "Your shot" back; the coordinator should still check this
  once on a phone.
- Rendering time on iPhone 17 Pro is expected to be about the clip's length; the progress bar and Cancel cover a slower
  case. Rendering stops if the game goes to the background on iPhone and iPad, and says so.
