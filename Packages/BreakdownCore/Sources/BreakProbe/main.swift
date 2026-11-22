// Author: Claude Sonnet 5.5 Medium
// Date: 03-November-2026
// Edited: Claude Opus 5.5 High, 20-November-2026 ("tricks" runs the trick-shot authoring search; with no argument it
//          still runs the original break sweep).
// Edited: Claude Opus 5.5 High, 21-November-2026 ("eightball [id ...]" authors the Behind the 8-Ball situations).
// Edited: Claude Opus 5.5 High, 21-November-2026 ("sweep [quick]" runs the real-table checks over a grid of the guessed
//          numbers (RealWorldSweep.swift); "verify [generation]" plays every authored trick shot and escape on a physics
//          generation and exits with status 1 if any fails (ContentVerify.swift), for the upload script.)
// PURPOSE: Dev tool. With no argument: sweeps candidate breaks (aim offset, speed, tip height) and prints the ones that
//          drop at least two object balls while keeping the cue ball, so the showpiece break is chosen with evidence.
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
} else if args.first == "tricks", args.dropFirst().first == "near" {
    runNearReauthor(only: Set(args.dropFirst(2)))
} else if args.first == "surfaces" {
    runSurfaceCheck()
} else if args.first == "tricks" {
    runTrickAuthoring(only: Set(args.dropFirst()))
} else if args.first == "lessons" {
    runLessonAuthoring(only: Set(args.dropFirst()), arguments: Array(args.dropFirst()))
} else if args.first == "eightball", args.dropFirst().first == "near" {
    runEightBallNear(only: Set(args.dropFirst(2)))
} else if args.first == "eightball" {
    runEightBallAuthoring(only: Set(args.dropFirst()))
} else if args.first == "sweep" {
    runRealWorldSweep(quick: args.dropFirst().contains("quick"))
} else if args.first == "verify" {
    // The upload script reads the exit status: 0 only when every authored shot still works.
    let generation = args.dropFirst().first.flatMap { Int($0) } ?? PoolParameters().modelGeneration
    exit(runContentVerify(generation: generation) ? 0 : 1)
} else {
    var shown = 0
    for speed in [8.0, 9.0, 10.0, 11.0, 12.0] {
        for tip in [-0.006, 0.0, 0.006] {
            for k in -6...6 {
                let off = Double(k) * 0.001
                let input = Rack.breakShot(seed: 3, aimOffset: off, speed: speed, tipUp: tip)
                let tl = PoolSolver.simulate(input)
                let dropped = (1..<tl.ballCount).filter { tl.pocketTime[$0] != nil }
                if dropped.count >= 2 && tl.pocketTime[0] == nil && shown < 25 {
                    shown += 1
                    print("speed \(speed) tip \(tip) off \(off): events \(tl.events.count) duration \(tl.duration) dropped \(dropped)")
                }
            }
        }
    }
}
