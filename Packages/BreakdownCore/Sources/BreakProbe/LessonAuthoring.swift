// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: Authors the six lessons of the lesson path (plans/21-Nov-2026-first-minute-and-lessons-plan.md, package 3)
//          with the real solver, the same way TrickAuthoring authors the trick shots: build the layout geometrically,
//          sweep the strike over a small grid, keep what passes the goal, screen out lucky single points, re-centre the
//          survivors in their windows (TrickSearch.measured) and keep the most forgiving one. Run by hand:
//          "BreakProbe lessons [id ...]". Each lesson prints the layout, the reference strike and every window the
//          app's judge and target zones use (aim, power, tip height, side, and for the jump the cue angles that work),
//          ready to copy into App/Lessons/Lessons.swift.
//          The six, in order: stop shot, follow, draw, cut and throw, curve, jump. A lesson is meant to be easier than
//          the trick shot it leads to, so the searches prefer wide windows in the one control the lesson is about.
//          "stop-exercise" (plan 14, section 4): a second straight pot on the stop shot's line with a different
//          cue-to-object distance, kept only when copying the stop lesson's own settings MISSES the finish zone and a
//          change of tip height alone (same aim, same power) makes it. Its output names the band of tip heights that
//          work, so the app's second exercise is checked, not hoped for.
//          Two evidence commands: "lessons scan <object gap> <cue gap> <power>" prints where a straight pot's cue ball
//          finishes for every tip height, and "lessons curvescan" how far a raised-cue side hit bends; both were used to
//          place the follow, draw and curve lessons and are kept so a re-author starts from the same evidence.
//          The default physics throughout (generation two since the proof plan's package 4; what ships); seed 1, as
//          every authored shot. Every tip stays inside the miscue limit (tipReach, about half the radius).
// Edited: Claude Opus 5.5 High, 21-November-2026 (proof plan package 4: tip grids inside the miscue limit, the curve's
//          side at 0.40 and 0.45 of the radius, so the lessons re-author on generation two.)
// SRP/DRY check: Pass - checked TrickAuthoring (its best(), placedOnPath and difficulty bands are reused, not copied)
//          and TrickSearch (simulate, passes, the band walks and measured are reused). Only the lesson layouts, the
//          side and cue-angle windows the trick report does not print, and the exercise check are new here.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation

/// The cue angles the app's cue-angle control offers, in degrees (App/CueAngleControl.swift, CueAngleMenu.angles,
/// copied because the package cannot import app files). A lesson that raises the cue must use one of these, or the
/// player could never set it exactly.
let offeredCueAngles: [Int] = [0, 5, 10, 15, 20, 25, 30, 40, 50, 60, 70, 80]
func sineOf(degrees a: Int) -> Double { a <= 0 ? 0 : sin(Double(a) * Double.pi / 180) }

/// The half-width either side of `centre` inside a band (the smaller side), so a window is honest both ways.
func halfWidth(_ b: (lo: Double, hi: Double)?, around centre: Double) -> Double {
    guard let b else { return 0 }
    return min(centre - b.lo, b.hi - centre)
}

/// The run of offered cue angles around the strike's own angle in which the goal still holds, in degrees.
func cueAngleBand(_ layout: [Vec2], _ s: Strike, _ goal: Goal) -> (lo: Int, hi: Int)? {
    guard let i = offeredCueAngles.firstIndex(where: { abs(sineOf(degrees: $0) - s.elevation) < 1e-9 }) else { return nil }
    func ok(_ k: Int) -> Bool { var t = s; t.elevation = sineOf(degrees: offeredCueAngles[k]); return passes(goal, simulate(layout, t)) }
    guard ok(i) else { return nil }
    var lo = i, hi = i
    while hi + 1 < offeredCueAngles.count, ok(hi + 1) { hi += 1 }
    while lo - 1 >= 0, ok(lo - 1) { lo -= 1 }
    return (offeredCueAngles[lo], offeredCueAngles[hi])
}

/// Prints a lesson as the app's Lessons file carries it: layout, reference strike, and the judge's windows as
/// half-widths (TrickWindow: aim degrees, power m/s, tip height and side metres), plus the cue-angle run if raised.
func reportLesson(_ a: Authored) {
    report(a)
    let s = a.strike
    let side = halfWidth(tipSideBand(a.layout, s, a.goal), around: s.tipSide)
    print(String(format: "   LESSON WINDOW: aim %.2f, power %.2f, tipUp %.4f, tipSide %.4f", a.aimHalfWindow, a.powerHalfWindow,
                 a.tipHalfWindow, side))
    if s.elevation > 0, let e = cueAngleBand(a.layout, s, a.goal) {
        print("   LESSON CUE ANGLES: \(e.lo) to \(e.hi) degrees work")
    }
    if let z = a.goal.cueZone { print(String(format: "   cue zone: centre %@, radius %.2f m", fmt(z.centre), z.radius)) }
    let tl = simulate(a.layout, s)
    print("   events: \(tl.events.count), duration \(String(format: "%.2f", tl.duration)) s")
    // Every event of the reference recording, so the moment the Watch beat stops on is chosen from what the solver
    // records (and whether its caption clears the caption engine's speed gates), not from what the plan expects.
    for e in tl.events {
        let b = e.balls.first
        var line = String(format: "     %.3f s %@ balls %@", e.time, "\(e.kind)", "\(e.balls.map(\.ball))")
        if e.kind == .phaseTransition { line += " \(e.phaseFrom) -> \(e.phaseTo) flight \(e.flight)" }
        if let b { line += String(format: " speed %.2f -> %.2f m/s", b.velocityBefore.length, b.velocityAfter.length) }
        print(line)
    }
}

// MARK: Straight pots: stop, follow, draw

/// A straight-in pot into the top-right corner: the object ball `objectGap` from the pocket, the cue ball `cueGap`
/// behind it on the same line. Returns the layout, the line's unit direction and the ghost-ball spot (where the cue
/// ball is at contact).
func straightPot(objectGap: Double, cueGap: Double, ball: Int = 3) -> (layout: [Vec2], u: Vec2, ghost: Vec2) {
    let pocket = pockets[3]
    // Along the corner's diagonal (at about 37 degrees, the table's own diagonal slope), so the pot is the one a
    // player meets most often and the line is easy to read from any camera.
    let u = unit(pocket - Vec2(L * 0.5, W * 0.5))
    let a = pocket - u * objectGap
    let c = a - u * cueGap
    return (layoutOf([0: c, ball: a]), u, a - u * (2 * R))
}

/// Stop shot: the cue ball must stop within 5 cm (under a ball's width) of the spot where it struck.
func authorLessonStop() -> Authored? {
    var cands: [Candidate] = []
    for og in [0.35, 0.45] { for cg in [0.25, 0.32, 0.4] {
        let s = straightPot(objectGap: og, cueGap: cg)
        let goal = Goal(drops: [(3, 3)], cueZone: (s.ghost, 0.05), firstHit: 3)
        for p in range(1.0, 3.0, 0.25) { for t in range(-0.014, 0.0, 0.001) {
            cands.append(Candidate(layout: s.layout, strike: Strike(aim: degrees(of: s.u), power: p, tipUp: t, tipSide: 0),
                                   goal: goal, note: String(format: "stop shot: object %.2f m from the pocket, cue %.2f m back", og, cg)))
        } }
    } }
    return best("lesson-stop", cands, .easy)
}

/// Follow: the cue ball must roll on past the contact spot and finish in a zone well ahead of it (radius 0.15 m centred
/// `ahead` past contact), so it reads as "roll on to the marked stretch" and rewards follow, not a millimetre-perfect
/// tip. Kept only when a centre-ball hit with the same aim and power misses the zone, so the follow is really what
/// makes it. Why these numbers: a first run with a 0.08 m zone chose a centre hit with a tip window of half a
/// millimetre; "lessons scan" then showed that at 2 m/s each millimetre of tip moves the finish 0.1 to 0.2 m, while
/// at 1.2 m/s from 1 m out it moves about 3 cm, so the search was moved to soft strokes and a long run to the pocket.
func authorLessonFollow() -> Authored? {
    var cands: [Candidate] = []
    for og in [1.0, 1.1] { for cg in [0.25, 0.3] { for ahead in [0.7, 0.8] {
        let s = straightPot(objectGap: og, cueGap: cg)
        let goal = Goal(drops: [(3, 3)], cueZone: (s.ghost + s.u * ahead, 0.15), firstHit: 3)
        for p in range(0.9, 2.0, 0.1) { for t in range(0.004, 0.014, 0.001) {
            cands.append(Candidate(layout: s.layout, strike: Strike(aim: degrees(of: s.u), power: p, tipUp: t, tipSide: 0),
                                   goal: goal, note: String(format: "follow: object %.2f m out, cue %.2f m back, zone %.2f m past contact", og, cg, ahead)))
        } }
    } } }
    return best("lesson-follow", cands, .easy) { a in
        var centre = a.strike; centre.tipUp = 0
        return !passes(a.goal, simulate(a.layout, centre))
    }
}

/// Draw: the cue ball must come back from the contact spot and finish in a wide zone behind it (radius 0.25 m centred
/// `back` behind contact), for the same reason as follow; soft strokes and a short gap to the object ball keep the
/// backspin alive to contact without making each millimetre of tip worth half a metre ("lessons scan 0.4 0.25 1.4":
/// about 0.1 to 0.15 m per millimetre around the zone). Kept only when a centre-ball hit misses.
func authorLessonDraw() -> Authored? {
    var cands: [Candidate] = []
    for og in [0.4, 0.5] { for cg in [0.2, 0.25] { for back in [0.45, 0.5] {
        let s = straightPot(objectGap: og, cueGap: cg)
        let goal = Goal(drops: [(3, 3)], cueZone: (s.ghost - s.u * back, 0.25), firstHit: 3)
        for p in range(1.0, 2.5, 0.1) { for t in range(-0.014, -0.004, 0.001) {
            cands.append(Candidate(layout: s.layout, strike: Strike(aim: degrees(of: s.u), power: p, tipUp: t, tipSide: 0),
                                   goal: goal, note: String(format: "draw: object %.2f m out, cue %.2f m back, zone %.2f m behind contact", og, cg, back)))
        } }
    } } }
    return best("lesson-draw", cands, .easy) { a in
        var centre = a.strike; centre.tipUp = 0
        return !passes(a.goal, simulate(a.layout, centre))
    }
}

// MARK: Cut and throw

/// A cut into the top-right corner. The answer sits a touch fuller than the geometric ghost ball, because friction at
/// contact throws the object ball a little along the cue ball's path; the report prints both aims so the lesson's
/// claim is checked, not assumed.
func authorLessonCut() -> Authored? {
    var cands: [Candidate] = []
    for og in [0.35, 0.5] { for cut in [25.0, 30.0, -25.0, -30.0] {
        let pocket = pockets[3]
        let u = unit(pocket - Vec2(L * 0.5, W * 0.5))
        let a = pocket - u * og
        let ghost = a - u * (2 * R)
        let c = ghost - rotate(u, cut) * 0.45
        guard clearOfRails(c) else { continue }
        let layout = layoutOf([0: c, 3: a])
        let aim0 = degrees(of: unit(ghost - c))
        for da in range(-2, 2, 0.05) { for p in [1.5, 2.0, 2.5, 3.0] {
            cands.append(Candidate(layout: layout, strike: Strike(aim: aim0 + da, power: p, tipUp: 0, tipSide: 0),
                                   goal: Goal(drops: [(3, 3)], firstHit: 3),
                                   note: String(format: "cut of %.0f deg, object %.2f m out; geometric ghost aim %.3f deg", cut, og, aim0)))
        } }
    } }
    return best("lesson-cut", cands, .easy)
}

// MARK: Curve

/// A ball half-blocks the straight line to the target. Raise the cue and strike right of centre: the cue ball sets off
/// to the left of the blocker and bends back to the right onto the target, touching it first. Only touching the
/// target first is asked (no pot): the lesson is the curve. Kept only if the same strike with a level cue misses.
/// Why the blocker is off the line: "lessons curvescan" shows that on generation one a raised cue with right side
/// sends the cue ball off a few degrees right of the aim and bends it a further 10 to 25 degrees right while it slides
/// (more with a steeper cue, less with more pace). That is too little to pass a ball sitting dead on the line and come
/// back to it within half a metre (three earlier runs with the blocker on the line, aims to 45 degrees, cue angles 25
/// to 60, never once reached the target; the authored masse trick gets its extra turn from a cushion). With the
/// blocker's centre about a radius right of the line, the cue ball only has to bow about a radius to the left.
func authorLessonCurve() -> Authored? {
    var cands: [Candidate] = []
    let c = Vec2(1.0, 0.635)
    for reach in [0.45, 0.55] { for gap in [0.2, 0.25] { for shift in [0.8 * R, 1.2 * R] {
        let target = c + Vec2(reach, 0)
        let blocker = c + Vec2(gap, -shift)
        let layout = layoutOf([0: c, 4: blocker, 9: target])
        for angle in [30, 40, 50, 60] { for side in [0.4 * R, 0.45 * R] { for p in [0.5, 0.6, 0.8, 1.0, 1.2, 1.5] {
            for da in range(0, 30, 1.0) { for up in [0.0, -0.004] {
                cands.append(Candidate(layout: layout,
                                       strike: Strike(aim: da, power: p, tipUp: up, tipSide: side, elevation: sineOf(degrees: angle)),
                                       goal: Goal(drops: [], firstHit: 9),
                                       note: String(format: "curve round the 4 onto the 9: target %.2f m, blocker %.2f m ahead and %.3f m right, cue %d deg", reach, gap, shift, angle)))
            } }
        } } }
    } } }
    print("   lesson-curve: \(cands.count) candidates")
    if ProcessInfo.processInfo.environment["LESSON_DIAG"] != nil {
        // What the candidates actually do: which ball the cue ball reaches first, and how many scratch.
        let fixed = cands
        let outcomes = parallelMap(fixed.count) { i -> String in
            let tl = simulate(fixed[i].layout, fixed[i].strike)
            return "first \(firstStruck(tl).map(String.init) ?? "none")\(tl.pocketTime[0] != nil ? " scratch" : "")"
        }
        var counts: [String: Int] = [:]
        for o in outcomes { counts[o, default: 0] += 1 }
        print("   lesson-curve diag: \(counts.sorted { $0.key < $1.key })")
    }
    return best("lesson-curve", cands, .easy) { a in
        var level = a.strike; level.elevation = 0
        return !passes(a.goal, simulate(a.layout, level))
    }
}

// MARK: Jump

/// A ball sits straight in the way, the target beyond it. Raise the cue: the cue ball leaves the cloth, clears the
/// blocker and lands to touch the target first. Kept only if the same strike with a level cue hits the blocker.
func authorLessonJump() -> Authored? {
    var cands: [Candidate] = []
    let c = Vec2(1.0, 0.635)
    for gap in [0.25, 0.3] { for reach in [0.8, 1.0] {
        let layout = layoutOf([0: c, 6: c + Vec2(gap, 0), 11: c + Vec2(reach, 0)])
        for angle in [20, 25, 30, 40] { for p in range(3.0, 5.5, 0.25) { for da in range(-1, 1, 0.25) {
            cands.append(Candidate(layout: layout,
                                   strike: Strike(aim: da, power: p, tipUp: 0, tipSide: 0, elevation: sineOf(degrees: angle)),
                                   goal: Goal(drops: [], firstHit: 11),
                                   note: String(format: "jump the 6 onto the 11: blocker %.2f m, target %.2f m, cue %d deg", gap, reach, angle)))
        } } }
    } }
    print("   lesson-jump: \(cands.count) candidates")
    return best("lesson-jump", cands, .easy) { a in
        var level = a.strike; level.elevation = 0
        guard !passes(a.goal, simulate(a.layout, level)) else { return false }
        // The lesson is about the cue angle, so at least two neighbouring angles of the control must work: a first
        // run chose a strike that only 40 degrees made, which leaves no band to draw and no room to learn in.
        guard let band = cueAngleBand(a.layout, a.strike, a.goal) else { return false }
        return band.lo < band.hi
    }
}

// MARK: The stop shot's second exercise (plan 14, section 4)

/// The stop lesson as the app carries it (copied from App/Lessons/Lessons.swift once authored; KEEP IN STEP).
/// Read by the exercise search below and by ContentVerify.
let lessonStopForExercise = (layout: authoredLessons[0].layout, strike: authoredLessons[0].strike)

/// On the stop lesson's own line, the cue ball moved to a different distance from the object ball. Copying the
/// lesson's settings (same aim, power and tip) must miss the finish zone; a tip-height change alone must make it.
func authorStopExercise() {
    let lesson = lessonStopForExercise
    let a = lesson.layout[3], c0 = lesson.layout[0]
    let u = unit(a - c0)
    let ghost = a - u * (2 * R)
    let goal = Goal(drops: [(3, 3)], cueZone: (ghost, 0.05), firstHit: 3)
    print("== stop-exercise: the stop lesson strikes \(lesson.strike) from \(fmt(c0))")
    var bestFound: (gap: Double, band: (lo: Double, hi: Double), centre: Double)?
    // Further back than the lesson's 0.25 m only: the exercise's words say "the cue ball further back" (four
    // translated strings). A first run tried only 0.6 to 1.0 m, where at the lesson's soft 1.4 m/s no tip height keeps
    // the backspin alive to contact. On generation two the draw a tip inside the miscue limit can give runs out near
    // 0.4 m at the lesson's first 1.4 m/s; the lesson was re-authored at 1.9 m/s (21-Nov-2026), where the exercise
    // works from about 0.5 to 0.6 m (a one-off scan of lesson pace against exercise distance; its table is in the
    // proof plan's Measured section).
    for gap in [0.3, 0.35, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65] {
        let layout = layoutOf([0: a - u * gap, 3: a])
        let copy = passes(goal, simulate(layout, lesson.strike))
        // The band of tip heights that work with the lesson's own aim and power, walked from every millimetre so a
        // band anywhere in reach is found, then the widest kept.
        var widest: (lo: Double, hi: Double)?
        for t0 in range(-0.014, 0.0, 0.001) {
            if let b = band(centre: t0, step: 0.0005, limit: 0.02, { v in
                guard insideGrip(up: v, side: lesson.strike.tipSide) else { return false }
                var t = lesson.strike; t.tipUp = v; return passes(goal, simulate(layout, t))
            }), widest == nil || b.hi - b.lo > widest!.hi - widest!.lo { widest = b }
        }
        let line = widest.map { String(format: "tip %+.4f to %+.4f m works", $0.lo, $0.hi) } ?? "no tip height works"
        print(String(format: "   cue %.2f m back: copying the lesson %@; %@", gap, copy ? "MAKES IT (rejected)" : "misses", line))
        guard !copy, let b = widest, b.lo > lesson.strike.tipUp || b.hi < lesson.strike.tipUp else { continue }
        // Kept: a working band at least 4 mm wide (two of the lesson's own half-windows), then the one whose band is
        // FURTHEST from the lesson's tip, so copying the demonstration misses clearly rather than by a millimetre and
        // the change a player has to make is one they can see on the cue-ball picture.
        guard b.hi - b.lo >= 0.004 - 1e-9 else { continue }
        func margin(_ x: (lo: Double, hi: Double)) -> Double {
            x.lo > lesson.strike.tipUp ? x.lo - lesson.strike.tipUp : lesson.strike.tipUp - x.hi
        }
        if bestFound == nil || margin(b) > margin(bestFound!.band) {
            bestFound = (gap, b, ((b.lo + b.hi) / 2 / 0.0005).rounded() * 0.0005)
        }
    }
    guard let f = bestFound else { print("== stop-exercise: NO SOLUTION FOUND"); return }
    let layout = layoutOf([0: a - u * f.gap, 3: a])
    var s = lesson.strike; s.tipUp = f.centre
    let aim = aimBand(layout, s, goal, step: 0.02, limit: 4)
    let power = band(centre: s.power, step: 0.05, limit: 4) { v in
        guard v >= 0.5, v <= 8 else { return false }
        var t = s; t.power = v; return passes(goal, simulate(layout, t))
    }
    let side = tipSideBand(layout, s, goal)
    print("== stop-exercise: cue \(f.gap) m back, reference \(s)")
    print("   layout: [0: \(fmt(layout[0])), 3: \(fmt(layout[3]))]; zone centre \(fmt(ghost)) radius 0.05")
    print(String(format: "   EXERCISE WINDOW: aim %.2f, power %.2f, tipUp %.4f, tipSide %.4f", halfWidth(aim, around: s.aim),
                 halfWidth(power, around: s.power), halfWidth(f.band, around: s.tipUp), halfWidth(side, around: s.tipSide)))
}

// MARK: Scan

/// "lessons scan <og> <cg> <power>": for a straight pot, how far past (+) or short of (-) the contact spot the cue ball
/// finishes for every tip height, and whether the 3 drops. The evidence for choosing a follow or draw zone that a
/// player can actually hit: it shows how quickly the finish moves with the tip.
func scanStraightPot(_ og: Double, _ cg: Double, _ power: Double) {
    let s = straightPot(objectGap: og, cueGap: cg)
    print(String(format: "== scan: object %.2f m out, cue %.2f m back, power %.2f m/s", og, cg, power))
    for t in range(-0.02, 0.02, 0.001) {
        let tl = simulate(s.layout, Strike(aim: degrees(of: s.u), power: power, tipUp: t, tipSide: 0))
        let along = (cueRest(tl) - s.ghost).dot(s.u)
        print(String(format: "   tip %+.3f: finish %+.3f m along the line, 3 %@, cue %@", t, along,
                     pocketOf(3, tl) == 3 ? "in" : "up", tl.pocketTime[0] == nil ? "up" : "IN"))
    }
}

/// "lessons curvescan": the cue ball alone on an open table, struck along +x with a raised cue and side: how far it
/// bends (degrees between its first and last heading) and where it ends up, for each cue angle, side and power. The
/// evidence for how big a curve the solver gives, so the curve lesson's blocker is placed where a curve can pass it.
func scanCurve() {
    let c = Vec2(0.8, 0.635)
    for angle in [20, 30, 40, 50, 60] { for side in [0.6 * R, 0.75 * R] { for p in [0.6, 1.0, 1.5, 2.0] {
        let tl = simulate(layoutOf([0: c]), Strike(aim: 0, power: p, tipUp: -0.004, tipSide: side, elevation: sineOf(degrees: angle)))
        let path = cuePath(tl, fromStart: true)
        guard path.count > 3 else { continue }
        let first = unit(path[2].p - path[0].p), end = path[path.count - 1].p
        let last = unit(end - path[max(0, path.count - 4)].p)
        let bend = degrees(of: last) - degrees(of: first)
        print(String(format: "   cue %d deg, side %.4f, %.1f m/s: leaves at %.1f deg, bends %.1f deg, ends at %@ (%.2f m along, %+.2f m aside)",
                     angle, side, p, degrees(of: first), bend, fmt(end), end.x - c.x, end.y - c.y))
    } } }
}

// MARK: Driver

func runLessonAuthoring(only: Set<String>, arguments: [String] = []) {
    if arguments.first == "curvescan" { scanCurve(); return }
    if arguments.first == "scan", arguments.count >= 4, let og = Double(arguments[1]), let cg = Double(arguments[2]),
       let p = Double(arguments[3]) {
        scanStraightPot(og, cg, p)
        return
    }
    let all: [(String, () -> Authored?)] = [
        ("stop", authorLessonStop), ("follow", authorLessonFollow), ("draw", authorLessonDraw),
        ("cut", authorLessonCut), ("curve", authorLessonCurve), ("jump", authorLessonJump),
    ]
    for (id, author) in all where only.isEmpty || only.contains(id) {
        let start = Date()
        if let a = author() { reportLesson(a) } else { print("== lesson-\(id): NO SOLUTION FOUND") }
        print(String(format: "   (search took %.1f s)", Date().timeIntervalSince(start)))
    }
    if only.isEmpty || only.contains("stop-exercise") { authorStopExercise() }
}
