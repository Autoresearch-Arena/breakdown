<!--
Author: Claude Opus 5.5 High
Date: 21-November-2026
PURPOSE: The shared contract for the award batch: every type, field and function the foundation step added to the
         package, the app interface the "model" stream will build and every other stream codes against, and who owns
         which file. Eleven builders branch from the foundation commit and read this first.
SRP/DRY check: Pass - names and ownership only. The why of each change lives in the plans (plans/21-Nov-2026-*.md)
         and in the comments of the files named here; this page does not repeat them.
-->
# Award batch: the shared contract

## In plain words

Twelve builders are working on the game at the same time, each on their own branch, and the pieces only fit if they
all use the same names. The first builder (this step) laid the foundation: a safe switch for new physics, the new
fields the physics work will fill in, one shared reading of what happened in a shot, and the building blocks of a
real match (players, turns, fouls, rulings). This page lists those names exactly, plus the names the app's central
model will offer to the screens, and who owns which file. Nothing here changes how the game plays today.

Rules for using this page:

- Use these names exactly. If you must change one, say so in your report; the coordinator reconciles at the merge.
- Contract files (marked "shared" below) take additive edits only: append enum cases at the end, add members with
  defaults. Never rename or reorder a raw value: saved matches and recording hashes depend on them.
- Words a player reads never live in the package. The package gives codes; the app turns codes into sentences with
  `String(localized:)`, so the string catalog finds them.

## 1. What the foundation added to the package (built and committed)

### 1.1 The physics switch — `BreakdownPhysics/Parameters.swift` (solver owns it from here)

```swift
public struct PoolParameters {
    public var modelGeneration: Int = 1           // read by the solver; 1 = today's solver, bit for bit
    public static let newestGeneration: Int = 2   // what -newPhysics plays on
    public var usesGenerationTwo: Bool { get }    // modelGeneration >= 2

    // Generation-two numbers: ignored at generation 1, hashed only above it. Starting values, reasons in the file.
    public var railRestitutionSlope: Double = 0.025      // e(v) = max(floor, cushionRestitution - slope * v_normal)
    public var railRestitutionFloor: Double = 0.6
    public var cueMass: Double = 0.54                    // kg
    public var shaftEndMass: Double = 0.0073             // kg: about 2.49 degrees of deflection at half-radius side
    public var tipGrip: Double = 0.58                    // miscue past R * tipGrip / sqrt(1 + tipGrip^2) = 0.5017 R
    public var miscueSpeedFraction: Double = 0.5         // miscue launch speed / centre-hit speed
    public var miscueMaxDeflection: Double = 0.0875      // tangent (tan 5 degrees), seeded random within +-
    public var pocketCaptureFallFraction: Double = 1.0 / 3.0  // captured once it falls this share of R crossing
    public var rimSkipSpeedLoss: Double = 0.05           // share of speed lost skipping a hole
}
```

Hash rule: the generation is folded in only when it is not 1, behind the marker `"GENR"`, and the nine numbers above
only when it is above 1 (in the order listed; append new ones at the end of `generationTwoNumbers`). Default
parameters hash exactly as before (test: `PhysicsSwitchTests.testDefaultParameterHashIsUnchanged`).

The generation rule is written at the top of `Simulation.swift`: every physics change checks `modelGeneration` and
takes the old path, line for line, at generation 1, and leaves the new event fields nil there. The jam guard is the
one change allowed at every generation (it only alters shots that hit the event limit today).

### 1.2 The strike names its ball — `CueStrike`

```swift
public struct CueStrike {
    public var ballIndex: Int   // the ball the cue strikes; 0 (the default) is the pool cue ball
    public init(direction: Vec2, speed: Double, tipUp: Double = 0, tipSide: Double = 0, elevation: Double = 0,
                ballIndex: Int = 0)
}
```

Not hashed, not encoded. The solver still strikes ball 0; making it strike `ballIndex` is the solver's job.

### 1.3 New event shapes — `BreakdownLensModel/LensEvent.swift`

```swift
public enum LensEventKind: UInt8 {
    case cueStrike, phaseTransition, ballBall, cushion, pocket, pinDown, rimSkip, settledInContact  // last two new
}
public struct PocketEntry: Sendable, Equatable {
    public var speed: Double    // m/s across the cloth
    public var sine: Double     // angle between the path and the pocket's centre line, + is counter-clockwise
    public var cosine: Double   // 1 is dead centre
    public init(speed: Double, sine: Double, cosine: Double)
}
public struct LensEvent {
    // ...all existing fields unchanged, plus (all nil at generation 1 and in older recordings):
    public var entry: PocketEntry?        // .pocket and .rimSkip
    public var miscue: Bool?              // .cueStrike
    public var deflectionSine: Double?    // .cueStrike: sine of the turn from the aim, + counter-clockwise
    public var bedImpulse: Double?        // .cushion on a rail nose: N s pushed down into the cloth
    public var energyRemoved: Double?     // .settledInContact: joules taken out (before minus after)
    // init gains: entry:, miscue:, deflectionSine:, bedImpulse:, energyRemoved: (all default nil), before producer:
}
```

- `.rimSkip`: `pocket` = the hole (0 to 5 edge, 6 + j bed hole j), `balls[0]` = the ball, `entry` = how it came in.
- `.settledInContact`: `balls` lists every ball in the jam (two or more). Never index `balls[1]` blindly.
- Corner and side centre lines for `entry`: corner along its diagonal into the corner; side straight out across the
  rail; a bed hole from the entry point through the hole's centre.
- `Timeline.contentHash` folds each new field only when it is set, behind its own marker (`ENTR`, `MISC`, `DEFL`,
  `BEDI`, `JAMS`). So the solver must leave them nil at generation 1.
- `Vec2` is now `Codable` (for saving a match's layout).

Switches over event kinds that the foundation touched with minimal handling (owners refine them):

| File | Owner | What it does with the new kinds now |
|---|---|---|
| App/Captions.swift | solver (physics captions) | `.rimSkip`, `.settledInContact` return no caption |
| App/PacePlan.swift | notebook / Lens | rim skip paces like a jaw hit, settled like an impact |
| App/ScrubBar.swift | access | settled ticks like an impact, rim skip a short pocket-coloured tick |
| App/DuoInfo.swift | notebook | `default:` already ignores them |
| App/EightBall/EightBallJudge.swift | (judge) | `default:` already ignores them |
| App/LensLayer.swift (rings) | access | filtered by kind, so the new kinds draw no ring yet |
| App/FeelMapping.swift | sound | filtered by kind, so no sound or haptic yet (rim and miscue sounds are the sound stream's) |
| App/CaptionViews.swift anchor | access | works for any kind |

### 1.4 One reading of a shot — `BreakdownTimeline/ShotFacts.swift` (shared)

```swift
public struct ShotFacts: Sendable, Equatable {
    public static let sameInstant: Double      // 1e-5 s: contacts closer than this are a tie
    public static let railMoveMinimum: Double  // 0.002 m: a frozen ball pushed into its rail has not "reached" it
    public static let offTable: Vec2           // (-1, -1), the same parking spot as NextShot.offTable
    public static func isOnTable(_ p: Vec2) -> Bool

    public struct Contact { public var ball: Int; public var time: Double }
    public struct Drop { public var ball: Int; public var pocket: Int; public var time: Double
                         public var entry: PocketEntry?; public var isBedHole: Bool { get } }
    public struct HoleDrop { public var ball: Int; public var hole: Int; public var time: Double }
    public struct PinKnock { public var pin: Int; public var ball: Int; public var time: Double; public var order: Int }
    public struct PostTouch { public var post: Int; public var ball: Int; public var time: Double }

    public init(timeline: Timeline, start: [Vec2], cueBall: Int = 0,
                sameInstant: Double = ShotFacts.sameInstant, railMoveMinimum: Double = ShotFacts.railMoveMinimum)

    public let cueBall: Int
    public let ballCount: Int
    public let firstContactTime: Double?          // nil: the cue ball touched nothing
    public let firstContactBalls: [Int]           // every ball touched within sameInstant of the first, event order
    public var firstContact: Contact? { get }
    public func firstContact(preferring legal: Set<Int>) -> Contact?   // a tie goes to a legal ball
    public let pocketed: [Drop]                   // every drop, in order (edge pockets and bed holes)
    public let holeDrops: [HoleDrop]              // bed holes only, hole = pocket - 6
    public let cueBallPocketed: Bool
    public let cueBallOffTable: Bool
    public let cueBallScratched: Bool             // pocketed or off the table
    public let objectBallsOffTable: [Int]
    public let railOrPocketAfterContact: Bool     // the pool "rail after contact" test: any cushion face (rail, jaw,
                                                  // knuckle; not a post), a drop or flying off counts
    public let ballsReachingRail: [Int]           // straight rails only (not jaws), after first contact, cue ball
                                                  // included, first-reach order
    public var objectBallsReachingRail: [Int] { get }   // the break's "four balls to a rail" count is .count
    public var objectBallsPocketed: [Drop] { get }
    public func pocket(of ball: Int) -> Int?
    public let resting: [Vec2]                    // offTable for any ball gone; NextShot.layout(after:) gives the
                                                  // same places except it re-spots a scratched cue ball
    public let pinsDown: [PinKnock]
    public let postsTouched: [PostTouch]
    public let rimSkips: [Drop]
}
```

Build it with the striking player's ball: `ShotFacts(timeline: tl, start: layoutBeforeShot, cueBall:
rules.cueBall(for: state.turn, in: state))`. The Behind the 8-Ball judge now reads its scratch, first contact, rail
after contact and ball-off-the-table checks from it (same numbers, same verdicts).

### 1.5 The match building blocks — new module `BreakdownRules` (shared contract files)

Pure Swift, depends on LensModel and Timeline (never Physics). It is in the `BreakdownCore` library product, so the
app links it already: add `import BreakdownRules` to any app file that names these types.

Moved from the app, names and raw values unchanged (`BreakdownRules/EightBallTypes.swift`):

```swift
public enum EightBallGroup: String, CaseIterable, Codable, Sendable { case solids, stripes
    public var balls: [Int]; public var other: EightBallGroup; public static func of(ball: Int) -> EightBallGroup? }
public enum EightBallPocket: Int, CaseIterable, Codable, Sendable {
    case headRight = 0, footRight = 1, headLeft = 2, footLeft = 3, rightSide = 4, leftSide = 5 }
public enum EightBallCall: Equatable, Hashable, Codable, Sendable { case ball(Int, pocket: EightBallPocket), safety
    public var ball: Int?; public var pocket: EightBallPocket? }
public enum EightBallFoul: String, CaseIterable, Codable, Sendable { case scratch, wrongBallFirst, noBallHit,
    noRailAfterContact, objectBallOffTable, cueOrBridgeTouchedBall, doubleHit, illegalJump }
public enum EightBallLoss: String, CaseIterable, Codable, Sendable { case eightOnFoul, eightEarly, eightWrongPocket,
    eightOffTable }
```

Their `title` (the words) stays in the app, as extensions in `App/EightBall/EightBallTypes.swift`.

Match types (`BreakdownRules/MatchTypes.swift`):

```swift
public enum MatchKind: String, CaseIterable, Codable, Sendable { case eightBall, nineBall, bumperPool, fivePin, barBilliards }
public struct PlayerID: Hashable, Comparable, Codable, Sendable { public var index: Int; public init(_ index: Int)
    public static let first, second: PlayerID; public func next(among count: Int) -> PlayerID }
public struct Player: Hashable, Codable, Sendable { public var id: PlayerID; public var name: String }
public enum BallInHand: String, Codable, Sendable { case none, anywhere, behindHeadLine }   // never use BallInHand?
public enum MatchRack: Equatable, Sendable { case fifteenBallTriangle, nineBallDiamond
    case tableLayout(objectBalls: [Int]); public var objectBalls: [Int] }
public enum MatchFoul: String, CaseIterable, Codable, Sendable { case scratch, wrongBallFirst, noBallHit,
    noRailAfterContact, objectBallOffTable, cueOrBridgeTouchedBall, doubleHit, illegalJump, wrongCup,
    ownBallKnockedPins; public init(_ foul: EightBallFoul) }
public enum RulingReason: String, Codable, Sendable { case legalPot, noLegalPot, calledBallMissed, foul, tableOpen,
    groupsAssigned, breakLegal, breakIllegal, scratchOnBreak, eightOnBreak, ballSpotted, foulWarning, pointsScored,
    pinsReset, ballsReturned, whitePegDown, blackPegDown, timeUp, choiceAnswered, rerack, gameOver }
public enum MatchEndReason: String, Codable, Sendable { case eightBallPocketed, eightOnFoul, eightEarly,
    eightWrongPocket, eightOffTable, nineBallPocketed, threeConsecutiveFouls, allBallsSunk, targetScoreReached,
    timeExpired, conceded; public init(_ loss: EightBallLoss) }
public struct MatchResult: Equatable, Codable, Sendable { public var winner: PlayerID?; public var reason: MatchEndReason }
public enum MatchChoice: String, Codable, Sendable { case acceptTableOrRerack, spotEightOrRerack
    public var answers: [MatchChoiceAnswer] }
public enum MatchChoiceAnswer: String, Codable, Sendable { case acceptTable, spotEight, rerack }
public struct PendingChoice: Equatable, Codable, Sendable { public var choice: MatchChoice; public var chooser: PlayerID }
public struct FoulRecord: Equatable, Codable, Sendable { public var shot: Int; public var player: PlayerID
    public var fouls: [MatchFoul] }

public struct Ruling: Equatable, Codable, Sendable {
    public var shooter: PlayerID
    public var fouls: [MatchFoul]
    public var reasons: [RulingReason]
    public var nextShooter: PlayerID
    public var ballInHand: BallInHand
    public var ballsToSpot: [Int]
    public var assignedGroup: EightBallGroup?   // to the shooter; everyone else gets .other
    public var points: [Int]                    // per seat, this shot
    public var choice: PendingChoice?
    public var rerack: Bool
    public var result: MatchResult?
    public init(shooter:nextShooter:fouls:reasons:ballInHand:ballsToSpot:assignedGroup:points:choice:rerack:result:)
    public var fouled: Bool { get }; public var turnPasses: Bool { get }
}

public struct MatchState: Equatable, Codable, Sendable {
    public var kind: MatchKind
    public var players: [Player]
    public var turn: PlayerID
    public var groups: [EightBallGroup?]        // by seat
    public var ballsLeft: [Int]                 // object balls on the table, ascending
    public var ballInHand: BallInHand
    public var shotCount: Int
    public var isBreak: Bool
    public var consecutiveFouls: [Int]          // by seat
    public var foulHistory: [FoulRecord]
    public var scores: [Int]                    // by seat
    public var pendingChoice: PendingChoice?
    public var clockRemaining: Double?          // seconds, bar billiards
    public var result: MatchResult?
    public init(kind:playerNames:ballsLeft:ballInHand:clock:firstShooter:)
    public var isOver: Bool; public var tableOpen: Bool; public var currentPlayer: Player?
    public func group(of player: PlayerID) -> EightBallGroup?
    public func ballsRemaining(for player: PlayerID) -> [Int]
}
```

The rules protocol (`BreakdownRules/MatchRules.swift`):

```swift
public protocol MatchRules: Sendable {
    var kind: MatchKind { get }
    var rack: MatchRack { get }
    func ruling(for facts: ShotFacts, call: EightBallCall?, in state: MatchState) -> Ruling
    func mayCall(_ ball: Int, in state: MatchState) -> Bool
    // Optional, with defaults for a plain two-player pool game:
    var playerCount: ClosedRange<Int> { get }                                  // 2...2
    var usesCalls: Bool { get }                                                // false
    var startingBallInHand: BallInHand { get }                                 // .none
    func cueBall(for player: PlayerID, in state: MatchState) -> Int            // 0
    func ballsReturningToHand(after facts: ShotFacts, in state: MatchState) -> [Int]   // []
    var resetsPinsBetweenShots: Bool { get }                                   // false
    var keepsRunningScore: Bool { get }                                        // false
    var turnClock: Double? { get }                                             // nil
    func ruling(answering answer: MatchChoiceAnswer, in state: MatchState) -> Ruling   // no change
    func initialState(playerNames: [String]) -> MatchState
    func applying(_ ruling: Ruling, facts: ShotFacts?, to state: MatchState) -> MatchState   // the bookkeeping
}
```

Implementations go in their own files: `EightBallRules`, `NineBallRules` (rules stream, `Sources/BreakdownRules/`),
`BumperPoolRules`, `FivePinRules`, `BarBilliardsRules` (tables-rules stream, `Sources/BreakdownRules/Tables/`). Each
is a `public struct` with a `public init()`.

### 1.6 Package helpers the rules stream adds (names fixed here so the model can call them)

These do not exist yet; the rules stream writes them with exactly these signatures. `CueBallSpot` lives in
BreakdownPhysics (NextShot.swift). BreakdownPhysics does not import BreakdownRules, so the head-line area is passed
as a plain flag, not a BallInHand. `shot(from:...)` is the existing function with `ballIndex` appended (not a second
overload), and it passes `ballIndex` into the CueStrike it builds.

```swift
// NextShot.swift (rules stream)
public enum CueBallSpot: Equatable, Sendable { case legal, overlapsBall(Int), offBed, onFeature, outsideHeadArea }
extension NextShot {
    public static func placement(of point: Vec2, cueBall: Int = 0, among positions: [Vec2],
                                 behindHeadLine: Bool, parameters p: PoolParameters) -> CueBallSpot
    public static func spot(_ ball: Int, among positions: [Vec2], parameters p: PoolParameters) -> Vec2
        // foot spot, or the nearest free place straight behind it
    public static func shot(from positions: [Vec2], direction: Vec2, speed: Double, tipUp: Double, tipSide: Double,
                            seed: UInt64, parameters p: PoolParameters = PoolParameters(), elevation: Double = 0,
                            ballIndex: Int = 0) -> ShotInput      // ballIndex appended, default 0
}
// Rack.swift (rules stream)
extension Rack {
    public static func nineBallPositions(parameters p: PoolParameters, seed: UInt64) -> [Vec2]  // 10-15 off table
    public static func nineBallBreakShot(parameters p: PoolParameters = PoolParameters(), seed: UInt64,
                                         aimOffset: Double, speed: Double, tipUp: Double = 0,
                                         tipSide: Double = 0) -> ShotInput
}
```

## 2. The app interface the "model" stream builds (documented here, built there)

Everyone else codes against these names from the start. All live on the main actor, like today's model.

### 2.1 ShowpieceModel (App/ShowpieceModel.swift)

```swift
@MainActor @Observable final class ShowpieceModel {
    // Physics developer flag: launch with -newPhysics to play free play and matches on the newest generation.
    // Trick shots, puzzles and the opening break stay on generation 1 until the proof plan re-authors them.
    static let newPhysicsRequested: Bool                 // CommandLine.arguments.contains("-newPhysics")
    var activeModelGeneration: Int { get }               // the generation the next solve uses

    // Solving off the main thread (shootNow and breakNow; table and surface changes may stay direct).
    private(set) var isSolving: Bool

    // Ball in hand (free play after a scratch, matches after a foul, "Move cue ball" at any time in free play).
    private(set) var ballInHand: BallInHand              // from BreakdownRules
    private(set) var placingCueBall: Bool                // the placement state is on
    private(set) var cueBallCandidate: Vec2?             // where the lifted cue ball is now (table metres)
    func beginPlacingCueBall()
    @discardableResult func moveCueBallCandidate(to point: Vec2) -> CueBallSpot   // legality for the red tint
    @discardableResult func confirmCueBallPlacement() -> Bool                     // false (and stays lifted) if illegal
    func cancelPlacement()

    // Free play.
    private(set) var shotsThisRack: Int
    var tableCleared: Bool { get }                       // free play, only the cue ball left
    func rackAgain()                                     // the table-cleared card's "Rack again"
    var canUndo: Bool { get }
    func undoLastShot()                                  // one step back: the layout before the last shot
    private(set) var freePlayRack: FreePlayRack
    func setFreePlayRack(_ rack: FreePlayRack)
    var elevationAllowed: Bool { get }                   // the raised cue is open in free play and matches

    // Matches.
    private(set) var match: MatchMode?                   // nil outside a match
    func startMatch(_ kind: MatchKind)
    var hasSavedMatch: Bool { get }
    func continueSavedMatch()
    func endMatch()

    // Learn from a retry (plan 14).
    private(set) var retryComparison: RetryComparison?   // nil until a second try of the same layout
    var firstContactTime: Double? { get }                // current recording; nil when the cue ball touched nothing
    func seekToFirstContact()                            // pause the replay at that moment

    // The opening for a first-time player.
    private(set) var openingStage: OpeningStage
    func skipOpening()
    var hasSeenOpening: Bool { get }

    // Tip travel.
    var tipLimit: Double { get }          // the dot's travel in this mode (instance; replaces the static 0.02)
    var miscueLimit: Double { get }       // where the ring is drawn: R * tipGrip / sqrt(1 + tipGrip^2)
}

enum FreePlayRack: String, CaseIterable, Codable { case fifteen, nineBall, placeBalls }
enum OpeningStage: Equatable { case none, playing, handOver, firstBreak }

/// App/ShotAttempt.swift (model). The model supplies facts; the view owns the words.
struct RetryComparison: Equatable {
    enum Control: String, CaseIterable { case aim, power, tipUp, tipSide, elevation }
    struct InputChange: Equatable { let control: Control; let before: Double; let after: Double }
    enum Key: Equatable {              // which one sentence the card shows
        case exactRepeat               // same inputs AND same recorded motion and events
        case sameSpot                  // changed too little to describe; finish near the same spot
        case oneChange(Control)        // exactly one control moved
        case severalChanges            // report the differences, leave the cause open
        case missedEverything          // this try touched no ball
    }
    let inputChanges: [InputChange]
    let cueBallFinishShift: Double?    // metres between the two finishes; nil if either cue ball was gone
    let pottedBefore: [Int]
    let pottedNow: [Int]
    let key: Key
}
```

### 2.2 MatchMode (App/Match/MatchMode.swift, model stream)

```swift
@MainActor @Observable final class MatchMode {
    enum Phase: Equatable { case aiming, shooting, ruling, handOver, over }
    let rules: any MatchRules
    private(set) var state: MatchState
    private(set) var phase: Phase
    private(set) var currentCall: EightBallCall?
    func setCall(_ call: EightBallCall?)
    var mustCall: Bool { get }                       // rules.usesCalls && !state.isBreak
    private(set) var lastRuling: Ruling?
    func acknowledgeRuling()                         // ruling card dismissed: to handOver, aiming or over
    func answer(_ answer: MatchChoiceAnswer)         // a pending choice (accept table, spot the 8, re-rack)
    func rematch()
    var playerNames: [String] { get }
    func setPlayerName(_ name: String, for player: PlayerID)
    var cueBallIndex: Int { get }                    // rules.cueBall(for: state.turn, in: state)
}
```

The ruling card waits until the replay is dismissed or finished. The state and the layout are saved after every
ruling to the app's support folder (the model stream picks the file name and the save type; Vec2 is Codable).

## 3. Who owns which file

| Stream | Files |
|---|---|
| base (done) | ShotFacts.swift, BreakdownRules/EightBallTypes.swift, MatchTypes.swift, MatchRules.swift, this page |
| solver | Parameters.swift, Simulation.swift, Impacts.swift, BreakProbe jam command, physics captions in Captions.swift, guide bending in AimGeometry.swift |
| proof | new test files, BreakProbe sweep command, scripts/testflight.py, README.md, ROADMAP.md, the docs spec note |
| rules | BreakdownRules implementations (EightBallRules, NineBallRules), NextShot.swift, Rack.swift |
| tables-rules | table rules in Sources/BreakdownRules/Tables |
| model | ShowpieceModel.swift, ShotAttempt.swift, App/Match/MatchMode.swift, GameSettings.swift |
| menu | TitleScreen.swift, TrickShots.swift (ordering only), the opening hand-over view, Lens callouts |
| play-views | ShotPanel.swift, App/Match/MatchViews.swift, the call control moved out of EightBallViews.swift, GhostOverlay.swift, free-play cards, the ball-in-hand drag in AimOverlay.swift |
| notebook | ShowpieceView.swift, DuoPanel.swift, DuoInfo.swift, Surfaces.swift ScreenLayout, CameraFraming.swift, MacChrome.swift |
| look | TableBuilder.swift, TableMeshes.swift, SurfaceTextures.swift, BallTextures.swift, TableCamera.swift, CueRig.swift, Theme.swift, Tools/blender |
| access | TableWords.swift (new), TableStage.swift, AimOverlay.swift accessibility parts, LensLayer.swift, LensTextures.swift, CaptionViews.swift, controller support, Breakdown-Info.plist |
| sound | SoundBoard.swift, FeelMapping.swift, Haptics.swift, TitleMusic.swift, new audio files |
| release | the app unit-test target (project.pbxproj target edit), the privacy file, scripts/translation check |

Shared by edit rule rather than owner:

- Captions.swift: the solver adds physics captions; anyone else only small additive edits, listed in their report.
- AimOverlay.swift: access owns accessibility, play-views adds the ball-in-hand drag, the solver's guide bending
  goes in AimGeometry.swift.
- ShotFacts.swift, MatchTypes.swift, MatchRules.swift, LensEvent.swift: append-only; the rules stream is the default
  owner of the first three, the solver of the last.
- CHANGELOG.md, the version and build number, App/Localizable.xcstrings: the coordinator only. New player text goes
  in localization/pending/<stream>.json with all eleven translations.

## 4. Edits the foundation made outside its own files

Small, additive, so everything still compiles with the new event kinds and the moved types:

- App/Captions.swift, App/PacePlan.swift, App/ScrubBar.swift: the two new event kinds handled (see 1.3).
- App/EightBall/EightBallJudge.swift: reads ShotFacts for scratch, first contact, rail after contact and balls off
  the table; its two constants now point at ShotFacts' identical values.
- App/EightBall/EightBallTypes.swift: the five moved types replaced by title extensions.
- App/EightBall/EightBallMode.swift, EightBallSituations.swift, EightBallViews.swift: `import BreakdownRules` only.
- Simulation.swift: the generation rule written at the top; no code change.
- Timeline.swift: contentHash folds the new event fields only when set.
- Geometry.swift: Vec2 is Codable.

## 5. Decided here beyond the brief (so nobody is surprised)

- EightBallLoss moved with the other four eight-ball types (the eight-ball rules need it for the result).
- Match additions the plans imply but did not name: `MatchRack` (keeps the rules free of physics), `MatchFoul`
  (with two table fouls, `wrongCup` and `ownBallKnockedPins`), `RulingReason`, `MatchEndReason`, `MatchChoice`,
  `MatchChoiceAnswer` and `PendingChoice` (the eight-ball plan's "accept the table or re-rack" and "spot the 8 or
  re-rack"), `FoulRecord`, and the protocol's `ruling(answering:in:)`, `initialState(playerNames:)` and
  `applying(_:facts:to:)` with shared bookkeeping defaults.
- The retry comparison's `key` is a code, not a sentence: plan 14 gives the words to the view.
- The table rules (bumper pool, five-pin, bar billiards) still need the Boss's yes on their rule sheets
  (other-tables plan); the codes above are the starting set and the tables-rules stream may append to them.
