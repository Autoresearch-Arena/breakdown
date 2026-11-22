// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: "BreakProbe jamtrace [seed] [gen1]" or "jamtrace shot <n>": the evidence command for item 29 of the bug
//          plan after 0.6.6 (the jam guard stepping into an ordinary break). It solves the break of JamGuardTests'
//          untouched-shots check (seed 5, aimed 1 cm off the apex, 10 m/s, 8 mm of follow and 7 mm of left side) and
//          prints, for the first storm the guard settles (or, when none, the busiest millisecond), every event in the
//          millisecond before it: kind, balls, approach speed, and what each ball touched, so what pins the pair can
//          be read rather than guessed.
//          "shot <n>" traces shot n of the jam sweep instead. Run by hand; never in the tests.
// SRP/DRY check: Pass - a print-out only; the solve is PoolSolver.simulateWithReport, the break is Rack.breakShot.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation

func runJamTrace(_ args: [String]) {
    let p = args.contains("gen1") ? PoolParameters.generationOne : PoolParameters()
    let input: ShotInput
    if args.first == "shot", let n = args.dropFirst().compactMap({ Int($0) }).first {
        // One shot of the jam sweep ("BreakProbe jams"), by its number.
        input = jamSweepShot(n, p)
    } else {
        let seed = args.compactMap { UInt64($0) }.first ?? 5
        input = Rack.breakShot(parameters: p, seed: seed, aimOffset: 0.01, speed: 10, tipUp: 0.008, tipSide: -0.007)
    }
    let seed = input.seed
    let (tl, report) = PoolSolver.simulateWithReport(input)
    print("== jamtrace: seed \(seed), generation \(p.modelGeneration): \(report.events) events, \(report.jamsSettled) storms settled, \(tl.events.count) recorded")
    // The moment to look at: the first settled storm, else the millisecond with the most events.
    var focus = tl.events.first { $0.kind == .settledInContact }?.time
    if focus == nil {
        var bestCount = 0
        for e in tl.events {
            let n = tl.events.filter { $0.time >= e.time && $0.time < e.time + 0.001 }.count
            if n > bestCount { bestCount = n; focus = e.time + 0.001 }
        }
    }
    guard let t1 = focus else { print("   no events"); return }
    let window = tl.events.filter { $0.time >= t1 - 0.001 && $0.time <= t1 }
    print(String(format: "   %ld events in the millisecond before t = %.6f s", window.count, t1))
    var byKind: [String: Int] = [:]
    for e in window {
        let key = "\(e.kind) \(e.balls.map(\.ball))" + (e.kind == .cushion ? " edge \(e.edge)" : "")
        byKind[key, default: 0] += 1
    }
    for (k, n) in byKind.sorted(by: { $0.value > $1.value }) { print("   \(n) x \(k)") }
    // The first forty events of that millisecond in full: the approach speed along the normal and each ball's speeds.
    for e in window.prefix(40) {
        var line = String(format: "   %.9f %@ %@", e.time, "\(e.kind)", "\(e.balls.map(\.ball))")
        if e.kind == .ballBall, e.balls.count == 2 {
            let a = e.balls[0], b = e.balls[1]
            let approach = (a.velocityBefore - b.velocityBefore).dot(e.normal)
            line += String(format: " approach %.6f m/s", approach)
        }
        if e.kind == .cushion, let b = e.balls.first {
            line += String(format: " into the rubber %.6f m/s edge %@", -b.velocityBefore.dot(e.normal), "\(e.edge)")
        }
        for b in e.balls {
            line += String(format: " | %ld v %.5f->%.5f w(%.1f,%.1f,%.1f)", b.ball, b.velocityBefore.length,
                           b.velocityAfter.length, b.omegaBefore.x, b.omegaBefore.y, b.omegaBefore.z)
        }
        print(line)
    }
    if let s = tl.events.first(where: { $0.kind == .settledInContact }) {
        print(String(format: "   settled: balls %@, energy removed %.3e J", "\(s.balls.map(\.ball))", s.energyRemoved ?? 0))
        for b in s.balls {
            let pos = tl.state(ball: b.ball, at: s.time).position
            print(String(format: "     ball %ld at (%.6f, %.6f)", b.ball, pos.x, pos.y))
        }
    }
}
