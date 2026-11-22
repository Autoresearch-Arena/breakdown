// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: Authors the Behind the 8-Ball situations with the real solver (run "BreakProbe eightball [s1 s2 ...]").
//          Each situation is a full eight-ball table in progress written in diamonds exactly as the app's
//          EightBallTable.point does (across 0 left rail to 4 right rail, along 0 head to 8 foot; metres = along x D,
//          (4 - across) x D). For every situation it first proves the hook: a sweep of level, straight strokes all the
//          way round must not make any legal ball in any pocket without a rail first. Then, for each authored escape,
//          it sweeps aim (and power, tip, elevation as the escape needs) at a grid, keeps the strokes that are LEGAL and
//          MADE AS CALLED (cue ball neither pocketed nor off the table, the first ball struck is one of yours, or the 8
//          when you are on it, the called ball in the called pocket, the 8 not pocketed unless it was called, no object
//          ball off the table, a rail or a pocket after contact, the cue stick clear of every other ball at the strike),
//          that also show the escape's technique (rails before contact for kicks, a take-off for jumps, a curve that a
//          level cue cannot copy for massés and swerves, the called ball off a rail for banks), picks the centre of the
//          longest unbroken aim run, re-centres it in its aim, power and tip windows and prints the stroke and every
//          measured window, ready for App/EightBall/EightBallSituations.swift. A safety escape instead needs a legal hit,
//          nothing pocketed, and the opponent left with no straight line from the cue ball to the centre of any of their
//          balls. "eightball verify" re-checks the exact strokes the app carries (ebFinal, at the end) and prints, for
//          the "On a real table" cards, every cushion the cue ball takes before its first ball, in diamonds.
//          The situation list keeps the search rounds: the design's layout first, then the reworked layouts (tucked2,
//          bend2/bend3, kick-game-db, kick-bank2, swerve2, no-way2/no-way3) where a hook leaked or an escape was
//          knife-edge; ebFinal names the ones the app uses.
//          The cloth numbers for Tournament cloth and Dive-bar felt are COPIED from App/PlaySurface.swift (the app
//          target cannot be imported here); if those change, change them here too and re-run.
// Edited: Claude Opus 5.5 High, 21-November-2026 (a situation carries the physics generation it is solved on, default
//          1, so "BreakProbe verify 2" can re-check every authored escape on generation two; nothing else changes).
// Edited: Claude Opus 5.5 High, 21-November-2026 (proof plan package 4: situations solve on the default generation
//          (two); every tip grid and window stays inside the miscue limit (tipReach); the escapes are re-authored.)
// SRP/DRY check: Pass - situation search only. Simulation, pockets, first-ball and band primitives are reused from
//          TrickSearch.swift; the legality test is new because the trick goal has no "must not drop" (the 8) or
//          "must be one of a group" first hit. The app ships the authored answers; this tool only finds them.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation

// MARK: Table, cloth and units

/// One diamond in metres, the same as EightBallTable.diamond in the app.
let ebDiamond = 2.54 / 8

/// Diamonds to solver metres, identical to EightBallTable.point(across:along:).
func ebPoint(_ across: Double, _ along: Double) -> Vec2 { Vec2(along * ebDiamond, (4 - across) * ebDiamond) }

/// The three cloths a situation can be set on. Numbers copied from PlaySurface.apply (App/PlaySurface.swift).
enum EBCloth: String, Sendable {
    case cloth, tournament, diveBar

    var parameters: PoolParameters {
        var p = PoolParameters()
        apply(to: &p)
        return p
    }

    /// Write this cloth's numbers into `p`, as PlaySurface.apply does.
    func apply(to p: inout PoolParameters) {
        switch self {
        case .cloth: break
        case .tournament:
            p.slidingFriction = 0.15; p.rollingResistance = 0.005; p.spinDecay = 5.0; p.cushionRestitution = 0.95
        case .diveBar:
            p.slidingFriction = 0.3; p.rollingResistance = 0.015; p.spinDecay = 14.0; p.cushionRestitution = 0.8
            p.cushionFriction = 0.22
        }
    }
}

/// Pocket names in the design's words, by the solver's index (EightBallPocket raw values).
let ebPocketNames = ["headRight", "footRight", "headLeft", "footLeft", "rightSide", "leftSide"]

// MARK: What an escape must be

enum EBTechnique: String, Sendable {
    /// Level cue, the cue ball takes `rails` cushions before its first ball.
    case kick
    /// Level cue, the called ball takes a cushion before it drops (the cue ball may kick first).
    case bank
    /// Raised cue, the cue ball leaves the cloth before its first ball; a level cue on the same stroke fails.
    case jump
    /// Raised cue with side: the curve does it; a level cue on the same stroke fails.
    case curve
    /// Call safety: legal hit, a rail after contact, and the opponent left with no straight line to any of theirs.
    case safety
    /// Call safety and just make a legal hit on the named ball with nothing dropping (a kick safety a player can repeat;
    /// whether it also hooks the opponent is reported, not required).
    case touch
}

/// One authored way out and the grid to search it on.
struct EBEscapeSpec: Sendable {
    var id: String
    var technique: EBTechnique
    /// Called ball and pocket (solver index); nil for a safety.
    var ball: Int?
    var pocket: Int?
    /// Cushions the cue ball takes before its first contact (inclusive range).
    var rails: ClosedRange<Int> = 0...9
    /// Aim search: nil sweeps the full circle; otherwise (centre degrees, half range, step). With aimRelative the
    /// centre is an offset from the straight ghost-ball aim at the called ball and pocket.
    var aimAround: (Double, Double, Double)? = nil
    var aimRelative: Bool = false
    var aimStep: Double = 0.2
    var powers: [Double] = [1.6, 2.4, 3.4]
    var tipUps: [Double] = [0]
    var tipSides: [Double] = [0]
    var elevations: [Double] = [0]
    var bridge: Bool = false
}

struct EBSituationSpec: Sendable {
    var id: String
    var number: Int
    var cue: (Double, Double)
    var eight: (Double, Double)
    var balls: [Int: (Double, Double)]
    /// The player's group: "solids" or "stripes".
    var solids: Bool
    var cloth: EBCloth
    var escapes: [EBEscapeSpec]
    /// The physics generation to solve on (PoolParameters.modelGeneration). The default is the solver's default (two
    /// since the proof plan's package 4 re-authored every escape on it); the content check can set 1 to compare.
    var generation: Int = P.modelGeneration

    /// The cloth's numbers on this situation's physics generation (generation one starts from its old numbers).
    var parameters: PoolParameters {
        var p = generationParameters(generation)
        cloth.apply(to: &p)
        return p
    }

    var layout: [Vec2] {
        var out = [Vec2](repeating: NextShot.offTable, count: 16)
        out[0] = ebPoint(cue.0, cue.1)
        out[8] = ebPoint(eight.0, eight.1)
        for (k, v) in balls where k > 0 && k < 16 && k != 8 { out[k] = ebPoint(v.0, v.1) }
        return out
    }
    var group: [Int] { solids ? Array(1...7) : Array(9...15) }
    var opponent: [Int] { solids ? Array(9...15) : Array(1...7) }
    var legal: [Int] {
        let mine = group.filter { NextShot.isOnTable(layout[$0]) }
        return mine.isEmpty ? [8] : mine
    }
}

// MARK: Legality and the technique test

func ebSim(_ s: EBSituationSpec, _ k: Strike) -> Timeline { simulate(s.layout, k, parameters: s.parameters) }

func wentOff(_ ball: Int, _ tl: Timeline) -> Bool {
    tl.events.contains { $0.flight == .offTable && $0.balls.first?.ball == ball }
}

/// Cushions the cue ball took before its first ball contact.
func railsBeforeContact(_ tl: Timeline) -> Int {
    let contact = tl.events.first { $0.kind == .ballBall && $0.balls.contains { $0.ball == 0 } }?.time ?? .infinity
    return tl.events.filter { $0.kind == .cushion && $0.balls.first?.ball == 0 && $0.time < contact }.count
}

/// The cue stick, at the strike, passes clear of every other ball. The cue's axis runs back from the tip's contact
/// point at the stroke's elevation; the stick is treated as a cylinder 6.5 mm in radius at the tip, thickening to about
/// 15 mm over its 1.45 m. Conservative on purpose: a ball near the stick fails the stroke.
func cueClear(_ layout: [Vec2], _ k: Strike) -> Bool {
    let cue = layout[0]
    let e = min(max(k.elevation, 0), 0.995)
    let cosT = (1 - e * e).squareRoot()
    let fwd = k.direction
    let lat = Vec2(-fwd.y, fwd.x)
    // Back along the cue: horizontal component -fwd * cos, vertical + sin.
    let tipBack = (R * R - k.tipSide * k.tipSide - k.tipUp * k.tipUp).squareRoot()
    let p0 = (s: tipBack, l: k.tipSide, h: R + k.tipUp)            // tip contact, in (back, lateral, height)
    for b in 1..<16 where NextShot.isOnTable(layout[b]) {
        let d = layout[b] - cue
        let back = -(d.x * fwd.x + d.y * fwd.y), side = d.x * lat.x + d.y * lat.y
        if back < 0 { continue }
        let v = (s: back - p0.s, l: side - p0.l, h: R - p0.h)
        let t = v.s * cosT + v.h * e
        guard t > 0, t < 1.45 else { continue }
        let q = (s: v.s - t * cosT, l: v.l, h: v.h - t * e)
        let dist = (q.s * q.s + q.l * q.l + q.h * q.h).squareRoot()
        if dist < R + 0.0065 + t * 0.006 { return false }
    }
    return true
}

/// Legal (no foul, no loss of game) for this situation, whatever was called. Nil when legal, else the reason.
func ebFoul(_ s: EBSituationSpec, _ k: Strike, _ tl: Timeline) -> String? {
    if tl.events.count > 4000 { return "chatter" }
    if tl.pocketTime[0] != nil { return "scratch" }
    guard let first = firstStruck(tl) else { return "no ball hit" }
    if !s.legal.contains(first) { return "wrong ball first (\(first))" }
    for b in 1..<16 where wentOff(b, tl) { return "ball \(b) off the table" }
    // A rail or a pocket after the first contact.
    let contact = tl.events.first { $0.kind == .ballBall && $0.balls.contains { $0.ball == 0 } }!.time
    let railAfter = tl.events.contains { ($0.kind == .cushion || $0.kind == .pocket) && $0.time >= contact }
    if !railAfter { return "no rail after contact" }
    if !cueClear(s.layout, k) { return "cue touches a ball" }
    return nil
}

/// Made as called with no foul and no loss.
func ebMade(_ s: EBSituationSpec, _ e: EBEscapeSpec, _ k: Strike, _ tl: Timeline) -> Bool {
    guard let ball = e.ball, let pocket = e.pocket else { return false }
    if ebFoul(s, k, tl) != nil { return false }
    if pocketOf(ball, tl) != pocket { return false }
    if ball != 8, tl.pocketTime[8] != nil { return false }            // the 8 early: game lost
    return true
}

/// After the shot, no straight line from the cue ball to the centre of any opponent ball (each one is screened by
/// another ball within a ball's width of the line).
func opponentHooked(_ s: EBSituationSpec, _ tl: Timeline) -> Bool {
    let end = tl.duration
    let rest = (0..<16).map { b -> Vec2? in
        guard NextShot.isOnTable(s.layout[b]), tl.pocketTime[b] == nil else { return nil }
        return tl.state(ball: b, at: end).position
    }
    guard let c = rest[0] else { return false }
    // The opponent shoots at THEIR group next (the player's opponent's balls), or the 8 when they have none.
    let theirs = s.opponent.filter { rest[$0] != nil }
    let targets = theirs.isEmpty ? [8] : theirs
    for t in targets {
        guard let p = rest[t] else { continue }
        let seg = p - c, len = seg.length, u = seg * (1 / len)
        var blocked = false
        for b in 1..<16 where b != t {
            guard let q = rest[b] else { continue }
            let w = q - c
            let along = w.x * u.x + w.y * u.y
            guard along > 0, along < len else { continue }
            let off = abs(w.x * u.y - w.y * u.x)
            if off < 2 * R { blocked = true; break }
        }
        if !blocked { return false }
    }
    return true
}

/// The whole test for one escape: legal, made as called (or a hooking safety), and the technique really used.
func ebPasses(_ s: EBSituationSpec, _ e: EBEscapeSpec, _ k: Strike) -> Bool {
    let tl = ebSim(s, k)
    let rails = railsBeforeContact(tl)
    guard e.rails.contains(rails) else { return false }
    switch e.technique {
    case .safety:
        // A clean safety: legal, and nothing drops (a ball of yours dropping on a declared safety only confuses it).
        guard ebFoul(s, k, tl) == nil, (1..<16).allSatisfy({ tl.pocketTime[$0] == nil }) else { return false }
        return opponentHooked(s, tl)
    case .touch:
        guard ebFoul(s, k, tl) == nil, (1..<16).allSatisfy({ tl.pocketTime[$0] == nil }) else { return false }
        return e.ball == nil || firstStruck(tl) == e.ball
    case .kick:
        return ebMade(s, e, k, tl)
    case .bank:
        guard ebMade(s, e, k, tl), let ball = e.ball else { return false }
        let drop = tl.pocketTime[ball] ?? -1
        return tl.events.contains { $0.kind == .cushion && $0.edge == .rail && $0.time < drop && $0.balls.first?.ball == ball }
    case .jump:
        guard ebMade(s, e, k, tl) else { return false }
        let contact = tl.events.first { $0.kind == .ballBall && $0.balls.contains { $0.ball == 0 } }?.time ?? 0
        let flew = tl.events.contains { $0.flight == .takeOff && $0.balls.first?.ball == 0 && $0.time < contact }
        guard flew else { return false }
        var level = k; level.elevation = 0
        return !ebMade(s, e, level, ebSim(s, level))
    case .curve:
        guard ebMade(s, e, k, tl) else { return false }
        var level = k; level.elevation = 0
        return !ebMade(s, e, level, ebSim(s, level))
    }
}

/// One word on why a stroke fails an escape, for the diagnosis when nothing passes.
func ebWhy(_ s: EBSituationSpec, _ e: EBEscapeSpec, _ k: Strike) -> String {
    let tl = ebSim(s, k)
    let rails = railsBeforeContact(tl)
    if let f = ebFoul(s, k, tl) { return f.hasPrefix("wrong") ? "wrong ball first" : f }
    if !e.rails.contains(rails) { return "legal, \(rails) rails" }
    if e.technique == .safety || e.technique == .touch { return tl.pocketTime[8] != nil ? "8 down" : "not hooked" }
    guard let b = e.ball else { return "?" }
    if let pk = pocketOf(b, tl) {
        if pk != e.pocket { return "called ball in \(ebPocketNames[pk])" }
        if b != 8, tl.pocketTime[8] != nil { return "8 down too" }
        return "made, technique test fails"
    }
    return "legal, called ball stays up"
}

// MARK: The hook

/// Level straight strokes all round (every 0.25 degrees, two speeds, centre ball): how many make a legal ball in any
/// pocket with no foul and no rail before contact. Zero means truly hooked for the plain shot.
func directMakes(_ s: EBSituationSpec) -> [String] {
    let strikes: [Strike] = [1.5, 3.0].flatMap { p in range(0, 359.75, 0.25).map { Strike(aim: $0, power: p, tipUp: 0, tipSide: 0) } }
    let found = parallelMap(strikes.count) { i -> String? in
        let k = strikes[i]
        let tl = ebSim(s, k)
        guard ebFoul(s, k, tl) == nil, railsBeforeContact(tl) == 0 else { return nil }
        for b in s.legal { if let pk = pocketOf(b, tl), (b == 8 || tl.pocketTime[8] == nil) {
            return String(format: "%d in %@ (aim %.2f, %.1f m/s)", b, ebPocketNames[pk], k.aim, k.power)
        } }
        return nil
    }
    return found.compactMap { $0 }
}

// MARK: Search and measure

/// The strokes to try for one escape.
func ebGrid(_ s: EBSituationSpec, _ e: EBEscapeSpec) -> [Strike] {
    let aims: [Double]
    if let (c0, h, st) = e.aimAround {
        var c = c0
        if e.aimRelative, let b = e.ball, let pk = e.pocket {
            let lay = s.layout
            let ghost = lay[b] + unit(lay[b] - pockets[pk]) * (2 * R)
            c += ebAim(lay[0], ghost)
        }
        aims = range(c - h, c + h, st)
    } else { aims = range(0, 360 - e.aimStep, e.aimStep) }
    var out: [Strike] = []
    for el in e.elevations { for p in e.powers { for tu in e.tipUps { for ts in e.tipSides { for a in aims {
        out.append(Strike(aim: a, power: p, tipUp: tu, tipSide: ts, elevation: el))
    } } } } }
    return out
}

/// Contiguous band of one setting around a stroke in which the escape still passes.
func ebBand(_ s: EBSituationSpec, _ e: EBEscapeSpec, _ k: Strike, step: Double, limit: Double,
            _ set: @escaping (inout Strike, Double) -> Void, _ get: (Strike) -> Double,
            valid: @escaping (Double) -> Bool = { _ in true }) -> (lo: Double, hi: Double)? {
    band(centre: get(k), step: step, limit: limit) { v in
        guard valid(v) else { return false }
        var t = k; set(&t, v); return ebPasses(s, e, t)
    }
}

struct EBResult: Sendable {
    var strike: Strike
    var aim: (lo: Double, hi: Double)
    var power: (lo: Double, hi: Double)
    var tipUp: (lo: Double, hi: Double)
    var tipSide: (lo: Double, hi: Double)?
    var elevation: (lo: Double, hi: Double)?
    var aimHalf: Double { min(strike.aim - aim.lo, aim.hi - strike.aim) }
    var powerHalf: Double { min(strike.power - power.lo, power.hi - strike.power) }
    var tipHalf: Double { min(strike.tipUp - tipUp.lo, tipUp.hi - strike.tipUp) }
}

/// Re-centre a stroke in its aim, power and tip windows (twice), then measure every window from the final stroke.
func ebMeasure(_ s: EBSituationSpec, _ e: EBEscapeSpec, _ start: Strike) -> EBResult? {
    var c = start
    let aimSet: (inout Strike, Double) -> Void = { $0.aim = $1 }
    let powSet: (inout Strike, Double) -> Void = { $0.power = $1 }
    let tipSet: (inout Strike, Double) -> Void = { $0.tipUp = $1 }
    let sideSet: (inout Strike, Double) -> Void = { $0.tipSide = $1 }
    let elSet: (inout Strike, Double) -> Void = { $0.elevation = $1 }
    let aimStep = e.technique == .curve ? 0.1 : 0.02
    for _ in 0..<2 {
        guard let a = ebBand(s, e, c, step: aimStep, limit: 6, aimSet, { $0.aim }) else { return nil }
        c.aim = ((a.lo + a.hi) / 2 / 0.01).rounded() * 0.01
        guard let p = ebBand(s, e, c, step: 0.05, limit: 3, powSet, { $0.power }, valid: { $0 >= 0.3 && $0 <= 8 }) else { return nil }
        c.power = ((p.lo + p.hi) / 2 / 0.05).rounded() * 0.05
        let side0 = c.tipSide
        guard let t = ebBand(s, e, c, step: 0.0005, limit: 0.02, tipSet, { $0.tipUp },
                             valid: { insideGrip(up: $0, side: side0) }) else { return nil }
        c.tipUp = ((t.lo + t.hi) / 2 / 0.0005).rounded() * 0.0005
    }
    let up = c.tipUp, sideNow = c.tipSide
    guard let a = ebBand(s, e, c, step: aimStep, limit: 6, aimSet, { $0.aim }),
          let p = ebBand(s, e, c, step: 0.05, limit: 3, powSet, { $0.power }, valid: { $0 >= 0.3 && $0 <= 8 }),
          let t = ebBand(s, e, c, step: 0.0005, limit: 0.02, tipSet, { $0.tipUp }, valid: { insideGrip(up: $0, side: sideNow) })
    else { return nil }
    let side = ebBand(s, e, c, step: 0.0005, limit: 0.02, sideSet, { $0.tipSide }, valid: { insideGrip(up: up, side: $0) })
    let el = c.elevation > 0
        ? ebBand(s, e, c, step: 0.01, limit: 0.3, elSet, { $0.elevation }, valid: { $0 > 0.05 && $0 <= 0.95 }) : nil
    return EBResult(strike: c, aim: a, power: p, tipUp: t, tipSide: side, elevation: el)
}

/// Search one escape: run the grid, find the longest unbroken aim runs per (power, tip, side, elevation), measure the
/// centres of the best few, keep the one with the widest aim window that is also not knife-edge in power.
func ebSearch(_ s: EBSituationSpec, _ e: EBEscapeSpec) -> EBResult? {
    let grid = ebGrid(s, e)
    let ok = parallelMap(grid.count) { i in ebPasses(s, e, grid[i]) }
    // Group by everything but aim, then find runs of consecutive passing aims.
    struct Run { var start: Strike; var count: Int; var centreAim: Double }
    var runs: [Run] = []
    var i = 0
    while i < grid.count {
        if ok[i] {
            var j = i
            while j + 1 < grid.count, ok[j + 1], grid[j + 1].power == grid[i].power, grid[j + 1].tipUp == grid[i].tipUp,
                  grid[j + 1].tipSide == grid[i].tipSide, grid[j + 1].elevation == grid[i].elevation,
                  abs(grid[j + 1].aim - grid[j].aim) < (e.aimAround?.2 ?? e.aimStep) * 1.5 { j += 1 }
            var k = grid[i]; k.aim = (grid[i].aim + grid[j].aim) / 2
            runs.append(Run(start: k, count: j - i + 1, centreAim: k.aim))
            i = j + 1
        } else { i += 1 }
    }
    let passCount = ok.filter { $0 }.count
    print("   \(e.id): \(grid.count) strokes tried, \(passCount) pass, \(runs.count) runs")
    guard !runs.isEmpty else {
        // Why nothing passed: the outcome of every stroke, tallied.
        let why = parallelMap(grid.count) { i in ebWhy(s, e, grid[i]) }
        var tally: [String: Int] = [:]
        for w in why { tally[w, default: 0] += 1 }
        print("   why: \(tally.sorted { $0.value > $1.value }.prefix(8).map { "\($0.key) \($0.value)" }.joined(separator: "; "))")
        return nil
    }
    let top = Array(runs.sorted { $0.count > $1.count }.prefix(e.technique == .curve ? 30 : 12))
    let measuredAll = parallelMap(top.count) { n in ebMeasure(s, e, top[n].start) }.compactMap { $0 }
    // Most forgiving in what a player sets by hand: aim, then speed, then tip height, each capped so no one huge
    // window wins on its own.
    func score(_ r: EBResult) -> Double {
        let el = r.elevation.map { min(r.strike.elevation - $0.lo, $0.hi - r.strike.elevation) } ?? 0.03
        let side = r.tipSide.map { min(r.strike.tipSide - $0.lo, $0.hi - r.strike.tipSide) } ?? 0.002
        let curve = e.technique == .curve ? min(el / 0.03, 1) + min(side / 0.002, 1) : 0
        return min(r.aimHalf / 0.3, 1) + min(r.powerHalf / 0.3, 1) + min(r.tipHalf / 0.003, 1) + curve + r.aimHalf * 0.01
    }
    return measuredAll.max { score($0) < score($1) }
}

func ebReport(_ s: EBSituationSpec, _ e: EBEscapeSpec, _ r: EBResult) {
    let k = r.strike
    // The app's aim slider runs -180 to 180: print the aim that way too (the same direction).
    let shown = k.aim > 180 ? k.aim - 360 : (k.aim < -180 ? k.aim + 360 : k.aim)
    let el: String = k.elevation > 0 ? String(format: ", elevation: %.2f", k.elevation) : ""
    print(String(format: "== %@ escape %@ (%@): TrickSettings(aim: %.2f, power: %.2f, tipUp: %.4f, tipSide: %.4f%@)",
                 s.id, e.id, e.technique.rawValue, shown, k.power, k.tipUp, k.tipSide, el))
    print(String(format: "   aim %.2f to %.2f deg (half %.2f); power %.2f to %.2f m/s (half %.2f); tip up %+.4f to %+.4f m",
                 r.aim.lo, r.aim.hi, r.aimHalf, r.power.lo, r.power.hi, r.powerHalf, r.tipUp.lo, r.tipUp.hi))
    if let t = r.tipSide { print(String(format: "   side %+.4f to %+.4f m", t.lo, t.hi)) }
    if let t = r.elevation {
        print(String(format: "   elevation sine %.2f to %.2f (%.1f to %.1f deg; stroke %.1f deg)", t.lo, t.hi,
                     asin(t.lo) * 180 / .pi, asin(t.hi) * 180 / .pi, asin(k.elevation) * 180 / .pi))
    }
    let tl = ebSim(s, k)
    let dropped = (1..<16).compactMap { b in pocketOf(b, tl).map { "\(b)->\(ebPocketNames[$0])" } }
    let firstCushion = tl.events.first { $0.kind == .cushion && $0.balls.first?.ball == 0 }.map { fmt($0.point) } ?? "none"
    print("   rails before contact \(railsBeforeContact(tl)); first cue cushion at \(firstCushion); first hit \(firstStruck(tl).map(String.init) ?? "none"); dropped \(dropped.joined(separator: ", ")); cue rests at \(fmt(cueRest(tl)))")
    if e.technique == .touch { print("   leaves the opponent hooked: \(opponentHooked(s, tl))") }
    // Seed independence: the app shoots with a varying seed.
    let other = PoolSolver.simulate(NextShot.shot(from: s.layout, direction: k.direction, speed: k.power, tipUp: k.tipUp,
                                                  tipSide: k.tipSide, seed: 4242, parameters: s.parameters,
                                                  elevation: k.elevation))
    print("   seed check: \(other.events.count == tl.events.count && pocketOf(e.ball ?? 0, other) == pocketOf(e.ball ?? 0, tl) ? "same" : "DIFFERENT")")
}

// MARK: The situations (diamonds as in the design, nudged where the solver needed it)

// Escape grids. Kicks sweep the whole circle with a level cue; jumps sweep a few degrees either side of the straight
// line at the called ball with the cue raised; massés and swerves sweep wide either side of it with side spin.
let ebKickPowers = range(1.0, 5.0, 0.25)
let ebKickTips = [-0.008, -0.004, 0, 0.004, 0.008]

func ebKick(_ id: String, _ ball: Int, _ pocket: Int, rails: ClosedRange<Int>, sides: [Double] = [0],
            tips: [Double] = ebKickTips, powers: [Double] = ebKickPowers) -> EBEscapeSpec {
    EBEscapeSpec(id: id, technique: .kick, ball: ball, pocket: pocket, rails: rails, aimStep: 0.1,
                 powers: powers, tipUps: tips, tipSides: sides)
}

func ebBank(_ id: String, _ ball: Int, _ pocket: Int, rails: ClosedRange<Int>) -> EBEscapeSpec {
    EBEscapeSpec(id: id, technique: .bank, ball: ball, pocket: pocket, rails: rails, aimStep: 0.1,
                 powers: range(1.5, 6.5, 0.25), tipUps: ebKickTips)
}

func ebJump(_ id: String, _ ball: Int, _ pocket: Int, bridge: Bool = false,
            elevations: [Double] = [0.4, 0.5, 0.6, 0.7, 0.8]) -> EBEscapeSpec {
    EBEscapeSpec(id: id, technique: .jump, ball: ball, pocket: pocket, rails: 0...0, aimAround: (0, 4, 0.1),
                 aimRelative: true, powers: range(2.5, 6.5, 0.25), tipUps: [0, -0.005],
                 elevations: elevations, bridge: bridge)
}

func ebMasse(_ id: String, _ ball: Int, _ pocket: Int) -> EBEscapeSpec {
    EBEscapeSpec(id: id, technique: .curve, ball: ball, pocket: pocket, rails: 0...0, aimAround: (0, 75, 1),
                 aimRelative: true, powers: [0.6, 0.8, 1.0, 1.3, 1.6, 2.0, 2.5], tipUps: [0, -0.004],
                 tipSides: [-0.0135, -0.011, 0.011, 0.0135], elevations: [0.5, 0.6, 0.7, 0.8, 0.9])
}

func ebSwerve(_ id: String, _ ball: Int, _ pocket: Int, half: Double = 30, powers: [Double] = range(1.0, 5.0, 0.5),
              elevations: [Double] = [0.2, 0.3, 0.4, 0.5, 0.6]) -> EBEscapeSpec {
    EBEscapeSpec(id: id, technique: .curve, ball: ball, pocket: pocket, rails: 0...0, aimAround: (0, half, 0.5),
                 aimRelative: true, powers: powers, tipUps: [0],
                 tipSides: [-0.014, -0.012, -0.010, -0.008, 0.008, 0.010, 0.012, 0.014], elevations: elevations)
}

func ebSafety(_ id: String, tips: [Double] = [0], powers: [Double] = range(0.5, 2.5, 0.25)) -> EBEscapeSpec {
    EBEscapeSpec(id: id, technique: .safety, rails: 0...3, aimStep: 0.2, powers: powers, tipUps: tips)
}

// Pocket indices: headRight 0, footRight 1, headLeft 2, footLeft 3, rightSide 4, leftSide 5.
let ebSituations: [EBSituationSpec] = [
    EBSituationSpec(
        id: "tucked", number: 1, cue: (2.2, 2.6), eight: (2.0, 3.0),
        balls: [3: (1.0, 5.0), 6: (3.6, 7.5), 9: (3.5, 6.8), 11: (0.5, 2.0), 12: (3.2, 1.4), 14: (1.6, 7.2), 15: (3.0, 5.4)],
        solids: true, cloth: .cloth,
        escapes: [ebKick("A", 3, 3, rails: 1...1), ebJump("B", 3, 3, elevations: [0.7, 0.8, 0.85, 0.9]), ebSafety("C")]),
    // The 3 a little nearer its corner, still dead behind the 8: a wider kick.
    EBSituationSpec(
        id: "tucked2", number: 1, cue: (2.2, 2.6), eight: (2.0, 3.0),
        balls: [3: (0.8, 5.4), 6: (3.6, 7.5), 9: (3.5, 6.8), 11: (0.5, 2.0), 12: (3.2, 1.4), 14: (1.6, 7.2), 15: (3.0, 5.4)],
        solids: true, cloth: .cloth,
        escapes: [ebKick("A", 3, 3, rails: 1...1), ebJump("B", 3, 3, elevations: [0.7, 0.8, 0.85, 0.9])]),
    EBSituationSpec(
        id: "frozen", number: 2, cue: (2.4, 4.6), eight: (2.0, 3.6),
        balls: [10: (3.905, 7.0), 12: (0.5, 7.4), 1: (0.8, 2.5), 3: (2.95, 5.65), 5: (3.4, 6.3), 6: (1.3, 6.3)],
        solids: false, cloth: .diveBar,
        escapes: [ebKick("A", 10, 1, rails: 1...1), ebKick("B", 10, 1, rails: 2...2)]),
    EBSituationSpec(
        id: "jump-diamond", number: 3, cue: (2.0, 1.4), eight: (2.4, 6.4),
        balls: [5: (3.5, 3.7), 2: (0.6, 6.9), 9: (0.9, 5.8), 11: (2.5, 2.15), 13: (3.3, 7.4), 14: (0.4, 4.8)],
        solids: true, cloth: .cloth,
        escapes: [ebKick("A", 5, 4, rails: 1...1), ebJump("B", 5, 4)]),
    EBSituationSpec(
        id: "bend", number: 4, cue: (1.0, 2.0), eight: (2.9, 2.4),
        balls: [15: (2.0, 4.6), 11: (3.05, 6.5), 2: (0.4, 5.2), 4: (3.2, 6.9), 6: (1.45, 3.0), 7: (0.9, 7.6)],
        solids: false, cloth: .cloth,
        escapes: [ebSwerve("A", 15, 1), ebJump("B", 15, 1), ebKick("C", 15, 1, rails: 2...3)]),
    EBSituationSpec(
        id: "kick-game", number: 5, cue: (1.6, 3.0), eight: (0.2, 6.8),
        balls: [1: (1.0, 4.6), 4: (2.8, 6.4), 6: (3.5, 2.0), 7: (2.2, 7.6)],
        solids: false, cloth: .cloth,
        escapes: [ebKick("A", 8, 3, rails: 1...1), ebKick("B", 8, 3, rails: 3...3)]),
    EBSituationSpec(
        id: "z-shot", number: 6, cue: (2.6, 3.2), eight: (1.2, 3.0),
        balls: [13: (1.5, 7.85), 15: (3.0, 1.2), 2: (0.6, 6.4), 4: (2.27, 4.6), 6: (1.9, 5.8), 7: (2.8, 2.3)],
        solids: false, cloth: .cloth,
        escapes: [ebKick("A", 13, 3, rails: 2...2, sides: [-0.01, -0.005, 0, 0.005], tips: [-0.006, 0, 0.006],
                         powers: range(2.0, 5.0, 0.25)),
                  ebKick("B", 13, 3, rails: 3...3)]),
    EBSituationSpec(
        id: "point-blank", number: 7, cue: (1.0, 6.0), eight: (1.3, 6.17),
        balls: [14: (2.6, 6.9), 1: (3.4, 3.1), 3: (0.6, 2.2), 6: (2.2, 4.9), 7: (3.7, 5.8)],
        solids: false, cloth: .cloth,
        escapes: [ebKick("A", 14, 1, rails: 1...1), ebJump("B", 14, 1, elevations: [0.7, 0.8, 0.85, 0.9])]),
    EBSituationSpec(
        id: "masse-win", number: 8, cue: (2.9, 6.5), eight: (3.85, 7.85),
        balls: [9: (0.8, 2.6), 10: (1.6, 5.2), 12: (3.4, 7.2), 13: (0.5, 7.0)],
        solids: true, cloth: .tournament,
        escapes: [ebKick("A", 8, 1, rails: 1...1), ebMasse("B", 8, 1)]),
    EBSituationSpec(
        id: "bridge-jump", number: 9, cue: (2.0, 5.0), eight: (3.0, 5.2),
        balls: [4: (0.9, 7.3), 7: (3.2, 3.0), 9: (1.75, 5.6), 11: (3.6, 1.0), 12: (2.3, 7.4), 15: (0.4, 3.0)],
        solids: true, cloth: .cloth,
        escapes: [ebKick("A", 4, 3, rails: 1...1), ebJump("B", 4, 3, bridge: true)]),
    EBSituationSpec(
        id: "kick-bank", number: 10, cue: (2.2, 6.6), eight: (2.2, 2.0),
        balls: [13: (3.7, 4.0), 10: (0.7, 1.5), 2: (2.68, 5.75), 3: (1.4, 7.0), 5: (3.5, 6.9), 6: (1.15, 3.0)],
        solids: false, cloth: .diveBar,
        escapes: [ebKick("A", 13, 4, rails: 1...1), ebBank("B", 13, 5, rails: 0...2)]),
    EBSituationSpec(
        id: "swerve", number: 11, cue: (2.6, 7.0), eight: (2.6, 2.2),
        balls: [9: (0.4, 0.5), 14: (1.2, 3.4), 1: (1.6, 3.8), 3: (2.1, 4.3), 4: (1.8, 4.6), 5: (0.3, 3.2), 7: (0.5, 5.5)],
        solids: false, cloth: .tournament,
        escapes: [ebKick("A", 9, 2, rails: 3...3), ebSwerve("B", 9, 2, half: 25)]),
    EBSituationSpec(
        id: "no-way", number: 12, cue: (2.4, 0.6), eight: (2.5, 1.0),
        balls: [1: (2.0, 7.9), 6: (1.1, 5.9), 9: (1.8, 7.5), 10: (1.25, 5.75), 11: (0.95, 6.1), 13: (2.4, 7.55), 14: (3.4, 4.2)],
        solids: true, cloth: .cloth,
        escapes: [ebSafety("A"), ebKick("B", 1, 3, rails: 1...4), ebKick("B2", 1, 1, rails: 1...4),
                  ebKick("B3", 6, 3, rails: 1...4)]),
    // Round four: a finer swerve grid for Bend Around, and a wider safety search for No Way to Make It.
    EBSituationSpec(
        id: "bend3", number: 4, cue: (1.6, 3.0), eight: (2.9, 2.4),
        balls: [15: (3.0, 6.4), 11: (3.55, 2.1), 2: (0.4, 5.2), 4: (3.5, 5.4), 6: (2.1, 3.98), 7: (0.9, 7.6)],
        solids: false, cloth: .cloth,
        escapes: [EBEscapeSpec(id: "A", technique: .curve, ball: 15, pocket: 1, rails: 0...0, aimAround: (-13, 6, 0.25),
                               powers: range(1.5, 4.0, 0.25), tipUps: [0], tipSides: range(0.008, 0.014, 0.002),
                               elevations: range(0.2, 0.5, 0.025))]),
    EBSituationSpec(
        id: "no-way3", number: 12, cue: (2.4, 0.6), eight: (2.5, 1.0),
        balls: [1: (2.0, 7.9), 6: (1.1, 5.9), 9: (1.8, 7.5), 10: (1.25, 5.75), 11: (0.95, 6.1), 13: (2.4, 7.55), 14: (3.4, 4.2)],
        solids: true, cloth: .cloth,
        escapes: [ebSafety("A", tips: [-0.006, 0, 0.006], powers: range(0.4, 3.0, 0.1)),
                  EBEscapeSpec(id: "T", technique: .touch, ball: 1, rails: 1...3, aimStep: 0.1, powers: range(0.8, 3.0, 0.2))]),
    // Round three: positions reworked where round two found the escapes knife-edge or missing.
    EBSituationSpec(
        id: "bend2", number: 4, cue: (1.6, 3.0), eight: (2.9, 2.4),
        balls: [15: (3.0, 6.4), 11: (3.55, 2.1), 2: (0.4, 5.2), 4: (3.5, 5.4), 6: (2.1, 3.98), 7: (0.9, 7.6)],
        solids: false, cloth: .cloth,
        escapes: [ebSwerve("A", 15, 1), ebJump("B", 15, 1), ebKick("C", 15, 1, rails: 2...3)]),
    EBSituationSpec(
        id: "kick-game-db", number: 5, cue: (1.6, 3.0), eight: (0.2, 6.8),
        balls: [1: (1.0, 4.6), 4: (2.8, 6.4), 6: (3.5, 2.0), 7: (2.2, 7.6)],
        solids: false, cloth: .diveBar,
        escapes: [ebKick("A", 8, 3, rails: 1...1), ebKick("B", 8, 3, rails: 3...3)]),
    EBSituationSpec(
        id: "kick-bank2", number: 10, cue: (2.2, 6.6), eight: (2.2, 2.0),
        balls: [13: (3.6, 4.6), 10: (0.7, 1.5), 2: (2.83, 5.7), 3: (1.4, 7.0), 5: (3.5, 6.9), 6: (1.15, 3.0)],
        solids: false, cloth: .cloth,
        escapes: [ebKick("A", 13, 4, rails: 1...1), ebBank("B", 13, 5, rails: 0...2)]),
    EBSituationSpec(
        id: "swerve2", number: 11, cue: (2.6, 7.0), eight: (2.6, 2.2),
        balls: [9: (0.4, 0.5), 14: (2.65, 1.0), 1: (1.6, 3.8), 3: (2.1, 4.3), 4: (1.8, 4.6), 5: (0.3, 3.2), 7: (0.5, 5.5)],
        solids: false, cloth: .tournament,
        escapes: [ebKick("A", 9, 2, rails: 3...3),
                  ebSwerve("B", 9, 2, half: 35, powers: range(1.5, 6.0, 0.5), elevations: [0.15, 0.2, 0.25, 0.3, 0.4, 0.5])]),
    EBSituationSpec(
        id: "no-way2", number: 12, cue: (2.4, 0.6), eight: (2.5, 1.0),
        balls: [1: (2.0, 7.9), 6: (1.1, 5.9), 9: (1.8, 7.5), 10: (1.25, 5.75), 11: (0.95, 6.1), 13: (2.4, 7.55)],
        solids: true, cloth: .cloth,
        escapes: [ebSafety("A", tips: [-0.006, 0, 0.006], powers: range(0.4, 3.0, 0.1))]),
]

func ebAim(_ from: Vec2, _ to: Vec2) -> Double { degrees(of: unit(to - from)) }

/// Where a cushion contact sits, in the design's words: which rail and how many diamonds along it.
func ebRailWords(_ p: Vec2) -> String {
    let along = p.x / ebDiamond, across = 4 - p.y / ebDiamond
    if p.x < 0.001 { return String(format: "head rail at across %.2f", across) }
    if p.x > 2.539 { return String(format: "foot rail at across %.2f", across) }
    if p.y < 0.001 { return String(format: "right rail at along %.2f", along) }
    if p.y > 1.269 { return String(format: "left rail at along %.2f", along) }
    return String(format: "cushion at (%.2f, %.2f)", across, along)
}

/// Check the exact strokes written into the app (aims as the app holds them, -180 to 180) and print, for the cards,
/// every cushion the cue ball takes before its first ball in diamonds, and the windows walked from that very stroke
/// (no re-centring).
func runEightBallVerify(only: Set<String>) {
    for f in ebFinal where only.isEmpty || only.contains(f.situation) {
        guard let s = ebSituations.first(where: { $0.id == f.situation }),
              let e = s.escapes.first(where: { $0.id == f.escape }) else { print("?? \(f.situation) \(f.escape)"); continue }
        let k = f.strike
        let ok = ebPasses(s, e, k)
        let tl = ebSim(s, k)
        let contact = tl.events.first { $0.kind == .ballBall && $0.balls.contains { $0.ball == 0 } }?.time ?? .infinity
        let rails = tl.events.filter { $0.kind == .cushion && $0.balls.first?.ball == 0 && $0.time < contact }.map { ebRailWords($0.point) }
        print("== \(s.id) \(e.id) \(ok ? "PASSES" : "FAILS") \(k)")
        print("   cue ball rails before contact: \(rails.isEmpty ? "none" : rails.joined(separator: "; "))")
        if e.technique == .touch || e.technique == .safety { print("   leaves the opponent hooked: \(opponentHooked(s, tl))") }
        let first = firstStruck(tl).map(String.init) ?? "none"
        let dropped = (1..<16).compactMap { b in pocketOf(b, tl).map { "\(b)->\(ebPocketNames[$0])" } }
        let rest = cueRest(tl)
        print(String(format: "   first hit %@; dropped %@; cue rests at across %.2f along %.2f; took %.1f s", first,
                     dropped.joined(separator: ", "), 4 - rest.y / ebDiamond, rest.x / ebDiamond, tl.duration))
        if e.technique == .jump {
            let up = tl.events.first { $0.flight == .takeOff && $0.balls.first?.ball == 0 }
            let peak = tl.events.filter { $0.balls.first?.ball == 0 && $0.time < contact }.map(\.height).max() ?? 0
            print(String(format: "   take-off up speed %.2f m/s; highest recorded event height %.3f m", up?.verticalSpeedUp ?? 0, peak))
        }
        guard ok else { continue }
        let aim = band(centre: k.aim, step: e.technique == .curve ? 0.1 : 0.02, limit: 6) { v in var t = k; t.aim = v; return ebPasses(s, e, t) }!
        let pow = band(centre: k.power, step: 0.05, limit: 3) { v in v >= 0.3 && v <= 8 && { var t = k; t.power = v; return ebPasses(s, e, t) }() }!
        let side = band(centre: k.tipSide, step: 0.0005, limit: 0.02) { v in insideGrip(up: k.tipUp, side: v) && { var t = k; t.tipSide = v; return ebPasses(s, e, t) }() }!
        let tip = band(centre: k.tipUp, step: 0.0005, limit: 0.02) { v in insideGrip(up: v, side: k.tipSide) && { var t = k; t.tipUp = v; return ebPasses(s, e, t) }() }!
        var line = String(format: "   windows: aim %.2f..%.2f, power %.2f..%.2f, side %+.4f..%+.4f, tip %+.4f..%+.4f",
                          aim.lo, aim.hi, pow.lo, pow.hi, side.lo, side.hi, tip.lo, tip.hi)
        if k.elevation > 0, let el = band(centre: k.elevation, step: 0.01, limit: 0.3, { v in
            v > 0.05 && v <= 0.95 && { var t = k; t.elevation = v; return ebPasses(s, e, t) }() }) {
            line += String(format: ", elevation %.2f..%.2f (stroke %.1f deg)", el.lo, el.hi, asin(k.elevation) * 180 / .pi)
        }
        print(line)
    }
}

func runEightBallAuthoring(only: Set<String>) {
    if only.contains("verify") { runEightBallVerify(only: only.subtracting(["verify"])); return }
    for s in ebSituations where only.isEmpty || only.contains(s.id) {
        let start = Date()
        print("#### \(s.number) \(s.id) on \(s.cloth.rawValue)")
        let lay = s.layout
        for (b, p) in lay.enumerated() where NextShot.isOnTable(p) {
            let rail = clearOfRails(p, margin: 0.0, pocketClear: 0.06)
            let others = lay.enumerated().filter { $0.offset != b && NextShot.isOnTable($0.element) }.map(\.element)
            let near = others.contains { ($0 - p).length < 2 * R + 0.001 }
            if !rail || near { print("   ball \(b) at \(fmt(p)): \(rail ? "" : "on or past a rail or pocket ")\(near ? "overlaps a ball" : "")") }
        }
        let direct = directMakes(s)
        print("   hook: \(direct.count) direct makes\(direct.isEmpty ? "" : ": " + direct.prefix(6).joined(separator: "; "))")
        for e in s.escapes {
            if let r = ebSearch(s, e) { ebReport(s, e, r) } else { print("== \(s.id) escape \(e.id): NO SOLUTION") }
        }
        print(String(format: "   (took %.1f s)", Date().timeIntervalSince(start)))
    }
}

// MARK: The strokes the app carries

/// One authored escape exactly as App/EightBall/EightBallSituations.swift holds it ("eightball verify" re-checks them).
struct EBFinal: Sendable {
    var situation: String
    var escape: String
    var strike: Strike
}

/// Aims as the app holds them (-180 to 180); elevations set inside each jump's measured band rather than at its edge.
let ebFinal: [EBFinal] = [
    EBFinal(situation: "tucked2", escape: "A", strike: Strike(aim: 169.97, power: 3.50, tipUp: 0.004, tipSide: 0)),
    EBFinal(situation: "tucked2", escape: "B", strike: Strike(aim: 27.25, power: 3.80, tipUp: -0.002, tipSide: 0, elevation: 0.80)),
    EBFinal(situation: "frozen", escape: "A", strike: Strike(aim: -173.78, power: 3.05, tipUp: 0.0055, tipSide: 0)),
    EBFinal(situation: "frozen", escape: "B", strike: Strike(aim: -173.39, power: 4.45, tipUp: 0.007, tipSide: 0)),
    EBFinal(situation: "jump-diamond", escape: "A", strike: Strike(aim: 60.68, power: 3.75, tipUp: -0.008, tipSide: 0)),
    EBFinal(situation: "jump-diamond", escape: "B", strike: Strike(aim: -31.30, power: 5.20, tipUp: -0.010, tipSide: 0, elevation: 0.70)),
    EBFinal(situation: "bend2", escape: "A", strike: Strike(aim: -14.43, power: 3.15, tipUp: -0.0025, tipSide: 0.0135, elevation: 0.40)),
    EBFinal(situation: "bend2", escape: "B", strike: Strike(aim: -21.95, power: 4.35, tipUp: -0.0055, tipSide: 0, elevation: 0.70)),
    EBFinal(situation: "bend2", escape: "C", strike: Strike(aim: -129.06, power: 4.30, tipUp: 0.0105, tipSide: 0)),
    EBFinal(situation: "kick-game-db", escape: "A", strike: Strike(aim: 27.71, power: 1.50, tipUp: 0.0065, tipSide: 0)),
    EBFinal(situation: "kick-game-db", escape: "B", strike: Strike(aim: 122.55, power: 7.65, tipUp: 0.0115, tipSide: 0)),
    EBFinal(situation: "z-shot", escape: "A", strike: Strike(aim: -36.62, power: 5.00, tipUp: -0.004, tipSide: -0.005)),
    EBFinal(situation: "z-shot", escape: "B", strike: Strike(aim: 52.60, power: 4.95, tipUp: -0.008, tipSide: 0)),
    EBFinal(situation: "point-blank", escape: "A", strike: Strike(aim: 70.62, power: 3.45, tipUp: -0.008, tipSide: 0)),
    EBFinal(situation: "point-blank", escape: "B", strike: Strike(aim: -61.55, power: 3.50, tipUp: -0.0045, tipSide: 0, elevation: 0.85)),
    EBFinal(situation: "masse-win", escape: "A", strike: Strike(aim: -177.14, power: 1.75, tipUp: 0.006, tipSide: 0)),
    EBFinal(situation: "masse-win", escape: "B", strike: Strike(aim: -11.28, power: 4.30, tipUp: 0.0005, tipSide: 0.0095, elevation: 0.80)),
    EBFinal(situation: "bridge-jump", escape: "A", strike: Strike(aim: -59.44, power: 3.55, tipUp: -0.008, tipSide: 0)),
    EBFinal(situation: "bridge-jump", escape: "B", strike: Strike(aim: 23.49, power: 3.85, tipUp: -0.0045, tipSide: 0, elevation: 0.75)),
    EBFinal(situation: "kick-bank2", escape: "A", strike: Strike(aim: -21.46, power: 3.45, tipUp: -0.006, tipSide: 0)),
    EBFinal(situation: "kick-bank2", escape: "B", strike: Strike(aim: -132.88, power: 3.65, tipUp: 0.011, tipSide: 0)),
    EBFinal(situation: "swerve2", escape: "A", strike: Strike(aim: 52.41, power: 2.90, tipUp: 0.0105, tipSide: 0)),
    EBFinal(situation: "swerve2", escape: "B", strike: Strike(aim: 151.30, power: 5.05, tipUp: -0.002, tipSide: -0.0135, elevation: 0.50)),
    EBFinal(situation: "no-way3", escape: "T", strike: Strike(aim: 59.45, power: 2.75, tipUp: 0.009, tipSide: 0)),
    EBFinal(situation: "no-way", escape: "B2", strike: Strike(aim: 27.90, power: 4.10, tipUp: -0.008, tipSide: 0)),
]
