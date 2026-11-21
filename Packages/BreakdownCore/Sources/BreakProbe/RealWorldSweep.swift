// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: "BreakProbe sweep [quick]": the tuning sweep of plans/21-Nov-2026-physics-proof-plan.md package 4 step 1.
//          It runs the eleven real-table checks (RealWorldCases.swift) on physics generation two over a grid of the
//          numbers that are still guesses, prints one line per combination (how many bands it passes, which fail, and
//          the numbers), and then the best combination with every case's measurement. "Best" is the most bands
//          passed; among equals, the combination whose numbers sit nearest the middle of their plausible ranges, as the
//          plan asks, so a lucky edge value does not win.
//          The grid. The five numbers marked "calibrate" in Parameters.swift (cloth grip, rolling drag, spin decay, rail
//          bounce, rail grip), the two generation-two rail numbers (how fast the rail's bounce falls with speed, and
//          its floor) and the two generation-two cue numbers that are not fixed by the spec's own figures (the cue's
//          mass and the effective mass of the shaft's end). Each is tried at the low end, the middle and the high end
//          of the range written beside it: 3^9 = 19,683 combinations, about a quarter of an hour on three threads.
//          "quick" sweeps only the five guessed numbers (243 combinations) with the generation-two numbers at their
//          starting values: the first pass of a tuning session. Tip grip is left at the spec's 0.58 (a measured
//          friction figure, not a guess), and so are the pocket numbers (no real-table case constrains them yet).
//          Threads: TrickSearch's parallelMap (three unless BREAKPROBE_THREADS says otherwise). Output goes to the
//          terminal; redirect it to a file on the Team 4TB drive to keep it.
// SRP/DRY check: Pass - the grid and the choice only; the cases are RealWorldCases.swift, the thread pool is
//          TrickSearch's parallelMap.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation

/// One number the sweep varies: its name as in PoolParameters, the plausible range, why, and how to set it.
struct SweepAxis: Sendable {
    var name: String
    var low: Double
    var high: Double
    var reason: String
    var set: @Sendable (inout PoolParameters, Double) -> Void
    /// Low end, middle, high end.
    var levels: [Double] { [low, (low + high) / 2, high] }
}

let sweepGuessed: [SweepAxis] = [
    SweepAxis(name: "slidingFriction", low: 0.15, high: 0.4, reason: "spec 3.4 range for pool cloth",
              set: { $0.slidingFriction = $1 }),
    SweepAxis(name: "rollingResistance", low: 0.005, high: 0.015, reason: "spec 3.4 range",
              set: { $0.rollingResistance = $1 }),
    SweepAxis(name: "spinDecay", low: 5, high: 14,
              reason: "the span the app's own cloths use (tournament 5 to dive-bar 14, App/PlaySurface.swift)",
              set: { $0.spinDecay = $1 }),
    SweepAxis(name: "cushionRestitution", low: 0.75, high: 0.95, reason: "spec 3.3 starting value 0.85, plus or minus 0.1",
              set: { $0.cushionRestitution = $1 }),
    SweepAxis(name: "cushionFriction", low: 0.14, high: 0.2, reason: "spec 3.3 range", set: { $0.cushionFriction = $1 }),
]

let sweepGenerationTwo: [SweepAxis] = [
    SweepAxis(name: "railRestitutionSlope", low: 0.0125, high: 0.0375,
              reason: "half to one and a half times the starting value (Parameters.swift)",
              set: { $0.railRestitutionSlope = $1 }),
    SweepAxis(name: "railRestitutionFloor", low: 0.5, high: 0.7, reason: "the starting 0.6 plus or minus 0.1",
              set: { $0.railRestitutionFloor = $1 }),
    SweepAxis(name: "cueMass", low: 0.48, high: 0.6, reason: "ordinary playing cues, about 17 to 21 ounces",
              set: { $0.cueMass = $1 }),
    SweepAxis(name: "shaftEndMass", low: 0.0058, high: 0.0088,
              reason: "2 to 3 degrees of squirt at half-radius side (the derivation in Parameters.swift)",
              set: { $0.shaftEndMass = $1 }),
]

/// One point of the grid: the level chosen on each axis (0 low, 1 middle, 2 high).
struct SweepPoint: Sendable {
    var levels: [Int]
}

func runRealWorldSweep(quick: Bool) {
    let axes = quick ? sweepGuessed : sweepGuessed + sweepGenerationTwo
    // A constant, so the worker threads can share it.
    let base: PoolParameters = {
        var q = PoolParameters()
        q.modelGeneration = 2
        return q
    }()
    let start = Date()
    print("== real-table sweep on generation two, \(quick ? "quick (five guessed numbers)" : "full") grid")
    for a in axes { print(String(format: "   %@: %g, %g, %g (%@)", a.name, a.levels[0], a.levels[1], a.levels[2], a.reason)) }

    // The starting numbers first, so every run shows where today's guesses stand.
    let today = rwCases.map { $0.run(base) }
    print("== today's numbers: \(today.filter(\.passed).count) of \(rwCases.count) bands pass")
    for (c, o) in zip(rwCases, today) { print("   \(c.number) \(c.name): \(o.passed ? "pass" : "FAIL") - \(o.note)") }

    // Every combination of levels, the last axis changing fastest.
    var points: [SweepPoint] = [SweepPoint(levels: [])]
    for _ in axes { points = points.flatMap { p in (0..<3).map { SweepPoint(levels: p.levels + [$0]) } } }
    let grid = points
    let combos = grid.count
    print("== \(combos) combinations")
    @Sendable func parameters(_ point: SweepPoint) -> PoolParameters {
        var q = base
        for (a, level) in zip(axes, point.levels) { a.set(&q, a.levels[level]) }
        return q
    }
    let results = parallelMap(combos) { i -> [Bool] in
        let q = parameters(grid[i])
        return rwCases.map { $0.run(q).passed }
    }
    for (i, passed) in results.enumerated() {
        let failing = zip(rwCases, passed).filter { !$0.1 }.map { String($0.0.number) }
        let numbers = zip(axes, grid[i].levels).map { String(format: "%@=%g", $0.0.name, $0.0.levels[$0.1]) }
        print("passes \(passed.filter { $0 }.count)/\(rwCases.count)  fails [\(failing.joined(separator: " "))]  "
              + numbers.joined(separator: " "))
    }
    // Most bands passed; then nearest the middle of every range (the sum of how many steps each axis is off-centre).
    func offCentre(_ p: SweepPoint) -> Int { p.levels.reduce(0) { $0 + abs($1 - 1) } }
    let best = results.indices.max { a, b in
        let pa = results[a].filter { $0 }.count, pb = results[b].filter { $0 }.count
        if pa != pb { return pa < pb }
        return offCentre(grid[a]) > offCentre(grid[b])
    }
    guard let b = best else { return }
    let q = parameters(grid[b])
    print("== best: \(results[b].filter { $0 }.count) of \(rwCases.count) bands")
    for (a, level) in zip(axes, grid[b].levels) { print(String(format: "   %@ = %g", a.name, a.levels[level])) }
    for c in rwCases {
        let o = c.run(q)
        print("   \(c.number) \(c.name): \(o.passed ? "pass" : "FAIL") - \(o.note)")
    }
    print(String(format: "== sweep took %.0f s", Date().timeIntervalSince(start)))
}
