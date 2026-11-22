// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (the draw-massé carom joins the list; a carom goal checks the cue
//          ball's second contact as the app's judge does).
// Edited: Claude Opus 5.5 High, 21-November-2026 (the six lessons and the stop shot's second exercise join the check:
//          each lesson's reference must still make its goal, the exercise's answer must make it, and copying the stop
//          lesson's settings onto the exercise must still miss, so a physics change that breaks a lesson is caught).
// Edited: Claude Opus 5.5 High, 21-November-2026 (proof plan package 4: every shot re-authored on the tuned generation
//          two, now the default; "verify 1" plays generation one on its old numbers, PoolParameters.generationOne.)
// PURPOSE: "BreakProbe verify [generation]": plays every authored trick shot and every Behind the 8-Ball escape the app
//          carries, exactly as authored, on the chosen physics generation (default: the solver's default, the one the
//          app ships), and prints one PASS or FAIL line each, with the reason for a failure. Returns whether all passed;
//          main.swift turns that into the exit status, so scripts/testflight.py can stop an upload when a physics change
//          breaks authored content (plans/21-Nov-2026-release-safety-plan.md package 1 step 2). With 2 it lists what
//          the generation-two physics breaks, which is the size of the proof plan's package 4 re-authoring step.
//          Trick shots: the answers below are COPIED from App/TrickShots.swift (layout, aim, power, tip, elevation
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

/// The shots of App/TrickShots.swift (its authored list), in authored order, copied number for number.
let authoredTricks: [AuthoredTrick] = [
    AuthoredTrick(id: "called-break",
                  layout: layoutOf([0: Vec2(0.6350, 0.4350), 1: Vec2(1.9050, 0.6350), 2: Vec2(1.9549, 0.6638),
                                    3: Vec2(2.0049, 0.6927), 8: Vec2(2.0049, 0.6350), 9: Vec2(1.9549, 0.6062),
                                    10: Vec2(2.0049, 0.5773)]),
                  strike: Strike(aim: 8.61, power: 7.05, tipUp: 0.0005, tipSide: 0),
                  goal: Goal(drops: [(3, 3)], firstHit: 1)),
    AuthoredTrick(id: "stop-dead",
                  layout: layoutOf([0: Vec2(1.7233, 0.5318), 3: Vec2(2.0200, 0.8000)]),
                  strike: Strike(aim: 42.17, power: 1.75, tipUp: -0.008, tipSide: 0),
                  goal: Goal(drops: [(3, 3)], cueZone: (Vec2(1.9776, 0.7617), 0.05), firstHit: 3)),
    AuthoredTrick(id: "bridge-draw",
                  layout: layoutOf([0: Vec2(1.5000, 0.5200), 2: Vec2(0.0901, 1.2184), 6: Vec2(1.6073, 0.4663)]),
                  strike: Strike(aim: -26.08, power: 5.80, tipUp: -0.0105, tipSide: 0),
                  goal: Goal(drops: [(6, 1), (2, 2)], firstHit: 6)),
    AuthoredTrick(id: "follow-train",
                  layout: layoutOf([0: Vec2(1.6830, 0.5403), 1: Vec2(2.0500, 0.9500), 2: Vec2(1.9171, 1.0103)]),
                  strike: Strike(aim: 50.26, power: 4.65, tipUp: 0.009, tipSide: 0),
                  goal: Goal(drops: [(1, 3), (2, 5)], firstHit: 1)),
    AuthoredTrick(id: "two-rail-kick",
                  layout: layoutOf([0: Vec2(0.7000, 0.4500), 5: Vec2(0.2015, 1.2182), 9: Vec2(0.4661, 0.7895),
                                    10: Vec2(0.4053, 0.9356)]),
                  strike: Strike(aim: 10.52, power: 3.25, tipUp: 0.0065, tipSide: 0),
                  goal: Goal(drops: [(5, 2)], firstHit: 5)),
    AuthoredTrick(id: "cross-bank",
                  layout: layoutOf([0: Vec2(1.0663, 0.8296), 5: Vec2(1.0500, 0.4500)]),
                  strike: Strike(aim: -95.10, power: 2.65, tipUp: 0.0015, tipSide: 0),
                  goal: Goal(drops: [(5, 5)], firstHit: 5, bank: 5)),
    AuthoredTrick(id: "combo-chain",
                  layout: layoutOf([0: Vec2(1.4597, 0.5082), 3: Vec2(2.0396, 0.3542), 4: Vec2(2.1263, 0.3103),
                                    7: Vec2(2.2040, 0.2520)]),
                  strike: Strike(aim: -16.10, power: 3.65, tipUp: 0.0045, tipSide: 0),
                  goal: Goal(drops: [(7, 1)], firstHit: 3)),
    AuthoredTrick(id: "throw-it",
                  layout: layoutOf([0: Vec2(0.8025, 0.5992), 2: Vec2(0.4356, 0.2595), 8: Vec2(0.3825, 0.2371)]),
                  strike: Strike(aim: -134.58, power: 5.10, tipUp: 0, tipSide: -0.012),
                  goal: Goal(drops: [(8, 0)], firstHit: 2)),
    AuthoredTrick(id: "masse-curve",
                  layout: layoutOf([0: Vec2(1.9992, 0.9726), 4: Vec2(2.1745, 1.0690), 9: Vec2(2.4436, 1.2170)]),
                  strike: Strike(aim: 53.55, power: 1.60, tipUp: -0.0025, tipSide: 0.0135, elevation: 0.40),
                  goal: Goal(drops: [(9, 3)], firstHit: 9)),
    AuthoredTrick(id: "jump-over",
                  layout: layoutOf([0: Vec2(1.3708, 0.6854), 6: Vec2(1.6392, 0.8196), 11: Vec2(2.2270, 1.1135)]),
                  strike: Strike(aim: 27.02, power: 4.55, tipUp: -0.005, tipSide: 0, elevation: 0.55),
                  goal: Goal(drops: [(11, 3)], firstHit: 11)),
    AuthoredTrick(id: "draw-masse-carom",
                  layout: layoutOf([0: Vec2(0.9, 0.61), 4: Vec2(1.06, 0.61), 9: Vec2(0.93, 0.219)]),
                  strike: Strike(aim: 348.22, power: 2.65, tipUp: -0.010, tipSide: 0.006, elevation: 0.45),
                  goal: Goal(drops: [], firstHit: 4, secondHit: 9)),
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
    if let second = goal.secondHit {
        // The app's TrickShotJudge: the cue ball's second ball contact must be this ball.
        let contacts = tl.events.filter { $0.kind == .ballBall && $0.balls.contains { $0.ball == 0 } }
            .compactMap { $0.balls.first { $0.ball != 0 }?.ball }
        if contacts.dropFirst().first != second { return "the cue ball's second contact was not the \(second)" }
        if goal.drops.isEmpty && goal.cueZone == nil && goal.bank == nil { return nil }
    }
    if !passes(goal, tl) { return goal.bank != nil ? "the banked ball missed its cushion" : "the cue ball stopped out of its zone" }
    return nil
}

/// Plays every authored trick shot and escape on `generation`; prints a line each and returns true when all pass.
func runContentVerify(generation: Int) -> Bool {
    let start = Date()
    let parameters = generationParameters(generation)
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
    // The lessons, judged like the tricks; then the stop shot's second exercise both ways: its own answer must make it,
    // and copying the stop lesson's settings onto it must NOT (plan 14, section 4: the exercise only checks learning
    // while copying the demonstration fails).
    let lessons = parallelMap(authoredLessons.count) { i -> String? in
        let t = authoredLessons[i]
        return trickFailure(t.goal, simulate(t.layout, t.strike, parameters: parameters))
    }
    let exercise = stopExercise
    let exerciseWhy = trickFailure(exercise.goal, simulate(exercise.layout, exercise.strike, parameters: parameters))
    let copied = trickFailure(exercise.goal, simulate(exercise.layout, authoredLessons[0].strike, parameters: parameters))
    var failures = 0
    for (t, why) in zip(authoredLessons, lessons) {
        if let why { failures += 1; print("FAIL \(t.id): \(why)") } else { print("PASS \(t.id)") }
    }
    if let why = exerciseWhy { failures += 1; print("FAIL lesson-stop-exercise: \(why)") }
    else { print("PASS lesson-stop-exercise") }
    if copied == nil { failures += 1; print("FAIL lesson-stop-exercise: copying the stop lesson's settings makes it too") }
    else { print("PASS lesson-stop-exercise: copying the stop lesson's settings misses (\(copied!))") }
    for (t, why) in zip(authoredTricks, tricks) {
        if let why { failures += 1; print("FAIL trick \(t.id): \(why)") } else { print("PASS trick \(t.id)") }
    }
    for (f, why) in zip(ebFinal, escapes) {
        if let why { failures += 1; print("FAIL eightball \(f.situation) \(f.escape): \(why)") }
        else { print("PASS eightball \(f.situation) \(f.escape)") }
    }
    let total = authoredTricks.count + ebFinal.count + authoredLessons.count + 2
    print(String(format: "== %d of %d authored shots pass on generation %d (%.1f s)", total - failures, total,
                 generation, Date().timeIntervalSince(start)))
    return failures == 0
}

/// The six lessons of App/Lessons/Lessons.swift, in lesson order, copied number for number from "BreakProbe lessons"
/// (LessonAuthoring.swift). KEEP IN STEP with that file, as the trick shots above are with TrickShots.swift. The
/// stop lesson must stay first: the second exercise is built on its line.
let authoredLessons: [AuthoredTrick] = [
    AuthoredTrick(id: "lesson-stop",
                  layout: layoutOf([0: Vec2(2.0033, 1.0017), 3: Vec2(2.2270, 1.1135)]),
                  strike: Strike(aim: 26.57, power: 1.90, tipUp: -0.0035, tipSide: 0),
                  goal: Goal(drops: [(3, 3)], cueZone: (Vec2(2.1758, 1.0879), 0.05), firstHit: 3)),
    AuthoredTrick(id: "lesson-follow",
                  layout: layoutOf([0: Vec2(1.4220, 0.7110), 3: Vec2(1.6456, 0.8228)]),
                  strike: Strike(aim: 26.71, power: 1.85, tipUp: 0.010, tipSide: 0),
                  goal: Goal(drops: [(3, 3)], cueZone: (Vec2(2.2206, 1.1103), 0.15), firstHit: 3)),
    AuthoredTrick(id: "lesson-draw",
                  layout: layoutOf([0: Vec2(2.0033, 1.0017), 3: Vec2(2.1822, 1.0911)]),
                  strike: Strike(aim: 27.04, power: 2.15, tipUp: -0.011, tipSide: 0),
                  goal: Goal(drops: [(3, 3)], cueZone: (Vec2(1.7286, 0.8643), 0.25), firstHit: 3)),
    AuthoredTrick(id: "lesson-cut",
                  layout: layoutOf([0: Vec2(1.9279, 0.7124), 3: Vec2(2.2270, 1.1135)]),
                  strike: Strike(aim: 57.13, power: 2.15, tipUp: 0, tipSide: 0),
                  goal: Goal(drops: [(3, 3)], firstHit: 3)),
    AuthoredTrick(id: "lesson-curve",
                  layout: layoutOf([0: Vec2(1.0000, 0.6350), 4: Vec2(1.2000, 0.6007), 9: Vec2(1.5500, 0.6350)]),
                  strike: Strike(aim: 9.47, power: 1.95, tipUp: -0.009, tipSide: 0.008, elevation: sineOf(degrees: 25)),
                  goal: Goal(drops: [], firstHit: 9)),
    AuthoredTrick(id: "lesson-jump",
                  layout: layoutOf([0: Vec2(1.0000, 0.6350), 6: Vec2(1.2500, 0.6350), 11: Vec2(2.0000, 0.6350)]),
                  strike: Strike(aim: -1.18, power: 4.20, tipUp: 0.0015, tipSide: 0, elevation: sineOf(degrees: 40)),
                  goal: Goal(drops: [], firstHit: 11)),
]

/// The stop shot's second exercise as App/Lessons/Lessons.swift carries it (Lessons.stopExercise), copied from
/// "BreakProbe lessons stop-exercise": the stop lesson's own line with the cue ball 0.55 m back instead of 0.25 m, the
/// same aim and power, and the tip lower (tip heights -13.5 to -5.5 mm work there; the lesson's -3.5 mm misses by two
/// millimetres of tip). KEEP IN STEP.
let stopExercise = AuthoredTrick(id: "lesson-stop-exercise",
                                 layout: layoutOf([0: Vec2(1.7350, 0.8676), 3: Vec2(2.2270, 1.1135)]),
                                 strike: Strike(aim: 26.57, power: 1.90, tipUp: -0.0095, tipSide: 0),
                                 goal: Goal(drops: [(3, 3)], cueZone: (Vec2(2.1759, 1.0880), 0.05), firstHit: 3))
