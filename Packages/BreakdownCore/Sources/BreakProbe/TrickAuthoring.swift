// Author: Claude Opus 5.5 High
// Date: 20-November-2026
// Edited: Claude Opus 5.5 High, 20-November-2026 (throw search moved further off the pocket so it needs the throw, coarser aim steps; new massé and jump searches using cue elevation).
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.4 trick-shots stream: searches for the two side-spin shots,
//          "squirt" and "side-off-rail", each kept only if it teaches what its words say; see their MARK sections.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 learn-modes stream, plans/22-Nov-2026-v075-whatif-and-gaps-plan.md
//          item 6: "tricks masse-offered jump-offered draw-masse-carom" re-author the three raised-cue shots on an angle
//          the cue-angle menu offers, each kept on its old checks plus a tip-height window of at least 1.5 mm each side;
//          see "Raised cue on the offered angles".)
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
import BreakdownAuthored
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
    var passing = zip(first, sturdy).filter { $0.1 }.map { $0.0 }
    // Some shots (a long draw) are touchy in power and tip by nature: when none survive the full screen, fall back to
    // the aim screen alone, and say so, rather than finding nothing.
    if passing.isEmpty {
        let aimOnly = parallelMap(first.count) { i -> Bool in
            var lo = first[i].strike, hi = first[i].strike
            lo.aim -= nudge; hi.aim += nudge
            return passes(first[i].goal, simulate(first[i].layout, lo)) && passes(first[i].goal, simulate(first[i].layout, hi))
        }
        passing = zip(first, aimOnly).filter { $0.1 }.map { $0.0 }
        print("   \(id): none survive the power and tip screen; \(passing.count) survive the aim screen alone")
    }
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
                  pocketDistance: ClosedRange<Double> = 0.2...9,
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
                guard clearOfRails(b, margin: 0.02, pocketClear: min(0.12, pocketDistance.lowerBound)), clearOfBalls(b, base, gap: 0.03),
                      pocketDistance.contains((pockets[target] - b).length) else { continue }
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
        // The 6 close in front of the cue ball: a fraction of a degree of aim then changes the cut on the 6, and so
        // the line the cue ball draws back on, far less than from further away (0.3 to 0.55 m gave half-windows of
        // 0.06 degrees at best, too fine for anyone).
        for gapAB in [0.12, 0.18, 0.25] {
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
                // The 2 hangs near its pocket (7 to 16 cm out), so the returning cue ball only has to reach it: a
                // ball placed further out needs the return line to the centimetre, which no player could repeat.
                cands += placedOnPath(base: base, ball: 2, strikes: strikes, pocketsAllowed: [0, 2, 5], minTime: 0.3,
                                      every: 2, pocketDistance: 0.07...0.16, goal: { Goal(drops: [(6, 1), (2, $0)], firstHit: 6) },
                                      note: { "pot the 6, draw back the table to pot the 2 in the \(pocketNames[$0])" })
            }
        }
    }
    // Keep only shots where the 2 is really at the far end: the draw must carry the cue ball most of the table.
    let far = cands.filter { ($0.layout[2] - $0.layout[6]).length > 1.2 }
    // A long draw that also pots a second ball is touchy by nature: a fraction of a degree changes the cut on the 6
    // and so the line the cue ball comes back on. A first run asked for the medium window and found none; it is hard.
    return best("bridge-draw", far, .hard)
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

/// The 5 sits a little off the middle of the table; bank it off the bottom cushion and back across into the top side
/// pocket. The cue ball is above it (on the top pocket's side), so the 5 has to cross the table twice.
func authorCrossBank() -> Authored? {
    var cands: [Candidate] = []
    let target = pockets[5]
    for ax in [0.85, 0.95, 1.05, 1.5, 1.6, 1.7] {
        for ay in [0.45, 0.55, 0.65] {
            let a = Vec2(ax, ay)
            // Aim the 5 at the pocket's mirror image in the bottom cushion line (the ball's centre turns at y = R).
            let mirror = Vec2(target.x, 2 * R - target.y)
            let objDir = unit(mirror - a)
            for cut in [-20.0, -10.0, 10.0, 20.0] {
                let c = a - rotate(objDir, cut) * 0.38
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
        // Far enough off the pocket that the cut angle alone cannot make it: the shot has to need the throw.
        for miss in [-12.0, -9.0, 9.0, 12.0] {
            let v = rotate(toPocket, miss)                 // the line of centres, missing the pocket by `miss` degrees
            // Half a millimetre apart: touching to the eye. At a micrometre (as the rack is) the solver chatters: the
            // cue ball, following the 2 after a full hit, re-collides with it tens of thousands of times. The cue ball
            // also comes in at an angle for the same reason, so it glances away instead of pressing on.
            let a = b - v * (2 * R + 5e-4)
            for approach in [-35.0, -20.0, 20.0, 35.0] {
                let c = a - rotate(v, approach) * 0.5
                guard [a, b, c].allSatisfy({ clearOfRails($0) }) else { continue }
                let layout = layoutOf([0: c, 2: a, 8: b])
                let aim0 = degrees(of: unit(a - c))
                for da in range(-4, 4, 0.25) { for side in [-0.016, -0.012, 0.012, 0.016] { for p in [1.5, 2.5] {
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

// MARK: 9. The Massé

/// A ball sits dead in the way between the cue ball and the target. A steeply raised cue with side offset bends the
/// cue ball round the blocker onto the target, which drops. A level cue on the same line hits the blocker.
func authorMasse() -> Authored? {
    var cands: [Candidate] = []
    let pocket = pockets[3]                                   // top-right corner
    // A massé covers about half a metre (sine 0.5 at 0.5 m/s ends about 0.53 m along and 0.18 m aside), so the
    // three balls sit close together.
    for (gap, reach) in [(0.15, 0.35), (0.2, 0.45)] {
        // The target hangs near the pocket's mouth, as in the classic massé trick: the curve arrives slowly, so the
        // touch it gives has to be enough.
        let target = pocket + unit(Vec2(-1, -0.55)) * 0.11
        let toPocket = unit(pocket - target)
        let cueSpot = target - toPocket * (2 * R) - toPocket * reach      // straight behind the target on its pocket line
        let blocker = cueSpot + toPocket * gap
        guard clearOfRails(cueSpot), clearOfRails(blocker), clearOfRails(target, pocketClear: 0.05) else { continue }
        let layout = layoutOf([0: cueSpot, 4: blocker, 9: target])
        let direct = degrees(of: toPocket)
        for e in [0.4, 0.5] { for side in [-0.75 * R, -0.6 * R, 0.6 * R, 0.75 * R] { for p in [0.6, 0.8, 1.0, 1.2] {
            for da in range(-40, 40, 1.0) {
                cands.append(Candidate(layout: layout, strike: Strike(aim: direct + da, power: p, tipUp: 0, tipSide: side, elevation: e),
                                       goal: Goal(drops: [(9, 3)], firstHit: 9),
                                       note: "massé round the 4 onto the 9"))
            }
        } } }
    }
    print("   masse: \(cands.count) candidates")
    if ProcessInfo.processInfo.environment["MASSE_DIAG"] != nil {
        var hits: [String: Int] = [:]
        var reachTarget = 0
        for c in cands {
            let tl = simulate(c.layout, c.strike)
            hits["first \(firstStruck(tl).map(String.init) ?? "none")", default: 0] += 1
            if firstStruck(tl) == 9 { reachTarget += 1; if let k = pocketOf(9, tl) { hits["9 in \(k)", default: 0] += 1 } else { hits["9 stays up", default: 0] += 1 } }
        }
        print("   masse diag: \(hits.sorted { $0.key < $1.key })")
    }
    return best("masse-curve", cands, .hard) { a in
        // It must really be the curve: the same strike with a level cue does not make it.
        var level = a.strike; level.elevation = 0
        return !passes(a.goal, simulate(a.layout, level))
    }
}

// MARK: 10. Jump the Blocker

/// A ball sits in the way, straight between the cue ball and the target. A raised cue makes the cue ball leave the
/// cloth, clear the blocker, land and run on into the target, which drops. A level cue hits the blocker.
func authorJump() -> Authored? {
    var cands: [Candidate] = []
    let pocket = pockets[3]
    for (gap, reach) in [(0.3, 0.9), (0.35, 1.0)] {
        let target = pocket + unit(Vec2(-1, -0.5)) * 0.35
        let toPocket = unit(pocket - target)
        let cueSpot = target - toPocket * (2 * R) - toPocket * reach
        let blocker = cueSpot + toPocket * gap
        guard [target, cueSpot, blocker].allSatisfy({ clearOfRails($0) }) else { continue }
        let layout = layoutOf([0: cueSpot, 6: blocker, 11: target])
        let direct = degrees(of: toPocket)
        for e in [0.5, 0.55, 0.6, 0.65] { for p in range(3.0, 5.5, 0.25) { for da in range(-1.5, 1.5, 0.1) {
            cands.append(Candidate(layout: layout, strike: Strike(aim: direct + da, power: p, tipUp: 0, tipSide: 0, elevation: e),
                                   goal: Goal(drops: [(11, 3)], firstHit: 11),
                                   note: "jump the 6, pot the 11"))
        } } }
    }
    print("   jump: \(cands.count) candidates")
    return best("jump-over", cands, .medium) { a in
        var level = a.strike; level.elevation = 0
        return !passes(a.goal, simulate(a.layout, level))
    }
}

// MARK: 1. The Called Break

/// Breaks with a fixed rack seed. For every (seed, power, tip) the aim offset at the head ball is swept, and for each
/// ball-and-pocket pair the longest unbroken run of offsets in which that ball drops in that pocket (with the cue ball
/// staying up) is found. The widest run wins: that is the break you can call.
func authorCalledBreak() {
    struct Run: Sendable { var seed: UInt64; var power: Double; var tip: Double; var ball: Int; var pocket: Int; var lo: Double; var hi: Double }
    // A full break is costly to solve (sixteen balls, hundreds of contacts), so the sweep is kept small: a few rack
    // seeds and strengths, the aim offset in millimetre steps. (A first, much wider sweep did not finish on a shared
    // machine.)
    let offsets = range(-0.025, 0.025, 0.001)
    var settings: [(UInt64, Double, Double)] = []
    for seed in [UInt64(3), 5, 8, 13] { for p in [10.0, 12.0] { for t in [-0.006] { settings.append((seed, p, t)) } } }
    let all = settings
    let clock = Date()
    let runs = parallelMap(all.count) { i -> [Run] in
        let (seed, power, tip) = all[i]
        defer { print(String(format: "   called-break: seed %llu power %.0f done at %.0f s", seed, power, Date().timeIntervalSince(clock))) }
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

// MARK: 1. The Called Break, on a short rack

/// The full fifteen-ball rack turned out to be chaotic at the scale a player can aim (no ball dropped in the same
/// pocket for even three millimetre steps of aim in a row; see authorCalledBreak). So the called break uses the front
/// of a rack: the first three or four rows, a micrometre apart as the full rack is, broken from the head spot as a
/// shot. For every rack size, strength and tip, the aim is swept across the front ball in 0.02 degree steps, and for
/// each ball-and-pocket pair the longest unbroken run of aims in which that ball drops there (cue ball staying up) is
/// found. The widest run is kept and measured like every other shot.
func authorCalledBreakShort() -> Authored? {
    struct Run: Sendable { var config: Int; var ball: Int; var pocket: Int; var lo: Double; var hi: Double }
    struct Config: Sendable { var rows: Int; var cue: Vec2; var power: Double; var tip: Double }
    var configs: [Config] = []
    for rows in [3, 4] { for cue in [Vec2(L * 0.25, W * 0.5), Vec2(L * 0.25, W * 0.5 - 0.2)] {
        for power in [5.0, 6.5, 8.0] { for tip in [-0.006, 0.0] { configs.append(Config(rows: rows, cue: cue, power: power, tip: tip)) } }
    } }
    @Sendable func layout(_ c: Config) -> [Vec2] {
        // Rack gaps of half a millimetre (the full rack uses a micrometre, at which the solver can chatter between
        // balls pressed together; see the throw shot).
        var spaced = P
        spaced.rackGap = 5e-4
        let full = Rack.positions(parameters: spaced, seed: 3)
        var out = [Vec2](repeating: NextShot.offTable, count: 16)
        out[0] = c.cue
        for row in Rack.layout.prefix(c.rows) { for b in row { out[b] = full[b] } }
        return out
    }
    let aims = range(-1.5, 1.5, 0.02)
    let all = configs
    let runs = parallelMap(all.count) { i -> [Run] in
        let c = all[i]
        let lay = layout(c)
        let base = degrees(of: unit(lay[1] - c.cue))
        var outcome: [[Int: Int]] = []
        for da in aims {
            let tl = simulate(lay, Strike(aim: base + da, power: c.power, tipUp: c.tip, tipSide: 0))
            var o: [Int: Int] = [:]
            if tl.pocketTime[0] == nil { for b in 1..<16 { if let k = pocketOf(b, tl) { o[b] = k } } }
            outcome.append(o)
        }
        var found: [Run] = []
        for b in 1..<16 where NextShot.isOnTable(lay[b]) { for k in 0..<6 {
            var start: Int?
            for j in 0...aims.count {
                let hit = j < aims.count && outcome[j][b] == k
                if hit { if start == nil { start = j } }
                else if let s0 = start {
                    found.append(Run(config: i, ball: b, pocket: k, lo: base + aims[s0], hi: base + aims[j - 1]))
                    start = nil
                }
            }
        } }
        return found
    }.flatMap { $0 }
    let sorted = runs.sorted { ($0.hi - $0.lo) > ($1.hi - $1.lo) }
    print("== called-break (short rack): \(runs.count) runs; widest first")
    for r in sorted.prefix(10) {
        let c = all[r.config]
        print(String(format: "   %d rows, cue at %@, power %.1f, tip %+.3f: the %d into the %@ for aims %.2f to %.2f deg",
                     c.rows, fmt(c.cue), c.power, c.tip, r.ball, pocketNames[r.pocket], r.lo, r.hi))
    }
    // Measure the best few the same way as every other shot and keep the most forgiving.
    let top = Array(sorted.prefix(6))
    let measuredRuns = parallelMap(top.count) { i -> Authored? in
        let r = top[i], c = all[r.config]
        let goal = Goal(drops: [(r.ball, r.pocket)])
        return measured("called-break", layout(c), Strike(aim: (r.lo + r.hi) / 2, power: c.power, tipUp: c.tip, tipSide: 0), goal,
                        note: "\(c.rows)-row rack: the \(r.ball) into the \(pocketNames[r.pocket])")
    }.compactMap { $0 }
    return choose(measuredRuns, .medium)
}

/// Of shots already measured, the one whose aim window best fits the difficulty band (see best()).
func choose(_ list: [Authored], _ difficulty: Difficulty) -> Authored? {
    let band = difficulty.band
    func distance(_ a: Authored) -> Double {
        let h = a.aimHalfWindow
        return h < band.lowerBound ? band.lowerBound - h : (h > band.upperBound ? h - band.upperBound : 0)
    }
    return list.min { a, b in
        let da = (distance(a) * 50).rounded(), db = (distance(b) * 50).rounded()
        if da != db { return da < db }
        return min(a.feelScore, 2) > min(b.feelScore, 2)
    }
}

// MARK: 12. Squirt (0.7.4)

/// The strong-side rule both side-spin shots are judged by, read from the package library's one copy
/// (AuthoredTricks.strongSide), so the windows measured here are the ones the app's judge holds the player to.
let strongSide = AuthoredTricks.strongSide

/// The side band of a strike inside the strong-side rule: walked like every other band, but a side weaker than the rule
/// (or on the other side of centre) counts as a miss, as it does in the app. Nil when the strike itself fails.
func strongSideBand(_ layout: [Vec2], _ s: Strike, _ goal: Goal) -> (lo: Double, hi: Double)? {
    band(centre: s.tipSide, step: 0.0005, limit: 0.04) { v in
        guard insideGrip(up: s.tipUp, side: v), v * s.tipSide > 0, abs(v) >= strongSide - 1e-12 else { return false }
        var t = s; t.tipSide = v; return passes(goal, simulate(layout, t))
    }
}

/// The half-width of a band around a value.
func halfWidth(_ b: (lo: Double, hi: Double), _ centre: Double) -> Double { min(centre - b.lo, b.hi - centre) }

/// The heading the cue ball actually leaves on (degrees), read from the recording a moment after the strike: the aim
/// turned by the side-spin deflection.
func launchHeading(_ tl: Timeline) -> Double {
    degrees(of: tl.state(ball: 0, at: 1e-4).velocity)
}

/// An object ball hanging near a corner, the cue ball far down the table on the same line. Struck with strong side the
/// cue ball leaves the cue's line by the deflection (the solver's squirt: about two and a half degrees at the strongest
/// side the tip can hold), and over a long run that is enough to miss a straight-in pot; the answer aims off the other
/// way to allow for it. Kept only if (a) the same stroke aimed dead straight misses, (b) the answer's own aim with no
/// side misses (the side is needed at that aim), (c) the answer aims at least one degree off the straight line, and the
/// windows are makeable: aim half-width at least 0.4 degrees, power at least 0.2 m/s, a tip-height band, and a side band
/// inside the strong-side rule.
func authorSquirt() -> Authored? {
    var cands: [Candidate] = []
    let ball = 2
    for (k, pocketIndex) in [3, 1].enumerated() {
        let pocket = pockets[pocketIndex]
        // Directions from the pocket into the table, mostly along its length, so the cue ball can sit far back.
        let into: [Double] = k == 0 ? [188, 196, 205, 215] : [-188, -196, -205, -215]
        for phi in into {
            let dir = Vec2(cos(phi * Double.pi / 180), sin(phi * Double.pi / 180))
            for hang in [0.16, 0.24, 0.34] {
                let a = pocket + dir * hang
                for reach in [1.0, 1.3, 1.6] {
                    let c = a + dir * reach
                    guard clearOfRails(a, pocketClear: 0.05), clearOfRails(c) else { continue }
                    let layout = layoutOf([0: c, ball: a])
                    let straight = degrees(of: unit(a - c))
                    let goal = Goal(drops: [(ball, pocketIndex)], firstHit: ball)
                    let note = String(format: "squirt: the %d hangs %.2f m from the %@, the cue ball %.2f m back", ball, hang,
                                      pocketNames[pocketIndex], reach)
                    for da in range(-4, 4, 0.1) { for p in [4.0, 5.0, 6.0] {
                        for side in [-0.0125, -0.011, 0.011, 0.0125] { for up in [-0.004, 0.0] {
                            cands.append(Candidate(layout: layout, strike: Strike(aim: straight + da, power: p, tipUp: up, tipSide: side),
                                                   goal: goal, note: note))
                        } }
                    } }
                }
            }
        }
    }
    print("   squirt: \(cands.count) candidates")
    let found = best("squirt", cands, .medium) { a in
        let straight = degrees(of: unit(a.layout[ball] - a.layout[0]))
        guard abs(a.strike.aim - straight) >= 1.0, abs(a.strike.tipSide) >= strongSide,
              a.aimHalfWindow >= 0.4, a.powerHalfWindow >= 0.2, a.tipHalfWindow > 0 else { return false }
        var dead = a.strike; dead.aim = straight
        var plain = a.strike; plain.tipSide = 0
        guard !passes(a.goal, simulate(a.layout, dead)), !passes(a.goal, simulate(a.layout, plain)) else { return false }
        guard let side = strongSideBand(a.layout, a.strike, a.goal) else { return false }
        return halfWidth(side, a.strike.tipSide) >= 0.0005
    }
    if let a = found {
        explainSide(a)
        var dead = a.strike; dead.aim = degrees(of: unit(a.layout[ball] - a.layout[0]))
        print(String(format: "   aimed dead straight (%.2f deg) with the same stroke: ", dead.aim) + trickOutcome(a.goal, simulate(a.layout, dead)))
        // The words say a firm stroke: does a slow one aimed straight with the same side still go (throw and slide pull it
        // back), or miss as well? Printed as evidence for the maths line, not used to choose.
        var slow = dead; slow.power = 1.5
        print("   aimed dead straight at 1.5 m/s: " + trickOutcome(a.goal, simulate(a.layout, slow)))
    }
    return found
}

/// The facts behind a side-spin shot's words, printed under its report: the side band inside the strong-side rule (the
/// window the app stores), the launch deflection, and what the same stroke does with no side.
func explainSide(_ a: Authored) {
    let s = a.strike
    if let b = strongSideBand(a.layout, s, a.goal) {
        print(String(format: "   side window inside the strong-side rule (%.4f m): %+.4f to %+.4f m (half-width %.4f)",
                     strongSide, b.lo, b.hi, halfWidth(b, s.tipSide)))
    }
    let tl = simulate(a.layout, s)
    print(String(format: "   launch heading %.2f deg for aim %.2f deg: the side turns the cue ball %+.2f deg",
                 launchHeading(tl), s.aim, launchHeading(tl) - s.aim))
    var plain = s; plain.tipSide = 0
    print("   same aim and power, no side: " + trickOutcome(a.goal, simulate(a.layout, plain)))
}

/// A short account of a recording against a goal, for the authoring notes.
func trickOutcome(_ goal: Goal, _ tl: Timeline) -> String {
    if passes(goal, tl) { return "makes it" }
    let first = firstStruck(tl).map { "first hit the \($0)" } ?? "touched no ball"
    let drops = goal.drops.map { d in
        pocketOf(d.ball, tl).map { "the \(d.ball) in the \(pocketNames[$0])" } ?? "the \(d.ball) stays up"
    }
    return "misses (\(first); \(drops.joined(separator: ", "))\(tl.pocketTime[0] != nil ? "; scratch" : ""))"
}

// MARK: 13. Side Off the Rail (0.7.4)

/// The cue ball's first rail contact before its first ball, and how far its path lies from that rail's normal going in
/// and coming out, degrees (0 is straight at or back off the rail, 90 along it). Nil when it touches no rail first.
func firstRailRebound(_ tl: Timeline) -> (inFromNormal: Double, outFromNormal: Double)? {
    let contact = tl.events.first { $0.kind == .ballBall && $0.balls.contains { $0.ball == 0 } }?.time ?? .infinity
    guard let e = tl.events.first(where: { $0.kind == .cushion && $0.edge == .rail && $0.balls.first?.ball == 0 && $0.time < contact }),
          let b = e.balls.first, b.velocityAfter.length > 1e-6, b.velocityBefore.length > 1e-6 else { return nil }
    let n = e.normal.normalized
    func angle(_ v: Vec2) -> Double { acos(min(1, abs(v.normalized.dot(n)))) * 180 / Double.pi }
    return (angle(b.velocityBefore), angle(b.velocityAfter))
}

/// A one-rail kick: the cue ball goes off one cushion to the 7, which drops; two blockers sit on the straight line, so
/// the kick is the way. Struck with side, the spin grips the rail as the ball turns off it and changes the angle it
/// leaves at. Kept only if the side really does the work: (a) the same aim and power with no side fails; (b) a no-side
/// stroke launched on exactly the answer's line (aimed where the side's stroke actually went) also fails, so it is the
/// rail, not the launch deflection, that needs the side; (c) the side widens the angle off the rail, as the words say;
/// and the windows are makeable, as for the squirt.
func authorSideOffRail() -> Authored? {
    let target = 7
    var placed: [Candidate] = []
    for c in [Vec2(0.75, 0.40), Vec2(0.70, 0.85), Vec2(1.0, 0.35), Vec2(1.8, 0.4)] {
        let base = layoutOf([0: c])
        var strikes: [Strike] = []
        // Every 5 degrees round the circle, leaving out the lines straight along or across the table (those come
        // straight back off a rail and teach nothing about the angle).
        for aim in Swift.stride(from: -177.5, through: 177.5, by: 5.0)
            where abs(abs(aim) - 90) > 6 && abs(aim) > 6 && abs(abs(aim) - 180) > 6 {
            for p in [2.5, 3.5] { for side in [-0.011, 0.011] {
                strikes.append(Strike(aim: aim, power: p, tipUp: 0.004, tipSide: side))
            } }
        }
        placed += placedOnPath(base: base, ball: target, strikes: strikes, pocketsAllowed: [0, 1, 2, 3, 4, 5], fromStart: true,
                               minCushions: 1, maxCushions: 1, minTime: 0.1, every: 6, pocketDistance: 0.2...0.9,
                               goal: { Goal(drops: [(target, $0)], firstHit: target) },
                               note: { "one cushion with side, then the \(target) into the \(pocketNames[$0])" })
    }
    print("   side-off-rail: \(placed.count) placements")
    // Blockers on the straight line from the cue ball to the 7 (as the two-rail kick), clear of the kick's own path.
    let all = placed
    let blocked = parallelMap(all.count) { i -> Candidate? in
        let cand = all[i]
        let c = cand.layout[0], t = cand.layout[target]
        let line = t - c
        guard line.length > 0.6 else { return nil }
        let b1 = c + line * 0.45 + unit(line).perp * (R * 0.4)
        let b2 = c + line * 0.62 - unit(line).perp * (R * 0.6)
        guard clearOfRails(b1), clearOfRails(b2), (b1 - t).length > 4 * R, (b2 - t).length > 4 * R else { return nil }
        let path = cuePath(simulate(cand.layout, cand.strike), fromStart: true)
        guard path.allSatisfy({ ($0.p - b1).length > 2 * R + 0.02 && ($0.p - b2).length > 2 * R + 0.02 }) else { return nil }
        var layout = cand.layout
        layout[9] = b1; layout[10] = b2
        return Candidate(layout: layout, strike: cand.strike, goal: cand.goal, note: cand.note)
    }.compactMap { $0 }
    print("   side-off-rail: \(blocked.count) candidates with the straight line blocked")
    let found = best("side-off-rail", blocked, .hard) { a in
        guard abs(a.strike.tipSide) >= strongSide, a.aimHalfWindow >= 0.4, a.powerHalfWindow >= 0.2, a.tipHalfWindow > 0
        else { return false }
        let tl = simulate(a.layout, a.strike)
        var plain = a.strike; plain.tipSide = 0
        guard !passes(a.goal, simulate(a.layout, plain)) else { return false }
        var sameLine = plain; sameLine.aim = launchHeading(tl)
        let lineTl = simulate(a.layout, sameLine)
        guard !passes(a.goal, lineTl) else { return false }
        guard let with = firstRailRebound(tl), let without = firstRailRebound(lineTl),
              with.outFromNormal > without.outFromNormal + 0.5 else { return false }
        guard let side = strongSideBand(a.layout, a.strike, a.goal) else { return false }
        return halfWidth(side, a.strike.tipSide) >= 0.0005
    }
    if let a = found {
        explainSide(a)
        let tl = simulate(a.layout, a.strike)
        var sameLine = a.strike; sameLine.tipSide = 0; sameLine.aim = launchHeading(tl)
        let lineTl = simulate(a.layout, sameLine)
        if let w = firstRailRebound(tl), let o = firstRailRebound(lineTl) {
            print(String(format: "   off the rail: with side in %.1f, out %.1f deg from the normal; same line with no side in %.1f, out %.1f deg",
                         w.inFromNormal, w.outFromNormal, o.inFromNormal, o.outFromNormal))
        }
        print("   same launch line, no side: " + trickOutcome(a.goal, lineTl))
    }
    return found
}

// MARK: Raised cue on the offered angles (0.7.5)

// The three raised-cue trick shots were first authored on any sine the search liked (the massé 0.40, the jump 0.55, the
// carom 0.45), none of which the cue-angle menu can set: its angles are offeredCueAngles (LessonAuthoring.swift, the
// app's CueAngleMenu.angles). So a player could never strike the answer exactly, and Your turn after Watch it put the
// cue on a different angle from the one just watched. These searches keep each shot's layout and goal and re-author its
// strike on an offered angle near the old one, with the elevation exactly sineOf(degrees:), the same formula the app's
// control writes (so the answer's elevation is bit for bit the menu's value).

/// The offered angles within `spread` degrees of an elevation (a sine), nearest first, as (degrees, sine).
func offeredAngles(near elevation: Double, spread: Double = 12) -> [(angle: Int, sine: Double)] {
    let degrees = asin(min(max(elevation, 0), 0.995)) * 180 / Double.pi
    return offeredCueAngles.filter { $0 > 0 && abs(Double($0) - degrees) <= spread }
        .sorted { abs(Double($0) - degrees) < abs(Double($1) - degrees) }
        .map { ($0, sineOf(degrees: $0)) }
}

/// The least tip-height half-window a trick may ship with, metres: 1.5 mm either side of the answer. The tip picture's
/// own steps (a millimetre by VoiceOver, about one by a fingertip on the 52-point picture) must be able to land in it,
/// so a window of half a millimetre each side, the carom's before 0.7.5, was a target nobody could reliably set. The
/// app's AuthoredLibraryTests holds every trick to the same number.
let leastTipHalfWindow = 0.0015

/// What each raised-cue trick must still show, as it was kept on the first time (Reauthor's nearRules, whose closures
/// are private there): a level cue misses (it is the raised cue that does it), and for the carom removing the draw or
/// the side misses too. Every one also needs the tip-height window above.
func raisedCueKeeps(_ id: String) -> (Difficulty, @Sendable (Authored) -> Bool) {
    let levelMisses: @Sendable (Authored) -> Bool = { a in
        var level = a.strike; level.elevation = 0
        return !passes(a.goal, simulate(a.layout, level))
    }
    let roomyTip: @Sendable (Authored) -> Bool = { $0.tipHalfWindow >= leastTipHalfWindow - 1e-9 }
    switch id {
    case "draw-masse-carom":
        return (.hard, { a in
            guard roomyTip(a), levelMisses(a) else { return false }
            var noDraw = a.strike; noDraw.tipUp = 0
            var noSide = a.strike; noSide.tipSide = 0
            return !passes(a.goal, simulate(a.layout, noDraw)) && !passes(a.goal, simulate(a.layout, noSide))
        })
    case "jump-over": return (.medium, { roomyTip($0) && levelMisses($0) })
    default: return (.hard, { roomyTip($0) && levelMisses($0) })      // the massé
    }
}

/// Re-author one raised-cue trick (masse-curve, jump-over or draw-masse-carom) on an offered angle near its old one.
/// First the cheap way: the old strike at each nearby offered angle, re-centred in its windows (TrickSearch.measured
/// leaves the elevation untouched). Only when none of those keeps the shot's checks, a grid near the old strike on the
/// same angles: aim either side (wide for a curve, whose aim swings with the bend), power from softer to harder, tip
/// height a few millimetres either way, the side a little either way where the shot uses it, every tip inside the grip.
/// The choice among survivors is the first authoring's (best, choose).
func authorOnOfferedAngle(_ id: String) -> Authored? {
    guard let t = authoredTricks.first(where: { $0.id == id }), t.strike.elevation > 0 else {
        print("   \(id): not a raised-cue trick in the library"); return nil
    }
    let (difficulty, keeps) = raisedCueKeeps(id)
    let angles = offeredAngles(near: t.strike.elevation)
    print(String(format: "   %@: old elevation sine %.2f (%.1f deg); offered angles tried: %@", id, t.strike.elevation,
                 asin(t.strike.elevation) * 180 / Double.pi, angles.map { "\($0.angle)" }.joined(separator: ", ")))
    // 1. The old strike, moved onto each offered angle.
    let moved = parallelMap(angles.count) { i -> Authored? in
        var s = t.strike; s.elevation = angles[i].sine
        guard passes(t.goal, simulate(t.layout, s)),
              let a = measured(id, t.layout, s, t.goal, note: "the old strike on \(angles[i].angle) degrees, re-centred"),
              keeps(a) else { return nil }
        return a
    }.compactMap { $0 }
    // How many offered angles make each one (its run, cueAngleBand): a player who picks the next angle up or down
    // should still have a chance, so the widest run wins, then the first authoring's choice (choose).
    let runs = parallelMap(moved.count) { i -> Int in
        guard let b = cueAngleBand(moved[i].layout, moved[i].strike, moved[i].goal),
              let lo = offeredCueAngles.firstIndex(of: b.lo), let hi = offeredCueAngles.firstIndex(of: b.hi) else { return 0 }
        return hi - lo + 1
    }
    for (a, run) in zip(moved, runs) {
        print(String(format: "   kept as moved: %d degrees, aim half %.2f, tip half %.4f, feel %.2f, %d offered angles make it",
                     Int((asin(a.strike.elevation) * 180 / Double.pi).rounded()), a.aimHalfWindow, a.tipHalfWindow,
                     a.feelScore, run))
    }
    if let widest = runs.max(), let a = choose(zip(moved, runs).filter { $0.1 == widest }.map(\.0), difficulty) { return a }
    // 2. A grid near the old strike on the same angles. The tip is walked in whole millimetres, wider for the carom,
    // whose draw and side are what the shot is about and whose old answer sat in a half-millimetre tip window.
    let old = t.strike
    let curve = old.tipSide != 0
    let aims = curve ? range(old.aim - 8, old.aim + 8, 0.25) : range(old.aim - 1.5, old.aim + 1.5, 0.05)
    let powers = range(max(0.6, old.power * 0.75), min(8, old.power * 1.4), max(0.05, (old.power * 0.05 / 0.05).rounded() * 0.05))
    let upSpread = id == "draw-masse-carom" ? 5 : 4, sideSpread = id == "draw-masse-carom" ? 3 : 2
    let ups = (-upSpread...upSpread).map { ((old.tipUp + Double($0) * 0.001) / 0.0005).rounded() * 0.0005 }
    let sides: [Double] = old.tipSide == 0 ? [0]
        : (-sideSpread...sideSpread).map { ((old.tipSide + Double($0) * 0.001) / 0.0005).rounded() * 0.0005 }
            .filter { $0 * old.tipSide > 0 }
    var cands: [Candidate] = []
    for (_, e) in angles { for ts in sides { for tu in ups where insideGrip(up: tu, side: ts) {
        for p in powers { for a in aims {
            cands.append(Candidate(layout: t.layout, strike: Strike(aim: a, power: p, tipUp: tu, tipSide: ts, elevation: e),
                                   goal: t.goal, note: "near the old strike, on an offered angle"))
        } }
    } } }
    print("   \(id): the old strike keeps nothing on an offered angle; \(cands.count) grid strikes")
    // More of the survivors are measured than in a first authoring (240, not 48): the tip-height rule is strict, and a
    // shot that meets it may be rare among strokes that pass.
    if let a = best(id, cands, difficulty, limit: 240, extra: keeps) { return a }
    diagnoseOffered(id, cands, keeps)
    return nil
}

/// When no grid strike keeps a raised-cue trick's checks, says why: of a spread of measured strikes that pass, the
/// widest tip-height half-window found and how many fail each check, so the next search (or the decision to keep the
/// old numbers) rests on what the solver did.
func diagnoseOffered(_ id: String, _ cands: [Candidate], _ keeps: @Sendable (Authored) -> Bool) {
    let ok = parallelMap(cands.count) { i in passes(cands[i].goal, simulate(cands[i].layout, cands[i].strike)) }
    let passing = zip(cands, ok).filter { $0.1 }.map(\.0)
    guard !passing.isEmpty else { print("   \(id) diagnosis: nothing passes"); return }
    let step = max(1, passing.count / 120)
    let sample = Swift.stride(from: 0, to: passing.count, by: step).map { passing[$0] }
    let measuredSample = parallelMap(sample.count) { i in
        measured(id, sample[i].layout, sample[i].strike, sample[i].goal, note: "diagnosis")
    }.compactMap { $0 }
    let roomy = measuredSample.filter { $0.tipHalfWindow >= leastTipHalfWindow - 1e-9 }
    let kept = parallelMap(roomy.count) { i in keeps(roomy[i]) }
    let widest = measuredSample.max { $0.tipHalfWindow < $1.tipHalfWindow }
    print(String(format: "   %@ diagnosis: %d measured, widest tip half-window %.4f m, %d with at least %.4f, %d of those keep the other checks",
                 id, measuredSample.count, widest?.tipHalfWindow ?? 0, roomy.count, leastTipHalfWindow,
                 kept.filter { $0 }.count))
    if let w = widest { print("   widest: \(w.strike)") }
}

/// Prints what the app needs beside a re-authored raised-cue trick: the strike and windows (report), the side window
/// walked from the answer, the run of offered angles that still makes it (for the comment and the judge's cue-angle
/// band), and the three checks the shot is kept on.
func reportOnOfferedAngle(_ a: Authored) {
    report(a)
    let side = halfWidth(tipSideBand(a.layout, a.strike, a.goal), around: a.strike.tipSide)
    let deg = Int((asin(a.strike.elevation) * 180 / Double.pi).rounded())
    print(String(format: "   APP: AuthoredStrike(aim: %.2f, power: %.2f, tipUp: %.4f, tipSide: %.4f, elevation: sine(forAngle: %d))",
                 a.strike.aim, a.strike.power, a.strike.tipUp, a.strike.tipSide, deg))
    print(String(format: "   APP: AuthoredWindow(aim: %.2f, power: %.2f, tipUp: %.4f, tipSide: %.4f)", a.aimHalfWindow,
                 a.powerHalfWindow, a.tipHalfWindow, side))
    if let band = cueAngleBand(a.layout, a.strike, a.goal) {
        print("   OFFERED ANGLES THAT MAKE IT: \(band.lo) to \(band.hi) degrees")
    }
    var level = a.strike; level.elevation = 0
    print("   level cue: " + trickOutcome(a.goal, simulate(a.layout, level)))
    if a.strike.tipUp != 0 { var s = a.strike; s.tipUp = 0; print("   no draw or follow: " + trickOutcome(a.goal, simulate(a.layout, s))) }
    if a.strike.tipSide != 0 { var s = a.strike; s.tipSide = 0; print("   no side: " + trickOutcome(a.goal, simulate(a.layout, s))) }
}

// MARK: Driver

/// Authors every shot (or only the ids named) and prints each report.
func runTrickAuthoring(only: Set<String>) {
    // 0.7.5: the raised-cue tricks on the cue-angle menu's own angles ("BreakProbe tricks masse-offered jump-offered
    // draw-masse-carom"). Run only when named, so a bare "tricks" keeps doing what it always did.
    let offered: [(String, String)] = [("masse-offered", "masse-curve"), ("jump-offered", "jump-over"),
                                       ("draw-masse-carom", "draw-masse-carom")]
    for (name, id) in offered where only.contains(name) {
        let start = Date()
        if let a = authorOnOfferedAngle(id) { reportOnOfferedAngle(a) } else { print("== \(id): NO SOLUTION ON AN OFFERED ANGLE") }
        print(String(format: "   (search took %.1f s)", Date().timeIntervalSince(start)))
    }
    if !only.isEmpty && only.isSubset(of: Set(offered.map(\.0))) { return }
    let all: [(String, () -> Authored?)] = [
        ("called-break-short", authorCalledBreakShort),
        ("stop-dead", authorStopDead),
        ("bridge-draw", authorBridgeDraw),
        ("follow-train", authorFollowTrain),
        ("two-rail-kick", authorTwoRailKick),
        ("cross-bank", authorCrossBank),
        ("combo-chain", authorComboChain),
        ("throw-it", authorThrowIt),
        ("masse-curve", authorMasse),
        ("jump-over", authorJump),
        ("squirt", authorSquirt),
        ("side-off-rail", authorSideOffRail),
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
