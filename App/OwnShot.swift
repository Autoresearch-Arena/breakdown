// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// PURPOSE: Make it again (0.7.7, plans/23-Nov-2026-make-it-again-plan.md, new file 1): a player's own saved challenge
//          as plain data, and the one place a free-play attempt is turned into one. An OwnShot keeps the table as it
//          stood before the shot (sixteen start positions), the table and cloth it was played on, the exact strike
//          the solver took (the stroke's drift already in it, and the input's own seed), what the shot did (each object
//          ball that dropped with its pocket or bed hole, the first ball the cue ball touched, a ball that banked in),
//          the player's name for it, whether it has been made again, and how forgiving it is once measured.
//          Everything is stored as plain numbers and raw strings because nothing in the physics package but Vec2 is
//          Codable: the input is rebuilt bit for bit from the numbers (`input`), and the TrickShot the trick-shot mode
//          plays is built from them (`challenge(note:)`), so the existing flow, judge, card, rings and Lens replay
//          need no new judging code.
//          Read by OwnShotShelf (storage and actions), OwnShotProof (solving and measuring), OwnShotWords (the words)
//          and OwnShotViews. No views and no model access here: every function is pure and nonisolated.
// SRP/DRY check: Pass - checked TrickShots (TrickShot, TrickGoal, TrickSettings, TrickWindow are reused as the
//          challenge, not copied), TrickShotJudge (pocket(of:in:) is the judge's own reading; drops(of:) reads the same
//          first pocket event of each ball), ShotAttempt (firstStruck, cueBallScratched, motionHash reused), ShotMoments
//          (railAfterLastContact reused for the bank) and NextShot (the input is rebuilt through NextShot.shot as
//          ShowpieceModel.shootNow builds it). Nothing like a player-saved challenge existed before.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation

/// This run's check of a saved stroke (never stored: a new build may change the physics, so it is checked again).
enum OwnShotCheck: Equatable, Sendable { case checking, holds, changed }

/// One ball the challenge needs down, and the hole it went into (edge pocket 0 to 5, bed hole 6 + j).
struct OwnDrop: Codable, Equatable, Sendable {
    let ball: Int
    let pocket: Int
}

/// The exact strike as the solver took it: the attempt's `input.strike` (the stroke's drift already applied) and the
/// input's own seed, which alone drives the solve (the attempt's `seed` is the model's serial seed; see `make`).
struct OwnStrike: Codable, Equatable, Sendable {
    let directionX: Double
    let directionY: Double
    let speed: Double
    let tipUp: Double
    let tipSide: Double
    let elevation: Double
    let seed: UInt64
}

/// How far each setting can move either way from the saved strike and the shot still works (half-widths: aim in
/// degrees, power in metres per second, tips in metres), and the app build it was measured on, so a new build measures
/// it again (OwnShotProof.measureWindow).
struct OwnWindow: Codable, Equatable, Sendable {
    let aim: Double
    let power: Double
    let tipUp: Double
    let tipSide: Double
    let build: String

    /// Used until a shot's window is measured. It only steers the judge's advice; the notebook's How forgiving block
    /// is never shown with it (OwnShotShelf.isUnmeasured), so no made-up number is shown as a measurement.
    static let fallback = OwnWindow(aim: 0.5, power: 0.5, tipUp: 0.005, tipSide: 0.003, build: "")
}

struct OwnShot: Codable, Identifiable, Equatable, Sendable {
    /// Saved shots' ids start with this, so the trick-shot mode can tell them from the authored ids, which never do.
    static let idPrefix = "own-"
    static func isOwnID(_ id: String) -> Bool { id.hasPrefix(idPrefix) }

    /// idPrefix + a UUID string (no commas, so it could never break the authored progress list's comma format).
    let id: String
    /// The player's own words (shown verbatim, never looked up in the catalog).
    var name: String
    let saved: Date
    /// TableKind.rawValue and PlaySurface.rawValue: raw strings, so neither enum has to become Codable, and a value an
    /// older build does not know survives in the file.
    let tableRaw: String
    let surfaceRaw: String
    /// The physics generation it was solved on (always the default when saved: see `refusal`).
    let generation: Int
    /// Sixteen positions, index 0 the cue ball; off-table balls at NextShot.offTable.
    let start: [Vec2]
    let strike: OwnStrike
    let drops: [OwnDrop]
    let firstHit: Int?
    let bank: Int?
    /// HighlightKind.rawValue when the shot was a remarkable kind the goal really asks for, else nil.
    let kindRaw: String?
    /// String(attempt.motionHash, radix: 16): the save's fingerprint, so the shot on screen is known as saved.
    let motionHash: String
    var window: OwnWindow?
    /// False on save; written every time (no default, as synthesised decoding needs the key).
    var made: Bool

    var table: TableKind? { TableKind(rawValue: tableRaw) }
    var surface: PlaySurface? { PlaySurface(rawValue: surfaceRaw) }
    var kind: HighlightKind? { kindRaw.flatMap(HighlightKind.init(rawValue:)) }

    // MARK: The stroke

    /// The input as ShowpieceModel.shootNow built it (default PoolParameters; the table and surface are written in at
    /// the solve), ball 0 struck, bit for bit. CueStrike's init normalises the direction again, and dividing a unit
    /// vector by its computed length can move the last bit, so the saved components are written back afterwards.
    var input: ShotInput {
        let direction = Vec2(strike.directionX, strike.directionY)
        var i = NextShot.shot(from: start, direction: direction, speed: strike.speed, tipUp: strike.tipUp,
                              tipSide: strike.tipSide, seed: strike.seed, parameters: PoolParameters(),
                              elevation: strike.elevation, ballIndex: 0)
        i.strike.direction = direction
        return i
    }

    /// The answer: the stroke as it was actually struck, in the controls' units. Not the settings the player chose:
    /// free play may have picked the jump or massé cue (whose launch speed is not the power setting) and the stroke's
    /// drift turned the aim and moved the side, so the chosen settings struck clean in trick mode (always the house cue,
    /// where power is the launch speed) would be a different shot. Aim in degrees, as aimAtNearestBall sets it.
    var solution: TrickSettings {
        TrickSettings(aim: atan2(strike.directionY, strike.directionX) * 180 / Double.pi, power: strike.speed,
                      tipUp: strike.tipUp, tipSide: strike.tipSide,
                      elevation: strike.elevation > 0 ? strike.elevation : nil)
    }

    /// The goal the judge checks: the same balls in the same pockets in any order, the same first ball, the bank when
    /// there was one (the judge adds that the cue ball must stay on the table). No cue zone, side rule or second hit.
    var goal: TrickGoal {
        TrickGoal(drops: drops.map { TrickDrop(ball: $0.ball, pocket: $0.pocket) }, firstHit: firstHit, bank: bank)
    }

    // MARK: From an attempt

    /// Why an attempt cannot be saved.
    enum Refusal: Equatable {
        case isBreak, otherCueBall, otherPhysics, cueBallDropped, nothingDropped
    }

    /// Why an attempt cannot be saved, or nil when it can (Decision 1). Five-pin has no holes, so it always gives
    /// .nothingDropped; the table needs no check of its own.
    static func refusal(for a: ShotAttempt) -> Refusal? {
        if a.isBreak { return .isBreak }
        if a.cueBall != 0 { return .otherCueBall }
        if a.generation != PoolParameters().modelGeneration { return .otherPhysics }
        // A pocket event of the cue ball, or a cue ball that left the table any other way (pocketTime covers both).
        if TrickShotJudge.pocket(of: a.cueBall, in: a.timeline) != nil || a.cueBallScratched { return .cueBallDropped }
        if drops(of: a).isEmpty { return .nothingDropped }
        return nil
    }

    /// Object balls with a pocket event, in the order they dropped, each with its pocket. Pocket events are the source,
    /// not pocketTime (which is also set for a ball that flew off the table). The first pocket event of a ball is the
    /// one TrickShotJudge.pocket(of:in:) reads, so the judge sees the same pocket.
    static func drops(of a: ShotAttempt) -> [OwnDrop] {
        var out: [OwnDrop] = []
        for e in a.timeline.events where e.kind == .pocket {
            // LensEvent.pocket is -1 on events that name no pocket.
            guard let b = e.balls.first?.ball, b != a.cueBall, e.pocket >= 0,
                  a.start.indices.contains(b), NextShot.isOnTable(a.start[b]),
                  !out.contains(where: { $0.ball == b }) else { continue }
            out.append(OwnDrop(ball: b, pocket: e.pocket))
        }
        return out
    }

    /// The first dropped ball that came off a rail after its last ball contact (a real bank), or nil. A ball that only
    /// rolled along a rail before anything struck it does not count; the original always passes the judge's own,
    /// weaker bank test. ShotMoments' finders read the events only, so no captions are needed here.
    static func bankedBall(in a: ShotAttempt, drops: [OwnDrop]) -> Int? {
        let m = ShotMoments(timeline: a.timeline, captions: [])
        return drops.first { m.railAfterLastContact(of: $0.ball) != nil }?.ball
    }

    /// The kinds whose name and idea the goal does not ask for: the cue ball's finish (a stop, a draw), a ball that did
    /// not drop (a rim skip), and two that are never saveable. Such a shot gets the plain name and idea.
    static let unnamedKinds: Set<HighlightKind> = [.stopDead, .drawBack, .rimSkip, .breakShot, .redPinAlone]

    /// The challenge made from an attempt, or nil when `refusal(for:)` refuses it. `kind` is the highlight judged on
    /// the attempt (or nil); `number` is the shelf's count plus one, for the default name; `now` is the save time.
    static func make(from a: ShotAttempt, kind: HighlightKind?, number: Int, now: Date = Date()) -> OwnShot? {
        guard refusal(for: a) == nil else { return nil }
        let found = drops(of: a)
        let s = a.input.strike
        let named = kind.flatMap { unnamedKinds.contains($0) ? nil : $0 }
        // The input's seed, never a.seed: after a kept strike the attempt keeps shootNow's serial seed while the input
        // that was solved carries its own.
        let strike = OwnStrike(directionX: s.direction.x, directionY: s.direction.y, speed: s.speed, tipUp: s.tipUp,
                               tipSide: s.tipSide, elevation: s.elevation, seed: a.input.seed)
        return OwnShot(id: idPrefix + UUID().uuidString, name: OwnShotWords.defaultName(kind: named, number: number),
                       saved: now, tableRaw: a.table.rawValue, surfaceRaw: a.surface.rawValue,
                       generation: a.generation, start: a.start, strike: strike, drops: found,
                       firstHit: a.firstStruck, bank: bankedBall(in: a, drops: found), kindRaw: named?.rawValue,
                       motionHash: String(a.motionHash, radix: 16), window: nil, made: false)
    }

    // MARK: As a trick shot

    /// The TrickShot the trick-shot mode plays; nil when the table or surface raw value is not known to this build.
    /// `note`, when given, is added after the hook (the "no longer makes it in this version" line), so the card says so.
    func challenge(note: String? = nil) -> TrickShot? {
        guard let table = self.table, surface != nil else { return nil }
        let w = window ?? .fallback
        let hook = OwnShotWords.hook(self)
        return TrickShot(id: id, number: 0, title: name, hook: note.map { hook + " " + $0 } ?? hook,
                         goalLine: OwnShotWords.goalLine(self), setup: .layout(start), solution: solution, goal: goal,
                         usesBridge: false, idea: OwnShotWords.idea(self), maths: nil, mathsSpoken: nil,
                         difficulty: Self.difficulty(window),
                         window: TrickWindow(aim: w.aim, power: w.power, tipUp: w.tipUp, tipSide: w.tipSide),
                         praise: OwnShotWords.praise, pending: false, cueAngles: nil, table: table)
    }

    /// The challenge with no note.
    var trickShot: TrickShot? { challenge() }

    /// Difficulty from the measured aim window (the authored windows run from about 0.1 to 1.6 degrees); unmeasured
    /// is Medium.
    static func difficulty(_ w: OwnWindow?) -> TrickDifficulty {
        guard let w else { return .medium }
        if w.aim >= 0.7 { return .easy }
        if w.aim >= 0.3 { return .medium }
        return .hard
    }
}
