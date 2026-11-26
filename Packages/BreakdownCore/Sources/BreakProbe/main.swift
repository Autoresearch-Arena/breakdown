// Author: Claude Sonnet 5.5 Medium
// Date: 03-November-2026
// Edited: Claude Opus 5.5 High, 20-November-2026 ("tricks" runs the trick-shot authoring search; with no argument it
//          still runs the original break sweep).
// Edited: Claude Opus 5.5 High, 21-November-2026 ("eightball [id ...]" authors the Behind the 8-Ball situations).
// Edited: Claude Opus 5.5 High, 21-November-2026 ("sweep [quick]" runs the real-table checks over a grid of the guessed
//          numbers (RealWorldSweep.swift); "verify [generation]" plays every authored trick shot and escape on a physics
//          generation and exits with status 1 if any fails (ContentVerify.swift), for the upload script.)
// PURPOSE: Dev tool. With no argument: sweeps candidate breaks (rack seed, aim offset, speed; struck at centre height)
//          and prints the ones that drop at least two object balls while keeping the cue ball, so the showpiece break is
//          chosen with evidence.
//          With "tricks [id ...]": authors the app's trick shots (TrickAuthoring) and prints each one's layout, strike
//          and measured skill windows, ready to copy into the app's TrickShots file.
//          With "eightball [id ...]": authors the Behind the 8-Ball situations (EightBallAuthoring); "eightball verify"
//          re-checks the strokes the app carries.
//          With "jams [count] [gen2]": solves random free-play shots and prints every one that needs more than five
//          thousand events or that the jam guard had to settle (JamSweep), so real jams become test fixtures.
// Edited: Claude Opus 5.5 High, 21-November-2026 ("jams" runs the jam sweep of the pockets-and-jams plan).
//          With "sweep [quick]": the real-table checks on generation two over a grid of the guessed numbers, and the
//          combination that passes the most. With "verify [generation]": every authored trick shot and Behind the 8-Ball
//          escape, pass or fail, on that physics generation (default: the solver's default); exit status 1 on any fail.
//          With "lessons [id ...]": authors the six lessons and the stop shot's second exercise (LessonAuthoring).
// Edited: Claude Opus 5.5 High, 21-November-2026 ("lessons" runs the lesson authoring of the lesson path.)
// Edited: Claude Opus 5.5 High, 21-November-2026 ("tricks near [id ...]" re-authors the app's trick shots and lessons
//          near their old answers on the default physics, and "surfaces" runs the real-table checks on every surface
//          (Reauthor.swift); "eightball near [situation ...]" does the same for the Behind the 8-Ball escapes; "verify"
//          with no argument checks the default, generation two since package 4.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (bug plan after 0.6.6: "jamtrace [seed] | jamtrace shot <n>" prints
//          what pins a storm (JamTrace.swift, item 29); "sweep rails" sweeps the rail's grips and bounce against the two
//          new rail bands (item 26); with no argument (or "breaks [gen1] [low]") the showpiece break sweep strikes at
//          centre height over twelve racks and tallies how breaks go (item 55); "tricks break" re-lays the called break;
//          "eightball relay [situation ...] [cue]" moves a situation's called ball (or the cue ball) until every escape's
//          aim window holds an aim step, and "eightball wide <situation> <escape> [rails]" searches a kick round the full
//          circle (item 30); "lessons stop-exercise <power>" tries the stop lesson at another power. The authored answers
//          the tools check come from the package library, BreakdownAuthored (item 38).)
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 bank: "daily [kind ...]" grows the shot of the day bank,
//          DailyAuthoring.swift, with a contact sheet of pictures per kind.)
// SRP/DRY check: Pass - single-purpose command line probe, not shipped in the app.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline

import Foundation

// Print as we go: a long search should show its progress even when its output goes to a file.
setvbuf(stdout, nil, _IOLBF, 0)
let args = Array(CommandLine.arguments.dropFirst())
if args.first == "timing" {
    // One frozen-pair throw shot, timed, with its event count: the throw search was far slower than the others.
    let b = pockets[0] + unit(Vec2(1, 0.62)) * 0.45
    let v = rotate(unit(pockets[0] - b), 5)
    for gap in [1e-6, 1e-4, 5e-4] {
        let a = b - v * (2 * R + gap)
        let c = a - v * 0.5
        let lay = layoutOf([0: c, 2: a, 8: b])
        let t0 = Date()
        let tl = simulate(lay, Strike(aim: degrees(of: unit(a - c)), power: 2.5, tipUp: 0, tipSide: 0.012))
        print("throw sim, gap \(gap) m: \(tl.events.count) events, duration \(tl.duration), took \(Date().timeIntervalSince(t0)) s")
        var kinds: [String: Int] = [:]
        for e in tl.events { kinds["\(e.kind) \(e.balls.map(\.ball))", default: 0] += 1 }
        print("   by kind: \(kinds.sorted { $0.value > $1.value }.prefix(6))")
        if let e = tl.events.dropFirst(200).first { print("   event 200 at t=\(e.time): \(e.kind) \(e.balls.map(\.ball)) slip \(e.slipSpeed) impulse \(e.normalImpulse)") }
    }
} else if args.first == "jams" {
    runJamSweep(Array(args.dropFirst()))
} else if args.first == "jamtrace" {
    runJamTrace(Array(args.dropFirst()))
} else if args.first == "tricks", args.dropFirst().first == "break" {
    runCalledBreakRelay()
} else if args.first == "tricks", args.dropFirst().first == "near" {
    runNearReauthor(only: Set(args.dropFirst(2)))
} else if args.first == "surfaces" {
    runSurfaceCheck()
} else if args.first == "tricks" {
    runTrickAuthoring(only: Set(args.dropFirst()))
} else if args.first == "lessons" {
    runLessonAuthoring(only: Set(args.dropFirst()), arguments: Array(args.dropFirst()))
} else if args.first == "eightball", args.dropFirst().first == "wide" {
    runEightBallWide(Array(args.dropFirst(2)))
} else if args.first == "eightball", args.dropFirst().first == "relay" {
    runEightBallRelay(only: Set(args.dropFirst(2)).subtracting(["cue", "two"]), moveCue: args.contains("cue"),
                      steps: args.contains("two") ? 2 : 1)
} else if args.first == "eightball", args.dropFirst().first == "near" {
    runEightBallNear(only: Set(args.dropFirst(2)))
} else if args.first == "eightball" {
    runEightBallAuthoring(only: Set(args.dropFirst()))
} else if args.first == "sweep" {
    runRealWorldSweep(quick: args.dropFirst().contains("quick"), rails: args.dropFirst().contains("rails"))
} else if args.first == "daily" {
    // 0.7.10 bank: grow the shot of the day bank (DailyAuthoring.swift).
    runDailyAuthoring(Array(args.dropFirst()))
} else if args.first == "verify" {
    // The upload script reads the exit status: 0 only when every authored shot still works.
    let generation = args.dropFirst().first.flatMap { Int($0) } ?? PoolParameters().modelGeneration
    exit(runContentVerify(generation: generation) ? 0 : 1)
} else {
    // The showpiece break sweep. Since the bug plan after 0.6.6 (item 55) the opening break is struck at centre height,
    // so the opening's first held beat is the cue ball handing its speed to the rack rather than a note about an
    // off-centre hit: tip 0 only. Each stroke that drops two or more and keeps the cue ball is printed with what the
    // opening's headline beats need: the cue ball's first hit, and its skid turning into roll after it.
    // Seed 3 first (the old showpiece rack), then other racks (the first run of 21-Nov-2026 found no centre-height break
    // on seed 3 that drops two and keeps the cue ball). The summary at the end counts how the breaks went, so a choice
    // that is rare is seen to be rare.
    var shown = 0
    var tally: [String: Int] = [:]
    // "breaks gen1" sweeps the old physics and "breaks low" the old 6 mm-low strike, for comparison only.
    // "oldrail" puts back the first tuning's rail numbers on today's coupled rail, and "bounce" turns the push rule off,
    // to see which change moves how often a break pockets a ball (evidence only; nothing ships with them).
    let breakParameters: PoolParameters = {
        var q = args.contains("gen1") ? PoolParameters.generationOne : PoolParameters()
        if args.contains("oldrail") {
            q.cushionRestitution = 0.95; q.railRestitutionSlope = 0.025; q.cushionFriction = 0.17; q.railCrossGrip = 0.17
        }
        if args.contains("bounce") { q.gentleContactSpeed = 0 }
        return q
    }()
    let breakTip = args.contains("low") ? -0.006 : 0.0
    let seeds: [UInt64] = [3, 1, 2, 4, 5, 6, 7, 8, 9, 10, 11, 12]
    let speeds = [8.0, 8.5, 9.0, 9.5, 10.0, 10.5, 11.0, 11.5, 12.0]
    for seed in seeds { for speed in speeds { for k in -8...8 {
        let off = Double(k) * 0.001
        let input = Rack.breakShot(parameters: breakParameters, seed: seed, aimOffset: off, speed: speed, tipUp: breakTip)
        let (tl, report) = PoolSolver.simulateWithReport(input)
        let dropped = (1..<tl.ballCount).filter { tl.pocketTime[$0] != nil }
        let scratch = tl.pocketTime[0] != nil
        tally["\(min(dropped.count, 3))\(dropped.count >= 3 ? "+" : "") down\(scratch ? ", scratch" : "")", default: 0] += 1
        if report.jamsSettled > 0 { tally["storm", default: 0] += 1 }
        guard dropped.count >= 2, !scratch, report.jamsSettled == 0, shown < 40 else { continue }
        shown += 1
        let hit = tl.events.first { $0.kind == .ballBall && $0.balls.contains { $0.ball == 0 } }
        let roll = tl.events.first { $0.kind == .phaseTransition && $0.balls.first?.ball == 0
            && $0.phaseFrom == .sliding && $0.phaseTo == .rolling && $0.time > (hit?.time ?? 0) }
        print(String(format: "seed %llu speed %.1f off %+.3f: events %ld duration %.2f dropped %@; first hit at %.3f s; cue ball rolls at %@",
                     seed, speed, off, tl.events.count, tl.duration, "\(dropped)", hit?.time ?? -1,
                     roll.map { String(format: "%.3f s", $0.time) } ?? "never"))
    } } }
    print("breaks: \(tally.sorted { $0.key < $1.key }.map { "\($0.key) \($0.value)" }.joined(separator: "; "))")
}
