// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (the draw-massé carom joins the list; a carom goal checks the cue
//          ball's second contact as the app's judge does).
// Edited: Claude Opus 5.5 High, 21-November-2026 (the six lessons and the stop shot's second exercise join the check:
//          each lesson's reference must still make its goal, the exercise's answer must make it, and copying the stop
//          lesson's settings onto the exercise must still miss, so a physics change that breaks a lesson is caught).
// Edited: Claude Opus 5.5 High, 21-November-2026 (proof plan package 4: every shot re-authored on the tuned generation
//          two, now the default; "verify 1" plays generation one on its old numbers, PoolParameters.generationOne.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (bug plan after 0.6.6: item 38, the shots are read from the package's
//          authored library (BreakdownAuthored), the very numbers the app ships, so the copies marked KEEP IN STEP are
//          gone; item 30, an escape whose aim window is narrower than one of the aim control's quarter-degree steps
//          fails, and one narrower than two (half a degree, the authoring's aim) is named in a note.)
// PURPOSE: "BreakProbe verify [generation]": plays every authored trick shot, lesson and Behind the 8-Ball escape the app
//          carries, exactly as authored, on the chosen physics generation (default: the solver's default, the one the
//          app ships), and prints one PASS or FAIL line each, with the reason for a failure. Returns whether all passed;
//          main.swift turns that into the exit status, so scripts/testflight.py can stop an upload when a physics change
//          breaks authored content (plans/21-Nov-2026-release-safety-plan.md package 1 step 2).
//          The answers come from the package library (AuthoredTricks, AuthoredLessons, AuthoredEscapes), which the app
//          reads too. Trick shots and lessons are judged with TrickSearch's passes(), the test they were authored against
//          (the app's TrickShotJudge applies the same goal), seed 1 as when they were authored. Escapes are judged with
//          ebPasses, the legality and technique test they were authored against, on each situation's own cloth, and
//          their aim window is walked from the stroke: narrower than one aim step fails.
// SRP/DRY check: Pass - checked TrickAuthoring (it searches for answers and holds none), TrickSearch (simulate, passes
//          and the Goal and Strike types are reused) and EightBallAuthoring ("eightball verify" re-measures every window
//          and prints rail diamonds for the cards; this is the quick pass-or-fail of the same strokes, on any
//          generation, with the one window rule item 30 adds).
import BreakdownAuthored
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation

/// One authored shot as this tool plays it.
struct ProbeShot: Sendable {
    var id: String
    var layout: [Vec2]
    var strike: Strike
    var goal: Goal
}

/// A library stroke in this tool's terms.
func probeStrike(_ s: AuthoredStrike) -> Strike {
    Strike(aim: s.aim, power: s.power, tipUp: s.tipUp, tipSide: s.tipSide, elevation: s.elevation)
}

/// A library goal in this tool's terms.
func probeGoal(_ g: AuthoredGoal) -> Goal {
    Goal(drops: g.drops.map { (ball: $0.ball, pocket: $0.pocket) }, cueZone: g.cueZone.map { ($0.centre, $0.radius) },
         firstHit: g.firstHit, bank: g.bank, secondHit: g.secondHit)
}

/// The trick shots of the library, in authored order.
let authoredTricks: [ProbeShot] = AuthoredTricks.all.map {
    ProbeShot(id: $0.id, layout: $0.layout, strike: probeStrike($0.solution), goal: probeGoal($0.goal))
}

/// The six lessons of the library, in lesson order. The stop lesson stays first: the second exercise is on its line.
let authoredLessons: [ProbeShot] = AuthoredLessons.all.map {
    ProbeShot(id: $0.id, layout: $0.layout, strike: probeStrike($0.reference), goal: probeGoal($0.goal))
}

/// The stop shot's second exercise as the library holds it.
let stopExercise = ProbeShot(id: "lesson-stop-exercise", layout: AuthoredLessons.stopExercise.layout,
                             strike: probeStrike(AuthoredLessons.stopExercise.reference),
                             goal: probeGoal(AuthoredLessons.stopExercise.goal))

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

/// Plays every authored trick shot, lesson and escape on `generation`; prints a line each and returns true when all
/// pass.
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
        guard var s = ebAuthored.first(where: { $0.id == f.situation }),
              let e = s.escapes.first(where: { $0.id == f.escape }) else { return "no such situation or escape" }
        s.generation = generation
        guard ebPasses(s, e, f.strike) else { return ebWhy(s, e, f.strike) }
        // Item 30: the aim window, walked from the stroke, must be at least one aim step wide.
        guard let w = ebAimWindow(s, e, f.strike) else { return "no aim window" }
        if w.hi - w.lo < ebAimStep - 1e-9 {
            return String(format: "aim window %.2f to %.2f is %.2f degrees wide, under one aim step (%.2f)", w.lo, w.hi,
                          w.hi - w.lo, ebAimStep)
        }
        return nil
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
    if let copied { print("PASS lesson-stop-exercise: copying the stop lesson's settings misses (\(copied))") }
    else { failures += 1; print("FAIL lesson-stop-exercise: copying the stop lesson's settings makes it too") }
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
