<!--
Author: Claude Opus 5.5 High (coordinator), from a design panel and lead judge run by Claude Opus 5.5 High
Date: 22-November-2026
PURPOSE: The plan for Breakdown 0.7.4: computer players for bumper pool and five-pin, and a glow-up that guides
         players, at natural moments and never pushily, to watch the coolest shots and see the physics. Written after
         the Boss asked for the computer player "with the bigger goal in mind" (an Apple Design Award; trick shots and
         the physics are the coolest part). Holds the features, what was dropped, the shared foundation and the six
         builder streams with their file ownership.
SRP/DRY check: Pass - checked plans/21-Nov-2026-award-gaps-order-plan.md and the 0.7.x plans; this file is only the
         0.7.4 release plan and links nothing it repeats.
Coordinator notes (checked against the repo before building): the build number comes from App Store Connect at upload
         (scripts/testflight.py), so only MARKETING_VERSION moves; the language list and the flat-row fragment shape
         below match scripts/localization-merge.py and the shipped fragments; no file outside MatchOpponent.swift and
         OpponentWords.swift switches over OpponentPlan.Kind, so the stream split holds.
-->
# Breakdown 0.7.4: watch the physics, and the computer on every table

1. RELEASE SUMMARY

Breakdown 0.7.4 adds a computer player for bumper pool and five-pin, so all four table games can be played against the computer at Easy, Medium and Hard. Around it, the release makes the physics the star: every guided Lens replay now holds on the moment the shot is about, a held ball-to-ball hit draws its line of centres, its tangent and the momentum triangle with a gentle close-up, and when the player (or the computer) plays a remarkable shot, one quiet card offers to watch it in the Lens and to try the matching trick shot. The trick-shot loop gets a gallery drawn from the real solved paths, "Watch yours in the Lens" after a make, the answer's path to compare after any try, and two new shots that teach squirt and side off the rail, while launch stays exactly as calm as 0.7.3.

2. FEATURES

R. Computer player for bumper pool and five-pin (REQUIRED)
- Player sees: on the Tables page for bumper pool and five-pin, an "Against the computer" heading, the Easy/Medium/Hard picker and "Play the computer"; the same two games in the menu's Play list and the Mac's New Game menu. The match plays like eight-ball against the computer: "Thinking…", the cue swings, the banner shows each seat's ball. "Why that shot" explains it in plain words ("Off a bumper on the way.", "It played for the pins: about 4 points on an average stroke of its hand.", "Nothing scored often enough, so it touched your ball softly to give away as little as possible.").
- Award: depth and fun. Three tables stop being goal-less practice toys, and a bumper-pool computer that banks and ricochets is a steady source of physics worth watching (feature 2 offers its best shots in the Lens).
- Files: App/Match/MatchOpponent.swift (edit); new App/Match/TableOpponentSearch.swift, App/Match/BumperPoolPlanner.swift, App/Match/FivePinPlanner.swift; App/Match/OpponentWords.swift; new BreakdownTests/TableOpponentTests.swift. Entries: App/Match/TableGamePage.swift, App/Match/TableGameWords.swift, App/TitleScreen.swift, App/MacChrome.swift (menus stream).
- Size: L.

G1. Signature beats: every guided Lens replay stops on the physics it is about
- Player sees: in the replay after a trick shot's Watch it, after "Watch it in the Lens", in lessons and the Behind the 8-Ball escapes, the slow motion always holds on the shot's key moment with its equation filled in: the jump's take-off and landing, the end of the massé's curve (the whole bend drawn), the throw contact, both carom contacts, the draw's reversal, the bank's cushion, the combination's second hit. A signature replay is short: strike, first hit, the signature, little else.
- Award: the core promise ("slow down exactly on the physics") is kept in the places it matters most; today the massé, jump and throw shots can fly past their own point.
- Files: App/PacePlan.swift, App/Captions.swift (bend lookup made readable; no wording change), App/TrickSignature.swift (stub from FOUNDATION), App/ShotHighlightJudge.swift (stub from FOUNDATION; the judge feature 2 uses lives here because it reads the same moments), tests. Model plumbing (paceSignature) is in FOUNDATION. The Lens tips no longer fire over a trick shot's own replay (FOUNDATION edit to replay(withLens:), matching the LensCallouts comment).
- Size: S/M.

G2. See the hit: contact geometry and a close-up on held hits
- Player sees: whenever a guided replay holds on a ball-to-ball beat, the Lens draws the dashed line of centres through both balls, the tangent line at the contact, and three arrows that close into a triangle: the striking ball's speed in, the struck ball's speed out (along the line of centres, up to throw) and the striking ball's speed out. A small right-angle mark appears when the two outgoing paths are square (a stun hit); with follow, draw or throw the angle visibly opens or closes. On a signature beat the camera eases in a little toward the moment (the spotted cue ball's spin is readable) and springs back when the hold ends.
- Award: the spec's top unbuilt "invisible made visible" item; the 90-degree and half-ball rules drawn by the true solver, at every hit the replay explains.
- Files: App/LensLayer.swift, new App/LensContactGeometry.swift, App/SignatureCloseUp.swift (stub from FOUNDATION), App/TableZoom.swift, tests. Hooks in TableScene/TableStage are in FOUNDATION.
- Size: M.

G3. "Worth watching": the invitation after a remarkable shot
- Player sees: in free play (and practice on the other tables), when the balls stop after a shot that really was remarkable (a jump, a curve, a throw, a combination, a kick, a bank, two at once, a big draw, a dead stop, a ball too fast for the pocket, a post into the cup, the red pin alone), one slim card in the existing card slot names the physics ("A combination: one ball passed its speed through another, along the line of centres.") with "Watch it in the Lens" and, when a trick shot teaches that kind, "Try the trick shot". It vanishes the moment the player aims, changes power or spin, or closes it; nothing plays by itself; no sound, no praise text. "Watch it in the Lens" plays a short guided replay holding on the signature beat (G1) with contact geometry (G2). From the second rack on, a free-play break gets the same card. In matches, a remarkable shot by either seat (the computer's two-bumper bank, its red pin alone) shows the ruling card with the shot named and "Watch it in the Lens"; rare kinds every time, common kinds once per match. The Mac's Playback menu gets "Watch It in the Lens".
- Award: this is the Boss's "guide people to watch the coolest shots", done as an invitation at the natural moment: the player's own accident becomes the doorway to the Lens and to the authored trick shot of the same kind.
- Files: App/ShowpieceModel.swift (owner after FOUNDATION), App/FreePlayViews.swift, App/Match/MatchMode.swift, App/Match/MatchViews.swift, new App/HighlightWords.swift, new App/HighlightOffer.swift, new BreakdownTests/HighlightOfferTests.swift; judge in App/ShotHighlightJudge.swift (lens-pacing); types in App/ShotHighlight.swift (FOUNDATION).
- Size: M/L.

G4. Dead ends become doorways
- Player sees: Watch the intro no longer ends on a frozen frame: a small card offers Trick shots and Practice. Table cleared plays the made-it sound and adds "Watch your best shot", which replays the rack's best remarkable shot in the Lens and returns to the cleared table. In the menu, Trick shots moves directly under Play with the line "Watch a shot that looks impossible, see why it works, then make it."; the Play and intro lines name four games against the computer; How to play stops opening with the lessons and ends with "Watch the trick shots" (the lessons offered there as an option).
- Award: the two walls a curious player hits are gone, and the coolest content sits where people look first. Nothing steers anyone into lessons.
- Files: App/ShowpieceModel.swift and App/FreePlayViews.swift (watch-invite); App/TitleScreen.swift and App/MacChrome.swift (menus).
- Size: S.

G5. The trick-shot loop: gallery of real paths, watch yours, see the answer's path
- Player sees: every row of the trick-shot list carries a small drawing of the answer's real solved path (table outline and pockets, start balls, the cue ball magenta while sliding and cyan while rolling, white dashed while in the air), with the made tick; the massé's curve and the jump's arc are visible before tapping anything. The answer's replay holds its signature beat. After a make, "Watch yours in the Lens" replays the player's own stroke holding the same beat. After any try (once the answer has been watched), "Show the answer's path" draws the answer's cue-ball path faintly in white on the cloth beside the player's own, so the difference is seen, not told.
- Award: watch, understand, try, land, as one loop; the list becomes a gallery of shots worth seeing.
- Files: App/TrickShotViews.swift, App/TrickShotMode.swift, new App/TrickPathThumb.swift, App/GhostOverlay.swift, new BreakdownTests/TrickPathThumbTests.swift.
- Size: M.

G6. Two new trick shots for physics the solver shows but nothing staged
- Player sees: "Squirt" (Medium): aimed straight with strong side, a hard stroke misses because the cue ball leaves off line; the answer aims off to allow for it. "Side Off the Rail" (Hard): a one-rail kick that only gets there with side, which widens the rebound angle. Two-Rail Kick's idea stops promising side it does not use; Draw-Massé Carom gets its missing "Show the maths" line.
- Award: the Boss called teaching trick shots the coolest part; these teach the two side-spin effects the captions already explain but no shot stages.
- Files: Packages/BreakdownCore/Sources/BreakdownAuthored/AuthoredTricks.swift, Packages/BreakdownCore/Sources/BreakProbe/TrickAuthoring.swift (and TrickSearch.swift only if a search helper is missing), App/TrickShots.swift, App/TrickShotJudge.swift (only if a new goal needs it), Packages/BreakdownCore/Tests/BreakdownCoreTests/AuthoredLibraryTests.swift (count or ids, if pinned). Same stream as G5.
- Size: M (authoring time is the risk; each shot is dropped if no makeable window is found).

3. DROPPED

- What-if fork: the roadmap's next big idea and the strongest innovation item, but large (nudge interface, parallel re-solve, fork marker) and all three designers hedged on its size; it gets its own release.
- Cinematic Ride-into-guided replay: guided pacing is off during Ride by design, the hand-off rate jump cannot be checked by builders who cannot run the app, and the plain guided replay already delivers the beat.
- "Watch them all" trick showreel: the largest state machine with the most edge cases; the gallery, the invitations and the intro's end card already guide people to the shots.
- Target band after two misses: reads as hand-holding, and the cue-raise windows it needs for the massé, jump and carom do not exist.
- A separate bend caption with a new title: the bend is held through the caption that already carries it, so no new caption or string is needed.
- Sound or praise text on the highlight card: "Amazing!" and chimes are cheap and noisy; naming the physics is the praise, and calm is the house rule (the table-cleared sound stays, as an ending).
- Predict-the-shot: a question in front of the shot is a gate, the 0.7.0 mistake.
- Daily or break challenge, physics journal, badges, Lens themes, confetti: retention gimmicks, not physics.
- Clip export and challenge links: large, and next to the store video work the Boss ruled out.
- Ride on by default, menu backdrop back, music on first launch: each changes the calm first minute.
- Orbit or pinch-zoom during replay, Clarity setting, violet spin spiral, equations placed in the scene: weak payoff per string; the caption already carries the equation.
- Trick shots on bumper pool or five-pin: TrickShotMode is pool-only; authoring and judging another table is a release of its own.
- "Fix" for TrickShotJudge naming the 4 and the 9: not a defect, that line only fires on the carom's own miss.
- Removing TrickShotMode's dead break branches: no behaviour change, not worth the risk in a patch.
- Requiring the marked ball first in bumper pool: rules unchanged in this build.

4. FOUNDATION (coordinator, one commit on a v074/foundation branch cut from v07/integration, before any builder starts)

Facts every brief relies on:
- New files under App/ and BreakdownTests/ need no project registration: the project uses file-system synchronized groups. Nobody edits Breakdown.xcodeproj except the coordinator.
- Real target languages (from App/Localizable.xcstrings and scripts/localization-merge.py ALL_LANGS): es, fr, de, it, pt, pt-BR, ja, ko, zh-Hans, ru, ar. There is no zh-Hant, nl or sv; the computed task's list is wrong.
- Translation fragments: localization/pending/v074-<stream-key>.json in the shape the shipped fragments and the merge script use, a FLAT ARRAY of rows (not a nested dictionary):
  {"keys": ["<English key>", ...], "translations": [{"culture": "es", "key": "<English key>", "text": "..."}, ...]}
  One row per key per language (11 rows per key). The English key is exactly the String(localized:) key as Xcode extracts it: an Int interpolation becomes %lld, a String interpolation becomes %@; never interpolate a Double (format it to a String first), because the merge script only accepts %lld and %@. Reused existing strings need no entry. Builders never edit App/Localizable.xcstrings.
- Changelog: each stream writes changelog-pending/v074-<stream-key>.md with What / Why / How / Checked lines in the CHANGELOG.md style; the coordinator folds them into one [0.7.4] entry and deletes the folder.
- House rules for every builder: every file written or edited follows CODING_STANDARDS.md (new files: Author / Date / PURPOSE / SRP-DRY header; edited files: an "Edited: <model> <effort>, 22-November-2026 (0.7.4 ...)" line), real comments on the non-obvious parts, credit by model name and effort level (for example "Claude Opus 5.5 High"). No orange anywhere (sliding is magenta, rolling cyan, air white); no names of real people, brands or sources in app text; nothing implying two players on one device; nothing over the table on the open Duo (cards live in the existing card slot: PlayCards / the match card).

F1. Version: in Breakdown.xcodeproj/project.pbxproj set MARKETING_VERSION = 0.7.4 (the build number is taken from App Store Connect at upload).

F2. New App/ShotHighlight.swift (frozen after FOUNDATION; owned by the coordinator):
```swift
import Foundation

/// The remarkable moments a shot can have, offered for a Lens replay. Raw values are stable keys.
enum HighlightKind: String, CaseIterable, Sendable {
    case breakShot, jump, curve, throwIn, combination, kick, bank, multiPot, drawBack, stopDead, rimSkip, bumperCup, redPinAlone

    /// Strength, for the best shot of a rack and for choosing between kinds in one shot: higher wins.
    var rank: Int {
        switch self {
        case .jump: return 12
        case .curve: return 11
        case .throwIn: return 10
        case .combination: return 9
        case .kick: return 8
        case .bumperCup, .redPinAlone: return 7
        case .bank: return 6
        case .multiPot: return 5
        case .drawBack: return 4
        case .stopDead: return 3
        case .rimSkip: return 2
        case .breakShot: return 1
        }
    }

    /// Rare kinds are offered every time they happen; the rest at most once per rack (free play) or match.
    var isRare: Bool { [.jump, .curve, .throwIn, .combination, .kick].contains(self) }

    /// The authored trick shot that teaches this kind, or nil.
    var trickID: String? {
        switch self {
        case .jump: return "jump-over"
        case .curve: return "masse-curve"
        case .throwIn: return "throw-it"
        case .combination: return "combo-chain"
        case .kick: return "two-rail-kick"
        case .bank: return "cross-bank"
        case .multiPot: return "follow-train"
        case .drawBack: return "bridge-draw"
        case .stopDead: return "stop-dead"
        case .breakShot, .rimSkip, .bumperCup, .redPinAlone: return nil
        }
    }
}

/// One remarkable moment of a recorded shot.
struct ShotHighlight: Equatable, Sendable {
    let kind: HighlightKind
    /// Indices into the recording's Timeline.events for the replay to hold on: clock order, at most two, each with a
    /// caption (Caption.id is the event index).
    let signatureEvents: [Int]
    /// The ball the moment is about (the close-up and the card's wording follow it).
    let ball: Int
}
```

F3. New App/ShotHighlightJudge.swift (stub; lens-pacing fills the bodies, signatures fixed):
```swift
import BreakdownLensModel
import BreakdownTimeline

enum ShotHighlightJudge {
    /// Every remarkable moment of a recorded shot, strongest (HighlightKind.rank) first; empty for an ordinary shot. Pure.
    static func detect(timeline: Timeline, facts: ShotFacts, captions: [Caption], table: TableKind, isBreak: Bool) -> [ShotHighlight] { [] }
    /// The strongest one, or nil.
    static func judge(timeline: Timeline, facts: ShotFacts, captions: [Caption], table: TableKind, isBreak: Bool) -> ShotHighlight? {
        detect(timeline: timeline, facts: facts, captions: captions, table: table, isBreak: isBreak).first
    }
}
```

F4. New App/TrickSignature.swift (stub; lens-pacing fills):
```swift
import BreakdownLensModel
import BreakdownTimeline

enum TrickSignature {
    /// The events a trick shot's guided replay must hold on (at most two, clock order, each captioned), for the
    /// recording of that shot on screen (the answer or the player's own try). Empty when none is found.
    static func events(forTrick id: String, in timeline: Timeline, captions: [Caption]) -> [Int] { [] }
}
```
Reserved ids for G6's new shots, so TrickSignature can map them before they exist: "squirt" and "side-off-rail".

F5. App/PacePlan.swift: change the initialiser to
```swift
init(captions: [Caption], timeline tl: Timeline, style: Style = .standard, signature: [Int] = [])
```
with the parameter unused for now (lens-pacing implements it). No other change.

F6. App/ShowpieceModel.swift (after this commit the watch-invite stream owns the file; every other stream uses only what is listed here):
```swift
/// Event indices the guided replay must hold as headline beats (a trick shot's or a highlight's signature). Cleared by load(_:).
private var paceSignature: [Int] = []

/// Hold these events in the next guided replay of the recording on screen; rebuilds the pace plan at once.
func setPaceSignature(_ events: [Int]) { paceSignature = events; refreshPacePlan() }

/// The caption of the beat being held right now (nil when not holding).
var heldCaption: Caption? {
    guard holding, let h = heldBeat, pacePlan.beats.indices.contains(h) else { return nil }
    return pacePlan.beats[h].caption
}

/// The event index of the held beat when it is one of the signature events, else nil.
var heldSignatureEvent: Int? {
    guard let c = heldCaption, paceSignature.contains(c.id) else { return nil }
    return c.id
}

/// The level picked for a game against the computer, shared by the menu and the Tables pages (kept while the app runs).
var computerLevel: ComputerLevel = .medium

/// Stubs filled by watch-invite (signatures fixed; MacChrome calls them):
var highlightOnOffer: ShotHighlight? { nil }
func watchHighlight() {}
```
- In load(_:showpiece:): set paceSignature = [] before the PacePlan is built; pass signature: paceSignature in load(_:) and in refreshPacePlan().
- In replay(withLens:): also exclude a trick shot's own demonstration from lensReplayStartedByPlayer:
  let trickDemonstration = trickModeStorage.map { $0.current != nil && ($0.phase == .watching || $0.phase == .explaining) } ?? false
  lensReplayStartedByPlayer = withLens && !lessonDemonstration && !trickDemonstration && openingStage == .none
  (TrickShotMode.update sets .explaining before it calls replay, so this matches; the LensCallouts comment is then true as written.)

F7. Lens hooks (these three files are frozen after FOUNDATION):
- App/LensLayer.swift: add the stored property `var heldEvent: Int?` (doc: "the timeline event of the guided beat being held, set by TableScene each frame; nil when nothing is held; LensScrubCheck leaves it nil, so the scrub check stays a pure function of the clock"). No other change.
- App/TableScene.swift: add `var lensHeldEvent: Int?`; in apply(time:...) set `lens.heldEvent = lensHeldEvent` on the line before `lens.apply(...)`.
- App/TableStage.swift: immediately before `table.apply(time: model.time, ...)` add `table.lensHeldEvent = model.heldCaption?.id`; immediately before `table.updateCamera(...)` add `SignatureCloseUp.step(model: model, table: table)`.
- New App/SignatureCloseUp.swift (stub; lens-drawing fills):
```swift
@MainActor
enum SignatureCloseUp {
    /// Called once per frame before the camera updates: eases the hand zoom toward the moment of a held signature beat
    /// and back when the hold ends.
    static func step(model: ShowpieceModel, table: TableScene) {}
}
```

F8. Create empty folders localization/pending (exists) and changelog-pending/ (with a .gitkeep). Commit. All six streams branch from this commit.

5. STREAMS

Stream: table-opponent
- Features: R (planner and words; the entry points are menus-entries').
- Owns (edit): App/Match/MatchOpponent.swift, App/Match/OpponentWords.swift. Creates: App/Match/TableOpponentSearch.swift, App/Match/BumperPoolPlanner.swift, App/Match/FivePinPlanner.swift, BreakdownTests/TableOpponentTests.swift, localization/pending/v074-table-opponent.json, changelog-pending/v074-table-opponent.md.
- May read: App/Match/MatchMode.swift, App/Match/MatchViews.swift, App/TableLines.swift, App/Tables/BumperPoolTable.swift, App/Tables/FivePinTable.swift, App/TableKind.swift, App/ShowpieceModel.swift, Packages/BreakdownCore/Sources/BreakdownRules/** (BumperPoolRules, FivePinRules, MatchRules, MatchTypes), Packages/BreakdownCore/Sources/BreakdownPhysics/NextShot.swift and Simulation.swift, Packages/BreakdownCore/Sources/BreakdownTimeline/ShotFacts.swift, BreakdownTests/MatchOpponentTests.swift and TestShots.swift, the design probe at /private/tmp/claude-501/-Users-macmini-GitHub-breakdown--claude-worktrees-game-assessment-733c61/77cad3fc-f9ad-40fe-940d-493ae32c2183/scratchpad/probe.
- Hooks used: none (MatchMode and the seating, stroke, save and record paths are already generic; a computer match is MatchStartRequest(kind:, computer:) with players nil, two seats, seat 1 the computer).
- Tests (BreakdownTests/TableOpponentTests.swift; parameters from TableKind.bumperPool.parameters / .fivePin.parameters; state from BumperPoolRules().initialState / FivePinRules().initialState with players[1].computer set, isBreak false, turn .second):
  testBumperOpeningFindsACupShot (hard from the start layout plans .cup and its noise-free stroke drops ball 9 in hole 0);
  testBumperNearCupIsWide (ball 9 near its cup, medium plans .cup with a window of at least 0.5 degrees);
  testBumperNeverChoosesAFoulWhenALegalStrokeExists (5 seeded random layouts, every level);
  testFivePinPlanIsLegalFromStart (medium and hard: first contact on ball 0, no foul);
  testFivePinHardExpectsPoints (.pins with expected > 0);
  testFivePinEasyIsGeometryOnly (easy's aim equals ghostAim to 1e-9);
  testPlansAreDeterministic (same snapshot twice gives equal plans, both tables, every level);
  testNoiseSamplesDifferFromTheStrokeNoise;
  testWhyLinesForTableKinds (OpponentWords.why non-empty, never a pocket title);
  testSelfPlay only when SELF_PLAY=1: hard vs easy, 4 seeded games per table; every game ends within 120 bumper or 200 five-pin shots, hard wins at least 3 of 4, every stroke speed inside PlayerShotSpeed.ordinary.
  MatchOpponentTests must stay green unchanged (pool behaviour identical).
- Brief (done looks like):
  1. OpponentPlanner.plan(_:) dispatches first, before the break check: BumperPoolRules goes to BumperPoolPlanner.plan(s), FivePinRules to FivePinPlanner.plan(s); pool is untouched. OpponentSnapshot gains `var noiseSeed: UInt64 = 0`; MatchOpponent.update sets it from OpponentNoise.seed(rackSeed: match.setup.rackSeed, shotCount: match.state.shotCount, seat: seat.index) (add that helper if missing). Keep the think Task handle and cancel it in cancel() as well as bumping the token. Make Slots internal and add `static func parallel<T: Sendable>(_ n: Int, _ body: @Sendable (Int) -> T) -> [T]` on DispatchQueue.concurrentPerform; every new solve runs through it.
  2. OpponentPlan.Kind gains `.cup(ball: Int, marked: Bool, route: CupRoute)` with `enum CupRoute { case straight, cushion, bumper, cushionAndBumper }`, `.advance(ball: Int)`, `.pins(expected: Double, clean: Int, kick: Bool)`, `.concede`. call stays nil for these tables.
  3. TableOpponentSearch: TableTrial (stroke, value, ruling, facts, railsBeforeFirstContact, postsBeforeDrop, railsBeforeDrop, jammed) solved exactly like OpponentPlanner.trial (NextShot.shot with ballIndex = rules.cueBall(for:in:), PoolSolver.simulate with EightBallJudge.sweepEventBudget, ShotFacts, rules.ruling; a jam scores -50). search(): coarse fan over 0..<360 degrees at fan.step x fan.speeds (+ extraAims); smooth each speed's row with a Gaussian of the level's own aimNoiseDegrees (0.25/0.5/0.25 when sigma < step); keep seedKeep seeds 1 degree apart; refine each (11 aims 0.1 degrees apart x speeds 0.85/1/1.15); noise-check the best noiseKeep with N noisy strokes each, sample k drawn with OpponentNoise.draw(level:, seed: mix(noiseSeed, k + 1)) and NEVER the noiseSeed itself (that is the noise perform will really deal); highest mean wins, ties to the lower aim then lower speed; window = width of the unbroken run of refined aims at the chosen speed whose noise-free value reaches successValue. Easy skips smoothing, refining and the noise check. Medium: seedKeep 6, noiseKeep 4 x 6, one tip. Hard: seedKeep 8, noiseKeep 6 x 12, tips 0 and -7 mm. Check Task.isCancelled at each phase. Cap by solve count, never clock time. Add `tableNoiseScale: [MatchKind: Double]` defaulting to 1; tune bumper hard with self-play if it wins every game against a person-like hand, never by changing the table.
  4. BumperPoolPlanner: value for seat s vs o: win +1000, loss -1000; +10 per own ball dropped in own cup (target hole from BumperPoolRules.targetHole, cup position parameters.bedHoles), -10 per opponent ball the shot drops in the opponent's cup; foul -8; position 3*delta(close(s)) - 3*delta(close(o)) with close(side) = sum of max(0, 1 - d/0.6 m) over that side's balls on the table, measured from the snapshot layout to facts.resting. Fan: speeds [0.6, 0.9, 1.3, 1.8, 2.4] m/s, step 1 degree, tip 0, successValue 10 (generation two refuses fast balls at the 18 mm cups). Kind .cup when the noise-free trial drops an own ball (marked = ball == BumperPoolRules.sides[seat][0]; route from railsBeforeDrop/postsBeforeDrop), else .advance(ball: struck). Easy: raw best of a 2-degree fan at [0.9, 1.4, 2.0] m/s. Do not build on mirror-image geometry (the probe showed mirror banks sink nothing from the start).
  5. FivePinPlanner: value = +1000/-1000 for a result, else ruling.points[s] - ruling.points[o]; hard subtracts 2*max(0, 1 - d/0.5 m) for its own ball resting near the castle centre (parameters.pins[FivePinRules.redPin]). Fan 0.5 degrees over 360 at [2.0, 3.0, 4.0, 5.5] m/s, tip -7 mm, plus extraAims every 0.1 degrees across +-asin(2R/d) of the line to the target ball; successValue 2. Kind .pins(expected, clean, kick: railsBeforeFirstContact > 0) when expected > 0, else .concede. Easy plays by eye with no solves: a private ghostAim(cue:object:toward:radius:) sending the target ball at the castle centre, speed for that distance x1.4 clamped 2 to 5.5 m/s, falling back to a full hit at 3 m/s when the cut exceeds 70 degrees or its path crosses the castle or the red; kind .pins(expected: 0, clean: 0, kick: false).
  6. OpponentWords.why handles the four new kinds (and never names a pocket for them). English lines: "It aimed to sink its marked ball in its cup." / "It aimed to sink one of its balls in its cup." / routes "Straight in, no cushion." (exists), "Off a cushion on the way.", "Off a bumper on the way.", "Off cushions and bumpers on the way." / "No cup shot was likely enough, so it rolled its ball nearer its cup." / "It played for the pins: about \(expected) points on an average stroke of its hand, \(clean) if struck perfectly." (expected rounded to an Int or formatted to a String first) / "It sent its ball off a cushion first to reach yours." / "Nothing scored often enough, so it touched your ball softly to give away as little as possible." / hard five-pin with a leave term: "It also kept its ball away from the pins, so you have less to aim at." The window line and the closing noise line are reused.
  7. Budgets to respect: about 2,000 solves bumper medium, 3,900 hard, 3,300 five-pin medium, 6,500 hard, 540 easy bumper, none easy five-pin. Nothing runs on the main actor. Write the translations fragment (about 10 keys x 11 languages) and the changelog fragment.

Stream: lens-pacing
- Features: G1, and the judge G3 consumes.
- Owns (edit): App/PacePlan.swift, App/Captions.swift, App/TrickSignature.swift, App/ShotHighlightJudge.swift. Creates: BreakdownTests/SignatureBeatTests.swift, BreakdownTests/ShotHighlightJudgeTests.swift, changelog-pending/v074-lens-pacing.md (no strings expected; if one is needed, localization/pending/v074-lens-pacing.json).
- May read: App/ShotHighlight.swift, App/ShowpieceModel.swift, App/TrickShots.swift, App/TrickShotMode.swift, App/Tables/*, Packages/BreakdownCore/Sources/** (LensEvent, Timeline, ShotFacts, AuthoredTricks, BumperPoolRules, FivePinRules), Packages/BreakdownCore/Sources/BreakProbe/TrickSearch.swift (how answers are solved), BreakdownTests/CaptionEngineTests.swift, TestShots.swift.
- Hooks used: F2, F3, F4, F5 (the model passes paceSignature into PacePlan; TrickShotMode and watch-invite call setPaceSignature with your outputs).
- Tests:
  SignatureBeatTests: solve every authored trick answer the way BreakProbe does (PoolSolver.simulate(NextShot.shot(from: layout, direction: (cos aim, sin aim), speed: power, tipUp:, tipSide:, seed: 1, parameters: PoolParameters(), elevation:))), build captions with CaptionEngine.make(from:surface: .cloth), and check that PacePlan(..., style: .standard, signature: TrickSignature.events(forTrick:...)) holds every signature event as a headline beat and that TrickSignature returns at least one event for each of the eleven ids; jump-over's standard plan with NO signature still holds a take-off beat; a .firstLaunch plan of the showpiece break is unchanged (at most four beats, no flight slot).
  ShotHighlightJudgeTests: each trick's own kind is among detect(...) for stop-dead (.stopDead), bridge-draw (.drawBack), follow-train (.multiPot), two-rail-kick (.kick), cross-bank (.bank), combo-chain (.combination), throw-it (.throwIn), masse-curve (.curve), jump-over (.jump); a soft plain single pot with natural roll detects nothing; every returned signature event has a caption; a break detects .breakShot only when isBreak is true.
- Brief (done looks like):
  1. Captions.swift: make the bend lookup readable as `static func bendEvents(in timeline: Timeline) -> [Int: [(ball: Int, degrees: Double)]]` (the existing private bends(in:), renamed or wrapped). No wording changes anywhere in this file.
  2. PacePlan: with a non-empty signature, the cap becomes min(captions.count, max(3, signature.count + 3)); take the strike, the first hit, then every signature caption (headline: true, even when it is the strike or first hit), then fill by the existing variety rules. For .standard and .opening (never .firstLaunch), right after the strike and first hit, take in order: the first flight caption (take-off), the first ball-to-ball caption whose event has CaptionEngine.throwFacts of at least 1 degree, and the caption whose event carries the largest bend from bendEvents; then the existing jaw / pocket / rail / roll / fill. Update the header and the PaceBeat.headline doc (headline now also means a signature beat).
  3. Shared event finders (one place, used by both the judge and TrickSignature, never copied): first ball-to-ball event of the struck ball; its first rail cushion events before first contact; a ball's take-off and next landing; the event that ends the struck ball's largest-bend sliding segment (bendEvents); the last ball-to-ball event before a pocketed ball drops; a ball's rail cushion after its last ball contact and before its pocket; the struck ball's first sliding-to-rolling after first contact; pocket, rim-skip, pinDown and post events. Every returned index must have a caption (Caption.id == event index); drop any that does not.
  4. ShotHighlightJudge.detect rules, struck ball = facts.cueBall, sorted by rank:
     breakShot: isBreak and a first contact exists; signature [first contact]; nothing else is judged on a break.
     jump: a take-off of the struck ball with verticalSpeedUp >= 0.5 m/s; signature [take-off, next landing].
     curve: the struck ball's sliding segment before its first contact bends at least 10 degrees; signature [the bend's ending event].
     throwIn: a pocketed object ball whose last ball contact has |throw| >= 1.5 degrees; signature [that contact].
     combination: a pocketed object ball whose last ball contact was with another object ball; signature [struck ball's first contact, that contact].
     kick: the struck ball reaches 2 or more rails before its first contact, or 1 rail and the shot drops an object ball or a hole drop; signature [its last rail before contact, first contact].
     bank: a pocketed object ball touched a rail after its last ball contact; signature [that cushion].
     bumperCup (table .bumperPool): a hole drop of a ball that touched a post before dropping; signature [its last post hit, the drop].
     redPinAlone (table .fivePin): exactly one pin down and it is FivePinRules.redPin; signature [the pinDown].
     multiPot: not a break, two or more object balls pocketed; signature [first two pocket events].
     drawBack: after first contact the struck ball's rest lies at least 0.6 m behind the contact point along its incoming direction; signature [first contact, its first sliding-to-rolling after contact].
     stopDead: speed into first contact >= 1.2 m/s, rest within one ball radius of where it touched, and the first ball it hit was pocketed; signature [first contact].
     rimSkip: any rim skip; signature [the first rim-skip event].
  5. TrickSignature.events: called-break [first contact]; stop-dead [first contact]; bridge-draw [first contact, cue's skid-to-roll after it]; follow-train [first contact, second pocket]; two-rail-kick [cue's second rail, first contact]; cross-bank [object's rail before its pocket]; combo-chain [the object-to-object contact]; throw-it [the throw contact]; masse-curve [the bend's ending event]; jump-over [take-off, landing]; draw-masse-carom [cue's first and second ball contacts]; squirt [first contact]; side-off-rail [cue's first rail, first contact]; unknown id: [].
  6. Changelog fragment.

Stream: lens-drawing
- Features: G2.
- Owns (edit): App/LensLayer.swift, App/SignatureCloseUp.swift, App/TableZoom.swift. Creates: App/LensContactGeometry.swift, BreakdownTests/LensContactGeometryTests.swift, changelog-pending/v074-lens-drawing.md (no strings planned).
- May read: App/TableScene.swift, App/TableStage.swift, App/TableCamera.swift, App/TableFrame.swift, App/LensTextures.swift, App/Theme.swift, App/Captions.swift (throwFacts), App/CaptionViews.swift (CaptionLeader), App/LensScrubCheck.swift, App/ShowpieceModel.swift, Packages/BreakdownCore/Sources/BreakdownLensModel/LensEvent.swift.
- Hooks used: F7 (LensLayer.heldEvent set every frame from model.heldCaption; SignatureCloseUp.step called every frame), F6 (model.heldSignatureEvent, model.heldCaption, model.timeline, model.stage, model.rideActive).
- Tests: LensContactGeometryTests: for the first ball-to-ball event of every authored trick answer where the struck ball was at rest, ContactGeometry.at(e) exists and incoming = strikerOut + objectOut to within 1e-3 of |incoming| (equal masses: momentum closes the triangle, throw included); a cut struck with no spin at contact (build one with tipUp chosen so the cue ball slides into the hit, or find one in the tricks) has rightAngle true; a full stop shot (stop-dead) has rightAngle false; an event that is not ball-to-ball returns nil.
- Brief (done looks like):
  1. LensContactGeometry.swift, pure: `struct ContactGeometry: Equatable { let point: Vec2; let normal: Vec2; let tangent: Vec2; let striker: Int; let object: Int; let incoming: Vec2; let strikerOut: Vec2; let objectOut: Vec2; let objectWasMoving: Bool; let rightAngle: Bool }` and `static func at(_ e: LensEvent) -> ContactGeometry?` (ball-to-ball events with two balls; the striker is the faster ball before; normal from striker to object; rightAngle when the object was at rest, both outgoing speeds exceed 0.05 m/s and the angle between them is within 2 degrees of 90).
  2. LensLayer: when heldEvent is a ball-to-ball event and melt > 0.02, draw at the contact, on the cloth: the line of centres dashed through both balls (about two ball diameters either side), the tangent line through the contact point with a different dash (with Differentiate Without Colour on, dotted versus dashed, so the two never depend on colour), and the momentum triangle: incoming from the contact forward, objectOut from the contact, strikerOut from the tip of objectOut to the tip of incoming, scaled 0.12 m per m/s and clamped to 0.35 m; a small square mark at the contact when rightAngle. Colours from the existing Lens tokens (white for incoming, cyan for outgoing); no orange. When the object was already moving, draw only the two lines. When CaptionEngine.throwFacts already draws the throw line for this event, do not draw a second line of centres. Build the entities once and reuse them; fade them in over a quarter second of real time when heldEvent changes to a contact, and hide them when it is nil or not a contact. With heldEvent nil everything here is off, so LensScrubCheck and every unheld frame are unchanged.
  3. TableZoom: add `func closeUp(on point: SIMD2<Float>, scale: Float)` (same clamping and spring as focus) and expose whether the current goal is the fitted view (`var atFittedView: Bool`).
  4. SignatureCloseUp.step: when model.heldSignatureEvent turns non-nil, model.stage == .explore, !model.rideActive, Reduce Motion is off and the hand zoom is at the fitted view (the player has not pinched), ease to scale 1.8 about the moment: for a ball-to-ball event the contact point, for a flight or phase event that ball's position at the event time, for cushion, pocket, rim-skip and pin events the event point (convert table metres to the zoom's plan coordinates the same way TableZoomGestures does). When the held signature ends or changes, springBack() only if this code set the zoom and the goal is still the one it set (a pinch in between is the player's). Never during Ride, never outside a held signature beat. Check that CaptionLeader still lands on its ball (it projects after updateCamera each frame, which this step precedes).
  5. Changelog fragment.

Stream: watch-invite
- Features: G3 (all of it), G4's model and card parts.
- Owns (edit): App/ShowpieceModel.swift (after FOUNDATION), App/FreePlayViews.swift, App/Match/MatchMode.swift, App/Match/MatchViews.swift. Creates: App/HighlightWords.swift, App/HighlightOffer.swift, BreakdownTests/HighlightOfferTests.swift, localization/pending/v074-watch-invite.json, changelog-pending/v074-watch-invite.md.
- May read: App/ShotHighlight.swift, App/ShotHighlightJudge.swift, App/TrickShotMode.swift, App/ShotAttempt.swift, App/SoundBoard.swift, App/OpeningHandover.swift, App/ShowpieceView.swift, App/NotebookPanel.swift, App/Lessons/LessonViews.swift, App/LensCallouts.swift, App/CaptionViews.swift, App/PlaybackControls.swift, App/ShotNarration (TableAccessLayer.swift), Packages/BreakdownCore/Sources/BreakdownRules/Tables/*.
- Hooks used: F2, F3 (ShotHighlightJudge.judge/detect), F6 (setPaceSignature; fill the highlightOnOffer and watchHighlight stubs without changing their signatures; MacChrome calls them).
- Tests: HighlightOfferTests on the pure HighlightOffer: rare kinds are offered every time; a common kind is offered once per rack and never twice in a row; at least three shots separate two common cards; startRack resets the per-rack memory; the trick link is allowed once per kind per session and never for a done trick.
- Brief (done looks like):
  1. HighlightOffer.swift, pure: `struct HighlightOffer { mutating func startRack(); mutating func noteShot(); mutating func shouldOffer(_ kind: HighlightKind) -> Bool; func mayLinkTrick(_ kind: HighlightKind, done: Set<String>) -> Bool; mutating func noteTrickLinked(_ kind: HighlightKind) }` with the rules in the tests (breakShot counts as common and naturally comes once per rack).
  2. HighlightWords.swift: `static func title(_ k: HighlightKind) -> String` and `static func line(_ k: HighlightKind) -> String`, generic physics words only. English: breakShot "Your break" / "Watch the cue ball hand its speed to the rack, ball to ball."; jump "The cue ball jumped" / "A downward hit bounced it off the slate and over the ball in the way."; curve "The path curved" / "While the ball slid, the cloth pulled it along the slip of its spin, not along its motion."; throwIn "Thrown in" / "Friction at the contact dragged the ball off the line of centres."; combination "A combination" / "One ball passed its speed through another, along the line of centres."; kick "A kick" / "The cue ball found its ball off the cushion, like light off a mirror."; bank "A bank shot" / "The ball left the cushion at its mirror angle, into the pocket."; multiPot "Two at once" / "One stroke, more than one ball down."; drawBack "Drawn back" / "Backspin outlasted the hit and pulled the cue ball back."; stopDead "Stopped dead" / "The spin ran out exactly at contact, so all the speed went on."; rimSkip "Too fast for the pocket" / "The ball crossed the hole faster than it could fall in."; bumperCup "Off a bumper" / "A bumper turned the ball into the cup."; redPinAlone "The red pin alone" / "Only the red pin fell." Plus a hint "Replays the shot slowly with the physics drawn on the table", "Watch your best shot", and the intro card line "Every trick shot can be watched like this: the answer, then the Lens." Reuse existing keys: "Watch it in the Lens", "Try the trick shot", "Close", "Trick shots", "Practice", "Table cleared".
  3. Model state: the highlight for the recording on screen (with the timelineVersion it belongs to), a snapshot of aim, power, tip and cue angle taken when it is set, a dismissed flag, a watched flag, a HighlightOffer, the rack's best (ShotAttempt, ShotHighlight) excluding breakShot and rimSkip (higher rank wins, ties keep the earlier), the attempt that cleared the table while the best shot replays, replayingBest, and the version at which Watch the intro ended plus its dismissed flag.
  4. In finishStrike, after record and the existing branch: when openingStage == .none, no authored mode is up and the stroke drill is not active, judge the shot with ShotHighlightJudge.judge(timeline: tl, facts: shotFacts, captions: captions, table: solvedTable, isBreak: s.isBreak). Free play: noteShot(); keep it only if offer.shouldOffer(kind); update the rack's best. Match: keep it for this version with no free-play frequency (MatchMode decides). rerack, rackAgain, startGame, playTable, setTable and any mode start call offer.startRack() and clear the best.
  5. highlightOnOffer (replace the stub): free play only (match nil, no authored mode), the highlight's version is the one on screen, aimReady, not dismissed, the aim/power/tip/angle snapshot still matches (any touch of aim, power or spin hides it for good), no ball in hand or placement, not tableCleared, menu closed, not solving, not replayingBest. After a watch, the card comes back without the Watch button, only "Try the trick shot" when allowed, else it stays gone. dismissHighlight() for the close button.
  6. watchHighlight() (replace the stub): Ride off if on (guided pacing and Ride do not mix), setPaceSignature(h.signatureEvents), replay(withLens: true), lensReplayStartedByPlayer = true, mark watched. tryHighlightTrick(): offer.noteTrickLinked(kind), trickMode.begin(id: kind.trickID).
  7. HighlightCard in FreePlayViews, inside PlayCards (so it appears in the bottom stack, the side column and the notebook, never over the table): icon, HighlightWords title and line, "Watch it in the Lens" (glassProminent), "Try the trick shot" when offer.mayLinkTrick(kind, done: trickMode.doneIDs), an xmark close with the "Close" label; styled like TableClearedCard; ShotNarration.announce(title) on appear; opacity transition only; no sound, no haptic.
  8. Matches: rename offerLensReplayOfBreak to offerLensReplay (true in the ruling or over phase, aimReady, the shot on screen, and either a break or a highlight for this version) and watchBreakInLens to watchShotInLens (a highlight sets its signature first). In MatchMode.rule(), after rulingShow: a .banner becomes .card when the shot has a highlight that is not rimSkip or breakShot and is rare or not yet offered this match (a Set kept on MatchMode, not saved, reset on rematch). MatchViews.lensOffer shows the highlight's title and line above the button for a non-break shot and uses the new hint; update MatchViews' header comment.
  9. Table cleared: the card plays SoundBoard.play(.madeItBig) once when it appears and gains "Watch your best shot" when a best exists. watchBestShot(): remember the clearing attempt, put the best attempt's recording on screen exactly as it was solved (restore its input, surface, table and generation before load so the captions and facts match), set its signature, replay(withLens: true). While replayingBest the cleared card stays up (without that button) and Menu or Rack again end the replay first. When the replay reaches its end (aimReady), put the clearing attempt back exactly as before (its recording at its end, still, currentAttempt and its version restored, shot count and undo untouched) and clear replayingBest. No shot is recorded or counted by any of this.
  10. Watch the intro's end: when .slowReplay moves to .explore with the showpiece on screen, remember that version; IntroEndCard in PlayCards while that version is on screen, stage is .explore, the menu is closed and it is not dismissed: the line above, "Trick shots" (trickMode.listOpen = true), "Practice" (startGame()), close.
  11. Translations fragment (about 32 keys) and changelog fragment. Keep every existing behaviour of finishStrike (real speed, the Lens as the player left it, scratch handling) unchanged.

Stream: trick-shots
- Features: G5 and G6.
- Owns (edit): App/TrickShots.swift, App/TrickShotMode.swift, App/TrickShotViews.swift, App/TrickShotJudge.swift, App/GhostOverlay.swift, Packages/BreakdownCore/Sources/BreakdownAuthored/AuthoredTricks.swift, Packages/BreakdownCore/Sources/BreakProbe/TrickAuthoring.swift, Packages/BreakdownCore/Sources/BreakProbe/TrickSearch.swift, Packages/BreakdownCore/Tests/BreakdownCoreTests/AuthoredLibraryTests.swift. Creates: App/TrickPathThumb.swift, BreakdownTests/TrickPathThumbTests.swift, localization/pending/v074-trick-shots.json, changelog-pending/v074-trick-shots.md.
- May read: App/ShowpieceModel.swift, App/ShotAttempt.swift, App/TrickSignature.swift, App/Theme.swift, App/LensLayer.swift (colours), App/BallTextures.swift, Packages/BreakdownCore/Sources/BreakProbe/** (ContentVerify, main), Packages/BreakdownCore/Sources/BreakdownPhysics/** (the cue strike and squirt model), BreakdownTests/TrickShotJudgeTests.swift.
- Hooks used: F4 (TrickSignature.events, filled by lens-pacing, ids "squirt" and "side-off-rail" reserved), F6 (setPaceSignature, replay(withLens:), currentAttempt, timeline, captions).
- Tests: TrickPathThumbTests: every TrickShots.all answer solves to a non-empty cue-ball path starting at its layout's cue ball; jump-over has an airborne stretch; masse-curve has a sliding stretch whose heading turns at least 10 degrees. Package: `swift test --package-path Packages/BreakdownCore --filter AuthoredLibraryTests` passes and `swift run -c release --package-path Packages/BreakdownCore BreakProbe verify` exits 0 with the new shots in it. TrickShotJudgeTests stay green.
- Brief (done looks like):
  1. Signature in the trick replay: in TrickShotMode.update, at .watching to .explaining, before model.replay(withLens: true), call model.setPaceSignature(TrickSignature.events(forTrick: shot.id, in: model.timeline, captions: model.captions)) and keep the answer's paths: answerPaths = model.currentAttempt?.ghostPaths().
  2. Watch yours: TrickShotMode.watchYours() (signature for this shot on the player's recording, then replay(withLens: true)); the judged card, when made, shows "Watch yours in the Lens". The phase stays judged (the version does not change, so nothing is re-judged).
  3. The answer's path: TrickShotMode.showAnswerPath (reset by begin, next, end and watch); in the judged and aiming phases, once answerPaths exists, the card offers "Show the answer's path" / "Hide the answer's path". Extract the path drawing from GhostOverlay into a reusable view (paths, colour, dash) used by GhostOverlay unchanged and by TrickTableLayer for the answer: neutral white, dashed, about half opacity, cue ball path only plus its rest point; never orange.
  4. Gallery: TrickPathThumb.swift with a shared @MainActor cache that solves each answer off the main actor once per run with PoolSolver.simulate(NextShot.shot(from: layout, direction: (cos aim, sin aim), speed: solution.power, tipUp:, tipSide:, seed: 1, parameters: PoolParameters(), elevation: solution.elevation ?? 0)) (the numbers BreakProbe verify proves), samples each moving ball's path by phase, and draws in a Canvas: table outline at the table's aspect, six pocket marks, start balls, the cue-ball path magenta while sliding, cyan while rolling, white dashed while airborne, object paths thin white. In TrickShotList each row gets the drawing (about 96 by 48 points) beside the text; at accessibility text sizes it sits above the text at full width; hidden from VoiceOver; a failed solve shows the row as today. Solving starts when the list appears, never at launch.
  5. New shots (ids "squirt", "side-off-rail"): add search specs to TrickAuthoring and run `swift run -c release --package-path Packages/BreakdownCore BreakProbe tricks squirt side-off-rail`; copy the layout, strike, goal and measured windows into AuthoredTricks; add the words and both shots to TrickShots.authored. Squirt (difficulty 2): an object ball in line with a pocket, a firm stroke (about 4 m/s or more) with strong side; acceptance: the same stroke aimed dead straight misses, the answer pots, side window above zero. Side Off the Rail (difficulty 3): a one-rail kick to a ball (first hit, and a drop if the search finds one); acceptance: the same aim and power with no side fails the goal. Both: aim window at least 0.4 degrees and power window at least 0.2 m/s, so they are makeable; if a shot cannot meet this after a fair search, leave it out and say so in the changelog fragment. Words per shot: title, hook, goal line, idea, maths (written from the solver's own squirt and rail models, read in BreakdownPhysics), spoken maths, praise; generic terms only.
  6. Text fixes: Two-Rail Kick's idea no longer mentions side spin; Draw-Massé Carom gets a maths line and its spoken form (hit the 4 first, the draw-massé curve back to the 9: a sliding ball's path bends along its slip); TrickShotViews' header no longer says "ten trick shots" or "two that wait on new physics" (count-agnostic).
  7. Translations fragment (about 20 keys) and changelog fragment.

Stream: menus-entries
- Features: R's entry points, G3's Mac menu item, G4's menu and How to play parts.
- Owns (edit): App/TitleScreen.swift, App/MacChrome.swift, App/Match/TableGamePage.swift, App/Match/TableGameWords.swift, BreakdownTests/TableGameWordsTests.swift. Creates: localization/pending/v074-menus-entries.json, changelog-pending/v074-menus-entries.md.
- May read: App/Match/MatchMode.swift, App/Match/MatchRecord.swift, App/Match/OpponentWords.swift, App/Match/MatchWords.swift, App/TableList.swift, App/NotebookPanel.swift, App/ShowpieceModel.swift, Packages/BreakdownCore/Sources/BreakdownRules/Tables/FivePinRules.swift.
- Hooks used: F6 (model.computerLevel, model.highlightOnOffer, model.watchHighlight()).
- Tests: TableGameWordsTests updated for the new game lines; no new test file.
- Brief (done looks like):
  1. TitleScreen: the level picker binds to model.computerLevel (remove the local @State). mainList order: Continue / Continue match, Play, Trick shots (line "Watch a shot that looks impossible, see why it works, then make it."), Learn, Behind the 8-Ball, Tables, Watch the intro, How to play, Options. Play's line: "Four games against the computer, or practise on your own." The intro: "A pool table that shows its own physics. Play four games against the computer, and see why every shot went where it did." playList: after Nine-ball, rows for bumper pool ("You against the computer. Bank your balls past the bumpers into your cup.") and five-pin ("You against the computer. Drive its ball into the pins. First to \(FivePinRules.standardTarget).") using the same game names as NotebookWords.gameName, recordMark(kind, level:), and start(MatchStartRequest(kind:, computer: model.computerLevel)). How to play steps: "Take your shot", "Read the Lens", "Try again", then a new last step "Watch the trick shots" / "Tap Trick shots to watch a shot that looks impossible, see why it works in the Lens, then make it yourself. Learn has six short lessons whenever you want them." (the old "Learn the shots" step goes). Fix the purpose comment and the stale two-player comments.
  2. MacChrome: New Game covers [.eightBall, .nineBall, .bumperPool, .fivePin, .barBilliards]; the computer levels show for every kind except bar billiards (reuse "Against the Computer: \(level.title)"); bar billiards keeps Play Alone. Playback gets "Watch It in the Lens" (no new shortcut unless a free one exists) enabled while model?.highlightOnOffer != nil, calling model?.watchHighlight().
  3. TableGamePage: for bumper pool and five-pin, an "Against the computer" heading (existing key), the level picker bound to model.computerLevel (existing "Level" key, ComputerLevel.title), level.line, then "Play the computer" (new key; prominent; symbol person.and.background.dotted) with the won/played line for that level when one exists, then Practice (not prominent). Bar billiards unchanged. replacingFor: Int? becomes replacing: MatchStartRequest?; start(_:) and begin(_:) take the request and call request.start(on: model) then onStarted(); replaceQuestion takes it. Remove the "no computer player" comment.
  4. TableGameWords.gameLine: bumper pool "Race the computer to sink all your balls in your cup."; five-pin "Score off the pins and the red against the computer, first to \(target)." (Int, the rules' standardTarget).
  5. Translations fragment (about 12 keys) and changelog fragment.

Merge and finish (coordinator): merge the six branches in any order (ownership is disjoint), merge each localization/pending/v074-*.json with scripts/localization-merge.py (keys list from each fragment's "keys"), run scripts/translation-check.py, fold changelog-pending into CHANGELOG.md [0.7.4] crediting each builder by model and effort, compile once, run the app tests and the package tests, fix what the compile finds, play the first minute on a fresh install, then ship to TestFlight.

6. FIRST-MINUTE CHECK

- Launch is untouched: no stream edits startOpeningIfFirstLaunch, beginHandOver, the hand-over card, FirstInstruction or the music start; the menu is still skipped on a first launch, so its new order is not seen until the player opens it.
- The first break cannot raise anything new: the highlight judge only runs when openingStage == .none, and the first break is struck while it is .firstBreak; the free-play break card therefore starts from the second rack.
- The first break still plays at real speed with the Lens off: finishStrike's speed rule is unchanged, so no guided hold happens, which means no signature beat, no contact geometry and no close-up (all three exist only inside a held guided beat).
- PacePlan's .firstLaunch style is left exactly as it is and never receives a signature.
- Nothing auto-plays anywhere: every new replay starts from a tap (Watch it in the Lens, Watch yours, Watch your best shot); every new card sits in the existing card slot, vanishes on the next touch of aim, power or spin, and makes no sound.
- No lesson is suggested anywhere new; How to play now ends with the trick shots and only mentions the lessons as an option.
- The computer games are reached only from the menu or the Tables pages.
- The only new sound is the made-it chime on Table cleared, which needs a whole rack cleared first.
