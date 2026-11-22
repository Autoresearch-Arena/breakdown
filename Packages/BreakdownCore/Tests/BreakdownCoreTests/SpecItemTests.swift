// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The spec's unit-test list (docs/2026-11-02-breakdown-spec.md section 9.1) finished: one test per item that
//          had no test, named after its number (plans/21-Nov-2026-physics-proof-plan.md package 2). Each test solves
//          small shots with the real solver and compares them with an answer worked out by hand or by an independent
//          method: the rolling cue ball's departure formula (item 2), a mirror-image shot (7), a tiny-step numerical
//          integration of the sliding equations (8), a brute-force root search (9), two hundred seeded breaks (11),
//          continuity at every phase change (17), the spin-down time (18), the energy ledger (19), a stale contact
//          that must be dropped (20), frozen balls (21), relabelled balls (23) and the impact formulas (24).
//          Where each of the other items lives, or why it does not apply here, is written in the list below.
//          All of these run at generation 1 (the default parameters), the physics every trick shot was authored on.
//
//          The spec's items and where they are tested:
//           1 stun shot, ninety degrees ........ PhysicsTests.testNinetyDegreeRule
//           2 rolling cue ball departure ....... here, testItem02RollingCueBallDeparture
//           3a cushion mirror .................. PhysicsTests.testCushionMirrorAngle (generation 1's rail is the flat
//                                                 one the item describes)
//           3b real rail angle, 4 side spin on a rail, 12 cue strike: written by the solver builder with the real-rail
//                                                 and cue-strike work (plans/21-Nov-2026-rails-plan.md and
//                                                 plans/21-Nov-2026-cue-strike-plan.md), not here
//           5 energy never rises ............... PhysicsTests.testMomentumAndEnergyAtEveryEvent, and the cushion and
//                                                 landing checks in PocketTests and JumpTests' random sweeps
//           6 momentum at ball-ball events ..... PhysicsTests.testMomentumAndEnergyAtEveryEvent, here in item 11
//           7 mirror symmetry .................. here
//           8 closed form against integration .. here; the rolling stop distance is PhysicsTests.testRollingStopDistance
//           9 quartic solver ................... here (PhysicsTests.testRootFinder only had lines and a parabola)
//          10 repeatability .................... PhysicsTests.testRepeatability, JumpTests.testRaisedStrikeRepeats
//          11 rack break over many seeds ....... here
//          13 jump ............................. JumpTests
//          14 golden shots ..................... JumpTests.testLevelStrikesAreBitForBitUnchanged (five recordings'
//                                                 hashes) and PhysicsTests.testDefaultBreakPocketsABall
//          15 timeline file round trip ......... does not apply yet. There is no timeline file: a recording lives
//                                                 in memory from the solve to the end of its replay, and nothing in
//                                                 the package or the app writes one to disk or reads one back (only a
//                                                 saved match's ball layout will be stored, as plain positions).
//                                                 Replay equality is the content hash, tested under 10 and 14. When a
//                                                 recording file is added, its round-trip and unknown-version tests
//                                                 belong with it.
//          16 Lens captions fire only on their events: the caption engine is app code (App/Captions.swift), which
//                                                 this package cannot import; it belongs to the app's own test target
//                                                 (plans/21-Nov-2026-release-safety-plan.md package 2)
//          17 continuity ....................... PhysicsTests.testSegmentsAreContinuousExceptAtImpacts (position);
//                                                 here for velocity and spin at phase changes and orientation always
//          18 spin-down ........................ here
//          19 energy ledger closes ............. here
//          20 stale events dropped ............. here
//          21 frozen balls ..................... here
//          22 airborne path .................... JumpTests (landing, clearing a ball, flying over a cushion)
//          23 relabelled balls ................. here
//          24 impact oracles ................... here; the pocket half (slow centred ball drops, a clipped knuckle
//                                                 rejects, rattles) is PocketTests; the rattle guard (the jam guard)
//                                                 comes with plans/21-Nov-2026-pockets-and-jams-plan.md part B
//          25 no math library in the solver .... PhysicsTests.testPhysicsModuleHasNoFoundationImport
// Edited: Claude Opus 5.5 High, 21-November-2026 (proof plan package 4: item 17 allows the solver's documented snap to
//          rest; item 23's hand-built shot names generation one, where it has no ties.)
// SRP/DRY check: Pass - checked PhysicsTests, PocketTests, JumpTests, TableFeatureTests, PhysicsSwitchTests,
//          ShotFactsTests and MatchContractTests line by line against section 9.1; only items with no test, or with a
//          test that covers part of the item, are written here, and the list above says which file has the rest.
import BreakdownLensModel
import BreakdownTimeline
@testable import BreakdownPhysics
import Foundation
import XCTest

final class SpecItemTests: XCTestCase {
    private let p = PoolParameters()

    /// Sixteen positions with only the named balls on the table.
    private func layout(_ balls: [Int: Vec2]) -> [Vec2] {
        var out = [Vec2](repeating: NextShot.offTable, count: 16)
        for (k, v) in balls { out[k] = v }
        return out
    }

    private func solve(_ positions: [Vec2], dir: Vec2, speed: Double, tipUp: Double = 0, tipSide: Double = 0,
                       parameters: PoolParameters? = nil, seed: UInt64 = 1) -> Timeline {
        PoolSolver.simulate(ShotInput(parameters: parameters ?? p, positions: positions,
                                      strike: CueStrike(direction: dir, speed: speed, tipUp: tipUp, tipSide: tipSide),
                                      seed: seed))
    }

    /// Kinetic plus spin energy of a ball on the cloth, joules.
    private func energy(_ k: BallKinematics, _ q: PoolParameters) -> Double {
        0.5 * q.ballMass * k.velocity.lengthSquared + 0.5 * q.inertia * k.omega.lengthSquared
    }

    // MARK: Item 2

    // A rolling cue ball that hits an object ball leaves along the tangent line, then its forward roll bends it: once
    // it rolls again its velocity is (5/7) v_t + (2/7) v_0, where v_t is its velocity just after the hit and v_0 just
    // before. Derivation: with no ball-ball friction the hit leaves the spin alone, so the cloth contact slips at
    // v_t - v_0 (the roll still matches v_0). Sliding friction takes slip out at 7/2 times the rate it takes speed, so
    // when the slip is gone the speed has changed by 2/7 of the slip. Oracle conditions from the spec: restitution 1,
    // no ball-ball friction, cloth sliding only. Then the spec's thirty-degree band: across cut angles 15 to 50 degrees
    // the rolling path turns 25 to 40 degrees off the original line (by the formula: 28 degrees at 15, 34 at 30, 26.5
    // at 50).
    func testItem02RollingCueBallDeparture() {
        var q = PoolParameters()
        q.ballBallRestitution = 1
        q.ballBallFrictionFloor = 0; q.ballBallFrictionGain = 0
        let r = q.ballRadius
        let cue = Vec2(0.5, 0.6)
        for cut in Swift.stride(from: 15.0, through: 50.0, by: 5.0) {
            let phi = cut * Double.pi / 180
            // The object ball sits so the cue ball, running along y = 0.6, meets it with the line of centres at `cut`.
            let object = Vec2(cue.x + 0.3 + 2 * r * cos(phi), cue.y + 2 * r * sin(phi))
            // A tip offset of 2/5 R above centre makes the ball roll from the first instant (spin R w = v).
            let tl = solve(layout([0: cue, 1: object]), dir: Vec2(1, 0), speed: 1.0, tipUp: 0.4 * r, parameters: q)
            XCTAssertEqual(tl.segments[0][0].phase, .rolling, "cut \(cut): the cue ball should roll from the start")
            guard let hit = tl.events.first(where: { $0.kind == .ballBall }),
                  let mine = hit.balls.first(where: { $0.ball == 0 }) else {
                XCTFail("cut \(cut): the cue ball never reached the object ball"); continue
            }
            guard let rolls = tl.events.first(where: { $0.kind == .phaseTransition && $0.time > hit.time
                                                        && $0.phaseFrom == .sliding && $0.phaseTo == .rolling
                                                        && $0.balls.first?.ball == 0 }) else {
                XCTFail("cut \(cut): the cue ball never rolled again"); continue
            }
            let expected = mine.velocityAfter * (5.0 / 7) + mine.velocityBefore * (2.0 / 7)
            let got = rolls.balls[0].velocityAfter
            XCTAssertEqual((got - expected).length, 0, accuracy: 1e-9, "cut \(cut): rolling velocity off the formula")
            let before = mine.velocityBefore
            let cosine = min(1, got.dot(before) / (got.length * before.length))
            let turn = acos(cosine) * 180 / Double.pi
            XCTAssertGreaterThanOrEqual(turn, 25, "cut \(cut): turned only \(turn) degrees")
            XCTAssertLessThanOrEqual(turn, 40, "cut \(cut): turned \(turn) degrees")
        }
    }

    // MARK: Item 7

    // A shot and its mirror image across the table's long centre line (y -> W - y) come out as mirror images. The
    // table is symmetric about that line: pockets 0 and 2, 1 and 3, 4 and 5 swap, and every jaw is built by sign flips.
    // (The spec says "a plane through the origin"; the solver's origin is a corner, so the table's own centre line is
    // the plane that maps the table onto itself.) Under the reflection the aim's y flips, side spin flips (right of
    // the cue becomes left) and draw or follow stays. Spin is a pseudovector: the component along the plane's normal
    // (y) keeps its sign, the two in the plane (x and the vertical z) flip. Ball numbers stay the same, so the event
    // order is the same. Tolerance one nanometre: the reflected start W - y already rounds in the last bit, and each
    // event's root finding carries that forward; anything a player could see is a million times larger.
    // Last, a shot straight along the centre line is its own mirror image, and every ball stays exactly on the line.
    func testItem07MirrorSymmetry() {
        let W = p.tableWidth
        func mirror(_ v: Vec2) -> Vec2 { NextShot.isOnTable(v) ? Vec2(v.x, W - v.y) : v }
        let swapPocket = [2, 3, 0, 1, 5, 4]
        struct Shot { var balls: [Int: Vec2]; var dir: Vec2; var speed: Double; var up: Double; var side: Double }
        let shots = [
            Shot(balls: [0: Vec2(0.5, 0.4), 1: Vec2(1.3, 0.55), 2: Vec2(1.9, 0.92)], dir: Vec2(1, 0.17), speed: 3.0,
                 up: 0.006, side: -0.008),
            Shot(balls: [0: Vec2(0.7, 0.3)], dir: Vec2(0.6, 0.8), speed: 2.5, up: -0.01, side: 0.01),
            Shot(balls: [0: Vec2(0.4, 0.9), 3: Vec2(1.0, 0.7), 5: Vec2(1.5, 0.35), 9: Vec2(2.1, 0.6)],
                 dir: Vec2(1, -0.31), speed: 4.0, up: 0.004, side: 0.006),
        ]
        for (k, s) in shots.enumerated() {
            let start = layout(s.balls)
            let a = solve(start, dir: s.dir, speed: s.speed, tipUp: s.up, tipSide: s.side)
            let b = solve(start.map(mirror), dir: Vec2(s.dir.x, -s.dir.y), speed: s.speed, tipUp: s.up, tipSide: -s.side)
            XCTAssertEqual(a.events.count, b.events.count, "shot \(k): different number of events")
            for (ea, eb) in zip(a.events, b.events) {
                XCTAssertEqual(ea.kind, eb.kind, "shot \(k): event kinds differ")
                XCTAssertEqual(ea.time, eb.time, accuracy: 1e-9, "shot \(k): event times differ")
                XCTAssertEqual(ea.balls.map(\.ball), eb.balls.map(\.ball), "shot \(k): event balls differ")
                if ea.kind == .pocket { XCTAssertEqual(swapPocket[ea.pocket], eb.pocket, "shot \(k): pockets differ") }
            }
            // Mid-shot and at rest: positions and velocities mirror; spin keeps y, flips x and z.
            for t in [a.duration * 0.25, a.duration * 0.5, a.duration + 1] {
                for ball in 0..<16 where NextShot.isOnTable(start[ball]) {
                    let sa = a.state(ball: ball, at: t), sb = b.state(ball: ball, at: t)
                    XCTAssertEqual(sa.pocketed, sb.pocketed, "shot \(k) ball \(ball) t \(t)")
                    XCTAssertEqual((mirror(sa.position) - sb.position).length, 0, accuracy: 1e-9, "shot \(k) ball \(ball) t \(t)")
                    XCTAssertEqual((Vec2(sa.velocity.x, -sa.velocity.y) - sb.velocity).length, 0, accuracy: 1e-9)
                    XCTAssertEqual(sa.omega.x, -sb.omega.x, accuracy: 1e-6)
                    XCTAssertEqual(sa.omega.y, sb.omega.y, accuracy: 1e-6)
                    XCTAssertEqual(sa.omega.z, -sb.omega.z, accuracy: 1e-6)
                }
            }
        }
        // On the axis: a draw shot straight down the centre line into a ball and back off the foot rail. No sideways
        // velocity ever appears, so every resting place is exactly on the line, bit for bit.
        let onAxis = solve(layout([0: Vec2(0.5, W / 2), 1: Vec2(1.2, W / 2)]), dir: Vec2(1, 0), speed: 3, tipUp: -0.005)
        for ball in [0, 1] {
            let s = onAxis.state(ball: ball, at: onAxis.duration + 1)
            XCTAssertEqual(s.position.y, W / 2, "ball \(ball) left the centre line")
        }
    }

    // MARK: Item 8

    // The sliding segment against an independent numerical integration. The sliding equations (spec 3.1): the contact
    // slip u = v + w x (-R z); dv/dt = -mu g u/|u|; the horizontal spin changes at 5 mu g / (2R) about z x u/|u|; the
    // vertical spin falls at spinDecay. A fourth-order Runge-Kutta integrator with a 10-microsecond step recomputes the
    // slip direction at every stage (it does not assume the direction stays fixed, which is what the closed form
    // relies on) and is compared with the solver's segment at ten times through the slide, in position, velocity and
    // spin. The slide must also end at 2 |u0| / (7 mu g). Tolerances: a nanometre and a nanometre per second, a
    // micro-radian per second for spin (the integrator is far more accurate than that over 40,000 steps).
    func testItem08ClosedFormMatchesTinyStepIntegration() {
        let start = Vec2(0.4, 0.3)
        let tl = solve(layout([0: start]), dir: Vec2(1, 0.3), speed: 1.5, tipUp: -0.008, tipSide: 0.006)
        let seg = tl.segments[0][0]
        XCTAssertEqual(seg.phase, .sliding)
        let R = p.ballRadius, mu = p.slidingFriction, g = p.gravity
        let u0 = Vec2(seg.velocity0.x - R * seg.omega0.y, seg.velocity0.y + R * seg.omega0.x)
        XCTAssertEqual(seg.t1 - seg.t0, 2 * u0.length / (7 * mu * g), accuracy: 1e-12,
                       "the slide should end when the slip is gone, not at another event")

        // State: x, y, vx, vy, wx, wy, wz.
        typealias S = [Double]
        func rate(_ s: S) -> S {
            let u = Vec2(s[2] - R * s[5], s[3] + R * s[4])
            let l = u.length
            let h = l > 0 ? u * (1 / l) : .zero
            let spin = 5 * mu * g / (2 * R)
            let wz = s[6] > 0 ? -p.spinDecay : (s[6] < 0 ? p.spinDecay : 0)
            return [s[2], s[3], -mu * g * h.x, -mu * g * h.y, -h.y * spin, h.x * spin, wz]
        }
        func step(_ s: S, _ dt: Double) -> S {
            func add(_ a: S, _ b: S, _ f: Double) -> S { (0..<a.count).map { a[$0] + b[$0] * f } }
            let k1 = rate(s), k2 = rate(add(s, k1, dt / 2)), k3 = rate(add(s, k2, dt / 2)), k4 = rate(add(s, k3, dt))
            return (0..<s.count).map { s[$0] + dt / 6 * (k1[$0] + 2 * k2[$0] + 2 * k3[$0] + k4[$0]) }
        }
        var s: S = [seg.position0.x, seg.position0.y, seg.velocity0.x, seg.velocity0.y,
                    seg.omega0.x, seg.omega0.y, seg.omega0.z]
        var now = seg.t0
        for k in 1...10 {
            // Ten times through the slide, stopping short of its very end where the slip direction is undefined.
            let target = seg.t0 + (seg.t1 - seg.t0) * 0.095 * Double(k)
            let n = Int(((target - now) / 1e-5).rounded(.up))
            let dt = (target - now) / Double(n)
            for _ in 0..<n { s = step(s, dt) }
            now = target
            let c = seg.kinematics(at: target)
            XCTAssertEqual(c.position.x, s[0], accuracy: 1e-9, "x at sample \(k)")
            XCTAssertEqual(c.position.y, s[1], accuracy: 1e-9, "y at sample \(k)")
            XCTAssertEqual(c.velocity.x, s[2], accuracy: 1e-9, "vx at sample \(k)")
            XCTAssertEqual(c.velocity.y, s[3], accuracy: 1e-9, "vy at sample \(k)")
            XCTAssertEqual(c.omega.x, s[4], accuracy: 1e-6, "wx at sample \(k)")
            XCTAssertEqual(c.omega.y, s[5], accuracy: 1e-6, "wy at sample \(k)")
            XCTAssertEqual(c.omega.z, s[6], accuracy: 1e-6, "wz at sample \(k)")
        }
    }

    // MARK: Item 9

    // The root finder against roots known in advance and a brute-force sign-change search. Random quartics are built
    // from their factors (two real roots and either two more real roots or a pair with no real root), signed so the
    // value at zero is positive, as every contact polynomial is; the first down-crossing in [0, 2] is then the
    // smallest real root inside the window. Cases with two roots closer than a hundredth of a second of each other or
    // of the window's ends are skipped, because a sign-change search cannot see them (they are the near-double cases
    // tested on their own below). Then constructed near-double roots: (t - 1)^2 - 1e-8 crosses at 1 - 1e-4, while
    // (t - 1)^2 + 1e-8 only grazes and must report nothing; a crossing exactly at the window's end counts, one just
    // past it does not.
    func testItem09RootFinderAgainstKnownRootsAndABruteForceSearch() {
        var rng = SeededGenerator(seed: 909)
        func uniform(_ lo: Double, _ hi: Double) -> Double { lo + (rng.signedUnit() + 1) * 0.5 * (hi - lo) }
        func times(_ a: [Double], _ b: [Double]) -> [Double] {
            var out = [Double](repeating: 0, count: a.count + b.count - 1)
            for i in a.indices { for j in b.indices { out[i + j] += a[i] * b[j] } }
            return out
        }
        let limit = 2.0
        var checked = 0
        for _ in 0..<400 {
            var roots = [uniform(-0.5, 2.5), uniform(-0.5, 2.5)]
            var poly = times([-roots[0], 1], [-roots[1], 1])
            if uniform(0, 1) < 0.5 {
                let r3 = uniform(-0.5, 2.5), r4 = uniform(-0.5, 2.5)
                roots += [r3, r4]
                poly = times(poly, times([-r3, 1], [-r4, 1]))
            } else {
                // (t - c)^2 + d with d > 0: no real root.
                let c = uniform(-1, 3), d = uniform(0.01, 1)
                poly = times(poly, [c * c + d, -2 * c, 1])
            }
            if RootFinder.evaluate(poly, 0) < 0 { poly = poly.map { -$0 } }
            let sorted = roots.sorted()
            let tooClose = zip(sorted, sorted.dropFirst()).contains { $1 - $0 < 1e-2 }
                || roots.contains { abs($0) < 1e-2 || abs($0 - limit) < 1e-2 }
            if tooClose || RootFinder.evaluate(poly, 0) == 0 { continue }
            let expected = sorted.first { $0 > 0 && $0 < limit }
            let got = RootFinder.firstDownCrossing(poly, limit: limit)
            if let e = expected {
                XCTAssertNotNil(got, "missed the root at \(e)")
                // The coefficients are rounded when the factors are multiplied out, which moves a root by about the
                // rounding (1e-14) over the slope there; with roots a centimetre-second apart the slope is at least
                // 6e-6, so 1e-8 covers it.
                XCTAssertEqual(got ?? -1, e, accuracy: 1e-8)
            } else {
                XCTAssertNil(got, "found a root where there is none: \(got ?? -1)")
            }
            // Brute force: the first of 20,000 samples where the value is no longer positive.
            let n = 20_000
            let firstDown = (1...n).first { RootFinder.evaluate(poly, limit * Double($0) / Double(n)) <= 0 }
            if let i = firstDown {
                let hi = limit * Double(i) / Double(n), lo = limit * Double(i - 1) / Double(n)
                XCTAssertGreaterThanOrEqual(got ?? -1, lo - 1e-12)
                XCTAssertLessThanOrEqual(got ?? -1, hi + 1e-12)
            } else {
                XCTAssertNil(got)
            }
            checked += 1
        }
        XCTAssertGreaterThan(checked, 300, "too many random cases were skipped")

        // Near-double roots, which a sign-change search cannot find.
        XCTAssertEqual(RootFinder.firstDownCrossing([1 - 1e-8, -2, 1], limit: limit) ?? -1, 1 - 1e-4, accuracy: 1e-10)
        XCTAssertNil(RootFinder.firstDownCrossing([1 + 1e-8, -2, 1], limit: limit))
        // ((t - 0.7)^2 - 1e-8)(t^2 + 1): a near-double crossing inside a quartic.
        let quartic = times([0.49 - 1e-8, -1.4, 1], [1, 0, 1])
        XCTAssertEqual(RootFinder.firstDownCrossing(quartic, limit: limit) ?? -1, 0.7 - 1e-4, accuracy: 1e-10)
        // The window's end: 1 - t reaches zero exactly at t = 1.
        XCTAssertEqual(RootFinder.firstDownCrossing([1, -1], limit: 1) ?? -1, 1, accuracy: 1e-12)
        XCTAssertNil(RootFinder.firstDownCrossing([1, -1], limit: 0.999_999))
    }

    // MARK: Item 11

    // Two hundred seeded breaks (the default rack jitter is on, so every seed is a different cascade). Each must keep
    // all sixteen balls accounted for (pocketed, or at rest on the cloth), conserve horizontal momentum at every
    // ball-ball event, and finish within the event limit. Over all of them the object balls must end up on the
    // shooter's left and right in roughly equal numbers: on the cloth by which half of the table they rest in, in a
    // pocket by which long rail the pocket is on. The band, 40 to 60 percent on the left: if the fifteen balls of one
    // break always went one way together (the worst case; really they spread), each break's left share would be a
    // number between 0 and 1 with a spread of at most 0.5, and the average of two hundred such has a standard error of
    // at most 0.5 / sqrt(200) = 0.035. The band is about three of those either side of a half, so it fails only for a
    // real lean to one side, not for chance. (Exact mirror symmetry is not claimed: balls touching at the same instant
    // are resolved in ball order, spec 3.5.)
    func testItem11BreakStatisticsOverTwoHundredSeeds() {
        let m = p.ballMass
        var left = 0.0, right = 0.0
        for seed in UInt64(1)...UInt64(200) {
            let input = Rack.breakShot(seed: seed, aimOffset: 0, speed: 9)
            guard let tl = PoolSolver.simulate(input, eventBudget: PoolSolver.maxEvents) else {
                XCTFail("seed \(seed) ran into the event limit"); continue
            }
            XCTAssertEqual(tl.ballCount, 16)
            XCTAssertLessThan(tl.duration, PoolSolver.maxTime, "seed \(seed) never settled")
            for e in tl.events where e.kind == .ballBall {
                let before = e.balls.reduce(Vec2.zero) { $0 + $1.velocityBefore * m }
                let after = e.balls.reduce(Vec2.zero) { $0 + $1.velocityAfter * m }
                XCTAssertEqual((before - after).length, 0, accuracy: 1e-9, "seed \(seed) momentum at t=\(e.time)")
            }
            for b in 0..<16 {
                let s = tl.state(ball: b, at: tl.duration + 5)
                if !s.pocketed { XCTAssertEqual(s.velocity.length, 0, accuracy: 1e-9, "seed \(seed) ball \(b) still moving") }
                guard b > 0 else { continue }
                if s.pocketed {
                    // Pockets 2, 3 and 5 are on the far long rail (y = W): the shooter's left, looking along +x.
                    let k = tl.events.first { $0.kind == .pocket && $0.balls.first?.ball == b }?.pocket ?? -1
                    if [2, 3, 5].contains(k) { left += 1 } else if [0, 1, 4].contains(k) { right += 1 }
                } else if s.position.y > p.tableWidth / 2 {
                    left += 1
                } else if s.position.y < p.tableWidth / 2 {
                    right += 1
                } else {
                    left += 0.5; right += 0.5
                }
            }
        }
        let share = left / (left + right)
        print(String(format: "BREAK statistics: %.0f object balls left, %.0f right over 200 seeds (left share %.3f)",
                     left, right, share))
        XCTAssertGreaterThanOrEqual(share, 0.40)
        XCTAssertLessThanOrEqual(share, 0.60)
    }

    // MARK: Item 17

    // Continuity beyond position (PhysicsTests checks positions): at every phase change that is not an impact
    // (sliding to rolling, rolling to spinning, spinning to rest) velocity and spin carry straight across, and at
    // every segment boundary, impacts included, the orientation carries across (an impact changes how a ball moves,
    // never which way up it is). Checked on a break and on a spin-heavy three-ball shot.
    func testItem17ContinuityOfVelocitySpinAndOrientation() {
        let shots = [
            Rack.breakShot(seed: 3, aimOffset: 0.002, speed: 9, tipUp: -0.006, tipSide: 0.004),
            ShotInput(positions: layout([0: Vec2(0.6, 0.5), 2: Vec2(1.3, 0.62), 6: Vec2(1.9, 0.3)]),
                      strike: CueStrike(direction: Vec2(1, 0.15), speed: 3.5, tipUp: 0.009, tipSide: -0.01), seed: 2),
        ]
        for (n, input) in shots.enumerated() {
            let tl = PoolSolver.simulate(input)
            // Every (ball, time) where something other than a plain phase change happened to that ball.
            var impacts = Set<String>()
            for e in tl.events where !(e.kind == .phaseTransition && e.flight == .none) {
                for b in e.balls { impacts.insert("\(b.ball)@\(e.time.bitPattern)") }
            }
            var phaseChanges = 0
            for b in 0..<tl.ballCount {
                let segs = tl.segments[b]
                for k in 1..<max(segs.count, 1) {
                    let t = segs[k].t0
                    let before = segs[k - 1].kinematics(at: t), after = segs[k].kinematics(at: t)
                    let qa = segs[k - 1].orientation(at: t), qb = segs[k].orientation0
                    let dq = abs(qa.w - qb.w) + abs(qa.x - qb.x) + abs(qa.y - qb.y) + abs(qa.z - qb.z)
                    XCTAssertEqual(dq, 0, accuracy: 1e-12, "shot \(n) ball \(b) orientation jumps at segment \(k)")
                    if impacts.contains("\(b)@\(t.bitPattern)") { continue }
                    phaseChanges += 1
                    // The one allowed jump: a ball whose speed has fallen under the solver's rest threshold (1e-6 m/s,
                    // Simulation.makeSegment) is put to rest or to spinning in place, losing that last hair of speed
                    // and the rolling spin that went with it (found on generation two's break: 3e-7 m/s after a gentle
                    // double kiss). Everywhere else the carry-over is exact.
                    let toRest = segs[k].phase == .spinning || segs[k].phase == .stationary
                    XCTAssertEqual((before.velocity - after.velocity).length, 0, accuracy: toRest ? 1e-6 : 1e-9,
                                   "shot \(n) ball \(b) velocity jumps at segment \(k)")
                    XCTAssertEqual((before.omega - after.omega).length, 0,
                                   accuracy: toRest ? 1e-6 / p.ballRadius : 1e-9,
                                   "shot \(n) ball \(b) spin jumps at segment \(k)")
                }
            }
            XCTAssertGreaterThan(phaseChanges, 0, "shot \(n) had no plain phase change to check")
        }
    }

    // MARK: Item 18

    // Vertical spin falls at the constant rate spinDecay in every phase on the cloth (spec 3.1), so a ball whose side
    // spin starts at w0 has none left at exactly w0 / spinDecay, whatever it is doing meanwhile, as long as nothing
    // touches it. First a slow ball with strong side on a cloth whose rolling resistance is raised (a test-only
    // number, so the ball stops rolling well before its spin is gone): it rolls, spins in place, and comes to rest at
    // w0 / spinDecay. Then on the default cloth, where the spin runs out while the ball is still rolling.
    func testItem18SpinDownTime() {
        let r = p.ballRadius
        var sticky = p
        sticky.rollingResistance = 0.05
        let a = solve(layout([0: Vec2(0.5, 0.6)]), dir: Vec2(1, 0), speed: 0.3, tipSide: 0.4 * r, parameters: sticky)
        let w0 = a.segments[0][0].omega0.z
        XCTAssertGreaterThan(w0, 0)
        let spinEnd = w0 / sticky.spinDecay
        let toSpin = a.events.first { $0.kind == .phaseTransition && $0.phaseTo == .spinning }
        XCTAssertNotNil(toSpin, "the ball should stop rolling and spin in place")
        XCTAssertLessThan(toSpin?.time ?? .infinity, spinEnd)
        let toRest = a.events.last { $0.kind == .phaseTransition && $0.phaseFrom == .spinning && $0.phaseTo == .stationary }
        XCTAssertEqual(toRest?.time ?? -1, spinEnd, accuracy: 1e-9)
        XCTAssertEqual(a.duration, spinEnd, accuracy: 1e-9)

        let b = solve(layout([0: Vec2(0.5, 0.6)]), dir: Vec2(1, 0), speed: 0.5, tipSide: 0.3 * r)
        let w1 = b.segments[0][0].omega0.z
        let end = w1 / p.spinDecay
        XCTAssertFalse(b.events.contains { $0.kind == .cushion }, "the check needs a ball nothing touches")
        XCTAssertGreaterThan(b.state(ball: 0, at: end - 1e-3).omega.z, 0)
        XCTAssertEqual(b.state(ball: 0, at: end + 1e-9).omega.z, 0, accuracy: 1e-6)
        XCTAssertEqual(b.state(ball: 0, at: end * 0.5).omega.z, w1 * 0.5, accuracy: 1e-9)
    }

    // MARK: Item 19

    // The energy ledger closes: the energy the cue strike gives = the energy taken at events (each event records
    // every ball's energy before and after) + the energy taken continuously inside segments (cloth friction while
    // sliding, rolling resistance, spin decay: each segment's energy at its start minus at its end) + what is left
    // at the end (nothing: every ball is at rest or in a pocket). A missing or wrong event value breaks the sum by the
    // size of an impact, tenths of a joule. Tolerance one part in 100,000: the solver snaps a ball to rolling when its
    // slip is under 1e-7 m/s and to rest under 1e-6 m/s, and each snap changes its spin energy by up to about 1e-8 J
    // without an event recording it; a break has a few hundred of them against several joules. Level shots only: a
    // ball in the air also carries height energy, which the events do not record.
    func testItem19EnergyLedgerCloses() {
        let shots = [
            Rack.showpieceBreak(),
            Rack.breakShot(seed: 5, aimOffset: 0.01, speed: 10, tipUp: 0.008, tipSide: -0.007),
            ShotInput(positions: layout([0: Vec2(0.5, 0.4), 1: Vec2(1.2, 0.7), 2: Vec2(1.6, 0.3)]),
                      strike: CueStrike(direction: Vec2(1, 0.14), speed: 4.0, tipUp: -0.01, tipSide: 0.006), seed: 9),
        ]
        for (n, input) in shots.enumerated() {
            let tl = PoolSolver.simulate(input)
            XCTAssertFalse(tl.segments.joined().contains { $0.phase == .airborne }, "shot \(n) must stay on the cloth")
            let given = tl.events.filter { $0.kind == .cueStrike }.reduce(0.0) { $0 + $1.balls.reduce(0.0) { $0 + $1.energyAfter } }
            let atEvents = tl.events.filter { $0.kind != .cueStrike }
                .reduce(0.0) { $0 + $1.balls.reduce(0.0) { $0 + $1.energyBefore - $1.energyAfter } }
            var inSegments = 0.0, left = 0.0
            for segs in tl.segments {
                for s in segs where s.t1.isFinite {
                    inSegments += energy(s.kinematics(at: s.t0), p) - energy(s.kinematics(at: s.t1), p)
                }
                if let last = segs.last { left += energy(last.kinematics(at: last.t0), p) }
            }
            XCTAssertGreaterThan(given, 0)
            XCTAssertEqual(left, 0, accuracy: 1e-9, "shot \(n): energy left at the end")
            XCTAssertEqual(given - atEvents - inSegments - left, 0, accuracy: 1e-5 * given,
                           "shot \(n): the ledger does not close (given \(given), events \(atEvents), segments \(inSegments))")
        }
    }

    // MARK: Item 20

    // A contact predicted before an earlier event changed a ball's path must be dropped. The cue ball is aimed
    // straight at the 2, a metre away, but takes the 1 half-ball first (its centre 1.5 radii off the line) and is
    // turned away. Alone, the same stroke hits the 2 (so the stale contact really was in the queue at the start);
    // with the 1 in the way, nothing ever touches the 2. The paths: after the cut the rolling cue ball runs about 27
    // degrees below its old line and the 1 about 49 degrees above it, so both pass the 2 by more than a ball's width.
    func testItem20StaleContactIsDropped() {
        let r = p.ballRadius
        let cue = Vec2(0.5, 0.6), two = Vec2(1.5, 0.6), one = Vec2(1.0, 0.6 + 1.5 * r)
        let alone = solve(layout([0: cue, 2: two]), dir: Vec2(1, 0), speed: 0.8)
        XCTAssertTrue(alone.events.contains { $0.kind == .ballBall && Set($0.balls.map(\.ball)) == [0, 2] },
                      "without the 1, the stroke should hit the 2")
        let blocked = solve(layout([0: cue, 1: one, 2: two]), dir: Vec2(1, 0), speed: 0.8)
        XCTAssertTrue(blocked.events.contains { $0.kind == .ballBall && Set($0.balls.map(\.ball)) == [0, 1] })
        XCTAssertFalse(blocked.events.contains { $0.balls.contains { $0.ball == 2 } }, "a stale contact with the 2 was kept")
        XCTAssertEqual(blocked.state(ball: 2, at: blocked.duration + 1).position, two)
    }

    // MARK: Item 21

    // Frozen balls and resting contact make no events of their own. (a) Two balls touching, and a ball touching a
    // rail, while the cue ball is played away from them: no event names any of them and they end exactly where they
    // started. (b) A cue ball frozen to a rail and played along it: no cushion event, and it never leaves the rail's
    // contact line. (c) A cue ball frozen to an object ball and played away from it: no contact between them. (d) The
    // cue ball played into the frozen pair: the first event to name either of them is the cue ball reaching the
    // front one; nothing happens between the pair before that.
    func testItem21FrozenBallsMakeNoSpuriousEvents() {
        let r = p.ballRadius, W = p.tableWidth
        let pairA = Vec2(2.0, 0.9), pairB = Vec2(2.0 + 2 * r, 0.9), railBall = Vec2(1.6, r)
        // (a)
        let start = layout([0: Vec2(0.5, 0.6), 1: pairA, 2: pairB, 3: railBall])
        let a = solve(start, dir: Vec2(-1, 0), speed: 0.6)
        XCTAssertFalse(a.events.contains { $0.balls.contains { [1, 2, 3].contains($0.ball) } }, "a frozen ball made an event")
        for b in [1, 2, 3] { XCTAssertEqual(a.state(ball: b, at: a.duration + 1).position, start[b]) }
        // (b) Frozen to the top rail beyond the side pocket, rolling along it; it stops before the corner.
        let along = solve(layout([0: Vec2(1.6, W - r)]), dir: Vec2(1, 0), speed: 0.5)
        XCTAssertFalse(along.events.contains { $0.kind == .cushion }, "a ball rolling along its rail hit it")
        XCTAssertEqual(along.state(ball: 0, at: along.duration + 1).position.y, W - r)
        XCTAssertFalse(along.events.contains { $0.kind == .pocket })
        // (c)
        let away = solve(layout([0: Vec2(0.6, 0.6), 4: Vec2(0.6 + 2 * r, 0.6)]), dir: Vec2(-0.6, 0.8), speed: 0.5)
        XCTAssertFalse(away.events.contains { $0.kind == .ballBall }, "the cue ball touched the ball it was frozen to")
        // (d)
        let into = solve(layout([0: Vec2(1.4, 0.9), 1: pairA, 2: pairB]), dir: Vec2(1, 0), speed: 1.5)
        let first = into.events.first { $0.balls.contains { [1, 2].contains($0.ball) } }
        XCTAssertEqual(first?.kind, .ballBall)
        XCTAssertEqual(Set(first?.balls.map(\.ball) ?? []), [0, 1], "the frozen pair moved before the cue ball arrived")
    }

    // MARK: Item 23

    // Relabelling: swap two object balls' numbers and places, solve, swap back, and every ball ends where it did.
    // Contact times come from the same polynomials either way (swapping which ball is "first" only negates the
    // vectors, whose squares and products are unchanged), and the impact formulas are symmetric, so the outcome is
    // the same. The documented exception (spec 3.5) is a tie: two events at the very same instant are taken in ball
    // order, and relabelling can change that order. So a hand-built shot with no ties, then sixty seeded random
    // layouts, skipping any whose recording has two events at the same instant (about four in ten have one: a ball
    // stopping and another settling share an instant often enough, measured on the first package run).
    func testItem23RelabelledBallsGiveTheSameOutcome() {
        func swapped(_ pos: [Vec2], _ i: Int, _ j: Int) -> [Vec2] { var q = pos; q.swapAt(i, j); return q }
        func compare(_ pos: [Vec2], _ i: Int, _ j: Int, dir: Vec2, speed: Double, up: Double, side: Double,
                     _ name: String, parameters: PoolParameters? = nil) -> Bool {
            let a = solve(pos, dir: dir, speed: speed, tipUp: up, tipSide: side, parameters: parameters)
            let times = a.events.map(\.time)
            if Set(times).count != times.count { return false }
            let b = solve(swapped(pos, i, j), dir: dir, speed: speed, tipUp: up, tipSide: side, parameters: parameters)
            for ball in 0..<16 {
                let other = ball == i ? j : (ball == j ? i : ball)
                let sa = a.state(ball: ball, at: a.duration + 1), sb = b.state(ball: other, at: b.duration + 1)
                XCTAssertEqual(sa.pocketed, sb.pocketed, "\(name) ball \(ball)")
                XCTAssertEqual((sa.position - sb.position).length, 0, accuracy: 1e-9, "\(name) ball \(ball)")
            }
            XCTAssertEqual(a.events.count, b.events.count, name)
            return true
        }
        // The hand-built shot is checked on generation one, where it has no ties; on the default generation two the
        // cue ball and the 12 happen to stop rolling at the same instant (2.509 s), which is the documented exception.
        // The sixty random layouts below run on the default.
        let hand = layout([0: Vec2(0.5, 0.5), 3: Vec2(1.1, 0.62), 7: Vec2(1.8, 0.95), 12: Vec2(2.2, 0.3)])
        XCTAssertTrue(compare(hand, 3, 7, dir: Vec2(1, 0.17), speed: 3, up: 0.005, side: -0.004, "hand-built",
                              parameters: .generationOne),
                      "the hand-built shot should have no ties")
        var rng = SeededGenerator(seed: 2323)
        func unit() -> Double { (rng.signedUnit() + 1) * 0.5 }
        let r = p.ballRadius, L = p.tableLength, W = p.tableWidth
        var compared = 0
        for n in 0..<60 {
            var pos = [Vec2](repeating: NextShot.offTable, count: 16)
            var placed: [Vec2] = []
            while placed.count < 5 {
                let c = Vec2(r + 0.05 + unit() * (L - 2 * r - 0.1), r + 0.05 + unit() * (W - 2 * r - 0.1))
                if placed.allSatisfy({ ($0 - c).length > 2 * r + 0.01 }) { placed.append(c) }
            }
            // The cue ball and four object balls with spread-out numbers.
            for (k, ball) in [0, 2, 5, 9, 14].enumerated() { pos[ball] = placed[k] }
            let dir = (placed[1 + Int(unit() * 3.999)] - placed[0]).normalized
            if compare(pos, 5, 14, dir: dir, speed: 1 + unit() * 5, up: (unit() - 0.5) * 0.02,
                       side: (unit() - 0.5) * 0.02, "random \(n)") { compared += 1 }
        }
        XCTAssertGreaterThan(compared, 20, "too many random shots had ties")
    }

    // MARK: Item 24

    // The impact routines against the spec's oracle formulas (3.3), called directly. Ball-ball normal impulse
    // (1 + e) m v_n / 2. Stick or slide: the friction impulse is the smaller of the one that cancels the slip (m |u| / 7
    // between two free balls, 2 m |u| / 7 against a fixed cushion) and mu times the normal impulse; a sticking impact
    // leaves no slip at all, a sliding one uses exactly mu J_n.
    func testItem24ImpactOracles() {
        let m = p.ballMass, r = p.ballRadius, e = p.ballBallRestitution
        // Ball-ball, a three-quarter-ball hit at 2 m/s with a little side spin: the slip is small, so it sticks.
        let n = Vec2(cos(0.25), sin(0.25))
        let a = BodyState(position: .zero, velocity: Vec2(2, 0), omega: Vec3(0, 0, 3))
        let b = BodyState(position: n * (2 * r), velocity: .zero, omega: .zero)
        let stick = Impacts.ballBall(a, b, p)
        let vn = Vec2(2, 0).dot(n)
        XCTAssertEqual(stick.normalImpulse, (1 + e) * m * vn / 2, accuracy: 1e-12)
        let t = n.perp
        func ballSlip(_ x: BodyState, _ y: BodyState) -> Double { (x.velocity - y.velocity).dot(t) + r * (x.omega.z + y.omega.z) }
        let slip0 = ballSlip(a, b)
        XCTAssertLessThan(m * abs(slip0) / 7, p.ballBallFriction(slip: abs(slip0)) * stick.normalImpulse, "should stick")
        XCTAssertEqual(stick.frictionImpulse, m * abs(slip0) / 7, accuracy: 1e-12)
        XCTAssertEqual(ballSlip(stick.states[0], stick.states[1]), 0, accuracy: 1e-12, "a sticking hit leaves no slip")
        // A thin cut at 4 m/s: lots of slip, little normal impulse, so it slides at mu(slip) J_n.
        let thin = Vec2(cos(1.3), sin(1.3))
        let fast = BodyState(position: .zero, velocity: Vec2(4, 0), omega: .zero)
        let slide = Impacts.ballBall(fast, BodyState(position: thin * (2 * r), velocity: .zero, omega: .zero), p)
        XCTAssertEqual(slide.frictionImpulse, p.ballBallFriction(slip: slide.slipSpeed) * slide.normalImpulse, accuracy: 1e-12)
        XCTAssertGreaterThan(m * slide.slipSpeed / 7, slide.frictionImpulse, "should slide")

        // Cushion (inward normal +y, the bottom rail). A naturally rolling ball straight in: the contact slips straight
        // up the rubber at the ball's speed; 2 m v / 7 is less than mu J_n here, so the friction impulse is exactly the
        // one that would cancel the slip. (On generation 1's flat rail the vertical push is dropped, so the ball's
        // vertical speed does not take its share and that slip is not fully cancelled; the real rail of
        // plans/21-Nov-2026-rails-plan.md resolves it in three dimensions.)
        let up = Vec2(0, 1)
        func cushionSlip(_ s: BodyState) -> (Double, Double) {
            (s.velocity.dot(up.perp) - r * s.omega.z, r * (s.omega.y * up.x - s.omega.x * up.y))
        }
        let v = 1.5
        let rolling = BodyState(position: Vec2(1, r), velocity: Vec2(0, -v), omega: Vec3(v / r, 0, 0))
        let rail = Impacts.cushion(rolling, normal: up, p)
        XCTAssertEqual(rail.normalImpulse, (1 + p.cushionRestitution) * m * v, accuracy: 1e-12)
        XCTAssertLessThan(2 * m * v / 7, p.cushionFriction * rail.normalImpulse, "should stick")
        XCTAssertEqual(rail.frictionImpulse, 2 * m * v / 7, accuracy: 1e-12)
        // A stunned ball (no spin) coming in at a slant: the contact slips along the rail only, all of it horizontal, so
        // a sticking hit leaves no slip at all (1/m + R^2/I = 7/(2m) for the speed and the vertical spin together).
        let slant = BodyState(position: Vec2(1, r), velocity: Vec2(0.3, -v), omega: .zero)
        let grip = Impacts.cushion(slant, normal: up, p)
        XCTAssertEqual(grip.frictionImpulse, 2 * m * 0.3 / 7, accuracy: 1e-12)
        let (st, sz) = cushionSlip(grip.states[0])
        XCTAssertEqual(st, 0, accuracy: 1e-12); XCTAssertEqual(sz, 0, accuracy: 1e-12)
        // A ball with heavy side spin, slow into the rail: the slip is large against the normal impulse, so it slides.
        let spun = BodyState(position: Vec2(1, r), velocity: Vec2(0.2, -0.5), omega: Vec3(0, 0, 60))
        let skid = Impacts.cushion(spun, normal: up, p)
        XCTAssertEqual(skid.frictionImpulse, p.cushionFriction * skid.normalImpulse, accuracy: 1e-12)
        XCTAssertGreaterThan(2 * m * skid.slipSpeed / 7, skid.frictionImpulse, "should slide")
    }
}
