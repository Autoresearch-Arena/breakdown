// Author: Claude Opus 5.5 Medium
// Date: 26-November-2026
// PURPOSE: "BreakProbe daily [kind ...]": grows the Shot of the day bank (plans/25-Nov-2026-shot-of-the-day-plan.md,
//          stage 4). For each kind of shot it builds candidate layouts from geometry (the ghost-ball line from a pocket
//          back through the object ball, a pocket mirrored in a cushion for a bank, a second ball dropped onto the cue
//          ball's own recorded path for a draw, a follow or a carom, a blocker on the straight line for a jump or a
//          massé, random free places on the small tables), finds a strike that makes it with the real solver on the
//          shot's own table and surface, re-centres it and measures how forgiving it is in aim, power, tip height (and
//          side, for a side-spin shot) with TrickSearch's window walks, and rates it by its aim half-window with the
//          bands at the top of TrickAuthoring.swift (easy 0.6 degrees or more, medium 0.3 to 0.6, hard 0.12 to 0.3;
//          anything narrower is thrown out as unplayable).
//          Every candidate gets a mark, the place the answer leaves the white ball. For Monday's position shots the
//          layout is nudged so that place is useful: a next ball is laid on the straight line from it to a pocket,
//          where nothing in the answer touches it, so the mark leaves the cue ball lined up on that ball ("leave").
//          Kinds: pot (Monday, easy, with a leave), bank, combo, carom, draw, follow, jump, masse, bumper, bar, fivepin
//          (the three other tables, for Friday) and the strange surfaces ice, glass, rubber, cork, carpet, sand, moon
//          (Saturday: a pot, a bank, a draw or a follow on that surface). "all" runs every kind.
//          Output, in DAILY_OUT (default /Volumes/Team 4TB/breakdown-build/bank-out/daily): a contact sheet per kind
//          (DailyPictures) for a person to look at, and <kind>.swift.txt, one AuthoredDaily "made(...)" line per
//          candidate, ready to copy into the bank. DAILY_SEED changes the random layouts; DAILY_PLANS the number of
//          layouts tried per kind (default 40); DAILY_DIAG prints how many strokes of each layout pass. Run with
//          BREAKPROBE_THREADS set to use more cores.
// SRP/DRY check: Pass - candidate construction and choice only; simulation, goals, window walks and the parallel map
//          are TrickSearch's; the tables' and surfaces' numbers are the package library's (AuthoredTables,
//          TableSurfaces); the picture is DailyPictures'. The trick-shot searches (TrickAuthoring) are hand-built one
//          shot at a time; this is the seeded, many-at-once version the bank needs.
import BreakdownAuthored
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation

// MARK: The place a shot is authored on

/// A table, a surface and the parameters they make (the default generation with the table, then the surface, written
/// in: the order the app's ShowpieceModel.solverCopy and DailyVerify use).
struct DailyPlace: Sendable {
    let table: AuthoredTable
    let surface: TableSurface
    let p: PoolParameters

    init(_ table: AuthoredTable = .standard, _ surface: TableSurface = .cloth) {
        var q = generationParameters(PoolParameters().modelGeneration)
        table.apply(to: &q)
        surface.apply(to: &q)
        self.table = table
        self.surface = surface
        self.p = q
    }

    var R: Double { p.ballRadius }
    var L: Double { p.tableLength }
    var W: Double { p.tableWidth }

    /// Every hole a ball can drop in, by the solver's pocket index: the six edge pockets when the table has them, then
    /// each bed hole j as 6 + j.
    var holes: [(index: Int, centre: Vec2)] {
        var out: [(Int, Vec2)] = []
        if p.pocketsEnabled { for (k, c) in p.pocketCenters.enumerated() { out.append((k, c)) } }
        for (j, h) in p.bedHoles.enumerated() { out.append((6 + j, h.center)) }
        return out
    }

    func centre(ofHole k: Int) -> Vec2 { holes.first { $0.index == k }?.centre ?? .zero }

    func sim(_ layout: [Vec2], _ s: Strike) -> Timeline { simulate(layout, s, parameters: p) }

    /// True when a ball can start at `q`: inside the cushions by `margin`, clear of every hole by `holeClear` beyond
    /// touching, clear of posts and pins, and clear of every ball already laid.
    func free(_ q: Vec2, _ layout: [Vec2], margin: Double = 0.03, holeClear: Double = 0.06) -> Bool {
        guard q.x > R + margin, q.x < L - R - margin, q.y > R + margin, q.y < W - R - margin else { return false }
        for (k, c) in holes {
            let radius = k < 6 ? 2 * R : (p.bedHoles[k - 6].radius)
            if (c - q).length < radius + R + holeClear { return false }
        }
        for post in p.posts where (post.center - q).length < post.radius + R + 0.012 { return false }
        for pin in p.pins where (pin.center - q).length < pin.radius + R + 0.03 { return false }
        return !layout.contains { NextShot.isOnTable($0) && ($0 - q).length < 2 * R + 0.012 }
    }

    /// The surface's short name for an id ("" on cloth).
    var tag: String { surface == .cloth ? "" : "-\(surface.rawValue.lowercased())" }
}

/// Positions are kept to a tenth of a millimetre, the precision the bank's literals carry, so what is printed is
/// exactly what was solved.
func r4(_ v: Vec2) -> Vec2 { Vec2((v.x * 1e4).rounded() / 1e4, (v.y * 1e4).rounded() / 1e4) }
func roundedAs(_ x: Double, _ format: String) -> Double { Double(String(format: format, x)) ?? x }

/// A small seeded random source, so a run can be repeated exactly.
struct DailyRandom {
    var state: UInt64
    init(_ seed: UInt64) { state = seed &* 0x9E3779B97F4A7C15 | 1 }
    mutating func next() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double(state >> 11) / Double(UInt64(1) << 53)
    }
    mutating func range(_ a: Double, _ b: Double) -> Double { a + (b - a) * next() }
    mutating func pick<T>(_ list: [T]) -> T { list[min(list.count - 1, Int(next() * Double(list.count)))] }
}

// MARK: One candidate layout and what it must do

/// An extra test the found answer must pass besides its goal.
enum DailyCheck: Sendable {
    case none
    /// A jump or a massé: the same stroke with a level cue must not make it.
    case raisedOnly
    /// A draw or a follow: the same stroke struck through the centre must not make it.
    case needsSpin
    /// Five-pin: the object balls (not the cue ball) knock down at least one pin, and the cue ball none.
    case pinsByObjectBalls
    /// Bar billiards: no skittle falls.
    case noPinDown
}

struct DailyPlan: Sendable {
    var id: String
    /// nil: decided from the answer (the small tables: a pot, a bank, a kick or a carom by what happens).
    var family: AuthoredFamily?
    var place: DailyPlace
    var layout: [Vec2]
    var goal: Goal
    var strikes: [Strike]
    /// The difficulty wanted, 1 to 3: the choice among passing strikes leans toward it.
    var want: Int
    var check: DailyCheck = .none
    /// Lay a next ball for position after the answer is found (Monday).
    var leave = false
    /// The goal's one drop may be in any hole: the hole the answer uses becomes the goal's.
    var anyHole = false
    var note: String
}

/// A finished candidate, ready for the bank.
struct DailyFound: Sendable {
    var id: String
    var family: AuthoredFamily
    var place: DailyPlace
    var layout: [Vec2]
    var strike: Strike
    var goal: Goal
    var aimHalf: Double
    var powerHalf: Double
    var tipHalf: Double
    var sideHalf: Double
    var difficulty: Int
    var mark: Vec2
    var leave: Int?
    var note: String
}

/// The difficulty of an aim half-window (TrickAuthoring's bands): nil when it is too narrow to play.
func dailyDifficulty(aimHalf h: Double) -> Int? {
    if h >= 0.6 { return 1 }
    if h >= 0.3 { return 2 }
    if h >= 0.12 { return 3 }
    return nil
}

/// The goal plus the plan's extra check, on one recording.
func dailyPasses(_ plan: DailyPlan, _ goal: Goal, _ tl: Timeline) -> Bool {
    guard passes(goal, tl) else { return false }
    switch plan.check {
    case .pinsByObjectBalls:
        let falls = tl.pinFalls
        return !falls.isEmpty && !falls.contains { $0.ball == 0 }
    case .noPinDown:
        return tl.pinFalls.isEmpty
    case .none, .raisedOnly, .needsSpin:
        return true
    }
}

// MARK: Finding and measuring an answer

/// Solve a plan: the passing strikes, a sturdiness screen, the windows of a few survivors, and the one nearest the
/// wanted difficulty that is comfortable in power and tip. Nil when nothing holds up.
func solveDaily(_ plan: DailyPlan) -> DailyFound? {
    var plan = plan
    let place = plan.place
    // Any hole: find which hole the passing strikes use, and fix the goal to the most used one.
    if plan.anyHole, let ball = plan.goal.drops.first?.ball {
        var count: [Int: Int] = [:]
        for s in plan.strikes {
            let tl = place.sim(plan.layout, s)
            if dailyPasses(plan, plan.goal, tl), let k = pocketOf(ball, tl) { count[k, default: 0] += 1 }
        }
        guard let best = count.max(by: { $0.value < $1.value })?.key else { return nil }
        plan.goal.drops = [(ball, best)]
    }
    let goal = plan.goal
    let passing = plan.strikes.filter { dailyPasses(plan, goal, place.sim(plan.layout, $0)) }
    if passing.isEmpty, ProcessInfo.processInfo.environment["DAILY_DIAG"] != nil {
        print("   diag \(plan.id): \(plan.strikes.count) strikes, none pass")
    }
    guard !passing.isEmpty else { return nil }
    let nudge = plan.want >= 3 ? 0.07 : 0.15
    var sturdy = passing.filter { s in
        var tries: [Strike] = []
        for (da, dp, dt) in [(-nudge, 0.0, 0.0), (nudge, 0, 0), (0, -0.08, 0), (0, 0.08, 0), (0, 0, -0.001), (0, 0, 0.001)] {
            var t = s; t.aim += da; t.power += dp; t.tipUp += dt; tries.append(t)
        }
        return tries.allSatisfy { insideGrip(up: $0.tipUp, side: $0.tipSide) && dailyPasses(plan, goal, place.sim(plan.layout, $0)) }
    }
    if ProcessInfo.processInfo.environment["DAILY_DIAG"] != nil {
        print("   diag \(plan.id): \(plan.strikes.count) strikes, \(passing.count) pass, \(sturdy.count) sturdy")
    }
    // A shot that is touchy in power or tip by nature (a draw or a carom onto a second ball): fall back to the aim
    // screen alone, half as wide; the windows measured next still decide whether it is playable.
    if sturdy.isEmpty {
        sturdy = passing.filter { s in
            [-nudge / 2, nudge / 2].allSatisfy { da in
                var t = s; t.aim += da; return dailyPasses(plan, goal, place.sim(plan.layout, t))
            }
        }
    }
    guard !sturdy.isEmpty else { return nil }
    let step = max(1, sturdy.count / 5)
    var found: [DailyFound] = []
    for i in Swift.stride(from: 0, to: sturdy.count, by: step) {
        if let f = measureDaily(plan, goal, sturdy[i]) { found.append(f) }
    }
    return found.min { a, b in
        let da = abs(a.difficulty - plan.want), db = abs(b.difficulty - plan.want)
        if da != db { return da < db }
        let fa = min(a.powerHalf / 0.25, a.tipHalf / 0.002, 2), fb = min(b.powerHalf / 0.25, b.tipHalf / 0.002, 2)
        if abs(fa - fb) > 0.05 { return fa > fb }
        return a.aimHalf > b.aimHalf
    }
}

/// Re-centre one strike and measure it; apply the plan's checks; lay the leave ball. Nil when it fails any of it.
func measureDaily(_ plan: DailyPlan, _ goal: Goal, _ s: Strike) -> DailyFound? {
    let place = plan.place
    var layout = plan.layout
    // A plan's own extra check is part of the goal while measuring, so a window never counts a stroke that breaks it.
    let p = place.p
    guard let m = measured(plan.id, layout, s, goal, note: plan.note, parameters: p) else { return nil }
    var strike = m.strike
    strike.aim = roundedAs(strike.aim, "%.2f")
    strike.power = roundedAs(strike.power, "%.2f")
    strike.tipUp = roundedAs(strike.tipUp, "%.4f")
    strike.tipSide = roundedAs(strike.tipSide, "%.4f")
    // A draw or follow position shot keeps the spin it was found with: re-centring the tip in a wide band (any tip pots
    // the ball) would put it near the middle of the cue ball, and the shot would no longer be the spin it is about.
    if plan.check == .needsSpin { strike.tipUp = s.tipUp }
    var tl = place.sim(layout, strike)
    guard dailyPasses(plan, goal, tl) else { return nil }
    switch plan.check {
    case .raisedOnly:
        var level = strike; level.elevation = 0
        if passes(goal, place.sim(layout, level)) { return nil }
    case .needsSpin:
        // A draw or follow position shot: the cue ball must come well back (draw) or run well on (follow) from the
        // object ball, and the same stroke through the centre must stop at least 30 cm from where the spin leaves it.
        guard let first = goal.firstHit else { return nil }
        let rest = tl.state(ball: 0, at: tl.duration).position
        let along = (rest - layout[first]).dot(strike.direction)
        let draw = plan.family == .draw
        if draw ? (strike.tipUp > -0.006 || along > -0.3) : (strike.tipUp < 0.006 || along < 0.35) { return nil }
        var plain = strike; plain.tipUp = 0
        let plainTl = place.sim(layout, plain)
        if plainTl.pocketTime[0] == nil, (plainTl.state(ball: 0, at: plainTl.duration).position - rest).length < 0.3 { return nil }
    default:
        break
    }
    var aimHalf = m.aimHalfWindow, powerHalf = m.powerHalfWindow, tipHalf = m.tipHalfWindow
    if plan.check == .needsSpin {
        // The windows round the kept tip, not the re-centred one measured above.
        guard let a = aimBand(layout, strike, goal, parameters: p), let pw = powerBand(layout, strike, goal, parameters: p),
              let tp = tipUpBand(layout, strike, goal, parameters: p) else { return nil }
        aimHalf = min(strike.aim - a.lo, a.hi - strike.aim)
        powerHalf = min(strike.power - pw.lo, pw.hi - strike.power)
        tipHalf = min(strike.tipUp - tp.lo, tp.hi - strike.tipUp)
    }
    // The windows must also hold the plan's own check (pins, a raised cue): walk them again with it.
    let ok: (Strike) -> Bool = { t in dailyPasses(plan, goal, place.sim(layout, t)) }
    func half(_ get: (Strike) -> Double, _ set: (inout Strike, Double) -> Void, step: Double, limit: Double,
              valid: (Strike) -> Bool) -> Double {
        let c = get(strike)
        guard let b = band(centre: c, step: step, limit: limit, { v in
            var t = strike; set(&t, v); return valid(t) && ok(t)
        }) else { return 0 }
        return min(c - b.lo, b.hi - c)
    }
    if plan.check == .pinsByObjectBalls || plan.check == .noPinDown {
        aimHalf = half({ $0.aim }, { $0.aim = $1 }, step: 0.02, limit: 4, valid: { _ in true })
        powerHalf = half({ $0.power }, { $0.power = $1 }, step: 0.05, limit: 4, valid: { $0.power >= 0.5 && $0.power <= 8 })
        tipHalf = half({ $0.tipUp }, { $0.tipUp = $1 }, step: 0.0005, limit: 0.04,
                       valid: { insideGrip(up: $0.tipUp, side: $0.tipSide) })
    }
    var sideHalf = 0.0
    if strike.tipSide != 0 {
        sideHalf = half({ $0.tipSide }, { $0.tipSide = $1 }, step: 0.0005, limit: 0.04,
                        valid: { insideGrip(up: $0.tipUp, side: $0.tipSide) })
        guard sideHalf > 0 else { return nil }
    }
    guard var difficulty = dailyDifficulty(aimHalf: aimHalf), powerHalf >= 0.08, tipHalf >= 0.001 else { return nil }
    // A massé's aim is loose (the curve forgives it) but its side is not: the side window rates it too, on the same
    // three steps (4 mm or more either way easy, 2 mm medium, less hard), and the harder of the two counts.
    if strike.tipSide != 0 {
        difficulty = max(difficulty, sideHalf >= 0.004 ? 1 : (sideHalf >= 0.002 ? 2 : 3))
    }
    // The cue ball must stay on the table and stop somewhere: its resting place is the mark.
    guard tl.pocketTime[0] == nil else { return nil }
    var leaveBall: Int? = nil
    if plan.leave {
        guard let laid = layLeave(plan, layout, strike, tl) else { return nil }
        let ball = laid.0
        layout[ball] = laid.1
        leaveBall = ball
        tl = place.sim(layout, strike)
        guard dailyPasses(plan, goal, tl), tl.events.allSatisfy({ !$0.balls.contains { $0.ball == ball } }) else { return nil }
        // The windows with the next ball on the table: it is part of the layout the player sees.
        guard let a = aimBand(layout, strike, goal, parameters: p), let pw = powerBand(layout, strike, goal, parameters: p),
              let tp = tipUpBand(layout, strike, goal, parameters: p) else { return nil }
        aimHalf = min(strike.aim - a.lo, a.hi - strike.aim)
        powerHalf = min(strike.power - pw.lo, pw.hi - strike.power)
        tipHalf = min(strike.tipUp - tp.lo, tp.hi - strike.tipUp)
        guard let d = dailyDifficulty(aimHalf: aimHalf), powerHalf >= 0.08, tipHalf >= 0.001 else { return nil }
        difficulty = d
    }
    let rest = tl.state(ball: 0, at: tl.duration).position
    let family = plan.family ?? familyOnSmallTable(goal, tl)
    return DailyFound(id: plan.id, family: family, place: place, layout: layout, strike: strike, goal: goal,
                      aimHalf: aimHalf, powerHalf: powerHalf, tipHalf: tipHalf, sideHalf: sideHalf,
                      difficulty: difficulty, mark: r4(rest), leave: leaveBall, note: plan.note)
}

/// On the small tables the family is what the answer does: a carom when the goal names the cue ball's second ball; a
/// kick when the cue ball meets a cushion or post before its first ball; a bank when the goal ball meets one before it
/// drops; else a plain pot.
func familyOnSmallTable(_ goal: Goal, _ tl: Timeline) -> AuthoredFamily {
    if goal.secondHit != nil { return .carom }
    let first = tl.events.first { $0.kind == .ballBall && $0.balls.contains { $0.ball == 0 } }?.time ?? .infinity
    if tl.events.contains(where: { $0.kind == .cushion && $0.time < first && $0.balls.first?.ball == 0 }) { return .kick }
    if let b = goal.drops.first?.ball {
        let drop = tl.pocketTime[b] ?? .infinity
        if tl.events.contains(where: { $0.kind == .cushion && $0.time < drop && $0.balls.first?.ball == b }) { return .bank }
    }
    return .pot
}

/// Monday's position: a next ball on the straight line from the answer's resting place to a pocket, 30 to 60 cm on,
/// at least 15 cm short of the pocket, where no ball in the answer comes near it. The nearest such line wins.
func layLeave(_ plan: DailyPlan, _ layout: [Vec2], _ s: Strike, _ tl: Timeline) -> (Int, Vec2)? {
    let place = plan.place
    let rest = tl.state(ball: 0, at: tl.duration).position
    let used = Set(layout.indices.filter { NextShot.isOnTable(layout[$0]) })
    guard let ball = [5, 6, 7, 2, 4, 1, 3, 9, 10, 11, 12, 13, 14, 15].first(where: { !used.contains($0) }) else { return nil }
    // Every ball's path, sampled, to keep the new ball clear of all of it.
    var trail: [Vec2] = []
    var t = 0.0
    while t <= tl.duration {
        for b in used where tl.pocketTime[b].map({ t <= $0 }) ?? true { trail.append(tl.state(ball: b, at: t).position) }
        t += 0.01
    }
    var options: [(Double, Vec2)] = []
    for (_, c) in place.holes {
        let line = c - rest
        for d in [0.3, 0.4, 0.5, 0.6] where line.length - d >= 0.15 {
            let q = r4(rest + line.normalized * d)
            guard place.free(q, layout, margin: 0.02, holeClear: 0.05) else { continue }
            guard trail.allSatisfy({ ($0 - q).length > 2 * place.R + 0.02 }) else { continue }
            options.append((d, q))
            break
        }
    }
    return options.min { $0.0 < $1.0 }.map { (ball, $0.1) }
}

// MARK: The kinds of candidate

/// Ball numbers for the object balls of a pool-table layout, in a seeded order (never 0, the cue ball).
func poolBalls(_ rng: inout DailyRandom) -> [Int] {
    var out = [1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 12, 13, 14, 15]
    for i in Swift.stride(from: out.count - 1, to: 0, by: -1) {
        let j = Int(rng.next() * Double(i + 1))
        out.swapAt(i, min(j, i))
    }
    return out
}

func aims(_ centre: Double, span: Double, step: Double) -> [Double] {
    range(-span, span, step).map { centre + $0 }
}

/// A direction from a pocket into the table, inside the pocket's mouth: a corner's diagonal give or take 30 degrees,
/// a side pocket's square line give or take 40.
func intoTable(from k: Int, _ place: DailyPlace, _ rng: inout DailyRandom) -> Vec2 {
    let c = place.p.pocketCenters[k]
    let middle = Vec2(place.L / 2, place.W / 2)
    var base = (middle - c).normalized
    if k >= 4 { base = Vec2(0, k == 4 ? 1 : -1) }
    return rotate(base, rng.range(k >= 4 ? -40 : -25, k >= 4 ? 40 : 25))
}

/// Plain pots (Monday when `leave`; Saturday on a strange surface): an object ball 25 to 90 cm out of a pocket, cut 0
/// to 35 degrees from 40 to 110 cm away.
/// `spin` -1 makes Thursday's draw-position shot, +1 its follow-position shot: the same pot, struck low or high, whose
/// mark (with its leave) only the spin reaches.
func potPlans(_ place: DailyPlace, n: Int, seed: UInt64, leave: Bool, want: Int, spin: Int = 0) -> [DailyPlan] {
    var rng = DailyRandom(seed)
    var out: [DailyPlan] = []
    for i in 0..<n * 6 where out.count < n {
        let k = Int(rng.next() * 6) % 6
        let pk = place.p.pocketCenters[k]
        // Monday's easy pots sit closer and straighter than a strange surface's.
        let a = r4(pk + intoTable(from: k, place, &rng) * (leave ? rng.range(0.2, 0.6) : rng.range(0.25, 0.9)))
        let balls = poolBalls(&rng)
        var layout = authoredLayout([:])
        guard place.free(a, layout, holeClear: 0.08) else { continue }
        layout[balls[0]] = a
        let u = (pk - a).normalized
        let ghost = a - u * (2 * place.R)
        let cut = spin != 0 ? rng.range(-15, 15) : (leave ? rng.range(-25, 25) : rng.range(-35, 35))
        let c = r4(ghost - rotate(u, cut) * (leave ? rng.range(0.35, 0.8) : rng.range(0.4, 1.1)))
        guard place.free(c, layout) else { continue }
        layout[0] = c
        let aim0 = degrees(of: ghost - c)
        var strikes: [Strike] = []
        let powers = place.surface == .cloth ? [1.2, 1.8, 2.4, 3.0] : range(0.6, 5.0, 0.4)
        let tips = spin < 0 ? [-0.011, -0.009, -0.007] : (spin > 0 ? [0.007, 0.009, 0.011] : [-0.008, -0.004, 0, 0.004, 0.008])
        for a in aims(aim0, span: 0.6, step: 0.1) { for pw in powers { for t in tips {
            strikes.append(Strike(aim: a, power: pw, tipUp: t, tipSide: 0))
        } } }
        let name = spin < 0 ? "draw" : (spin > 0 ? "follow" : "pot")
        out.append(DailyPlan(id: "\(name)\(place.tag)-\(seed % 1000)-\(i)",
                             family: spin < 0 ? .draw : (spin > 0 ? .follow : .pot), place: place, layout: layout,
                             goal: Goal(drops: [(balls[0], k)], firstHit: balls[0]), strikes: strikes, want: want,
                             check: spin == 0 ? .none : .needsSpin, leave: leave,
                             note: String(format: "%@: the %d in the %@, cut %.0f", name, balls[0], pocketName(k), cut)))
    }
    return out
}

/// Banks: the object ball off one cushion into a pocket, aimed at the pocket's mirror image in that cushion.
func bankPlans(_ place: DailyPlace, n: Int, seed: UInt64, want: Int) -> [DailyPlan] {
    var rng = DailyRandom(seed)
    var out: [DailyPlan] = []
    let R = place.R
    for i in 0..<n * 10 where out.count < n {
        let k = Int(rng.next() * 6) % 6
        let pk = place.p.pocketCenters[k]
        // Bank across the table (off the long cushion opposite) or along it (off a short cushion).
        let acrossBank = rng.next() < 0.75
        var mirror: Vec2
        if acrossBank {
            let railY = pk.y < place.W / 2 ? place.W - R : R
            mirror = Vec2(pk.x, 2 * railY - pk.y)
        } else {
            guard k < 4 else { continue }
            let railX = pk.x < place.L / 2 ? place.L - R : R
            mirror = Vec2(2 * railX - pk.x, pk.y)
        }
        let a = r4(Vec2(rng.range(0.25, place.L - 0.25), rng.range(0.25, place.W - 0.25)))
        let balls = poolBalls(&rng)
        var layout = authoredLayout([:])
        guard place.free(a, layout, holeClear: 0.15) else { continue }
        let u = (mirror - a).normalized
        // The cushion point must sit well away from any pocket, and the ball's way to it must be long enough to read.
        let toRail = acrossBank ? ((u.y > 0 ? place.W - R : R) - a.y) / u.y : ((u.x > 0 ? place.L - R : R) - a.x) / u.x
        guard toRail > 0.15 else { continue }
        let hit = a + u * toRail
        guard place.holes.allSatisfy({ ($0.centre - hit).length > 0.2 }) else { continue }
        layout[balls[0]] = a
        let ghost = a - u * (2 * R)
        let cut = rng.range(-25, 25)
        let c = r4(ghost - rotate(u, cut) * rng.range(0.35, 0.9))
        guard place.free(c, layout) else { continue }
        layout[0] = c
        let aim0 = degrees(of: ghost - c)
        var strikes: [Strike] = []
        let powers = place.surface == .cloth ? [1.8, 2.4, 3.0, 3.6, 4.2] : range(0.6, 5.0, 0.4)
        for a in aims(aim0, span: 1.5, step: 0.1) { for pw in powers { for t in [-0.006, 0, 0.006] {
            strikes.append(Strike(aim: a, power: pw, tipUp: t, tipSide: 0))
        } } }
        out.append(DailyPlan(id: "bank\(place.tag)-\(seed % 1000)-\(i)", family: .bank, place: place, layout: layout,
                             goal: Goal(drops: [(balls[0], k)], firstHit: balls[0], bank: balls[0]), strikes: strikes,
                             want: want, note: "bank the \(balls[0]) into the \(pocketName(k))"))
    }
    return out
}

/// Combinations: the cue ball sends one ball into a second near a pocket, which drops.
func comboPlans(_ place: DailyPlace, n: Int, seed: UInt64, want: Int) -> [DailyPlan] {
    var rng = DailyRandom(seed)
    var out: [DailyPlan] = []
    let R = place.R
    for i in 0..<n * 8 where out.count < n {
        let k = Int(rng.next() * 6) % 6
        let pk = place.p.pocketCenters[k]
        let b = r4(pk + intoTable(from: k, place, &rng) * rng.range(0.2, 0.55))
        let balls = poolBalls(&rng)
        var layout = authoredLayout([:])
        guard place.free(b, layout, holeClear: 0.07) else { continue }
        layout[balls[1]] = b
        let ub = (pk - b).normalized
        let ghostB = b - ub * (2 * R)
        let a = r4(ghostB - rotate(ub, rng.range(-25, 25)) * rng.range(0.15, 0.45))
        guard place.free(a, layout) else { continue }
        layout[balls[0]] = a
        let ua = (ghostB - a).normalized
        let ghostA = a - ua * (2 * R)
        let c = r4(ghostA - rotate(ua, rng.range(-20, 20)) * rng.range(0.3, 0.85))
        guard place.free(c, layout) else { continue }
        layout[0] = c
        let aim0 = degrees(of: ghostA - c)
        var strikes: [Strike] = []
        for a in aims(aim0, span: 0.8, step: 0.05) { for pw in [1.5, 2.2, 3.0, 3.8] { for t in [-0.005, 0, 0.005] {
            strikes.append(Strike(aim: a, power: pw, tipUp: t, tipSide: 0))
        } } }
        out.append(DailyPlan(id: "combo-\(seed % 1000)-\(i)", family: .combination, place: place, layout: layout,
                             goal: Goal(drops: [(balls[1], k)], firstHit: balls[0]), strikes: strikes, want: want,
                             note: "the \(balls[0]) into the \(balls[1]), which drops in the \(pocketName(k))"))
    }
    return out
}

/// A second ball laid on the cue ball's own path after it leaves the first (the trick shots' placedOnPath, for any
/// place): `kind` "draw", "follow" or "carom".
func pathPlans(_ place: DailyPlace, kind: String, n: Int, seed: UInt64, want: Int) -> [DailyPlan] {
    var rng = DailyRandom(seed)
    var out: [DailyPlan] = []
    let R = place.R
    for i in 0..<n * 12 where out.count < n {
        let k = Int(rng.next() * 6) % 6
        let pk = place.p.pocketCenters[k]
        let a = r4(pk + intoTable(from: k, place, &rng) * rng.range(0.3, 0.8))
        let balls = poolBalls(&rng)
        var base = authoredLayout([:])
        guard place.free(a, base, holeClear: 0.08) else { continue }
        base[balls[0]] = a
        let u = (pk - a).normalized
        let ghost = a - u * (2 * R)
        let cut: Double
        switch kind {
        case "draw": cut = rng.range(-12, 12)
        case "follow": cut = rng.range(-30, 30)
        default: cut = (rng.next() < 0.5 ? -1 : 1) * rng.range(25, 50)
        }
        let c = r4(ghost - rotate(u, cut) * rng.range(0.35, 0.8))
        guard place.free(c, base) else { continue }
        base[0] = c
        let aim0 = degrees(of: ghost - c)
        let tips: [Double]
        switch kind {
        case "draw": tips = [-0.012, -0.009]
        case "follow": tips = [0.009, 0.012]
        default: tips = [-0.004, 0, 0.004]
        }
        let powers = place.surface == .cloth ? [2.0, 3.0, 4.0] : range(0.8, 4.8, 0.8)
        // The cue ball's path from a few strikes; the second ball goes where the cue ball, arriving, sends it into a
        // pocket other than the first ball's.
        let probe = [Strike(aim: aim0, power: powers[powers.count / 2], tipUp: tips[0], tipSide: 0)]
        let tl = place.sim(base, probe[0])
        if kind != "carom" { guard passes(Goal(drops: [(balls[0], k)], firstHit: balls[0]), tl) else { continue } }
        let path = cuePath(tl)
        guard path.count > 20 else { continue }
        var placedOne = false
        // The second ball hangs near its pocket (7 to 25 cm out) and the cue ball reaches it within 90 cm of the first
        // contact: further on, a hundredth of a degree of aim moves the cue ball's line too far for anyone to repeat
        // (a first run of this tool laid it anywhere and found no window wider than a twentieth of a degree).
        for (j, sample) in path.enumerated() where j % 2 == 0 && sample.t - path[0].t > 0.1 && sample.cushions <= 1
            && (sample.p - path[0].p).length < 0.9 {
            for (k2, p2) in place.holes where k2 != k {
                let b = r4(sample.p + (p2 - sample.p).normalized * (2 * R))
                // A cannon's second ball only has to be met, so it may sit anywhere clear; the pockets only give the
                // directions to lay it at.
                let nearPocket = (p2 - b).length > 0.07 && (p2 - b).length < 0.25
                guard kind == "carom" ? place.free(b, base, holeClear: 0.06) : (nearPocket && place.free(b, base, holeClear: 0.0)),
                      (b - a).length > 0.25 else { continue }
                var layout = base
                layout[balls[1]] = b
                let goal: Goal
                let family: AuthoredFamily
                switch kind {
                case "draw":
                    goal = Goal(drops: [(balls[0], k), (balls[1], k2)], firstHit: balls[0]); family = .draw
                case "follow":
                    goal = Goal(drops: [(balls[0], k), (balls[1], k2)], firstHit: balls[0]); family = .follow
                default:
                    // A cannon, as on a carom table: the cue ball off the first ball onto the second; nothing has to
                    // drop (a carom that also pots the second ball proved too fine to play, a twentieth of a degree).
                    goal = Goal(drops: [], firstHit: balls[0], secondHit: balls[1]); family = .carom
                }
                // The cue ball may meet the new ball before the sampled point (it is laid a ball-width off the path):
                // keep the placement only if the probe stroke really makes the whole goal with it on the table.
                guard passes(goal, place.sim(layout, probe[0])) else { continue }
                var strikes: [Strike] = []
                for aa in aims(aim0, span: 0.6, step: 0.05) { for pw in powers { for t in tips {
                    strikes.append(Strike(aim: aa, power: pw, tipUp: t, tipSide: 0))
                } } }
                out.append(DailyPlan(id: "\(kind)\(place.tag)-\(seed % 1000)-\(i)", family: family, place: place,
                                     layout: layout, goal: goal, strikes: strikes, want: want,
                                     check: kind == "carom" ? .none : .needsSpin,
                                     note: "\(kind): the \(balls[0]) then the \(balls[1]) in the \(pocketName(k2))"))
                placedOne = true
                break
            }
            if placedOne { break }
        }
    }
    return out
}

/// Jumps and massés: a blocker straight between the cue ball and a ball near a pocket.
func raisedPlans(_ place: DailyPlace, masse: Bool, n: Int, seed: UInt64) -> [DailyPlan] {
    var rng = DailyRandom(seed)
    var out: [DailyPlan] = []
    let R = place.R
    for i in 0..<n * 8 where out.count < n {
        let k = Int(rng.next() * 4) % 4      // corners: the long straight line a jump or a massé needs
        let pk = place.p.pocketCenters[k]
        let target = r4(pk + intoTable(from: k, place, &rng) * (masse ? rng.range(0.09, 0.16) : rng.range(0.2, 0.45)))
        let balls = poolBalls(&rng)
        var layout = authoredLayout([:])
        guard place.free(target, layout, holeClear: masse ? 0.0 : 0.05) else { continue }
        layout[balls[0]] = target
        let u = (pk - target).normalized
        let reach = masse ? rng.range(0.32, 0.48) : rng.range(0.6, 1.0)
        let c = r4(target - u * (2 * R + reach))
        let gap = masse ? rng.range(0.13, 0.2) : rng.range(0.22, 0.38)
        let blocker = r4(c + u * gap)
        guard place.free(c, layout), place.free(blocker, layout) else { continue }
        layout[0] = c
        layout[balls[1]] = blocker
        let direct = degrees(of: u)
        var strikes: [Strike] = []
        if masse {
            for angle in [20, 25, 30] { for side in [-0.0135, -0.012, 0.012, 0.0135] { for pw in [0.6, 0.8, 1.0, 1.2] {
                for da in range(-36, 36, 1.5) {
                    strikes.append(Strike(aim: direct + da, power: pw, tipUp: 0, tipSide: side, elevation: AuthoredLessons.sine(forAngle: angle)))
                }
            } } }
        } else {
            for angle in [25, 30, 40] { for pw in range(3.0, 5.5, 0.25) { for da in range(-1.2, 1.2, 0.1) {
                strikes.append(Strike(aim: direct + da, power: pw, tipUp: 0, tipSide: 0, elevation: AuthoredLessons.sine(forAngle: angle)))
            } } }
        }
        out.append(DailyPlan(id: "\(masse ? "masse" : "jump")-\(seed % 1000)-\(i)", family: masse ? .masse : .jump,
                             place: place, layout: layout, goal: Goal(drops: [(balls[0], k)], firstHit: balls[0]),
                             strikes: strikes, want: 3, check: .raisedOnly,
                             note: "\(masse ? "massé" : "jump") past the \(balls[1]) onto the \(balls[0])"))
    }
    return out
}

/// Bumper pool: the marked red (ball 9) into a cup, from random free places, with one or two other balls about.
func bumperPlans(n: Int, seed: UInt64) -> [DailyPlan] {
    let place = DailyPlace(.bumperPool)
    var rng = DailyRandom(seed)
    var out: [DailyPlan] = []
    for i in 0..<n * 8 where out.count < n {
        var layout = authoredLayout([:])
        let cue = r4(Vec2(rng.range(0.12, place.L - 0.12), rng.range(0.08, place.W - 0.08)))
        guard place.free(cue, layout) else { continue }
        layout[0] = cue
        let target = r4(Vec2(rng.range(0.12, place.L - 0.12), rng.range(0.08, place.W - 0.08)))
        guard place.free(target, layout), (target - cue).length > 0.15 else { continue }
        layout[9] = target
        for extra in [1, 10] where rng.next() < 0.6 {
            let q = r4(Vec2(rng.range(0.1, place.L - 0.1), rng.range(0.08, place.W - 0.08)))
            if place.free(q, layout) { layout[extra] = q }
        }
        let cup = 6 + Int(rng.next() * 2) % 2
        let aim0 = degrees(of: target - cue)
        var strikes: [Strike] = []
        for a in aims(aim0, span: 30, step: 0.2) { for pw in [0.7, 1.0, 1.4, 1.9, 2.5] {
            strikes.append(Strike(aim: a, power: pw, tipUp: 0, tipSide: 0))
        } }
        out.append(DailyPlan(id: "bumper-\(seed % 1000)-\(i)", family: nil, place: place, layout: layout,
                             goal: Goal(drops: [(9, cup)], firstHit: 9), strikes: strikes, want: 2,
                             note: "the marked red into cup \(cup - 6)"))
    }
    return out
}

/// Bar billiards: the white off the D area onto the red, which drops in a hole; no skittle may fall.
func barPlans(n: Int, seed: UInt64) -> [DailyPlan] {
    let place = DailyPlace(.barBilliards)
    var rng = DailyRandom(seed)
    var out: [DailyPlan] = []
    for i in 0..<n * 8 where out.count < n {
        var layout = authoredLayout([:])
        let cue = r4(Vec2(rng.range(0.15, 0.45), rng.range(0.12, place.W - 0.12)))
        guard place.free(cue, layout) else { continue }
        layout[0] = cue
        let red = r4(Vec2(rng.range(0.45, place.L - 0.2), rng.range(0.1, place.W - 0.1)))
        guard place.free(red, layout, holeClear: 0.04), (red - cue).length > 0.2 else { continue }
        layout[3] = red
        if rng.next() < 0.5 {
            let q = r4(Vec2(rng.range(0.4, place.L - 0.15), rng.range(0.08, place.W - 0.08)))
            if place.free(q, layout, holeClear: 0.04) { layout[1] = q }
        }
        let aim0 = degrees(of: red - cue)
        var strikes: [Strike] = []
        for a in aims(aim0, span: 6, step: 0.1) { for pw in range(0.8, 2.4, 0.2) { for t in [-0.004, 0, 0.004] {
            strikes.append(Strike(aim: a, power: pw, tipUp: t, tipSide: 0))
        } } }
        out.append(DailyPlan(id: "bar-\(seed % 1000)-\(i)", family: nil, place: place, layout: layout,
                             goal: Goal(drops: [(3, nil)], firstHit: 3), strikes: strikes, want: 2, check: .noPinDown,
                             anyHole: true, note: "the red into a hole, every skittle standing"))
    }
    return out
}

/// Five-pin: the white onto the yellow, then on to the red (a carom), with the object balls knocking pins.
func fivePinPlans(n: Int, seed: UInt64) -> [DailyPlan] {
    let place = DailyPlace(.fivePin)
    var rng = DailyRandom(seed)
    var out: [DailyPlan] = []
    for i in 0..<n * 8 where out.count < n {
        var layout = authoredLayout([:])
        let cue = r4(Vec2(rng.range(0.2, place.L / 2), rng.range(0.15, place.W - 0.15)))
        guard place.free(cue, layout) else { continue }
        layout[0] = cue
        // The yellow 25 to 60 cm from the castle, so the white can send it through the pins on the way.
        let castle = AuthoredTables.FivePin.castleCentre
        let yellow = r4(castle + rotate(Vec2(1, 0), rng.range(0, 360)) * rng.range(0.25, 0.6))
        let red = r4(Vec2(rng.range(0.4, place.L - 0.2), rng.range(0.15, place.W - 0.15)))
        guard place.free(yellow, layout) else { continue }
        layout[1] = yellow
        guard place.free(red, layout), (yellow - cue).length > 0.4, (red - yellow).length > 0.35 else { continue }
        layout[3] = red
        // Aim the white to send the yellow at the castle (its ghost-ball line), and sweep round it.
        let ghost = yellow - (castle - yellow).normalized * (2 * place.R)
        let aim0 = degrees(of: ghost - cue)
        var strikes: [Strike] = []
        for a in aims(aim0, span: 4, step: 0.1) { for pw in range(1.5, 5.0, 0.5) { for t in [-0.008, -0.004, 0, 0.004, 0.008] {
            strikes.append(Strike(aim: a, power: pw, tipUp: t, tipSide: 0))
        } } }
        out.append(DailyPlan(id: "fivepin-\(seed % 1000)-\(i)", family: .carom, place: place, layout: layout,
                             goal: Goal(drops: [], firstHit: 1, secondHit: 3), strikes: strikes, want: 2,
                             check: .pinsByObjectBalls, note: "white onto the yellow, then the red; the pins fall"))
    }
    return out
}

// MARK: The bank's literal

/// One AuthoredDaily "made(...)" line for a found candidate.
func dailyLiteral(_ f: DailyFound) -> String {
    let balls = f.layout.enumerated().filter { NextShot.isOnTable($0.element) }
        .map { String(format: "%d: Vec2(%.4f, %.4f)", $0.offset, $0.element.x, $0.element.y) }.joined(separator: ", ")
    let s = f.strike
    var strike = String(format: "AuthoredStrike(aim: %.2f, power: %.2f, tipUp: %.4f, tipSide: %.4f", s.aim, s.power, s.tipUp, s.tipSide)
    if s.elevation > 0, let angle = offeredCueAngles.first(where: { abs(sineOf(degrees: $0) - s.elevation) < 1e-12 }) {
        strike += ", elevation: AuthoredLessons.sine(forAngle: \(angle))"
    }
    strike += ")"
    let drops = f.goal.drops.map { "AuthoredDrop(\($0.ball), \($0.pocket.map(String.init) ?? "nil"))" }.joined(separator: ", ")
    var goal = "AuthoredGoal(drops: [\(drops)]"
    if let x = f.goal.firstHit { goal += ", firstHit: \(x)" }
    if let x = f.goal.secondHit { goal += ", secondHit: \(x)" }
    if let x = f.goal.bank { goal += ", bank: \(x)" }
    goal += ")"
    var line = "made(\"\(f.id)\", .\(f.family == .throwIn ? "throwIn" : f.family.rawValue)"
    if f.place.table != .standard { line += ", table: .\(f.place.table.rawValue)" }
    if f.place.surface != .cloth { line += ", surface: .\(f.place.surface.rawValue)" }
    line += ",\n             balls: [\(balls)],\n             answer: \(strike),\n             goal: \(goal),\n"
    line += String(format: "             mark: Vec2(%.4f, %.4f), window: AuthoredWindow(aim: %.2f, power: %.2f, tipUp: %.4f, tipSide: %.4f),\n",
                   f.mark.x, f.mark.y, floorTo(f.aimHalf, 0.01), floorTo(f.powerHalf, 0.01), floorTo(f.tipHalf, 0.0005),
                   floorTo(f.sideHalf, 0.0005))
    line += "             difficulty: \(f.difficulty)"
    if let l = f.leave { line += ", leave: \(l)" }
    line += "),"
    return "        " + line
}

/// A window is written rounded down, so it never claims more room than was measured.
func floorTo(_ x: Double, _ step: Double) -> Double { (x / step + 1e-9).rounded(.down) * step }

// MARK: Driver

/// The kinds and what each makes.
func dailyPlans(kind: String, n: Int, seed: UInt64) -> [DailyPlan] {
    let strange: [String: TableSurface] = ["ice": .ice, "glass": .glass, "rubber": .rubber, "cork": .cork,
                                           "carpet": .carpet, "sand": .sand, "moon": .moon]
    if let surface = strange[kind] {
        let place = DailyPlace(.standard, surface)
        // A strange-surface day: a pot, a bank, a draw and a follow on that surface, a quarter of the layouts each,
        // each surface from its own seeds so no two surfaces share a layout.
        let q = max(1, n / 4)
        let seed = seed &* 31 &+ UInt64(TableSurface.allCases.firstIndex(of: surface) ?? 0) &* 1000
        return potPlans(place, n: q, seed: seed, leave: false, want: 2) + bankPlans(place, n: q, seed: seed + 1, want: 2)
            + potPlans(place, n: q, seed: seed + 2, leave: true, want: 2, spin: -1)
            + potPlans(place, n: q, seed: seed + 3, leave: true, want: 2, spin: 1)
    }
    let cloth = DailyPlace()
    switch kind {
    case "pot": return potPlans(cloth, n: n, seed: seed, leave: true, want: 1)
    case "bank": return bankPlans(cloth, n: n, seed: seed, want: 2)
    case "combo": return comboPlans(cloth, n: n, seed: seed, want: 2)
    case "draw": return potPlans(cloth, n: n, seed: seed, leave: true, want: 2, spin: -1)
    case "follow": return potPlans(cloth, n: n, seed: seed &+ 500, leave: true, want: 2, spin: 1)
    case "carom": return pathPlans(cloth, kind: kind, n: n, seed: seed, want: 2)
    case "jump": return raisedPlans(cloth, masse: false, n: n, seed: seed)
    case "masse": return raisedPlans(cloth, masse: true, n: n, seed: seed)
    case "bumper": return bumperPlans(n: n, seed: seed)
    case "bar": return barPlans(n: n, seed: seed)
    case "fivepin": return fivePinPlans(n: n, seed: seed)
    default: return []
    }
}

func runDailyAuthoring(_ args: [String]) {
    let env = ProcessInfo.processInfo.environment
    let seed = UInt64(env["DAILY_SEED"] ?? "") ?? 1
    let n = Int(env["DAILY_PLANS"] ?? "") ?? 40
    let all = ["pot", "bank", "combo", "carom", "draw", "follow", "jump", "masse", "bumper", "bar", "fivepin",
               "ice", "glass", "rubber", "cork", "carpet", "sand", "moon"]
    let kinds = args.isEmpty || args == ["all"] ? all : args
    let folder = URL(fileURLWithPath: env["DAILY_OUT"] ?? "/Volumes/Team 4TB/breakdown-build/bank-out/daily")
    try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    for kind in kinds {
        let t0 = Date()
        let plans = dailyPlans(kind: kind, n: n, seed: seed)
        let found = parallelMap(plans.count) { i in solveDaily(plans[i]) }.compactMap { $0 }
        print("== \(kind): \(plans.count) layouts, \(found.count) shots found (\(String(format: "%.0f", Date().timeIntervalSince(t0))) s)")
        var literals: [String] = []
        #if canImport(CoreGraphics) && canImport(ImageIO) && canImport(CoreText)
        var tiles: [DailyTile] = []
        #endif
        for (i, f) in found.enumerated() {
            print(String(format: "%3d %@ [%@] difficulty %d, aim +-%.2f deg, power +-%.2f, tip +-%.4f, side +-%.4f; %@",
                         i + 1, f.id, f.family.rawValue, f.difficulty, f.aimHalf, f.powerHalf, f.tipHalf, f.sideHalf, f.note))
            literals.append("        // \(i + 1): \(f.note)\n" + dailyLiteral(f))
            #if canImport(CoreGraphics) && canImport(ImageIO) && canImport(CoreText)
            let tl = f.place.sim(f.layout, f.strike)
            tiles.append(DailyTile(title: "\(i + 1). \(f.id) [\(f.family.rawValue)] d\(f.difficulty)",
                                   detail: String(format: "aim +-%.2f  power +-%.2f  tip +-%.1f mm  %@", f.aimHalf,
                                                  f.powerHalf, f.tipHalf * 1000, f.note),
                                   parameters: f.place.p, layout: f.layout, timeline: tl,
                                   goalBalls: f.goal.drops.map(\.ball) + [f.goal.firstHit, f.goal.secondHit].compactMap { $0 },
                                   leave: f.leave, mark: f.mark))
            #endif
        }
        let text = literals.joined(separator: "\n") + "\n"
        try? text.write(to: folder.appendingPathComponent("\(kind).swift.txt"), atomically: true, encoding: .utf8)
        #if canImport(CoreGraphics) && canImport(ImageIO) && canImport(CoreText)
        let sheets = DailyPictures.writeSheets(tiles, folder: folder, stem: kind)
        print("   pictures: \(sheets.map(\.path).joined(separator: ", "))")
        #endif
    }
}
