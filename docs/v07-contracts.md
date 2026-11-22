<!--
Author: Claude Opus 5.5 High
Date: 21-November-2026
PURPOSE: The shared contract for version 0.7.0 (plans/21-Nov-2026-bugs-after-0-6-6-plan.md, "How 0.7.0 is built"): the
         small shared types the foundation step added as real Swift, the new model calls and properties every view and
         input builder codes against (built later by the model stream in App/ShowpieceModel.swift), the calls other
         streams provide to each other, the touch arbitration rule, and who owns which file. Thirteen builders branch
         from the foundation commit and read this first.
SRP/DRY check: Pass - names, signatures and ownership only. The why of each fix lives in the plan and in the comments
         of the files named here. docs/award-batch-contracts.md still holds for everything it covers (the physics
         switch, ShotFacts, the match building blocks, the award-batch model calls); this page only adds to it.
-->
# 0.7.0: the shared contract

## In plain words

Thirteen builders fix every bug from the review of 0.6.6 at the same time, each in their own copy of the code, and the
pieces only fit if they all use the same names. This step laid the foundation: four small shared types (why a stroke
was refused, which balls each table uses, which cue the game picked, and which way the player is playing), the exact
names of every new thing the central model will offer the screens, the rule that decides who owns a finger on the
table, and a table of who owns which file. Nothing here changes how the game plays yet.

Rules for using this page:

- Use these names exactly. If you must change one, say so in your report; the coordinator reconciles at the merge.
- Section 1 is built and committed. Sections 2 and 3 are signatures: the named stream writes them, everyone else calls
  them as if they already exist. The coordinator compiles once, after the merge.
- Everything the model offers lives on the main actor, like today's model. The shared types in section 1 are plain
  nonisolated `Sendable` values, safe from any thread.
- Words a player reads go through `String(localized:)`; new English strings go in
  `localization/pending/v07-<stream>.json` with all eleven translations. The coordinator alone edits
  `CHANGELOG.md`, the version and build number, and adds keys to `App/Localizable.xcstrings`.

## 1. Shared types the foundation added (built and committed)

### 1.1 Why a stroke was refused — `App/ShotRefusal.swift`

```swift
enum ShotRefusal: String, CaseIterable, Sendable {
    case noCall               // eight-ball, no call and no suggestion (MatchMode.readyToShoot)
    case backswingTooShort    // pushed before a real backswing (StrokeTracker.minimumBackswing)
    case ballInHandNotPlaced  // a lifted ball sits where it may not go (fire: confirmCueBallPlacement failed)
    case gameOver             // the match has a result
    case notYourTurn          // the computer's turn (MatchMode.personMayAct)
    case replayPlaying        // the shot on screen is still playing (aimReady false)
    case choicePending        // accept the table / spot the 8 / re-rack is waiting
    case rulingPending        // the ruling card is up or the device is being handed over (phase != .aiming)
    case stillSolving         // the last stroke is still being solved (isSolving)
    var sentence: String { get }   // the card's one line, localized ("Call your shot first.")
}
```

Each case names, in its comment in the file, the guard in today's code that refuses for it. A pointer released ahead
of the cue ball is a change of mind, not a refusal: no card.

### 1.2 Each table's balls — `App/TableBallSet.swift`

```swift
enum BallColour: String, CaseIterable, Sendable { case white, red, yellow }
enum BallLook: Equatable, Sendable {
    case pool(number: Int)                       // today's numbered pool picture; 0 is the cue ball
    case plain(BallColour)                       // one colour, no number
    case spotted(BallColour, spot: BallColour)   // bumper pool's marked ball of each side
}
enum TableBallSet: String, CaseIterable, Sendable {
    case pool, barBilliards, fivePin, bumperPool
    static func `for`(table: TableKind) -> TableBallSet   // call it as TableBallSet.for(table: k)
    static let bumperPoolSideColours: [BallColour]        // [.white, .red]: seat 0 white, seat 1 red
    func look(of ball: Int) -> BallLook                   // per ball slot 0...15
    func label(of ball: Int) -> String                    // badge and ball-icon word
}
```

- Bar billiards: `BarBilliardsRules.whiteBalls` plain white, `BarBilliardsRules.redBall` plain red.
- Five-pin: `FivePinRules.playerBalls` white then yellow, `FivePinRules.redBall` plain red.
- Bumper pool: `BumperPoolRules.sides[0]` white, `sides[1]` red; the first ball of each side is `.spotted` with the
  other side's colour.
- A slot the table does not use keeps `.pool(number:)` (it is off the table and never drawn).
- Labels: pool keeps "Cue ball", "Solid", "Stripe", "Eight ball"; the tables say "White", "Red", "Yellow",
  "Marked white", "Marked red". Ball names inside sentences stay `TableGameWords.ball(_:kind:)` (match) and
  `MatchWords` / `TableWords` (pool); this type does not repeat them.

### 1.3 The cue pick — declarations in `App/Stroke/CueProfile.swift` (the equipment stream fills them)

```swift
enum CueKind: String, CaseIterable, Codable, Sendable {
    case house                    // house-maple.blend; raw value "house" = CueProfile's existing house id
    case breakCue = "break"       // oxblood-break.blend (`break` is a keyword)
    case jump                     // amber-jump.blend
    case masse                    // masse-cue.blend
    case rosewoodFourPoint        // rosewood-four-point.blend, a plain cue
    case cobalt                   // cobalt.blend, a plain cue
}
struct CueChoice: Equatable, Codable, Sendable {
    enum Reason: String, CaseIterable, Codable, Sendable { case standard, breakShot, jump, steepMasse }
    var kind: CueKind
    var reason: Reason
    init(kind: CueKind, reason: Reason)
    static let standard: CueChoice    // .house, .standard
}
```

Only the cues that have art are declared. art/equipment holds six cues (house maple, oxblood break, amber jump, the
massé cue, rosewood four-point, cobalt); brass cross and silver spider are rests, not cues, and the swan-neck rest is
the one rest model the game draws. `CueProfile.house`, `all`, `selected`, `launchSpeed` and `isHouse` are untouched:
the house cue still solves bit for bit as before.

### 1.4 Which way the player is playing — `App/PlayInput.swift`

```swift
enum PlayInput: String, CaseIterable, Sendable { case touch, pointer, keyboard, controller }
```

The Pencil on the glass counts as `.touch`. Each input route sets `model.inputInUse` (2.1) on its first event; the
hand-over card, the panel hint, How to play and the spoken first line pick their instruction by it (items 1 and 51).

## 2. The app contract: new model calls (the model stream builds them in `App/ShowpieceModel.swift`)

All on `@MainActor @Observable final class ShowpieceModel`. Existing names keep their meaning unless a line says
otherwise. "Called by" names the streams that use it.

### 2.1 Input and refusals (items 1, 2, 13, 51)

```swift
/// The input route in use; every route sets it on its first event (touch: StrokeGesture/AimOverlay, pointer and
/// Pencil hover: PointerAim, keyboard: MacChrome and the key handlers, controller: ControllerInput).
/// Starts as .pointer on the Mac, .touch elsewhere.
var inputInUse: PlayInput

/// What a fire attempt did.
enum StrokeOutcome: Equatable { case breakStruck, shotStruck, refused(ShotRefusal) }

/// Break or shoot, whichever is next, as fire() does today, reporting what happened. On refusal it records the reason
/// (lastRefusal) and strikes nothing. In eight-ball with no call made it adopts the suggested call (MatchMode, 3.3)
/// and plays it; with no suggestion it refuses with .noCall. Every route uses it: the stroke's push, Shoot, Return,
/// the Mac menu, the controller, VoiceOver.
@discardableResult func fireStroke() -> StrokeOutcome
/// Kept for existing callers: fireStroke() == .breakStruck.
@discardableResult func fire() -> Bool

/// Why a stroke would be refused if fired now (every case except .backswingTooShort, which only the input sees), or
/// nil when one may be struck. Asked BEFORE a stroke starts: touch refuses at touch-down on the cue ball, the shot
/// panel, the Mac menu and the controller disable Shoot and show the reason. .noCall only when no suggestion exists.
var strokeRefusal: ShotRefusal? { get }

/// The last refusal, for the shot card's line and the call card's pulse. Cleared by the next accepted strike and by
/// clearRefusal(). refusalSerial is bumped on every refusal, so the same reason twice still pulses the card.
private(set) var lastRefusal: ShotRefusal?
private(set) var refusalSerial: Int
/// Input code reports a refusal it decided itself (the touch stroke's short backswing).
func refuse(_ reason: ShotRefusal)
func clearRefusal()
```

Item 2's order on touch: the push is delivered, `fireStroke()` is called, and the contact click
(`Haptics.shared.strokeContact()`) plays only when the outcome is not `.refused`.

### 2.2 Aim snapshot, placement and the cue-angle lock (items 7, 9, 12)

```swift
/// The aim and power at one instant (touch-down), so a touch that turns out to be a pinch, a pan or a double tap can
/// put them back exactly.
struct AimSnapshot: Equatable { let racked: Bool; let aimDegrees: Double; let aimOffset: Double; let power: Double
                                let strokeBridge: Double? }
func aimSnapshot() -> AimSnapshot
/// Puts the snapshot back (written directly, so a lesson lock cannot half-restore it). Ignored if the table changed
/// meanwhile (racked differs).
func restoreAim(_ snapshot: AimSnapshot)

/// Free play: the ball at a table point that may be lifted now (any ball on the table in free play; in a match only
/// the striking ball with ball in hand), nearest first within `radius` metres; nil when none. Touch and pointer use
/// the same call, then the existing beginPlacingBall(_:), moveCueBallCandidate(to:), confirmCueBallPlacement()
/// ("Place it", FreePlayViews) and cancelPlacement(). placingBall (existing, private(set)) says which ball is lifted.
func liftableBall(near point: Vec2, within radius: Double) -> Int?

/// The cue's angle for the next shot (sine), with the lesson lock applied like power, tip and aim: the setter does
/// nothing unless openControls contains .elevation and elevationAllowed. Every player-facing writer uses it (the
/// Pencil in StrokeGesture, the cue-angle control in ShotPanel). Authored modes keep writing shotElevation directly.
var activeElevation: Double { get set }
```

### 2.3 The first minute and the menu (items 3, 6, 8, 42, 52, 53, 55)

```swift
/// .firstBreakCard is new and appended: the player's first break has played out and its short card is up (what the
/// break did, "Learn the shots" prominent, "Keep playing"); the menu opens only after it.
enum OpeningStage: Equatable { case none, playing, handOver, firstBreak, firstBreakCard }
/// The card's "Learn the shots": ends the opening, opens the menu with the lesson list open.
func learnAfterFirstBreak()
/// The card's "Keep playing": ends the opening, the menu stays closed, Your shot is asked to open.
func keepPlayingAfterFirstBreak()
/// The package's reading of the shot on screen (what the break did: pocketed, scratch), for the card's words.
var shotFactsOnScreen: ShotFacts? { get }

/// The model asks the view to open, close or toggle "Your shot" (after a break once the balls stop on the person's
/// turn, Keep playing, the controller's button). ShowpieceView watches it with onChange and acts on `action`.
struct ShotPanelRequest: Equatable { enum Action: Equatable { case open, close, toggle }
                                     let serial: Int; let action: Action }
private(set) var shotPanelRequest: ShotPanelRequest?
func requestShotPanel(_ action: ShotPanelRequest.Action)

/// True while one of the shots struck at this table (a player's shot or break, or the computer's) is the recording on
/// screen: not a still table, not the showpiece opening. The slim playback row under the shot panel shows then.
var playerShotOnScreen: Bool { get }

/// Later launches: the opening's slow Lens replay plays behind the dimmed menu on its own clock, with no table sounds
/// and no haptics (the title music plays as usual). Started by the model itself on a launch that has seen the opening
/// and asks for no specific screen; stopped by anything that puts a table on screen.
private(set) var menuBackdropPlaying: Bool

/// The next step from stored progress, for the menu's highlighted entry; nil once the whole path is done.
var nextStep: NextStep? { get }
enum NextStep: Equatable, Sendable {
    case lesson(number: Int, title: String)   // the first lesson not passed ("Next: Lesson 2, Follow")
    case trickShot(title: String)             // that lesson's trick shot (Lesson.trickID), once the lesson is passed
    case gameAgainstEasyComputer              // every lesson and its trick shot done, no game finished against easy
    /// "Next: Lesson %lld, %@" / "Next: the trick shot %@" / "Next: a game against the easy computer"
    var sentence: String { get }
}

/// True while the clock holds a headline beat (the cue ball handing its speed to the rack, skid turning into roll):
/// its equation shows with the event's own numbers even with Show the maths off (CaptionViews, lens).
var holdingHeadline: Bool { get }

/// True when the Lens replay on screen was started by the player (Replay with the Lens, Watch it in the Lens), not by
/// the opening; the Lens tips wait for the first guided hold of such a replay (LensCallouts, lens).
private(set) var lensReplayStartedByPlayer: Bool
/// While true, a held beat's reading time does not run out (the Lens tips are showing over it).
var holdForTips: Bool
```

The opening's beat count on first launch (three or four) and the headline beats are the model's (PacePlan); the skip
layer's place and "Tap to skip" are the menu's (ShowpieceView, OpeningHandover).

### 2.4 Matches and the computer (items 13, 14, 16)

```swift
/// A match break plays at real speed in the ordinary view (no cold open, the Lens left as it was); the full opening
/// stays for first launch, practice and Watch the intro. After a match break the ruling card offers the Lens replay:
var offerLensReplayOfBreak: Bool { get }
func watchBreakInLens()                  // replay(withLens: true) of the break on screen, started by the player
/// A match shot is still playing (solving or replaying): the "See the ruling" button shows.
var matchShotPlaying: Bool { get }
func seeRuling()                         // jump to the end of the shot on screen, so the ruling comes at once

/// The computer's turn, as the table shows it.
enum ComputerTurnStage: Equatable, Sendable {
    case none        // not the computer's turn
    case thinking    // MatchOpponent is planning (it starts while the ruling card before its turn is still up)
    case staging     // the aim line swings to its choice and the cue draws back for a beat
    case striking    // its stroke is struck and playing
}
var computerTurnStage: ComputerTurnStage { get }
/// False while the person may not act on the table: the computer's turn (any stage but .none) or a solve in flight.
/// ShotPanel greys out, touch and pointer ignore the cloth, the controller and the Mac menu disable Shoot.
var personControlsLive: Bool { get }

/// The computer's stroke, staged: places the cue ball, swings the aim to `aimDegrees` (or the break offset), draws
/// the cue back for a beat, then strikes (setting MatchMode.computerActing itself around the strike). Returns true
/// when staging began; the strike follows on its own. Replaces the instant playComputerStroke for MatchOpponent.
@discardableResult
func stageComputerStroke(placement: Vec2?, aimDegrees: Double, breakAimOffset: Double, power: Double,
                         tipUp: Double, tipSide: Double) -> Bool
```

### 2.5 Lessons, the strike and the cue (items 11, 23, 57)

```swift
/// The lesson pass shot's "Back to the lesson's stroke": as tryAgain() (same start, ghost kept, compared), but with
/// these settings instead of the last try's. LessonMode (sound-lessons) calls it with the lesson's reference.
func tryAgain(restoring settings: TrickSettings)

/// The cue's elevation the next strike and the 3D cue use: the larger of the player's angle (activeElevation) and the
/// least angle that clears every ball under the whole cue (Reach.clearingElevation, 3.1); 0 for a break.
var strikeElevation: Double { get }
/// The mechanical bridge (the swan-neck rest) is drawn and used: the mode shows the bridge, or the stance is Rest,
/// in every mode. TableStage (look) passes it to the cue rig instead of showsBridge.
var restInUse: Bool { get }

/// The cue the game picked for the next strike (CueProfile.choice, 3.2), from the break, the player's angle and side.
var cueChoice: CueChoice { get }
/// That cue's profile (CueProfile.profile(for: cueChoice.kind)). Replaces every app read of CueProfile.selected:
/// the launch speed, the power bar's zones, the drift, the power readout (AimGauges), the stroke words (StrokeWords).
var cueInHand: CueProfile { get }
```

The stance card's indicator line for the pick is the equipment stream's words (3.2). Power stays swing speed: the
heavier cue sends the ball faster at the same swing, through `cueInHand.launchSpeed(forPower:)`.

### 2.6 Store scenes (item 40)

```swift
/// Launch flags for the store pictures and video. Each skips the menu and the opening and puts its scene up still.
enum StoreScene: Equatable, Sendable {
    case match              // -storeMatch: eight-ball against the medium computer mid-game, "Why that shot" open
    case ruling             // -storeRuling: a two-player eight-ball ruling card after a foul
    case lesson(Int)        // -storeLesson <1...6>: that lesson held on its key moment with its band up
    case tableGame(MatchKind)   // -storeTableGame bumperPool|fivePin|barBilliards: a scored game mid-way
    case drill              // -storeDrill: the straight-stroke drill with a measured stroke on its card
    case ride               // -storeRide: a Ride replay held where the room and the lamp show
    static let flags: [String]   // the six flag names above, for TitleScreen.launchSkipsTitle
    static var requested: StoreScene? { get }   // parsed once from the launch arguments
}
```

Views that must open something for a scene (MatchViews' "Why that shot", the lesson card) read
`StoreScene.requested`. TitleScreen adds `StoreScene.flags` to its `launchSkipsTitle` switches (menu). The release
stream pins the one-time keys (seenOpening, lensTipsSeen, aimHintSeen, lessonsDone and the rest) in the store scripts.

## 3. Calls the other streams provide to each other

### 3.1 Physics — `App/Stroke/Reach.swift`

```swift
extension Reach {
    /// Sine of the least cue angle above the table that clears every ball under the whole cue, from the tip at the cue
    /// ball back `cueLength` metres to the butt (not only up to the bridge), with the cue resting on its support
    /// `support` metres behind the ball; 0 when a level cue clears. The model passes cueInHand.length and
    /// strokeBridgeLength.
    static func clearingElevation(layout: [Vec2], cueBall: Int, aim: Vec2, table: TableSpec, support: Double,
                                  cueLength: Double) -> Double
}
```

Physics also names and creates the one package library for authored answers (item 38); the app and BreakProbe both
import it. Its target name goes in physics' report so the release stream's upload gate and the coordinator use it.

### 3.2 Equipment — `App/Stroke/CueProfile.swift`, `App/Stroke/StanceWords.swift`

```swift
struct CueProfile {   // additions to the existing struct
    let length: Double                                 // stored, metres tip to butt; the house cue 1.47 (Cue.usdz)
    static func profile(for kind: CueKind) -> CueProfile
    /// The pick: break cue for a break, jump cue for a jump, massé cue for a steep massé, house cue otherwise.
    /// Thresholds are the equipment stream's, each with its reason in a comment.
    static func choice(isBreak: Bool, elevation: Double, tipUp: Double, tipSide: Double) -> CueChoice
}
enum StanceWords {
    static func cueLine(_ choice: CueChoice) -> String?   // the stance card's indicator; nil for .standard
}
```

`CueProfile.selected` stays the house cue: `BreakdownTests/StrokeTests.swift` (stroke-model) asserts it is the house
cue and that its launch speed is bit-identical to the power. The app reads the per-shot cue through
`model.cueInHand`; equipment does not repurpose `selected`.

### 3.3 Match — `App/Match/*`

```swift
final class MatchMode {   // additions to the existing class
    /// The suggested call (moved here from MatchCallControl so the model and the call card share it): the first ball
    /// on the aim line, if it may be called, into the pocket nearest the line it leaves along. Nil when none.
    var suggestedCall: EightBallCall? { get }
    /// No call made: take the suggestion as the call and remember it was suggested. False when there is none.
    func adoptSuggestedCall() -> Bool
    /// The last ruled shot was played on the suggested call (the ruling card says which call that was).
    private(set) var lastCallWasSuggested: Bool

    /// Routine rulings settle by themselves into a line in the turn banner; the card stays for the rest.
    enum RulingShow: Equatable { case banner, card }
    /// .card for any foul, a pending choice, a result, and a turn change between two people on one device;
    /// .banner for "keep shooting" and the computer's ordinary turns.
    var lastRulingShow: RulingShow { get }
    static let settleBeat: Double                       // seconds a .banner ruling shows before settling (reason in file)

    /// The saved game named for the menu's Continue row (which game, against whom, whose shot).
    static func savedSummary() -> SavedMatchSummary?
}
/// In App/Match/MatchMode.swift.
struct SavedMatchSummary: Equatable { let kind: MatchKind; let opponent: ComputerLevel?; let playerNames: [String]
                                      let turnName: String }
extension MatchRecord {   // App/Match/MatchRecord.swift
    /// Games against the computer only, per game and level (two-player games are no longer counted per seat).
    static func record(kind: MatchKind, level: ComputerLevel) -> (won: Int, lost: Int)
}
```

The model reads `MatchMode.savedSummary()` into `var savedMatchSummary: SavedMatchSummary? { get }` on ShowpieceModel
(refreshed whenever the save changes, as `savedMatchExists` is today) for TitleScreen, which also asks before a new
match replaces it; "End match" on the match card calls the existing `model.endMatch()`; the Mac's New Free Game calls
`model.startGame()` (keeps the save, as Practice does). MatchOpponent starts thinking while the ruling card before
its turn is up and plays through `model.stageComputerStroke` (2.4).

### 3.4 Touch — `App/TableZoom.swift`, `App/Stroke/StrokeTracker.swift`

```swift
extension TableZoom {
    func zoomStep(_ steps: Int)                // + in, - out, for the View menu's Zoom In / Zoom Out
    func actualSize()                          // the fitted view (springBack), for Actual Size
    func panStep(_ direction: SIMD2<Float>)    // arrow keys while zoomed
}
extension StrokeTracker {
    /// The pull's power curve (item 11): pull depth in metres to the power fraction 0...1, giving the soft and medium
    /// speeds most of the pull's length. The touch stroke, the overlay's pull and PointerAim's pull all use it.
    static func powerFraction(forDepth depth: Double) -> Double
}
```

### 3.5 Gauges and pointer — `App/AimGeometry.swift`

```swift
extension AimGeometry {
    /// What the guide shows the cue ball hitting first, along the launch direction (side-spin push included). One
    /// answer for the target badge (look), the spoken aim and Aim to pot (access) and the guide (item 50).
    @MainActor static func guideContact(for model: ShowpieceModel) -> AimContact?
    /// The labelled fork when side spin turns the ball half a degree or more off the cue's line (item 24); nil below.
    static func fork(aim: Vec2, tipUp: Double, tipSide: Double, elevation: Double,
                     parameters: PoolParameters) -> AimFork?
}
struct AimFork: Equatable, Sendable {
    let cueLine: Vec2            // unit: where the cue points
    let ballLine: Vec2           // unit: where the ball leaves
    let turnDegrees: Double      // signed, + counter-clockwise
    static var cueLabel: String { get }    // the words on each prong, localized by gauges
    static var ballLabel: String { get }
}
```

AimOverlay (touch) draws the fork from `AimGeometry.fork(...)`; with the aim guide off it draws only the cue's line.

### 3.6 The rest

- Stroke model — `App/GameSettings.swift`: `static let buttonOnlyKey = "optionShootWithButtonOnly"` (item 45). When on,
  the touch stroke sets power but never plays on the push; Shoot plays. StrokeGesture reads it.
- Menu — `App/OpeningHandover.swift`: `enum FirstInstruction { static func line(for input: PlayInput) -> String }`, the
  one instruction per input (item 1), read by the hand-over, the panel hint, How to play and TableAccessLayer (item 51).
- Look — `App/BallTextures.swift`: `static func swatch(_ look: BallLook) -> (Double, Double, Double)` for flat icons;
  the ball pictures follow `TableBallSet.for(table:)` and are re-dressed when the table changes (TableScene). The
  match views colour their icons with it and label them with `label(of:)`. The look stream also corrects the header of
  `App/Tables/FivePinTable.swift` (a one-comment hook), which still says the yellow and red carry pool number discs.
- Sound — `App/FeelMapping.swift`: `GameMoment` gains `case madeIt, madeItBig` (appended), played with the existing
  `SoundBoard.play(_:)`: a lesson passed, a trick shot made, a medal won; `madeItBig` for gold and the sixth lesson.
  LessonViews and TrickShotViews (sound-lessons) and EightBallViews (lens) each add that one call.

## 4. Who owns a touch on the table (item 7)

Touch, pointer and the model must agree on this; the touch stream builds it (AimOverlay, StrokeGesture, TableZoom),
the gauges stream follows it for the pointer (PointerAim), and the model supplies 2.2's calls.

States of one touch sequence (from the first finger down to the last finger up):

1. **Undecided** — from touch-down. The model's `aimSnapshot()` is taken at that instant. Nothing on the model changes
   while undecided: no aim, no power, no lift, no skip to the end.
2. **Zoom** — a second finger lands within the pairing window (touch's named constant) and NOT inside the cue-ball
   grab circle, or a double tap is recognised: `restoreAim(snapshot)`, then zoom owns every finger until all lift.
   From **Aim**, a second finger anywhere does the same (the first finger's aim is undone).
3. **Bridge and stroke** — a finger resting on the cloth while another lands inside the cue-ball grab circle (either
   order: a touch joined by a second within the pairing window, or a resting finger while another reaches the ball):
   the resting finger is the bridge, never an aim or a stroke; the other is the stroke candidate. Once a stroke owns,
   every further finger is the bridge and pinch and pan hold still (`TableZoom.strokeHold`).
4. **Commit** — the first finger moves past the slop (the overlay's 10-point `pullSlop`) or stays alone for the hold
   delay (touch's named constant). Then by where it started:
   - inside the cue-ball grab circle, balls at rest, `model.strokeRefusal == nil` → **Stroke** (a refusal there
     records it with `refuse(_:)` and the touch does nothing else);
   - on a ball `model.liftableBall(near:within:)` returns, or near the lifted ball → **Placement** (drag moves it,
     the red tint shows an illegal spot, "Place it" puts it down);
   - anywhere else → **Aim** (drag to aim).
5. **Tap** — lifted while undecided, with no second finger: on the cloth with the balls at rest, tap to aim; on a
   liftable ball in free play, lift it; while the shot on screen is still playing, skip to its end. A pinch while the
   shot plays zooms and never skips it.

The cue-ball grab circle is sized from the ball's own size on screen with a floor (touch states both numbers and why;
the floor is half of the 44-point minimum hit target). The pointer: hover only draws a faint preview line and never
moves the aim; a click or press-drag on the cloth sets the aim; a set aim never moves when the pointer leaves; a press
on the cue ball and a drag back is the pull, a release behind the ball plays (pointer only) and a release ahead of it,
or short of the backswing, is a change of mind that restores the snapshot with no card; no release plays while a ball
is lifted; scroll turns the aim by the camera's sign like the arrow keys. The Pencil's hover follows the pointer
rules; on the glass it follows the touch rules, and its tilt changes `activeElevation` only past the writing grip.

## 5. Who owns which file

Each file has exactly one owner. Paths are from the repository root. New files a stream creates are its own.

| Stream | Files |
|---|---|
| base (done) | `App/ShotRefusal.swift`, `App/TableBallSet.swift`, `App/PlayInput.swift`, `docs/v07-contracts.md`, `localization/pending/v07-base.json`; in `App/Stroke/CueProfile.swift` only the `CueKind` and `CueChoice` declarations (the file is equipment's) |
| physics | `Packages/BreakdownCore/Package.swift`; `Packages/BreakdownCore/Sources/BreakdownPhysics/Impacts.swift`, `NextShot.swift`, `Parameters.swift`, `Rack.swift`, `RootFinder.swift`, `Simulation.swift`; `Packages/BreakdownCore/Sources/BreakdownLensModel/Geometry.swift`, `LensEvent.swift`; `Packages/BreakdownCore/Sources/BreakdownTimeline/BallSegment.swift`, `Quat.swift`, `ShotFacts.swift`, `TableFeatures.swift`, `Timeline.swift`; every file in `Packages/BreakdownCore/Sources/BreakProbe/` (`ContentVerify.swift`, `EightBallAuthoring.swift`, `JamSweep.swift`, `LessonAuthoring.swift`, `RealWorldCases.swift`, `RealWorldSweep.swift`, `Reauthor.swift`, `TrickAuthoring.swift`, `TrickSearch.swift`, `main.swift`); every file in `Packages/BreakdownCore/Tests/BreakdownCoreTests/` except `BarBilliardsRulesTests.swift`; the new authored-answers library under `Packages/BreakdownCore/Sources/`; `App/PlaySurface.swift`, `App/Stroke/Reach.swift`, `App/TrickShots.swift`, `App/Lessons/Lessons.swift`, `App/EightBall/EightBallSituations.swift`; `BreakdownTests/ReachTests.swift`, `BreakdownTests/EightBallJudgeTests.swift`, `BreakdownTests/TrickShotJudgeTests.swift`, `BreakdownTests/LessonTests.swift`, `BreakdownTests/SelfCheckTests.swift`, `BreakdownTests/TestShots.swift` |
| touch | `App/Stroke/StrokeTracker.swift`, `App/Stroke/StrokeGesture.swift`, `App/AimOverlay.swift`, `App/TableZoom.swift` |
| gauges-pointer | `App/AimGauges.swift`, `App/PointerAim.swift`, `App/AimGeometry.swift` |
| stroke-model | `App/Stroke/StrokeModel.swift`, `App/Stroke/StrokeWords.swift`, `App/Stroke/StrokeViews.swift`, `App/Stroke/StrokeDrill.swift`, `App/GameSettings.swift`, `BreakdownTests/StrokeTests.swift` |
| model | `App/ShowpieceModel.swift`, `App/ShotAttempt.swift`, `App/PacePlan.swift` |
| match | `App/Match/CallControl.swift`, `App/Match/MatchMode.swift`, `App/Match/MatchOpponent.swift`, `App/Match/MatchRecord.swift`, `App/Match/MatchViews.swift`, `App/Match/MatchWords.swift`, `App/Match/OpponentWords.swift`, `App/Match/TableGamePage.swift`, `App/Match/TableGameWords.swift`, `App/Match/TableGames.swift`; `Packages/BreakdownCore/Sources/BreakdownRules/Tables/BarBilliardsRules.swift`, `Packages/BreakdownCore/Tests/BreakdownCoreTests/BarBilliardsRulesTests.swift`; `App/BreakdownApp.swift`; `BreakdownTests/MatchClockTests.swift`, `BreakdownTests/MatchOpponentTests.swift`, `BreakdownTests/TableGameWordsTests.swift` |
| menu | `App/OpeningHandover.swift`, `App/TitleScreen.swift`, `App/ShowpieceView.swift`, `App/PlaybackControls.swift`, `App/ShotPanel.swift`, `App/MacChrome.swift`, `App/FreePlayViews.swift`, `App/RetryWords.swift`, `App/NotebookPanel.swift` |
| lens | `App/LensLayer.swift`, `App/Captions.swift`, `App/LensCallouts.swift`, `App/CaptionViews.swift`, `App/NotebookInfo.swift`, `App/EightBall/EightBallViews.swift`, `App/LensTextures.swift`, `BreakdownTests/CaptionEngineTests.swift` |
| look | `App/BallTextures.swift`, `App/TableScene.swift`, `App/TargetBallBadge.swift`, `App/TableBuilder.swift`, `App/TableRoom.swift`, `App/TableMeshes.swift`, `App/TableDetail.swift`, `App/ShotCamera.swift`, `App/TableCamera.swift`, `App/TableStage.swift`, `App/SurfaceTextures.swift`; `Tools/blender/make_pocket.py` and the new pocket export scripts in `Tools/blender/`; `App/Models/Pocket.usdz` and the new side-pocket model in `App/Models/` |
| equipment | `App/Stroke/CueProfile.swift` (except base's two declarations, which it fills), `App/Stroke/StanceViews.swift`, `App/Stroke/StanceWords.swift`, `App/CueRig.swift`; `App/Models/Cue.usdz`, `App/Models/Bridge.usdz` and the new cue and rest models in `App/Models/`; `Tools/blender/make_cue.py`, `Tools/blender/make_bridge.py` and the new cue and rest export scripts in `Tools/blender/` |
| sound-lessons | `App/SoundBoard.swift`, `App/FeelMapping.swift`, `App/Haptics.swift`, `App/Lessons/LessonMode.swift`, `App/Lessons/LessonViews.swift`, `App/TrickShotMode.swift`, `App/TrickShotViews.swift`, `BreakdownTests/FeelMappingTests.swift` |
| access | `App/ControllerInput.swift`, `App/TableAccessLayer.swift`, `App/TableWords.swift`, `App/VoiceSynth.swift`, `scripts/translation-check.py`; the existing translations in `App/Localizable.xcstrings` (register and wording fixes only) |
| release | `scripts/testflight.py`, `scripts/store-shots.sh`, `scripts/store-shot.sh`, `scripts/store-video.sh`, `scripts/store-video-cut.sh`, `scripts/store-upload.py`, `scripts/store-listing-check.py`, `store/README.md`, every `store/listing/*.json` (`ar`, `de`, `en`, `es`, `fr`, `it`, `ja`, `ko`, `pt`, `pt-BR`, `ru`, `zh-Hans`), `store/screenshots/`, the app icon in `App/Assets.xcassets/` (and the new layered icon file), `docs/2026-11-02-breakdown-spec.md` (its status note); in `Breakdown.xcodeproj/project.pbxproj` only the two `ENABLE_USER_SELECTED_FILES = readonly` settings (the unused file-access entitlement, item 37) |
| coordinator | `CHANGELOG.md`; the version and build number in `Breakdown.xcodeproj/project.pbxproj`; new keys in `App/Localizable.xcstrings`; `scripts/localization-merge.py`; merging `localization/pending/` |

Files with no owner this batch (no item needs them; small additive hooks only, reported): `App/CameraFraming.swift`,
`App/CueAngleControl.swift`, `App/EightBall/EightBallJudge.swift`, `App/EightBall/EightBallMode.swift`,
`App/EightBall/EightBallTypes.swift`, `App/GhostOverlay.swift`, `App/LensScrubCheck.swift`,
`App/NotebookGeometry.swift`, `App/NotebookStory.swift`, `App/PlaySurfaceLook.swift`, `App/PlayTableLayer.swift`,
`App/PlayerShotSpeed.swift`, `App/PowerWords.swift`, `App/RollingVoices.swift`, `App/ScrubBar.swift`,
`App/SoundStage.swift`, `App/StartupAssets.swift`, `App/SurfaceSound.swift`, `App/Surfaces.swift`,
`App/TableFrame.swift`, `App/TableKind.swift`, `App/TableLines.swift`, `App/TableList.swift`, `App/TableProps.swift`,
`App/Tables/BarBilliardsTable.swift`, `App/Tables/BumperPoolTable.swift`, `App/Tables/FivePinTable.swift`,
`App/Theme.swift`, `App/TitleMusic.swift`, `App/TrickShotJudge.swift`, `App/Models/` files not named above,
`Packages/BreakdownCore/Sources/BreakdownRules/EightBallRules.swift`, `EightBallTypes.swift`, `MatchRules.swift`,
`MatchTypes.swift`, `NineBallRules.swift`, `Tables/BumperPoolRules.swift`, `Tables/FivePinRules.swift`,
`Tables/TableSpots.swift`, `BreakdownTests/CameraFramingTests.swift`, `Breakdown-Info.plist`,
`App/PrivacyInfo.xcprivacy`, `scripts/smoke-test.sh`, `Tools/framing-check/`.

Where the plan lists one item under two streams, the file's owner does that part and the other only calls it:

- `App/ShowpieceModel.swift` is the model's. Items 12, 13 and 23 appear under touch too: the model declares and owns
  `activeElevation`, `fireStroke`, `strokeRefusal` and `strikeElevation`; touch only calls them.
- `App/AimOverlay.swift` is touch's. Gauges owns `AimGauges.swift`, `AimGeometry.swift` and `PointerAim.swift` and
  never edits AimOverlay; the fork (item 24) is computed in AimGeometry and drawn by AimOverlay.
- `App/ShotPanel.swift` is the menu's, including the bridge slider (item 5), the cue-angle control's write through
  `activeElevation` (item 12), the grey-out (item 16) and See the contact's words (item 53).
- `App/GameSettings.swift` is the stroke model's in this batch (the award batch gave it to the model; this plan wins).
- `App/Captions.swift` is the lens's for this batch, the physics captions included.
- `App/TableStage.swift` is the look's: it draws the rest when `model.restInUse` (items 10 and 23) and the cue at
  `model.strikeElevation`; the rest model itself and the cue's angle handling are the equipment's (`App/CueRig.swift`).
- The notebook files named in the award-batch contract as `DuoPanel.swift` and `DuoInfo.swift` are now
  `App/NotebookPanel.swift` (menu) and `App/NotebookInfo.swift` (lens).

The hub rule: a file owned by another stream gets, at most, a small additive hook edit when it is truly unavoidable
(one call, one case appended, one property read), never a rewrite, and every such edit is listed in the report under
"hub edits outside ownership". The calls in sections 2 and 3 exist so that almost none are needed. New cards and pages
reach the notebook and side panel the way existing cards do (NotebookPanel's cards, ShowpieceView's layout switch and
the `inlinePages` environment value), so on the open folding phone and big screens nothing covers the table.

## 6. Decided here beyond the brief (so nobody is surprised)

- `PlayInput` is a fourth shared type: the per-input instruction (items 1 and 51) is used by four streams, so the code
  for "which input" is fixed here; its words stay the menu's.
- The cue list has the six cues that have art, not nine: the brief's "five other cues" counted the two rests.
- Bumper pool's first seat plays white and the second red (no file names a colour; ball 0 is white on every other
  table).
- `fire()` stays for existing callers; `fireStroke()` is the new route that reports a refusal.
