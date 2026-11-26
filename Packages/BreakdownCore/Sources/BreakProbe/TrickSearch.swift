// Author: Claude Opus 5.5 High
// Date: 20-November-2026
// Edited: Claude Opus 5.5 High, 20-November-2026 (searches use at most three threads unless BREAKPROBE_THREADS says otherwise; strikes carry cue elevation).
// Edited: Claude Opus 5.5 High, 21-November-2026 (proof plan package 4: tip windows stop at the miscue limit (tipReach)
//          instead of 20 mm; generationParameters gives generation one its old numbers.)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 bank: the window walks take the parameters to solve on, the
//          pool table's by default, so "BreakProbe daily" measures shots on other tables and surfaces; pocketName names a
//          bed hole instead of indexing past the six pocket names.)
// PURPOSE: The search machinery behind the trick shots (run by hand with "BreakProbe tricks"; never part of the app or
//          of the package tests). It simulates a candidate shot with the real solver, checks it against a goal (which
//          balls must drop and where, where the cue ball must stop, which ball the cue ball must touch first, no
//          scratch), and measures the "skill window": the contiguous band of aim angles around a solution in which the
//          goal still succeeds, stepping outward from the solution until the first failure on each side. Because the
//          band is walked step by step from the centre, a reported window is never a lucky single point surrounded by
//          misses. The same walk measures the power and cue-tip windows.
//          This is a dev tool, so it may use Foundation and trigonometry; the solver it drives does not.
// SRP/DRY check: Pass - checked main.swift (the old break sweep, kept) and the app's ShowpieceModel (which builds
//          shots the same way: unit direction from an angle, NextShot.shot). The goal test is deliberately duplicated
//          in the app's TrickShotJudge: the app ships the authored answers, this tool only finds them, and keeping the
//          app's data out of the package keeps the package free of app code.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation

let P = PoolParameters()
/// The parameters for a physics generation: the default (tuned) numbers for generation 2, and for generation 1 the
/// old numbers it was authored on (PoolParameters.generationOne), so "verify 1" reproduces what shipped before the flip.
func generationParameters(_ generation: Int) -> PoolParameters {
    var q = generation == 1 ? PoolParameters.generationOne : PoolParameters()
    q.modelGeneration = generation
    return q
}
/// How far from the ball's centre an authored tip may sit (metres, total offset): the miscue limit of the default
/// physics, about half the radius. Every search and window stays inside it, so no authored answer or window edge miscues.
let tipReach = P.miscueOffsetLimit
/// True when a strike's tip sits inside the grip (no miscue).
func insideGrip(up: Double, side: Double) -> Bool { (up * up + side * side).squareRoot() <= tipReach }
let R = P.ballRadius
let L = P.tableLength
let W = P.tableWidth
/// Pocket centres, in the solver's order: corners (0,0) (L,0) (0,W) (L,W), then the sides (L/2,0) (L/2,W).
let pockets = P.pocketCenters
let pocketNames = ["bottom-left corner", "bottom-right corner", "top-left corner", "top-right corner",
                   "bottom side", "top side"]
/// A pocket's name for the tool's output: an edge pocket by pocketNames, a hole in the bed (another table's cup or
/// hole, pocket index 6 + j) by its number, so a shot on another table never indexes past the six names.
func pocketName(_ k: Int) -> String { pocketNames.indices.contains(k) ? pocketNames[k] : "bed hole \(k - 6)" }

/// How the cue strikes: aim in degrees counter-clockwise from the long axis, launch speed in metres per second,
/// and the cue-tip offset from the ball's centre in metres (up is follow, down is draw; right side is positive).
struct Strike: Sendable, CustomStringConvertible {
    var aim: Double
    var power: Double
    var tipUp: Double
    var tipSide: Double
    /// Sine of the cue's angle above the table: 0 is a level cue (every shot but the massé and the jump).
    var elevation: Double = 0
    var direction: Vec2 { let a = aim * Double.pi / 180; return Vec2(cos(a), sin(a)) }
    var description: String {
        String(format: "aim %.3f deg, power %.2f m/s, tip up %+.4f m, side %+.4f m, elevation sine %.2f", aim, power, tipUp, tipSide, elevation)
    }
}

/// What a shot must do, read from its recording.
struct Goal: Sendable {
    /// Balls that must drop, each with the pocket it must drop in (nil: any pocket).
    var drops: [(ball: Int, pocket: Int?)]
    /// Where the cue ball must come to rest, if anywhere in particular.
    var cueZone: (centre: Vec2, radius: Double)? = nil
    /// The ball the cue ball must touch first, if it matters.
    var firstHit: Int? = nil
    /// A ball that must touch a cushion before it drops (a bank shot), if any.
    var bank: Int? = nil
    /// For a carom, the ball the cue ball must touch on its second ball contact (the app's TrickGoal.secondHit).
    var secondHit: Int? = nil
}

func layoutOf(_ placed: [Int: Vec2]) -> [Vec2] {
    var out = [Vec2](repeating: NextShot.offTable, count: 16)
    for (k, v) in placed { out[k] = v }
    return out
}

func unit(_ v: Vec2) -> Vec2 { v.normalized }
func degrees(of v: Vec2) -> Double { atan2(v.y, v.x) * 180 / Double.pi }
func rotate(_ v: Vec2, _ deg: Double) -> Vec2 {
    let a = deg * Double.pi / 180
    return Vec2(cos(a) * v.x - sin(a) * v.y, sin(a) * v.x + cos(a) * v.y)
}

func simulate(_ layout: [Vec2], _ s: Strike, parameters: PoolParameters = P) -> Timeline {
    PoolSolver.simulate(NextShot.shot(from: layout, direction: s.direction, speed: s.power, tipUp: s.tipUp,
                                      tipSide: s.tipSide, seed: 1, parameters: parameters, elevation: s.elevation))
}

/// The pocket a ball dropped in, or nil.
func pocketOf(_ ball: Int, _ tl: Timeline) -> Int? {
    tl.events.first { $0.kind == .pocket && $0.balls.first?.ball == ball }?.pocket
}

func firstStruck(_ tl: Timeline) -> Int? {
    for e in tl.events where e.kind == .ballBall {
        let ids = e.balls.map(\.ball)
        if ids.contains(0) { return ids.first { $0 != 0 } }
    }
    return nil
}

func cueRest(_ tl: Timeline) -> Vec2 { tl.state(ball: 0, at: tl.duration).position }

func passes(_ goal: Goal, _ tl: Timeline) -> Bool {
    // A recording with thousands of events for a handful of balls is the solver chattering (two balls pressed
    // together re-colliding with tiny impulses, found while authoring the throw shot): never author on that.
    if tl.events.count > 4000 { return false }
    if tl.pocketTime[0] != nil { return false }                       // the cue ball must never scratch
    for d in goal.drops {
        guard let k = pocketOf(d.ball, tl) else { return false }
        if let want = d.pocket, want != k { return false }
    }
    if let first = goal.firstHit, firstStruck(tl) != first { return false }
    if let second = goal.secondHit {
        // A carom (the app's TrickShotJudge): the cue ball's second ball contact must be this ball.
        let contacts = tl.events.filter { $0.kind == .ballBall && $0.balls.contains { $0.ball == 0 } }
            .compactMap { $0.balls.first { $0.ball != 0 }?.ball }
        if contacts.dropFirst().first != second { return false }
    }
    if let b = goal.bank {
        let drop = tl.pocketTime[b] ?? -1
        let banked = tl.events.contains { $0.kind == .cushion && $0.edge == .rail && $0.time < drop && $0.balls.first?.ball == b }
        if !banked { return false }
    }
    if let zone = goal.cueZone, (cueRest(tl) - zone.centre).length > zone.radius { return false }
    return true
}

/// Contiguous band of a value around `centre` in which `ok` holds, walked outward in `step`s up to `limit` each way.
/// Returns nil when the centre itself fails.
func band(centre: Double, step: Double, limit: Double, _ ok: (Double) -> Bool) -> (lo: Double, hi: Double)? {
    guard ok(centre) else { return nil }
    var lo = centre, hi = centre
    while hi + step <= centre + limit, ok(hi + step) { hi += step }
    while lo - step >= centre - limit, ok(lo - step) { lo -= step }
    return (lo, hi)
}

/// The aim band around a strike, in degrees, sampled every `step` degrees.
func aimBand(_ layout: [Vec2], _ s: Strike, _ goal: Goal, step: Double = 0.02, limit: Double = 4,
             parameters: PoolParameters = P) -> (lo: Double, hi: Double)? {
    band(centre: s.aim, step: step, limit: limit) { a in
        var t = s; t.aim = a; return passes(goal, simulate(layout, t, parameters: parameters))
    }
}

/// Run `body` for every index in parallel and collect the results in order. The solver is a pure function of its
/// input, so the order the work is done in cannot change any answer.
/// At most `workers` threads (BREAKPROBE_THREADS, default 3): the machine this runs on is shared, and an uncapped
/// search once took every core for an hour.
let workers = max(1, Int(ProcessInfo.processInfo.environment["BREAKPROBE_THREADS"] ?? "") ?? 3)

func parallelMap<T: Sendable>(_ count: Int, _ body: @Sendable (Int) -> T) -> [T] {
    let box = ResultBox<T>(count)
    let n = min(workers, max(1, count))
    DispatchQueue.concurrentPerform(iterations: n) { w in
        for i in Swift.stride(from: w, to: count, by: n) {
            let v = body(i)
            box.lock.lock(); box.items[i] = v; box.lock.unlock()
        }
    }
    return box.items.map { $0! }
}

/// Results slots for parallelMap, written under a lock (each slot once).
final class ResultBox<T>: @unchecked Sendable {
    var items: [T?]
    let lock = NSLock()
    init(_ n: Int) { items = [T?](repeating: nil, count: n) }
}

/// A found shot with its measured windows.
struct Authored: Sendable {
    var id: String
    var layout: [Vec2]
    var strike: Strike
    var goal: Goal
    var aimBand: (lo: Double, hi: Double)
    var powerBand: (lo: Double, hi: Double)
    var tipBand: (lo: Double, hi: Double)
    var note: String

    var aimHalfWindow: Double { min(strike.aim - aimBand.lo, aimBand.hi - strike.aim) }
    var powerHalfWindow: Double { min(strike.power - powerBand.lo, powerBand.hi - strike.power) }
    var tipHalfWindow: Double { min(strike.tipUp - tipBand.lo, tipBand.hi - strike.tipUp) }

    /// How forgiving the shot is in the two things a player sets by feel, power and cue-tip height, measured against
    /// what a player can reasonably hold: about a quarter of a metre per second of power (a few percent of the pull)
    /// and two millimetres on the cue-ball picture. 1 or more means comfortably repeatable.
    var feelScore: Double { min(powerHalfWindow / 0.25, tipHalfWindow / 0.002) }
}

/// Re-centre a strike in the middle of its aim, power and tip bands (twice, since each move shifts the others a
/// little) and measure every band again from the final strike: those are the honest windows to report, walked
/// outward from the very settings the app will play. Nil when the strike stops passing.
func measured(_ id: String, _ layout: [Vec2], _ s: Strike, _ goal: Goal, note: String,
              parameters: PoolParameters = P) -> Authored? {
    var c = s
    for _ in 0..<2 {
        guard let b = aimBand(layout, c, goal, parameters: parameters) else { return nil }
        c.aim = ((b.lo + b.hi) / 2 / 0.01).rounded() * 0.01        // two decimals, the precision the data carries
        guard let p = powerBand(layout, c, goal, parameters: parameters) else { return nil }
        c.power = ((p.lo + p.hi) / 2 / 0.05).rounded() * 0.05
        guard let t = tipUpBand(layout, c, goal, parameters: parameters) else { return nil }
        c.tipUp = ((t.lo + t.hi) / 2 / 0.0005).rounded() * 0.0005
    }
    guard let a = aimBand(layout, c, goal, parameters: parameters), let p = powerBand(layout, c, goal, parameters: parameters),
          let t = tipUpBand(layout, c, goal, parameters: parameters)
    else { return nil }
    return Authored(id: id, layout: layout, strike: c, goal: goal, aimBand: a, powerBand: p, tipBand: t, note: note)
}

/// Power band (metres per second) and tip bands (metres) around a strike, for the report.
func powerBand(_ layout: [Vec2], _ s: Strike, _ goal: Goal, parameters: PoolParameters = P) -> (lo: Double, hi: Double)? {
    band(centre: s.power, step: 0.05, limit: 4) { v in
        guard v >= 0.5, v <= 8 else { return false }
        var t = s; t.power = v; return passes(goal, simulate(layout, t, parameters: parameters))
    }
}

func tipUpBand(_ layout: [Vec2], _ s: Strike, _ goal: Goal, parameters: PoolParameters = P) -> (lo: Double, hi: Double)? {
    band(centre: s.tipUp, step: 0.0005, limit: 0.04) { v in
        guard insideGrip(up: v, side: s.tipSide) else { return false }
        var t = s; t.tipUp = v; return passes(goal, simulate(layout, t, parameters: parameters))
    }
}

func tipSideBand(_ layout: [Vec2], _ s: Strike, _ goal: Goal, parameters: PoolParameters = P) -> (lo: Double, hi: Double)? {
    band(centre: s.tipSide, step: 0.0005, limit: 0.04) { v in
        guard insideGrip(up: s.tipUp, side: v) else { return false }
        var t = s; t.tipSide = v; return passes(goal, simulate(layout, t, parameters: parameters))
    }
}

/// Prints the shot as the Swift literal the app's TrickShots file carries, plus every measured window.
func report(_ a: Authored) {
    let s = a.strike
    print("== \(a.id): \(a.note)")
    print("   strike: \(s)")
    print(String(format: "   aim window: %.2f to %.2f deg (half-width %.2f deg)", a.aimBand.lo, a.aimBand.hi, a.aimHalfWindow))
    print(String(format: "   power window: %.2f to %.2f m/s (half-width %.2f); tip-height window: %+.4f to %+.4f m (half-width %.4f); feel score %.2f",
                 a.powerBand.lo, a.powerBand.hi, a.powerHalfWindow, a.tipBand.lo, a.tipBand.hi, a.tipHalfWindow, a.feelScore))
    if let t = tipSideBand(a.layout, s, a.goal) { print(String(format: "   side window: %+.4f to %+.4f m", t.lo, t.hi)) }
    let tl = simulate(a.layout, s)
    let dropped = (1..<16).compactMap { b in pocketOf(b, tl).map { "\(b)->\(pocketName($0))" } }
    print("   dropped: \(dropped.joined(separator: ", ")); first hit \(firstStruck(tl).map(String.init) ?? "none"); cue rests at \(fmt(cueRest(tl)))")
    var balls: [String] = []
    for (k, v) in a.layout.enumerated() where NextShot.isOnTable(v) { balls.append("\(k): \(fmt(v))") }
    print("   layout: [\(balls.joined(separator: ", "))]")
}

func fmt(_ v: Vec2) -> String { String(format: "Vec2(%.4f, %.4f)", v.x, v.y) }

/// True when a ball centred at `p` sits fully on the cloth, clear of the cushions and of the pocket mouths.
func clearOfRails(_ p: Vec2, margin: Double = 0.01, pocketClear: Double = 0.12) -> Bool {
    guard p.x > R + margin, p.x < L - R - margin, p.y > R + margin, p.y < W - R - margin else { return false }
    return !pockets.contains { ($0 - p).length < pocketClear }
}

func clearOfBalls(_ p: Vec2, _ layout: [Vec2], gap: Double = 0.004) -> Bool {
    !layout.contains { NextShot.isOnTable($0) && ($0 - p).length < 2 * R + gap }
}

/// The cue ball's path after its first contact with a ball (or from the start when `fromStart`), sampled every
/// 10 ms, ending where it stops or drops; with the cushion count at each sample.
func cuePath(_ tl: Timeline, fromStart: Bool = false) -> [(t: Double, p: Vec2, cushions: Int)] {
    let contact = fromStart ? 0 : (tl.events.first { $0.kind == .ballBall && $0.balls.contains { $0.ball == 0 } }?.time ?? .infinity)
    let end = tl.pocketTime[0] ?? tl.duration
    guard contact < end else { return [] }
    let cushionTimes = tl.events.filter { $0.kind == .cushion && $0.balls.first?.ball == 0 }.map(\.time)
    var out: [(Double, Vec2, Int)] = []
    var t = contact
    while t <= end {
        out.append((t, tl.state(ball: 0, at: t).position, cushionTimes.filter { $0 <= t }.count))
        t += 0.01
    }
    return out
}

/// Where to put a ball so that a cue ball arriving at `p` sends it toward `pocket`: one ball-width beyond `p` on the
/// line from the pocket (the "ghost ball" construction run backwards).
func ballFor(cueAt p: Vec2, pocket: Vec2) -> Vec2 { p + unit(pocket - p) * (2 * R) }
