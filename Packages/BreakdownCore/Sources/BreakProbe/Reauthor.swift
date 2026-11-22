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
//          App/Lessons/Lessons.swift (since item 38 of the bug plan after 0.6.6: for the package library,
//          AuthoredTricks.swift and AuthoredLessons.swift, which the app and the content check both read).
//          "BreakProbe surfaces" runs the real-table checks on each playing surface's numbers (the package's
//          TableSurface, the numbers the app plays on), so a retune of the default can be checked against the surfaces.
// Edited: Claude Opus 5.5 High, 21-November-2026 (bug plan after 0.6.6, item 38: the shots and the surfaces are read
//          from the package library instead of copies.)
// SRP/DRY check: Pass - the near grid and the per-shot extra checks only; simulation, goals, windows and the choice are
//          TrickSearch's and TrickAuthoring's, the shots the package library's (through ContentVerify), the checks
//          RealWorldCases'.
import BreakdownAuthored
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
private func nearGrid(_ t: ProbeShot) -> [Strike] {
    let old = t.strike
    let curve = old.elevation > 0 && old.tipSide != 0
    let lesson = t.id.hasPrefix("lesson")
    let aims: [Double]
    // The called break: the coupled rail of item 26 moved the old answer out of a narrow search, so the aim is swept two
    // and a half degrees either way and the power from a soft to a hard break (the rack's outcome is chaotic in both).
    if t.id == "called-break" { aims = range(old.aim - 2.5, old.aim + 2.5, 0.02) }
    else if curve { aims = range(old.aim - 14, old.aim + 14, 0.25) }
    else { aims = range(old.aim - 3, old.aim + 3, 0.05) }
    let powerStep = max(0.05, (old.power * 0.05 / 0.05).rounded() * 0.05)
    let powers = t.id == "called-break" ? range(4.0, 9.0, 0.25)
        : range(max(0.5, old.power * 0.8), min(8, old.power * 1.6), powerStep)
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
private func measuredInPlace(_ t: ProbeShot) -> Authored? {
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

// MARK: The called break, from a new cue position

/// "BreakProbe tricks break": the called break re-laid (bug plan after 0.6.6). On the 0.7.0 physics no stroke near the
/// old answer dropped the 3 in the top-right corner in a band a player can repeat (26,355 strokes, 309 made it, none
/// survived the sturdiness screen), so the cue ball's starting spot is searched instead, keeping the rack, the ball and
/// the pocket the card names. For each spot on a grid behind the head string, every power and tip on a small grid and
/// aims across the front ball in fiftieths of a degree, the longest unbroken run of aims in which the 3 drops in the
/// top-right corner (front ball first, cue ball up) is found; the widest runs are measured like every other shot and
/// the one that fits a hard shot's window band is kept.
func runCalledBreakRelay() {
    guard let old = authoredTricks.first(where: { $0.id == "called-break" }) else { return }
    let goal = old.goal
    struct Run: Sendable { var cue: Vec2; var power: Double; var tip: Double; var gap: Double; var lo: Double; var hi: Double }
    // A first run (21-Nov-2026) on the half-millimetre rack found nothing wider than 0.08 degrees from 28 spots, so the
    // gap between the three rows' balls is searched too: a wider gap makes the break a chain of separate contacts rather
    // than one squeeze, which is less sensitive to the aim.
    var spots: [Vec2] = []
    for x in [0.45, 0.635, 0.75] { for y in [0.30, 0.435, 0.635, 0.85] { spots.append(Vec2(x, y)) } }
    struct Config: Sendable { var cue: Vec2; var power: Double; var tip: Double; var gap: Double }
    var configs: [Config] = []
    for g in [0.001, 0.002, 0.003, 0.005] { for c in spots { for p in [6.0, 7.0, 8.0] { for t in [-0.004, 0.0, 0.004] {
        configs.append(Config(cue: c, power: p, tip: t, gap: g))
    } } } }
    @Sendable func rack(_ c: Config) -> [Vec2] {
        var spaced = P
        spaced.rackGap = c.gap
        let full = Rack.positions(parameters: spaced, seed: 3)
        var lay = old.layout
        for b in [1, 9, 2, 10, 8, 3] { lay[b] = full[b] }
        lay[0] = c.cue
        return lay
    }
    let aims = range(-1.5, 1.5, 0.02)
    let settings = configs                       // a constant, so the worker threads can share it
    print("== called break re-laid: \(settings.count) spot, power and tip settings, \(aims.count) aims each")
    let runs = parallelMap(settings.count) { i -> Run? in
        let c = settings[i]
        let lay = rack(c)
        let base = degrees(of: unit(lay[1] - c.cue))
        var bestRun: Run?
        var start: Double?
        for (j, da) in aims.enumerated() {
            let ok = passes(goal, simulate(lay, Strike(aim: base + da, power: c.power, tipUp: c.tip, tipSide: 0)))
            if ok, start == nil { start = base + da }
            if (!ok || j == aims.count - 1), let s0 = start {
                let hi = ok ? base + da : base + aims[j - 1]
                if bestRun == nil || hi - s0 > bestRun!.hi - bestRun!.lo { bestRun = Run(cue: c.cue, power: c.power, tip: c.tip, gap: c.gap, lo: s0, hi: hi) }
                start = nil
            }
        }
        return bestRun
    }.compactMap { $0 }.sorted { ($0.hi - $0.lo) > ($1.hi - $1.lo) }
    for r in runs.prefix(10) {
        print(String(format: "   rack gap %.1f mm, cue at %@, %.1f m/s, tip %+.3f: aims %.2f to %.2f", r.gap * 1000, fmt(r.cue),
                     r.power, r.tip, r.lo, r.hi))
    }
    let top = Array(runs.prefix(8))
    let measuredRuns = parallelMap(top.count) { i -> Authored? in
        let r = top[i]
        let lay = rack(Config(cue: r.cue, power: r.power, tip: r.tip, gap: r.gap))
        return measured("called-break", lay, Strike(aim: (r.lo + r.hi) / 2, power: r.power, tipUp: r.tip, tipSide: 0), goal,
                        note: String(format: "the called break from %@", fmt(r.cue)))
    }.compactMap { $0 }
    guard let a = choose(measuredRuns, .hard) else { print("== called-break: NO SOLUTION"); return }
    report(a)
    print("   APP: solution: TrickSettings(aim: \(String(format: "%.2f", a.strike.aim)), power: \(String(format: "%.2f", a.strike.power)), tipUp: \(String(format: "%.4f", a.strike.tipUp)), tipSide: 0)")
    let side = halfWidth(tipSideBand(a.layout, a.strike, a.goal), around: a.strike.tipSide)
    print(String(format: "   APP: window: aim %.2f, power %.2f, tipUp %.4f, tipSide %.4f", a.aimHalfWindow, a.powerHalfWindow,
                 a.tipHalfWindow, side))
}

// MARK: Surfaces

func runSurfaceCheck() {
    print("== the real-table checks on each surface (default physics, generation \(P.modelGeneration))")
    for s in TableSurface.allCases {
        let q = s.parameters
        let results = rwCases.map { $0.run(q) }
        print("#### \(s.rawValue): \(results.filter(\.passed).count) of \(rwCases.count) bands")
        for (c, o) in zip(rwCases, results) { print("   \(c.number) \(c.name): \(o.passed ? "pass" : "FAIL") - \(o.note)") }
    }
}

// MARK: Behind the 8-Ball, near the old strokes

/// "BreakProbe eightball near [situation ...]": every escape the app carries (ebFinal), on its own situation and cloth
/// and the default physics. One that still passes keeps its stroke and has its windows walked again from it ("eightball
/// verify" prints the same lines); one that fails is searched again on a grid around its old stroke with the escape's
/// own technique test (EightBallAuthoring.ebSearch with the grid narrowed to the neighbourhood), so the route the card
/// describes stays the same wherever the physics allows.
/// The escape's search narrowed to the neighbourhood of an old stroke: aim four degrees either way (a curve fourteen),
/// power from a little softer to much harder, tip heights a few millimetres either way, the old side and a little less,
/// and the cue a little lower or higher; every grid point inside the grip.
func ebNearSpec(_ e: EBEscapeSpec, _ old: Strike) -> EBEscapeSpec {
    var near = e
    let curve = e.technique == .curve
    near.aimAround = curve ? (old.aim, 14, 0.25) : (old.aim, 4, 0.02)
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
    return near
}

/// "BreakProbe eightball relay [situation ...]" (bug plan after 0.6.6, item 30): re-lays a situation whose escapes
/// cannot all be given an aim window of one aim step where the balls are. The ball the escapes call (the same ball for
/// every escape of a situation, or the ball a safety must touch) is moved in tenths of a diamond, up to three tenths
/// either way along the table and across it (0.15, 0.3 and 0.45 of a diamond); a ball frozen to a rail stays frozen,
/// moving only along that rail. For each place every escape of the situation is searched near its old stroke
/// (ebNearSpec, aim in twenty-fifths of a degree to keep each place quick), and the place is kept only when every escape
/// passes with an aim window of one aim step or more (ebSearch itself prefers two). Places are tried nearest first, so the first that
/// works is the smallest move; it is reported with each escape's stroke, and the hook is checked again there: no legal
/// ball may be made by a level straight stroke with no rail first.
/// With "cue" the cue ball is moved instead of the called ball (its place is in no story), and the escapes are tried
/// narrowest first, so a place that cannot widen the hard one is left after one search.
func runEightBallRelay(only: Set<String>, moveCue: Bool = false) {
    print("== Behind the 8-Ball situations re-laid for aim windows of one aim step (item 30)\(moveCue ? ", moving the cue ball" : "")")
    for a in AuthoredEscapes.all where only.isEmpty || only.contains(a.id) {
        let start = Date()
        let base = ebSpec(a)
        guard let calledBall = a.escapes.compactMap({ $0.call.ball ?? $0.touchBall }).first else { continue }
        let called = moveCue ? 0 : calledBall
        let home: (Double, Double) = called == 0 ? base.cue : (called == 8 ? base.eight : (base.balls[called] ?? base.eight))
        // The narrowest escape first (its window where the balls are now).
        let order = a.escapes.indices.sorted { i, j in
            let wi = ebAimWindow(base, base.escapes[i], probeStrike(a.escapes[i].strike)).map { $0.hi - $0.lo } ?? 0
            let wj = ebAimWindow(base, base.escapes[j], probeStrike(a.escapes[j].strike)).map { $0.hi - $0.lo } ?? 0
            return wi < wj
        }
        // Frozen to a rail: within a twentieth of a diamond of across 0 or 4 (a long rail) or along 0 or 8 (an end).
        let onLongRail = home.0 < 0.15 || home.0 > 3.85
        let onEnd = home.1 < 0.15 || home.1 > 7.85
        var places: [(Double, Double)] = []
        for dAlong in [-0.45, -0.3, -0.15, 0.0, 0.15, 0.3, 0.45] { for dAcross in [-0.45, -0.3, -0.15, 0.0, 0.15, 0.3, 0.45] {
            if onLongRail && dAcross != 0 { continue }
            if onEnd && dAlong != 0 { continue }
            places.append((home.0 + dAcross, home.1 + dAlong))
        } }
        places.sort { abs($0.0 - home.0) + abs($0.1 - home.1) < abs($1.0 - home.0) + abs($1.1 - home.1) }
        print("#### \(a.id): the \(called) from across \(home.0), along \(home.1); \(places.count) places")
        var kept: (place: (Double, Double), results: [EBResult], narrowest: Double)?
        for place in places {
            var s = base
            if called == 0 { s.cue = place } else if called == 8 { s.eight = place } else { s.balls[called] = place }
            let lay = s.layout
            let p = lay[called]
            guard clearOfRails(p, margin: 0.0, pocketClear: 0.06),
                  !lay.enumerated().contains(where: { $0.offset != called && NextShot.isOnTable($0.element)
                                                       && ($0.element - p).length < 2 * R + 0.001 }) else { continue }
            var found: [Int: EBResult] = [:]
            for i in order {
                let e = s.escapes[i], ae = a.escapes[i]
                var near = ebNearSpec(e, probeStrike(ae.strike))
                if let a0 = near.aimAround, e.technique != .curve { near.aimAround = (a0.0, a0.1, 0.04) }
                guard let r = ebSearch(s, near),
                      let w = ebAimWindow(s, e, r.strike), w.hi - w.lo >= ebAimStep - 1e-9 else { break }
                found[i] = r
            }
            let ok = found.count == a.escapes.count
            let results = a.escapes.indices.compactMap { found[$0] }
            let narrowest = results.map { $0.aim.hi - $0.aim.lo }.min() ?? 0
            print(String(format: "   place across %.2f along %.2f: %@", place.0, place.1,
                         ok ? String(format: "every escape at least one aim step (narrowest %.2f)", narrowest) : "not every escape"))
            // Places are tried nearest first, so the first that works is the smallest move: kept.
            if ok { kept = (place, results, narrowest); break }
        }
        guard let f = kept else { print("== \(a.id): NO PLACE FOUND"); continue }
        var s = base
        if called == 0 { s.cue = f.place } else if called == 8 { s.eight = f.place } else { s.balls[called] = f.place }
        print(String(format: "== %@: the %d moved to across %.2f, along %.2f", a.id, called, f.place.0, f.place.1))
        let direct = directMakes(s)
        print("   hook there: \(direct.count) direct makes\(direct.isEmpty ? "" : ": " + direct.prefix(6).joined(separator: "; "))")
        for (e, r) in zip(s.escapes, f.results) { ebReport(s, e, r) }
        print(String(format: "   (took %.1f s)", Date().timeIntervalSince(start)))
    }
}

/// "BreakProbe eightball wide <situation> <escape> [maxRails]" (bug plan after 0.6.6, item 30): when neither the old
/// stroke's neighbourhood nor a re-laid table gives a kick an aim window of one aim step, the kick is searched as it
/// was first authored: every aim round the full circle in tenths of a degree, powers 1 to 5 m/s, five tip heights, and
/// any number of rails before contact from one to `maxRails` (default 3), so another route can be found. The card's
/// words describe the route, so a new route needs new words.
func runEightBallWide(_ args: [String]) {
    guard args.count >= 2, let a = AuthoredEscapes.situation(id: args[0]), a.escape(args[1]) != nil else {
        print("usage: eightball wide <situation> <escape> [maxRails]"); return
    }
    let maxRails = args.count > 2 ? Int(args[2]) ?? 3 : 3
    let s = ebSpec(a)
    guard let e = s.escapes.first(where: { $0.id == args[1] }), let ball = e.ball, let pocket = e.pocket else { return }
    // A bank keeps its own test (the called ball off a rail); its cue ball may kick first, from no rail up.
    let wide = e.technique == .bank ? ebBank(e.id, ball, pocket, rails: 0...maxRails)
                                    : ebKick(e.id, ball, pocket, rails: 1...maxRails)
    print("== \(a.id) \(e.id): full-circle \(e.technique.rawValue) search, up to \(maxRails) rails")
    if let r = ebSearch(s, wide) { ebReport(s, wide, r) } else { print("== \(a.id) \(e.id): NO SOLUTION") }
}

func runEightBallNear(only: Set<String>) {
    print("== Behind the 8-Ball escapes near their old strokes on the default physics (generation \(P.modelGeneration))")
    for f in ebFinal where only.isEmpty || only.contains(f.situation) {
        guard let s = ebAuthored.first(where: { $0.id == f.situation }),
              let e = s.escapes.first(where: { $0.id == f.escape }) else { print("?? \(f.situation) \(f.escape)"); continue }
        let start = Date()
        let old = f.strike
        // Kept when it still passes with an aim window of two aim steps or more (item 30); otherwise searched again.
        if insideGrip(up: old.tipUp, side: old.tipSide), ebPasses(s, e, old) {
            if let w = ebAimWindow(s, e, old), w.hi - w.lo >= 2 * ebAimStep - 1e-9 {
                print(String(format: "#### %@ %@: still passes with its old stroke, aim window %.2f degrees wide",
                             f.situation, f.escape, w.hi - w.lo))
                continue
            }
            print("#### \(f.situation) \(f.escape): passes, but its aim window is under two aim steps; searching again")
        }
        print("#### \(f.situation) \(f.escape): \(ebWhy(s, e, old)); searching near \(old)")
        let near = ebNearSpec(e, old)
        if let r = ebSearch(s, near) {
            ebReport(s, e, r)
            if !insideGrip(up: r.strike.tipUp, side: r.strike.tipSide) { print("   WARNING: the stroke is past the grip") }
        } else { print("== \(s.id) escape \(e.id): NO SOLUTION NEAR THE OLD STROKE") }
        print(String(format: "   (took %.1f s)", Date().timeIntervalSince(start)))
    }
}
