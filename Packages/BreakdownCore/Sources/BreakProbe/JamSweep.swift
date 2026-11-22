// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// Edited: Claude Opus 5.5 High, 21-November-2026 (proof plan package 4: default physics, "gen1" for the old one, and
//          the tip travel of free play on it.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (bug plan after 0.6.6, item 29: jamSweepShot rebuilds one shot of the
//          sweep by its number, for jamtrace and the saved fixtures in JamGuardTests.)
// PURPOSE: "BreakProbe jams [count] [gen1]": the jam finder of the pockets-and-jams plan (part B, step 1). Solves
//          `count` (default ten thousand) seeded random free-play shots and prints the full input of every one that
//          needs more than five thousand events, plus every one where the jam guard stepped in or the hard event limit
//          was reached, then a summary (largest event count, slowest solve, how many storms were settled). The shots
//          are solved on the default physics (generation two); with "gen1" on generation one with its old numbers.
//          A free-play shot here is what a player can set up: two to sixteen balls at random clear spots (a few of them
//          frozen together or against a rail, since that is where jams come from), any aim, a speed across the free-play
//          range, the tip anywhere in its travel and, one shot in four, a raised cue. Everything comes from a seeded
//          generator, so a printed shot can be solved again exactly. Run by hand; never part of the app or the tests.
//          This tool may use Foundation (timing, formatting); the solver it drives does not.
// SRP/DRY check: Pass - checked main.swift, TrickSearch.swift and the package's sweep tests (JumpTests, PocketTests):
//          those check physical invariants over random shots, this one hunts for shots that are expensive to solve and
//          prints them as fixtures. It builds ShotInput directly rather than through the trick helpers because its shots
//          have no aim angle or goal.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation

/// A small seeded generator for the sweep (the same LCG the package's sweep tests use), so every run is the same.
private struct JamRandom {
    var state: UInt64
    mutating func next() -> Double {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return Double(state >> 11) / Double(1 << 53)
    }
}

/// One random free-play shot, numbered `shot` (its seed), on parameters `p`.
private func randomFreePlayShot(_ shot: Int, _ rng: inout JamRandom, _ p: PoolParameters) -> ShotInput {
    let r = p.ballRadius, L = p.tableLength, W = p.tableWidth
    var pos = [Vec2](repeating: NextShot.offTable, count: 16)
    let count = 2 + Int(rng.next() * 15)                       // two to sixteen balls on the table
    var placed = 0
    var tries = 0
    while placed < count && tries < 2000 {
        tries += 1
        var c = Vec2(r + 0.001 + rng.next() * (L - 2 * r - 0.002), r + 0.001 + rng.next() * (W - 2 * r - 0.002))
        // One ball in three is frozen: against the last ball placed (a micrometre off, like the rack) or on a rail.
        let roll = rng.next()
        if placed > 0 && roll < 0.2 {
            let a = rng.next() * 2 * Double.pi
            c = pos[placed - 1] + Vec2(cos(a), sin(a)) * (2 * r + 1e-6)
        } else if roll < 0.33 {
            c = rng.next() < 0.5 ? Vec2(c.x, r + 1e-6) : Vec2(r + 1e-6, c.y)
        }
        guard c.x >= r, c.x <= L - r, c.y >= r, c.y <= W - r else { continue }
        if pos.prefix(placed).allSatisfy({ ($0 - c).length >= 2 * r }) { pos[placed] = c; placed += 1 }
    }
    let a = rng.next() * 2 * Double.pi
    // The free-play tip travel on the default physics (ShowpieceModel.tipLimit): a tenth of the radius past the miscue
    // ring, so random shots include miscues as free play does.
    let tipLimit = p.miscueOffsetLimit + 0.1 * p.ballRadius
    let strike = CueStrike(direction: Vec2(cos(a), sin(a)), speed: 0.5 + rng.next() * 7.5,
                           tipUp: (rng.next() * 2 - 1) * tipLimit, tipSide: (rng.next() * 2 - 1) * tipLimit,
                           elevation: rng.next() < 0.25 ? rng.next() * 0.9 : 0)
    return ShotInput(parameters: p, positions: pos, strike: strike, seed: UInt64(shot))
}

/// Every number needed to rebuild the shot, as Swift a test fixture can paste.
private func describe(_ input: ShotInput) -> String {
    let s = input.strike
    let balls = input.positions.enumerated().filter { NextShot.isOnTable($0.element) }
        .map { String(format: "%ld: Vec2(%.9f, %.9f)", $0.offset, $0.element.x, $0.element.y) }.joined(separator: ", ")
    return String(format: "seed %llu, generation %ld, strike: direction Vec2(%.12f, %.12f), speed %.6f, tipUp %.6f, tipSide %.6f, elevation %.6f\n      balls [%@]",
                  input.seed, input.parameters.modelGeneration, s.direction.x, s.direction.y, s.speed, s.tipUp,
                  s.tipSide, s.elevation, balls)
}

/// Shot `n` of the sweep exactly as runJamSweep solves it (the generator replayed from the start), so jamtrace can
/// look inside one and a fixture can be rebuilt from its number.
func jamSweepShot(_ n: Int, _ p: PoolParameters) -> ShotInput {
    var rng = JamRandom(state: 20_261_121)
    var input = randomFreePlayShot(0, &rng, p)
    if n > 0 { for shot in 1...n { input = randomFreePlayShot(shot, &rng, p) } }
    return input
}

func runJamSweep(_ args: [String]) {
    let count = args.compactMap { Int($0) }.first ?? 10_000
    // The default physics (generation two since the proof plan's package 4); "gen1" plays the old generation on its
    // old numbers. "gen2" is still accepted and is the default.
    let p = args.contains("gen1") ? PoolParameters.generationOne : PoolParameters()
    var rng = JamRandom(state: 20_261_121)
    var heavy = 0, settledShots = 0, limitShots = 0, maxEvents = 0
    var slowest = (seconds: 0.0, shot: -1)
    print("JAMS: \(count) random free-play shots on generation \(p.modelGeneration)")
    for shot in 0..<count {
        let input = randomFreePlayShot(shot, &rng, p)
        let t0 = Date()
        let (tl, report) = PoolSolver.simulateWithReport(input)
        let seconds = Date().timeIntervalSince(t0)
        if seconds > slowest.seconds { slowest = (seconds, shot) }
        maxEvents = max(maxEvents, report.events)
        if report.jamsSettled > 0 { settledShots += 1 }
        if report.hitEventLimit { limitShots += 1 }
        if report.events > 5_000 || report.jamsSettled > 0 || report.hitEventLimit {
            if report.events > 5_000 { heavy += 1 }
            print(String(format: "shot %ld: %ld events (%ld recorded), %ld storms settled%@, %.3f s",
                         shot, report.events, tl.events.count, report.jamsSettled,
                         report.hitEventLimit ? ", HIT THE EVENT LIMIT" : "", seconds))
            print("      " + describe(input))
        }
        if shot % 1000 == 999 { print("... \(shot + 1) solved") }
    }
    print(String(format: "JAMS summary: %ld shots over 5000 events, %ld with a storm settled, %ld at the event limit; most events %ld; slowest solve %.3f s (shot %ld)",
                 heavy, settledShots, limitShots, maxEvents, slowest.seconds, slowest.shot))
}
