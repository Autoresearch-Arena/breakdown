// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: "BreakProbe verify [generation]": plays every authored trick shot and every Behind the 8-Ball escape the app
//          carries, exactly as authored, on the chosen physics generation (default: the solver's default, the one the
//          app ships), and prints one PASS or FAIL line each, with the reason for a failure. Returns whether all passed;
//          main.swift turns that into the exit status, so scripts/testflight.py can stop an upload when a physics change
//          breaks authored content (plans/21-Nov-2026-release-safety-plan.md package 1 step 2). With 2 it lists what
//          the generation-two physics breaks, which is the size of the proof plan's package 4 re-authoring step.
//          Trick shots: the ten answers below are COPIED from App/TrickShots.swift (layout, aim, power, tip, elevation
//          and goal), because the app's files cannot be imported here. KEEP IN STEP: when a shot there is re-authored,
//          change its line here in the same commit. Judged with TrickSearch's passes(), the test they were authored
//          against (the app's TrickShotJudge applies the same goal). Seed 1, as when they were authored.
//          Escapes: ebFinal in EightBallAuthoring.swift (the strokes the app carries), judged with ebPasses, the same
//          legality and technique test they were authored against, on each situation's own cloth.
// SRP/DRY check: Pass - checked TrickAuthoring (it searches for answers and holds none), TrickSearch (simulate, passes
//          and the Goal and Strike types are reused) and EightBallAuthoring ("eightball verify" re-measures windows
//          and prints rail diamonds for the cards, minutes of work; this is the quick pass-or-fail of the same strokes,
//          on any generation).
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation

/// One trick shot as the app carries it.
struct AuthoredTrick: Sendable {
    var id: String
    var layout: [Vec2]
    var strike: Strike
    var goal: Goal
}

/// The ten shots of App/TrickShots.swift (TrickShots.all), in its order, copied number for number.
let authoredTricks: [AuthoredTrick] = [
    AuthoredTrick(id: "called-break",
                  layout: layoutOf([0: Vec2(0.6350, 0.4350), 1: Vec2(1.9050, 0.6350), 2: Vec2(1.9549, 0.6638),
                                    3: Vec2(2.0049, 0.6927), 8: Vec2(2.0049, 0.6350), 9: Vec2(1.9549, 0.6062),
                                    10: Vec2(2.0049, 0.5773)]),
                  strike: Strike(aim: 7.73, power: 6.45, tipUp: 0.0005, tipSide: 0),
                  goal: Goal(drops: [(3, 3)], firstHit: 1)),
    AuthoredTrick(id: "stop-dead",
                  layout: layoutOf([0: Vec2(1.7233, 0.5318), 3: Vec2(2.0200, 0.8000)]),
                  strike: Strike(aim: 42.17, power: 1.75, tipUp: -0.008, tipSide: 0),
                  goal: Goal(drops: [(3, 3)], cueZone: (Vec2(1.9776, 0.7617), 0.05), firstHit: 3)),
    AuthoredTrick(id: "bridge-draw",
                  layout: layoutOf([0: Vec2(1.5000, 0.5200), 2: Vec2(0.0901, 1.2184), 6: Vec2(1.6073, 0.4663)]),
                  strike: Strike(aim: -25.94, power: 3.80, tipUp: -0.0135, tipSide: 0),
                  goal: Goal(drops: [(6, 1), (2, 2)], firstHit: 6)),
    AuthoredTrick(id: "follow-train",
                  layout: layoutOf([0: Vec2(1.6830, 0.5403), 1: Vec2(2.0500, 0.9500), 2: Vec2(1.9171, 1.0103)]),
                  strike: Strike(aim: 50.22, power: 4.05, tipUp: 0.010, tipSide: 0),
                  goal: Goal(drops: [(1, 3), (2, 5)], firstHit: 1)),
    AuthoredTrick(id: "two-rail-kick",
                  layout: layoutOf([0: Vec2(0.7000, 0.4500), 5: Vec2(0.2015, 1.2182), 9: Vec2(0.4661, 0.7895),
                                    10: Vec2(0.4053, 0.9356)]),
                  strike: Strike(aim: 9.84, power: 2.95, tipUp: 0.0045, tipSide: 0),
                  goal: Goal(drops: [(5, 2)], firstHit: 5)),
    AuthoredTrick(id: "cross-bank",
                  layout: layoutOf([0: Vec2(1.0663, 0.8296), 5: Vec2(1.0500, 0.4500)]),
                  strike: Strike(aim: -94.75, power: 2.80, tipUp: 0.006, tipSide: 0),
                  goal: Goal(drops: [(5, 5)], firstHit: 5, bank: 5)),
    AuthoredTrick(id: "combo-chain",
                  layout: layoutOf([0: Vec2(1.4597, 0.5082), 3: Vec2(2.0396, 0.3542), 4: Vec2(2.1263, 0.3103),
                                    7: Vec2(2.2040, 0.2520)]),
                  strike: Strike(aim: -16.10, power: 3.65, tipUp: 0.0045, tipSide: 0),
                  goal: Goal(drops: [(7, 1)], firstHit: 3)),
    AuthoredTrick(id: "throw-it",
                  layout: layoutOf([0: Vec2(0.8025, 0.5992), 2: Vec2(0.4356, 0.2595), 8: Vec2(0.3825, 0.2371)]),
                  strike: Strike(aim: -136.19, power: 3.85, tipUp: 0.0075, tipSide: -0.012),
                  goal: Goal(drops: [(8, 0)], firstHit: 2)),
    AuthoredTrick(id: "masse-curve",
                  layout: layoutOf([0: Vec2(1.9992, 0.9726), 4: Vec2(2.1745, 1.0690), 9: Vec2(2.4436, 1.2170)]),
                  strike: Strike(aim: 64.61, power: 0.95, tipUp: -0.0035, tipSide: 0.0171, elevation: 0.5),
                  goal: Goal(drops: [(9, 3)], firstHit: 9)),
    AuthoredTrick(id: "jump-over",
                  layout: layoutOf([0: Vec2(1.3708, 0.6854), 6: Vec2(1.6392, 0.8196), 11: Vec2(2.2270, 1.1135)]),
                  strike: Strike(aim: 27.02, power: 4.55, tipUp: -0.005, tipSide: 0, elevation: 0.55),
                  goal: Goal(drops: [(11, 3)], firstHit: 11)),
]

/// Which part of a trick's goal failed, in the order TrickSearch.passes checks them; nil when it all held.
func trickFailure(_ goal: Goal, _ tl: Timeline) -> String? {
    if tl.events.count > 4000 { return "the solver chattered (over 4000 events)" }
    if tl.pocketTime[0] != nil { return "the cue ball scratched" }
    for d in goal.drops {
        guard let k = pocketOf(d.ball, tl) else { return "the \(d.ball) stayed up" }
        if let want = d.pocket, want != k { return "the \(d.ball) dropped in the \(pocketNames[k]), not the \(pocketNames[want])" }
    }
    if let first = goal.firstHit, firstStruck(tl) != first {
        let struck = firstStruck(tl).map(String.init) ?? "no ball"
        return "the cue ball hit \(struck) first, not the \(first)"
    }
    if !passes(goal, tl) { return goal.bank != nil ? "the banked ball missed its cushion" : "the cue ball stopped out of its zone" }
    return nil
}

/// Plays every authored trick shot and escape on `generation`; prints a line each and returns true when all pass.
func runContentVerify(generation: Int) -> Bool {
    let start = Date()
    var q = PoolParameters()
    q.modelGeneration = generation
    let parameters = q
    print("== authored content on physics generation \(generation)")
    let tricks = parallelMap(authoredTricks.count) { i -> String? in
        let t = authoredTricks[i]
        return trickFailure(t.goal, simulate(t.layout, t.strike, parameters: parameters))
    }
    let escapes = parallelMap(ebFinal.count) { i -> String? in
        let f = ebFinal[i]
        guard var s = ebSituations.first(where: { $0.id == f.situation }),
              let e = s.escapes.first(where: { $0.id == f.escape }) else { return "no such situation or escape" }
        s.generation = generation
        return ebPasses(s, e, f.strike) ? nil : ebWhy(s, e, f.strike)
    }
    var failures = 0
    for (t, why) in zip(authoredTricks, tricks) {
        if let why { failures += 1; print("FAIL trick \(t.id): \(why)") } else { print("PASS trick \(t.id)") }
    }
    for (f, why) in zip(ebFinal, escapes) {
        if let why { failures += 1; print("FAIL eightball \(f.situation) \(f.escape): \(why)") }
        else { print("PASS eightball \(f.situation) \(f.escape)") }
    }
    let total = authoredTricks.count + ebFinal.count
    print(String(format: "== %d of %d authored shots pass on generation %d (%.1f s)", total - failures, total,
                 generation, Date().timeIntervalSince(start)))
    return failures == 0
}
