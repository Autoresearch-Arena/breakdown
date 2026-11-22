// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: "BreakProbe tricks near [id ...]": re-authors the trick shots and lessons the app carries on the default
//          physics (generation two since the proof plan's package 4), keeping every layout and goal and searching only
//          the strike, near the old answer. A shot that still passes keeps its strike and only has its windows measured
//          again, walked outward from that very strike. A shot that fails gets a grid around its old answer (aim either
//          side, power from a little softer to much harder, because an off-centre hit now launches slower, tip height a
//          few millimetres either way, side and cue elevation where the shot uses them), with every tip inside the
//          miscue limit (tipReach), and the same choice as the first authoring (TrickAuthoring.best: sturdy against
//          small slips, then re-centred in its windows by TrickSearch.measured, then the window that fits the shot's
//          difficulty). Each result prints the strike and the app's TrickWindow half-widths, ready for App/TrickShots.swift,
//          App/Lessons/Lessons.swift and the copies in ContentVerify.swift.
//          "BreakProbe surfaces" runs the eleven real-table checks on each playing surface's numbers (copied from
//          App/PlaySurface.swift, KEEP IN STEP), so a retune of the default can be checked against the surfaces.
// SRP/DRY check: Pass - the near grid and the per-shot extra checks only; simulation, goals, windows and the choice are
//          TrickSearch's and TrickAuthoring's, the shots are ContentVerify's copies, the checks RealWorldCases'.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation

/// How each authored shot was chosen the first time: its difficulty (for the window band) and any extra condition the
/// first search kept it on (a level cue must miss for the curves and jumps, a centre tip must miss for follow and draw).
private func nearRules(_ id: String) -> (Difficulty, (@Sendable (Authored) -> Bool)?) {
    let levelMisses: @Sendable (Authored) -> Bool = { a in
        var level = a.strike; level.elevation = 0
        return !passes(a.goal, simulate(a.layout, level))
    }
    let centreMisses: @Sendable (Authored) -> Bool = { a in
        var centre = a.strike; centre.tipUp = 0
        return !passes(a.goal, simulate(a.layout, centre))
    }
    // Throw It In: the side spin and the friction between the balls must be what makes it (TrickShots.swift).
    let throwNeeded: @Sendable (Authored) -> Bool = { a in
        var plain = a.strike; plain.tipSide = 0
        var slick = P; slick.ballBallFrictionFloor = 0; slick.ballBallFrictionGain = 0
        return !passes(a.goal, simulate(a.layout, plain)) && !passes(a.goal, simulate(a.layout, a.strike, parameters: slick))
    }
    // The carom: levelling the cue, removing the draw or removing the side each misses (TrickShots.swift).
    let caromNeedsAll: @Sendable (Authored) -> Bool = { a in
        var noDraw = a.strike; noDraw.tipUp = 0
        var noSide = a.strike; noSide.tipSide = 0
        return levelMisses(a) && !passes(a.goal, simulate(a.layout, noDraw)) && !passes(a.goal, simulate(a.layout, noSide))
    }
    switch id {
    case "called-break", "bridge-draw", "two-rail-kick", "combo-chain": return (.hard, nil)
    case "masse-curve": return (.hard, levelMisses)
    case "draw-masse-carom": return (.hard, caromNeedsAll)
    case "throw-it": return (.medium, throwNeeded)
    case "follow-train", "cross-bank": return (.medium, nil)
    case "jump-over": return (.medium, levelMisses)
    case "lesson-follow", "lesson-draw": return (.easy, centreMisses)
    case "lesson-curve":
        // The lesson teaches side: its side window must be one a player can find (2 mm either way), and two
        // neighbouring cue angles must work, as for the jump.
        return (.easy, { a in
            guard levelMisses(a), let band = cueAngleBand(a.layout, a.strike, a.goal), band.lo < band.hi else { return false }
            return halfWidth(tipSideBand(a.layout, a.strike, a.goal), around: a.strike.tipSide) >= 0.002
        })
    case "lesson-jump":
        return (.easy, { a in
            guard levelMisses(a), let band = cueAngleBand(a.layout, a.strike, a.goal) else { return false }
            return band.lo < band.hi
        })
    default: return (.easy, nil)
    }
}

/// The grid around an old answer. Lessons that raise the cue stay on the cue angles the app offers.
private func nearGrid(_ t: AuthoredTrick) -> [Strike] {
    let old = t.strike
    let curve = old.elevation > 0 && old.tipSide != 0
    let lesson = t.id.hasPrefix("lesson")
    let aims: [Double]
    if t.id == "called-break" { aims = range(old.aim - 0.6, old.aim + 0.6, 0.01) }
    else if curve { aims = range(old.aim - 14, old.aim + 14, 0.25) }
    else { aims = range(old.aim - 3, old.aim + 3, 0.05) }
    let powerStep = max(0.05, (old.power * 0.05 / 0.05).rounded() * 0.05)
    let powers = range(max(0.5, old.power * 0.8), min(8, old.power * 1.6), powerStep)
    // Tip height: the old one pulled inside the grip, and a few millimetres either way.
    let up0 = max(-0.95 * tipReach, min(0.95 * tipReach, old.tipUp))
    var ups = [up0 - 0.004, up0 - 0.002, up0, up0 + 0.002, up0 + 0.004].map { ($0 / 0.0005).rounded() * 0.0005 }
    if old.tipUp == 0 && !curve { ups = [-0.002, 0, 0.002] }
    var sides: [Double] = [0]
    if lesson && curve {
        // The curve lesson: a wider spread of moderate side and draw, all well inside the grip, so the side window has
        // room either way.
        ups = [0, -0.002, -0.004, -0.006, -0.008]
        sides = [0.006, 0.008, 0.010, 0.012]
    } else if old.tipSide != 0 {
        let sign: Double = old.tipSide < 0 ? -1 : 1
        let m = min(abs(old.tipSide), 0.95 * tipReach)
        sides = [m, m - 0.002, m - 0.004].filter { $0 > 0 }.map { sign * ($0 / 0.0005).rounded() * 0.0005 }
    }
    var elevations: [Double] = [old.elevation]
    if old.elevation > 0 {
        if lesson {
            elevations = offeredCueAngles.filter { $0 > 0 }.map { sineOf(degrees: $0) }
                .filter { abs($0 - old.elevation) <= 0.2 }
        } else {
            elevations = range(max(0.1, old.elevation - 0.1), min(0.95, old.elevation + 0.2), 0.05)
        }
    }
    var out: [Strike] = []
    for el in elevations { for ts in sides { for tu in ups where insideGrip(up: tu, side: ts) {
        for p in powers { for a in aims { out.append(Strike(aim: a, power: p, tipUp: tu, tipSide: ts, elevation: el)) } }
    } } }
    return out
}

/// The app's TrickWindow half-widths for an authored shot, walked from its exact strike (no re-centring).
private func appWindow(_ a: Authored) -> String {
    let side = halfWidth(tipSideBand(a.layout, a.strike, a.goal), around: a.strike.tipSide)
    return String(format: "TrickWindow(aim: %.2f, power: %.2f, tipUp: %.4f, tipSide: %.4f)", a.aimHalfWindow,
                  a.powerHalfWindow, a.tipHalfWindow, side)
}

private func settingsLine(_ s: Strike) -> String {
    let el = s.elevation > 0 ? String(format: ", elevation: %.2f", s.elevation) : ""
    return String(format: "TrickSettings(aim: %.2f, power: %.2f, tipUp: %.4f, tipSide: %.4f%@)", s.aim, s.power,
                  s.tipUp, s.tipSide, el)
}

/// Windows walked from the exact strike, for a shot that still passes.
private func measuredInPlace(_ t: AuthoredTrick) -> Authored? {
    guard let a = aimBand(t.layout, t.strike, t.goal), let p = powerBand(t.layout, t.strike, t.goal),
          let u = tipUpBand(t.layout, t.strike, t.goal) else { return nil }
    return Authored(id: t.id, layout: t.layout, strike: t.strike, goal: t.goal, aimBand: a, powerBand: p, tipBand: u,
                    note: "unchanged strike, windows walked again on the default physics")
}

func runNearReauthor(only requested: Set<String>) {
    // "force" searches near the old answer even when the old strike still passes.
    let force = requested.contains("force")
    let only = requested.subtracting(["force"])
    let all = authoredTricks + authoredLessons
    print("== re-author near the old answers on the default physics (generation \(P.modelGeneration)); tip reach "
          + String(format: "%.4f m", tipReach))
    for t in all where only.isEmpty || only.contains(t.id) {
        let start = Date()
        let tl = simulate(t.layout, t.strike)
        let still = insideGrip(up: t.strike.tipUp, side: t.strike.tipSide) && trickFailure(t.goal, tl) == nil
        let (difficulty, extra) = nearRules(t.id)
        var found: Authored?
        if !force, still, let a = measuredInPlace(t), extra.map({ $0(a) }) ?? true {
            // Kept as it is when it still sits well inside its windows; when the new physics has moved it to the edge
            // of one (a half-width under half the difficulty's least aim window, or under a third of what a player can
            // hold in power or tip), re-centred in its windows from the old strike instead.
            let roomy = a.aimHalfWindow >= difficulty.band.lowerBound / 2 && a.feelScore >= 0.34
            if roomy {
                print("#### \(t.id): still passes with its old strike")
                found = a
            } else if let c = measured(t.id, t.layout, t.strike, t.goal, note: "re-centred from the old strike"),
                      extra.map({ $0(c) }) ?? true {
                print(String(format: "#### %@: still passes but sits at the edge (aim half %.2f, feel %.2f); re-centred",
                             t.id, a.aimHalfWindow, a.feelScore))
                found = c
            } else {
                print("#### \(t.id): still passes but sits at the edge and does not re-centre; kept as it is")
                found = a
            }
        } else {
            let why = force && still ? "still passes; searching anyway (force)"
                : (still ? "passes but fails its extra condition" : (trickFailure(t.goal, tl) ?? "tip past the grip"))
            print("#### \(t.id): \(why); searching near \(t.strike)")
            let grid = nearGrid(t)
            let cands = grid.map { Candidate(layout: t.layout, strike: $0, goal: t.goal, note: "near the old answer") }
            found = best(t.id, cands, difficulty, extra: extra)
        }
        guard let a = found else { print("== \(t.id): NO SOLUTION NEAR THE OLD ANSWER"); continue }
        report(a)
        print("   APP: solution: \(settingsLine(a.strike))")
        print("   APP: window: \(appWindow(a))")
        if a.strike.elevation > 0, a.id.hasPrefix("lesson"), let e = cueAngleBand(a.layout, a.strike, a.goal) {
            print("   LESSON CUE ANGLES: \(e.lo) to \(e.hi) degrees work")
        }
        if a.strike.elevation > 0 {
            if let e = band(centre: a.strike.elevation, step: 0.01, limit: 0.3, { v in
                v > 0.05 && v <= 0.95 && { var s = a.strike; s.elevation = v; return passes(a.goal, simulate(a.layout, s)) }()
            }) {
                print(String(format: "   elevation sine %.2f to %.2f (%.1f to %.1f deg)", e.lo, e.hi,
                             asin(e.lo) * 180 / .pi, asin(e.hi) * 180 / .pi))
            }
        }
        print(String(format: "   (took %.1f s)", Date().timeIntervalSince(start)))
    }
}

// MARK: Surfaces

/// The playing surfaces' numbers, copied from PlaySurface.apply (App/PlaySurface.swift). KEEP IN STEP.
let probeSurfaces: [(name: String, apply: @Sendable (inout PoolParameters) -> Void)] = [
    ("cloth", { _ in }),
    ("tournament", { EBCloth.tournament.apply(to: &$0) }),
    ("diveBar", { EBCloth.diveBar.apply(to: &$0) }),
    ("ice", { $0.slidingFriction = 0.025; $0.rollingResistance = 0.002; $0.spinDecay = 2.0; $0.slateFriction = 0.03 }),
    ("glass", { $0.slidingFriction = 0.09; $0.rollingResistance = 0.0025; $0.spinDecay = 3.0
                $0.slateRestitution = 0.7; $0.slateFriction = 0.1 }),
    ("rubber", { $0.slidingFriction = 0.8; $0.rollingResistance = 0.02; $0.spinDecay = 12.0
                 $0.slateRestitution = 0.75; $0.slateFriction = 0.8 }),
    ("cork", { $0.slidingFriction = 0.45; $0.rollingResistance = 0.03; $0.spinDecay = 15.0
               $0.slateRestitution = 0.3; $0.slateFriction = 0.45 }),
    ("carpet", { $0.slidingFriction = 0.3; $0.rollingResistance = 0.035; $0.spinDecay = 14.0 }),
    ("sand", { $0.slidingFriction = 0.5; $0.rollingResistance = 0.13; $0.spinDecay = 25.0
               $0.slateRestitution = 0.15; $0.slateFriction = 0.5 }),
    ("moon", { $0.gravity = 1.62 }),
]

func runSurfaceCheck() {
    print("== the eleven real-table checks on each surface (default physics, generation \(P.modelGeneration))")
    for s in probeSurfaces {
        var q = PoolParameters()
        s.apply(&q)
        let results = rwCases.map { $0.run(q) }
        print("#### \(s.name): \(results.filter(\.passed).count) of \(rwCases.count) bands")
        for (c, o) in zip(rwCases, results) { print("   \(c.number) \(c.name): \(o.passed ? "pass" : "FAIL") - \(o.note)") }
    }
}

// MARK: Behind the 8-Ball, near the old strokes

/// "BreakProbe eightball near [situation ...]": every escape the app carries (ebFinal), on its own situation and cloth
/// and the default physics. One that still passes keeps its stroke and has its windows walked again from it ("eightball
/// verify" prints the same lines); one that fails is searched again on a grid around its old stroke with the escape's
/// own technique test (EightBallAuthoring.ebSearch with the grid narrowed to the neighbourhood), so the route the card
/// describes stays the same wherever the physics allows.
func runEightBallNear(only: Set<String>) {
    print("== Behind the 8-Ball escapes near their old strokes on the default physics (generation \(P.modelGeneration))")
    for f in ebFinal where only.isEmpty || only.contains(f.situation) {
        guard let s = ebSituations.first(where: { $0.id == f.situation }),
              let e = s.escapes.first(where: { $0.id == f.escape }) else { print("?? \(f.situation) \(f.escape)"); continue }
        let start = Date()
        let old = f.strike
        if insideGrip(up: old.tipUp, side: old.tipSide), ebPasses(s, e, old) {
            print("#### \(f.situation) \(f.escape): still passes with its old stroke")
            continue
        }
        print("#### \(f.situation) \(f.escape): \(ebWhy(s, e, old)); searching near \(old)")
        var near = e
        let curve = e.technique == .curve
        near.aimAround = curve ? (old.aim, 14, 0.25) : (old.aim, 3, 0.02)
        near.aimRelative = false
        near.powers = range(max(0.4, old.power * 0.8), min(7.5, old.power * 1.6), max(0.05, (old.power * 0.05 / 0.05).rounded() * 0.05))
        let up0 = max(-0.95 * tipReach, min(0.95 * tipReach, old.tipUp))
        near.tipUps = curve ? [up0, up0 + 0.002, up0 - 0.002].map { ($0 / 0.0005).rounded() * 0.0005 }
                            : range(up0 - 0.004, up0 + 0.004, 0.002).map { ($0 / 0.0005).rounded() * 0.0005 }
        if old.tipSide != 0 {
            let sign: Double = old.tipSide < 0 ? -1 : 1
            let m = min(abs(old.tipSide), 0.95 * tipReach)
            near.tipSides = [m, m - 0.002, m - 0.004].filter { $0 > 0 }.map { sign * ($0 / 0.0005).rounded() * 0.0005 }
        } else { near.tipSides = [0] }
        near.elevations = old.elevation > 0 ? range(max(0.1, old.elevation - 0.1), min(0.95, old.elevation + 0.15), 0.05) : [0]
        // Kicks re-centre on aim only once their run is found, so keep the power grid coarse enough to finish.
        if !curve && e.technique != .jump { near.powers = Swift.stride(from: 0, to: near.powers.count, by: 2).map { near.powers[$0] } }
        // Every grid point must sit inside the grip.
        near.tipUps = near.tipUps.filter { u in near.tipSides.contains { insideGrip(up: u, side: $0) } }
        if let r = ebSearch(s, near) {
            ebReport(s, e, r)
            if !insideGrip(up: r.strike.tipUp, side: r.strike.tipSide) { print("   WARNING: the stroke is past the grip") }
        } else { print("== \(s.id) escape \(e.id): NO SOLUTION NEAR THE OLD STROKE") }
        print(String(format: "   (took %.1f s)", Date().timeIntervalSince(start)))
    }
}
