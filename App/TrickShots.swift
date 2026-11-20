// Author: Claude Opus 5.5 High
// Date: 20-November-2026
// PURPOSE: The trick-shot library: data only. Ten shots, each with its id, title, a one-sentence hook, where the balls
//          start (only the balls it uses; every other ball is off the table), the authored answer (aim, power, cue-tip
//          height and side; cue elevation is reserved for the massé and the jump), the goal the app checks from the
//          recording (which balls must drop and in which pockets, which ball the cue ball must touch first, a ball that
//          must bank, where the cue ball must stop; the cue ball must never scratch), whether it needs the mechanical
//          bridge, the one physics idea it teaches in plain words with an optional equation, a difficulty, and the
//          skill window: how far each setting can stray from the answer and the shot still works.
//          Shots 1 to 8 were authored with the real solver by the search in the package's dev tool (run
//          "BreakProbe tricks"; Packages/BreakdownCore/Sources/BreakProbe/TrickAuthoring.swift). Every number below
//          was printed by that search; each shot's comment records the windows it measured, walked outward from the
//          answer one small step at a time, so a window is an unbroken band, never a lucky point. Shots 9 and 10 need
//          cue elevation and airborne balls, which the solver does not have yet; they are listed as pending and show
//          as "Coming next".
//          Coordinates are table metres on the solver's plan: x along the length (0 to 2.54), y across (0 to 1.27).
//          Pockets by index: 0 (0,0), 1 (2.54,0), 2 (0,1.27), 3 (2.54,1.27) corners; 4 (1.27,0), 5 (1.27,1.27) sides.
//          Read by TrickShotMode (flow), TrickShotJudge (goals and windows) and TrickShotViews (titles and words).
// SRP/DRY check: Pass - data and the small types that hold it. The search lives in the package's dev tool and
//          copies nothing from here (the package must not depend on app files); this file holds only its answers.
import BreakdownLensModel
import BreakdownPhysics

/// The settings of one strike. For a shot `aim` is degrees counter-clockwise from the long axis; for the break it is
/// metres off the head ball (positive is to the shooter's left), as everywhere else in the app.
struct TrickSettings: Equatable {
    var aim: Double
    var power: Double            // launch speed, metres per second
    var tipUp: Double            // metres above (+) or below (-) the cue ball's centre
    var tipSide: Double          // metres right (+) or left (-) of centre
    /// How steeply the cue is raised, degrees. Reserved for the massé and the jump; nil means a level cue.
    var elevation: Double? = nil
}

/// How far each setting can move from the answer, either way, and the shot still works (half-widths, measured).
/// Aim is degrees for a shot and metres for the break; tip values are metres. A zero tipSide means side was not part
/// of the lesson and is not judged.
struct TrickWindow: Equatable {
    var aim: Double
    var power: Double
    var tipUp: Double
    var tipSide: Double
}

struct TrickDrop: Equatable {
    let ball: Int
    /// The pocket it must drop in; nil for any pocket.
    let pocket: Int?
}

struct TrickZone: Equatable {
    let centre: Vec2
    let radius: Double
}

struct TrickGoal: Equatable {
    var drops: [TrickDrop]
    /// Where the cue ball must come to rest, if anywhere in particular.
    var cueZone: TrickZone? = nil
    /// The ball the cue ball must touch first, if it matters.
    var firstHit: Int? = nil
    /// A ball that must touch a cushion before it drops (a bank), if any.
    var bank: Int? = nil
}

enum TrickSetup: Equatable {
    /// Sixteen positions, index 0 the cue ball; off-table balls sit at NextShot.offTable.
    case layout([Vec2])
    /// The full rack built from this seed (Rack.positions), broken from the head spot.
    case rack(seed: UInt64)
}

enum TrickDifficulty: Int, Comparable {
    case easy = 1, medium, hard
    var label: String {
        switch self { case .easy: return "Easy"; case .medium: return "Medium"; case .hard: return "Hard" }
    }
    static func < (a: TrickDifficulty, b: TrickDifficulty) -> Bool { a.rawValue < b.rawValue }
}

struct TrickShot: Identifiable, Equatable {
    let id: String
    let number: Int
    let title: String
    /// One sentence that sells the shot.
    let hook: String
    /// What has to happen, in a few words, for the card while aiming.
    let goalLine: String
    let setup: TrickSetup
    let solution: TrickSettings
    let goal: TrickGoal
    let usesBridge: Bool
    /// The one physics idea, a sentence for the card.
    let idea: String
    /// The equation behind it, shown behind Show the maths, and how VoiceOver should read it.
    let maths: String?
    let mathsSpoken: String?
    let difficulty: TrickDifficulty
    let window: TrickWindow
    /// What the card says when it is made.
    let praise: String
    /// True while the shot waits on physics the solver does not have yet.
    let pending: Bool

    var isBreak: Bool { if case .rack = setup { return true } else { return false } }
}

/// Sixteen positions with only the named balls on the table.
private func placed(_ balls: [Int: Vec2]) -> [Vec2] {
    var out = [Vec2](repeating: NextShot.offTable, count: 16)
    for (k, v) in balls { out[k] = v }
    return out
}

enum TrickShots {
    static func shot(id: String) -> TrickShot? { all.first { $0.id == id } }

    static let all: [TrickShot] = [
        // AUTHORED SHOTS GO HERE
        masse, jumpOver,
    ]

    // MARK: 9 and 10: waiting on cue elevation and airborne physics

    static let masse = TrickShot(
        id: "masse-curve", number: 9, title: "The Massé",
        hook: "Raise the cue almost straight up and the cue ball bends around a ball in its way.",
        goalLine: "Curve the cue ball around the blocker to pot the target.",
        setup: .layout(placed([:])), solution: TrickSettings(aim: 0, power: 0, tipUp: 0, tipSide: 0, elevation: 70),
        goal: TrickGoal(drops: []), usesBridge: false,
        idea: "A steep cue gives the cue ball spin about a tilted axis, and the cloth turns that spin into a curve.",
        maths: nil, mathsSpoken: nil, difficulty: .hard, window: TrickWindow(aim: 1, power: 1, tipUp: 1, tipSide: 0),
        praise: "Bent it round.", pending: true)

    static let jumpOver = TrickShot(
        id: "jump-over", number: 10, title: "Jump the Blocker",
        hook: "Hit down on the cue ball and it hops clean over a ball in the way.",
        goalLine: "Jump the blocker and pot the target.",
        setup: .layout(placed([:])), solution: TrickSettings(aim: 0, power: 0, tipUp: 0, tipSide: 0, elevation: 45),
        goal: TrickGoal(drops: []), usesBridge: false,
        idea: "A downward strike drives the ball into the slate, and the slate throws it back up into the air.",
        maths: nil, mathsSpoken: nil, difficulty: .hard, window: TrickWindow(aim: 1, power: 1, tipUp: 1, tipSide: 0),
        praise: "Clean over the top.", pending: true)
}
