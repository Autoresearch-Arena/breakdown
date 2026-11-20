// Author: Claude Opus 5.5 High
// Date: 20-November-2026
// PURPOSE: Authors the trick shots for the app with the real solver (run "BreakProbe tricks [id ...]"). Each shot is
//          built geometrically first (the ghost-ball line from the target pocket back through the object ball, a second
//          ball dropped onto the cue ball's own recorded path, blockers on the straight line, a frozen pair whose line
//          misses the pocket), then the strike is found by sweeping aim at a small grid of power and cue-tip settings.
//          Every passing candidate is re-centred in its aim, power and tip windows and measured (TrickSearch.measured),
//          and the one whose aim window fits the shot's difficulty while staying forgiving in power and tip is kept.
//          The printed layouts and strikes are copied into the app's TrickShots file by hand, with the windows in its
//          comments; the run's output is the evidence for each shot.
//          Difficulty bands for the aim half-window (degrees either side of the solution in which the shot still
//          works): easy at least 0.6, medium 0.3 to 1.2, hard 0.12 to 0.6.
// SRP/DRY check: Pass - shot construction and candidate choice only; simulation, goal checks and windows are in
//          TrickSearch.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation

enum Difficulty: String {
    case easy, medium, hard
    var band: ClosedRange<Double> {
        switch self { case .easy: return 0.6...8; case .medium: return 0.3...1.2; case .hard: return 0.12...0.6 }
    }
}

/// One layout plus one strike to try against one goal.
struct Candidate: Sendable {
    var layout: [Vec2]
    var strike: Strike
    var goal: Goal
    var note: String
}

func range(_ from: Double, _ to: Double, _ step: Double) -> [Double] {
    Swift.stride(from: from, through: to + step * 0.001, by: step).map { ($0 / step).rounded() * step }
}

/// Keep the candidates that pass, measure up to `limit` of them (spread evenly), and choose by difficulty: first the
/// aim window must sit in the difficulty's band (or as close to it as anything gets), then the most forgiving in power
/// and tip (capped, so a shot is not chosen only for a huge power window), then the wider aim window.
func best(_ id: String, _ all: [Candidate], _ difficulty: Difficulty, limit: Int = 48,
          extra: (@Sendable (Authored) -> Bool)? = nil) -> Authored? {
    let ok = parallelMap(all.count) { i in passes(all[i].goal, simulate(all[i].layout, all[i].strike)) }
    let first = zip(all, ok).filter { $0.1 }.map { $0.0 }
    // Cheap screen before the costly window walk: the shot must also pass half the difficulty's minimum window either
    // side of its aim, which throws out the lucky single points.
    let nudge = difficulty.band.lowerBound / 2
    let sturdy = parallelMap(first.count) { i -> Bool in
        // Aim either side, then power and tip height either side by about what a player can hold.
        let s = first[i].strike
        var tries: [Strike] = []
        for (da, dp, dt) in [(-nudge, 0.0, 0.0), (nudge, 0, 0), (0, -0.12, 0), (0, 0.12, 0), (0, 0, -0.001), (0, 0, 0.001)] {
            var t = s; t.aim += da; t.power += dp; t.tipUp += dt; tries.append(t)
        }
        return tries.allSatisfy { passes(first[i].goal, simulate(first[i].layout, $0)) }
    }
    let passing = zip(first, sturdy).filter { $0.1 }.map { $0.0 }
    print("   \(id): \(all.count) candidates tried, \(first.count) pass, \(passing.count) also pass at aim +-\(nudge) deg, power +-0.12 m/s and tip +-1 mm")
    guard !passing.isEmpty else { return nil }
    let step = max(1, passing.count / limit)
    let sample = Swift.stride(from: 0, to: passing.count, by: step).map { passing[$0] }
    let found = parallelMap(sample.count) { i -> Authored? in
        let c = sample[i]
        guard let a = measured(id, c.layout, c.strike, c.goal, note: c.note) else { return nil }
        if let extra, !extra(a) { return nil }
        return a
    }.compactMap { $0 }
    let band = difficulty.band
    func distance(_ a: Authored) -> Double {
        let h = a.aimHalfWindow
        return h < band.lowerBound ? band.lowerBound - h : (h > band.upperBound ? h - band.upperBound : 0)
    }
    return found.min { a, b in
        let da = (distance(a) * 50).rounded(), db = (distance(b) * 50).rounded()
        if da != db { return da < db }
        let fa = min(a.feelScore, 2), fb = min(b.feelScore, 2)
        if abs(fa - fb) > 0.05 { return fa > fb }
        return a.aimHalfWindow > b.aimHalfWindow
    }
}

/// Second-ball placement: for each strike, record the cue ball's path (from its first ball contact, or from the
/// start for a kick) and, at points along it, put `ball` exactly where a cue ball arriving there sends it toward each
/// allowed pocket. `minCushions` skips the part of the path before that many cushion hits.
func placedOnPath(base: [Vec2], ball: Int, strikes: [Strike], pocketsAllowed: [Int], fromStart: Bool = false,
                  minCushions: Int = 0, maxCushions: Int = 9, minTime: Double = 0.15, every: Int = 3,
                  goal: (Int) -> Goal, note: (Int) -> String) -> [Candidate] {
    var out: [Candidate] = []
    let timelines = parallelMap(strikes.count) { i in simulate(base, strikes[i]) }
    for (s, tl) in zip(strikes, timelines) {
        let path = cuePath(tl, fromStart: fromStart)
        guard let t0 = path.first?.t else { continue }
        for (k, sample) in path.enumerated() where k % every == 0 && sample.t - t0 >= minTime
            && sample.cushions >= minCushions && sample.cushions <= maxCushions {
            for target in pocketsAllowed {
                let b = ballFor(cueAt: sample.p, pocket: pockets[target])
                guard clearOfRails(b, margin: 0.02), clearOfBalls(b, base, gap: 0.03),
                      (pockets[target] - b).length > 0.2 else { continue }
                var layout = base
                layout[ball] = b
                out.append(Candidate(layout: layout, strike: s, goal: goal(target), note: note(target)))
            }
        }
    }
    return out
}

// MARK: 2. Stop Dead

/// Straight in to the top-right corner. The cue ball must stop within a ball's width of the spot where it struck.
func authorStopDead() -> Authored? {
    let pocket = pockets[3]
    let a = Vec2(2.02, 0.80)
    let u = unit(pocket - a)
    let ghost = a - u * (2 * R)
    var cands: [Candidate] = []
    for d in [0.4, 0.55, 0.7] {
        let layout = layoutOf([0: a - u * d, 3: a])
        let goal = Goal(drops: [(3, 3)], cueZone: (ghost, 0.05), firstHit: 3)
        for p in range(1.5, 5, 0.25) {
            for t in range(-0.02, 0.0, 0.001) {
                cands.append(Candidate(layout: layout, strike: Strike(aim: degrees(of: u), power: p, tipUp: t, tipSide: 0),
                                       goal: goal, note: String(format: "stun from %.2f m: cue ball stops where it struck", d)))
            }
        }
    }
    return best("stop-dead", cands, .easy)
}

// MARK: 3. The Long Bridge Draw

/// Cue ball in the middle of the table (out of reach without the bridge). The 6 sits near the long diagonal toward the
/// bottom-right corner; screw back the length of the table and the cue ball knocks the 2 in at the other end.
func authorBridgeDraw() -> Authored? {
    var cands: [Candidate] = []
    let diag = unit(pockets[1] - pockets[2])                 // from top-left corner toward bottom-right corner
    for cx in [1.35, 1.5] {
        let c = pockets[2] + diag * (cx / diag.x)            // a point on the diagonal at x = cx
        for gapAB in [0.4, 0.55] {
            for bend in [-2.0, 0.0, 2.0] {
                // A slight bend off the diagonal so the 6 is a gentle cut and the drawn cue ball comes back off line.
                let a = c + rotate(diag, bend) * gapAB
                let base = layoutOf([0: c, 6: a])
                let ghost = a - unit(pockets[1] - a) * (2 * R)
                let aim0 = degrees(of: unit(ghost - c))
                var strikes: [Strike] = []
                for da in range(-0.6, 0.6, 0.2) { for p in [5.0, 6.0, 7.0, 8.0] { for t in [-0.014, -0.017, -0.02] {
                    strikes.append(Strike(aim: aim0 + da, power: p, tipUp: t, tipSide: 0))
                } } }
                cands += placedOnPath(base: base, ball: 2, strikes: strikes, pocketsAllowed: [0, 2, 5], minTime: 0.3,
                                      every: 6, goal: { Goal(drops: [(6, 1), (2, $0)], firstHit: 6) },
                                      note: { "pot the 6, draw back the table to pot the 2 in the \(pocketNames[$0])" })
            }
        }
    }
    // Keep only shots where the 2 is really at the far end: the draw must carry the cue ball most of the table.
    let far = cands.filter { ($0.layout[2] - $0.layout[6]).length > 1.2 }
    return best("bridge-draw", far, .medium)
}

// MARK: 4. Follow-Through Train

/// The 1 is cut into a corner; follow carries the cue ball on through the contact to pot the 2 beyond it.
func authorFollowTrain() -> Authored? {
    var cands: [Candidate] = []
    for a in [Vec2(1.95, 0.85), Vec2(2.05, 0.95), Vec2(1.85, 0.95)] {
        let potLine = unit(pockets[3] - a)
        for cutDeg in [-25.0, -15.0, 15.0, 25.0] {
            let c = a - rotate(potLine, cutDeg) * 0.55
            guard clearOfRails(c) else { continue }
            let base = layoutOf([0: c, 1: a])
            let aim0 = degrees(of: unit(a - potLine * (2 * R) - c))
            var strikes: [Strike] = []
            for da in range(-0.4, 0.4, 0.2) { for p in [2.5, 3.5, 4.5] { for t in [0.01, 0.014, 0.018] {
                strikes.append(Strike(aim: aim0 + da, power: p, tipUp: t, tipSide: 0))
            } } }
            cands += placedOnPath(base: base, ball: 2, strikes: strikes, pocketsAllowed: [0, 1, 2, 4, 5], minTime: 0.25,
                                  every: 5, goal: { Goal(drops: [(1, 3), (2, $0)], firstHit: 1) },
                                  note: { "pot the 1, follow on to pot the 2 in the \(pocketNames[$0])" })
        }
    }
    return best("follow-train", cands, .medium)
}

// MARK: 5. Two-Rail Kick

/// The cue ball goes off two cushions to pot the 5, which is hidden behind the 9 and the 10 on the straight line.
func authorTwoRailKick() -> Authored? {
    var cands: [Candidate] = []
    for c in [Vec2(0.7, 0.45), Vec2(0.6, 0.8), Vec2(0.9, 0.35)] {
        let base = layoutOf([0: c])
        var strikes: [Strike] = []
        for aim in range(-80, -10, 2.5) + range(10, 80, 2.5) { for p in [3.0, 4.0, 5.0] {
            strikes.append(Strike(aim: aim, power: p, tipUp: 0.006, tipSide: 0))
        } }
        let placed = placedOnPath(base: base, ball: 5, strikes: strikes, pocketsAllowed: [0, 1, 2, 3, 4, 5], fromStart: true,
                                  minCushions: 2, maxCushions: 2, minTime: 0.1, every: 5,
                                  goal: { Goal(drops: [(5, $0)], firstHit: 5) },
                                  note: { "two cushions, then the 5 into the \(pocketNames[$0])" })
        for cand in placed {
            // Blockers on the straight line from the cue ball to the 5, clear of the kick's own path.
            let t = cand.layout[5]
            let line = t - c
            guard line.length > 0.7 else { continue }
            let b1 = c + line * 0.45 + unit(line).perp * (R * 0.4)
            let b2 = c + line * 0.62 - unit(line).perp * (R * 0.6)
            let path = cuePath(simulate(cand.layout, cand.strike), fromStart: true)
            let clear = path.allSatisfy { ($0.p - b1).length > 2 * R + 0.02 && ($0.p - b2).length > 2 * R + 0.02 }
            guard clear, clearOfRails(b1), clearOfRails(b2) else { continue }
            var layout = cand.layout
            layout[9] = b1; layout[10] = b2
            cands.append(Candidate(layout: layout, strike: cand.strike, goal: cand.goal, note: cand.note))
        }
    }
    return best("two-rail-kick", cands, .hard)
}

// MARK: 6. Cross-Side Bank

/// The 5 sits near the top side pocket; bank it off the bottom cushion and back across into that pocket.
func authorCrossBank() -> Authored? {
    var cands: [Candidate] = []
    let target = pockets[5]
    for ax in [0.95, 1.05, 1.5, 1.6] {
        for ay in [0.8, 0.95] {
            let a = Vec2(ax, ay)
            // Aim the 5 at the pocket's mirror image in the bottom cushion line (the ball's centre turns at y = R).
            let mirror = Vec2(target.x, 2 * R - target.y)
            let objDir = unit(mirror - a)
            for cut in [-20.0, -10.0, 10.0, 20.0] {
                let c = a - rotate(objDir, cut) * 0.5
                guard clearOfRails(c) else { continue }
                let layout = layoutOf([0: c, 5: a])
                let aim0 = degrees(of: unit(a - objDir * (2 * R) - c))
                for da in range(-2, 2, 0.1) { for p in [2.5, 3.5, 4.5] {
                    cands.append(Candidate(layout: layout, strike: Strike(aim: aim0 + da, power: p, tipUp: 0, tipSide: 0),
                                           goal: Goal(drops: [(5, 5)], firstHit: 5, bank: 5),
                                           note: "bank the 5 off the bottom cushion into the top side pocket"))
                } }
            }
        }
    }
    return best("cross-bank", cands, .medium)
}

// MARK: 7. Combination Chain

/// Cue ball into the 3, the 3 into the 4, the 4 into the 7, and the 7 drops in the bottom-right corner.
func authorComboChain() -> Authored? {
    var cands: [Candidate] = []
    let pocket = pockets[1]
    let d = pocket + unit(Vec2(-1, 0.75)) * 0.42
    let uD = unit(pocket - d)
    for bend1 in [-10.0, -5.0, 0.0, 5.0, 10.0] {
        for bend2 in [-10.0, 0.0, 10.0] {
            for gap in [0.04, 0.09] {
                let b = d - rotate(uD, bend1) * (2 * R + gap)
                let a = b - rotate(uD, bend1 + bend2) * (2 * R + gap)
                for bend3 in [-12.0, 0.0, 12.0] {
                    let c = a - rotate(uD, bend1 + bend2 + bend3) * 0.6
                    guard [a, b, c, d].allSatisfy({ clearOfRails($0) }) else { continue }
                    let layout = layoutOf([0: c, 3: a, 4: b, 7: d])
                    let aim0 = degrees(of: unit(a - c))
                    for da in range(-3, 3, 0.04) { for p in [2.5, 3.5, 4.5] {
                        cands.append(Candidate(layout: layout, strike: Strike(aim: aim0 + da, power: p, tipUp: 0.004, tipSide: 0),
                                               goal: Goal(drops: [(7, 1)], firstHit: 3),
                                               note: "the 3 into the 4 into the 7, which drops"))
                    } }
                }
            }
        }
    }
    return best("combo-chain", cands, .hard)
}

// MARK: 8. Throw It In

/// The 2 (behind) and the 8 (in front) are frozen together, but their line points past the bottom-left corner.
/// Hit the 2 with side spin and the friction between the touching balls throws the 8 in anyway.
func authorThrowIt() -> Authored? {
    var cands: [Candidate] = []
    let pocket = pockets[0]
    for dist in [0.45, 0.6] {
        let b = pocket + unit(Vec2(1, 0.62)) * dist
        let toPocket = unit(pocket - b)
        for miss in [-7.0, -5.0, 5.0, 7.0] {
            let v = rotate(toPocket, miss)                 // the line of centres, missing the pocket by `miss` degrees
            let a = b - v * (2 * R + 1e-6)                // frozen: a micrometre apart, as the rack is
            for approach in [-25.0, 0.0, 25.0] {
                let c = a - rotate(v, approach) * 0.5
                guard [a, b, c].allSatisfy({ clearOfRails($0) }) else { continue }
                let layout = layoutOf([0: c, 2: a, 8: b])
                let aim0 = degrees(of: unit(a - c))
                for da in range(-4, 4, 0.1) { for side in [-0.016, -0.012, -0.008, 0.008, 0.012, 0.016] { for p in [1.5, 2.5] {
                    cands.append(Candidate(layout: layout, strike: Strike(aim: aim0 + da, power: p, tipUp: 0, tipSide: side),
                                           goal: Goal(drops: [(8, 0)], firstHit: 2),
                                           note: String(format: "frozen pair %.0f deg off the pocket, side spin throws the 8 in", miss)))
                } } }
            }
        }
    }
    // The point of the shot is the throw: with the same strike but no friction between balls, or no side spin, it
    // must miss. Otherwise the shot does not teach what it says.
    var frictionless = P
    frictionless.ballBallFrictionFloor = 0
    frictionless.ballBallFrictionGain = 0
    let fl = frictionless
    return best("throw-it", cands, .medium) { a in
        var noSide = a.strike; noSide.tipSide = 0
        return !passes(a.goal, simulate(a.layout, a.strike, parameters: fl)) && !passes(a.goal, simulate(a.layout, noSide))
    }
}

// MARK: 1. The Called Break

/// Breaks with a fixed rack seed. For every (seed, power, tip) the aim offset at the head ball is swept, and for each
/// ball-and-pocket pair the longest unbroken run of offsets in which that ball drops in that pocket (with the cue ball
/// staying up) is found. The widest run wins: that is the break you can call.
func authorCalledBreak() {
    struct Run: Sendable { var seed: UInt64; var power: Double; var tip: Double; var ball: Int; var pocket: Int; var lo: Double; var hi: Double }
    let offsets = range(-0.03, 0.03, 0.0005)
    var settings: [(UInt64, Double, Double)] = []
    for seed in UInt64(1)...UInt64(24) { for p in [9.0, 10.0, 11.0, 12.0, 13.0] { for t in [-0.008, -0.004, 0.0] { settings.append((seed, p, t)) } } }
    let all = settings
    let runs = parallelMap(all.count) { i -> [Run] in
        let (seed, power, tip) = all[i]
        var outcome: [[Int: Int]] = []      // per offset: ball -> pocket (empty if the cue ball scratched)
        for off in offsets {
            var p = PoolParameters(); p.version = 1        // as the app's breaks are struck
            let tl = PoolSolver.simulate(Rack.breakShot(parameters: p, seed: seed, aimOffset: off, speed: power, tipUp: tip))
            var o: [Int: Int] = [:]
            if tl.pocketTime[0] == nil { for b in 1..<16 { if let k = pocketOf(b, tl) { o[b] = k } } }
            outcome.append(o)
        }
        var found: [Run] = []
        for b in 1..<16 { for k in 0..<6 {
            var start: Int?
            for j in 0...offsets.count {
                let hit = j < offsets.count && outcome[j][b] == k
                if hit { if start == nil { start = j } }
                else if let s = start {
                    if j - s >= 3 { found.append(Run(seed: seed, power: power, tip: tip, ball: b, pocket: k, lo: offsets[s], hi: offsets[j - 1])) }
                    start = nil
                }
            }
        } }
        return found
    }.flatMap { $0 }
    let sorted = runs.sorted { ($0.hi - $0.lo) > ($1.hi - $1.lo) }
    print("== called-break: \(runs.count) runs of three or more offsets; widest first")
    for r in sorted.prefix(15) {
        print(String(format: "   seed %llu power %.0f tip %+.3f: the %d into the %@ for aim offsets %+.4f to %+.4f m (centre %+.4f, half-width %.4f)",
                     r.seed, r.power, r.tip, r.ball, pocketNames[r.pocket], r.lo, r.hi, (r.lo + r.hi) / 2, (r.hi - r.lo) / 2))
    }
    // The power window at the centre of the best run.
    if let r = sorted.first {
        let centre = (((r.lo + r.hi) / 2) / 0.0005).rounded() * 0.0005
        func ok(_ power: Double) -> Bool {
            var p = PoolParameters(); p.version = 1
            let tl = PoolSolver.simulate(Rack.breakShot(parameters: p, seed: r.seed, aimOffset: centre, speed: power, tipUp: r.tip))
            return tl.pocketTime[0] == nil && pocketOf(r.ball, tl) == r.pocket
        }
        if let b = band(centre: r.power, step: 0.05, limit: 4, { $0 >= 7 && $0 <= 13 && ok($0) }) {
            print(String(format: "   best: centre offset %+.4f m, power window %.2f to %.2f m/s", centre, b.lo, b.hi))
        }
    }
}

// MARK: Driver

/// Authors every shot (or only the ids named) and prints each report.
func runTrickAuthoring(only: Set<String>) {
    let all: [(String, () -> Authored?)] = [
        ("stop-dead", authorStopDead),
        ("bridge-draw", authorBridgeDraw),
        ("follow-train", authorFollowTrain),
        ("two-rail-kick", authorTwoRailKick),
        ("cross-bank", authorCrossBank),
        ("combo-chain", authorComboChain),
        ("throw-it", authorThrowIt),
    ]
    if only.isEmpty || only.contains("called-break") {
        let start = Date()
        authorCalledBreak()
        print(String(format: "   (search took %.1f s)", Date().timeIntervalSince(start)))
    }
    for (id, author) in all where only.isEmpty || only.contains(id) {
        let start = Date()
        if let a = author() { report(a) } else { print("== \(id): NO SOLUTION FOUND") }
        print(String(format: "   (search took %.1f s)", Date().timeIntervalSince(start)))
    }
}
