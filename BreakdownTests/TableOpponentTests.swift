// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.4 table-opponent review: the foul test lets through a foul
//          that also sinks one of the computer's own balls in its cup, which the plan's value rightly prefers to a
//          clean roll; any other planned foul while a legal stroke exists still fails.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 rules-lens: easy five-pin with the other ball straight beyond
//          the castle no longer drives its own ball through the pins; it picks a line, here a one-cushion kick, whose
//          legs both clear the castle.)
// PURPOSE: The computer at bumper pool and five-pin (App/Match/BumperPoolPlanner.swift, FivePinPlanner.swift and their
//          shared search, TableOpponentSearch.swift) as unit tests, from plans/22-Nov-2026-v074-glow-up-plan.md
//          (table-opponent stream): bumper pool finds a cup shot from the start and a wide one near its cup, and never
//          plays a foul when a legal stroke is there; five-pin's medium and hard plans are legal from the start and
//          hard expects points; easy five-pin is geometry only; every plan is the same twice; the noise check never
//          draws the real stroke's own noise; "Why that shot" has words for every new kind and names no pocket. A
//          self-play check (hard against easy, whole games) runs only with SELF_PLAY=1 in the environment.
//          The parameters and layouts are the tables' own (TableKind.bumperPool / .fivePin), the states the rules'
//          fresh ones with the computer in seat 2 to shoot. Slow, not stuck: a medium or hard search solves 2,000 to
//          7,200 budgeted shots, and the file runs about 90,000 in all (the foul test alone is fifteen searches, the
//          determinism test twelve), where MatchOpponentTests' few hundred take about a second in a Debug build, so
//          expect minutes here, plausibly ten or more on a Debug build.
// SRP/DRY check: Pass - no planning logic here; the rules, layouts and solver are the app's own, and
//          MatchOpponentTests (pool) is left unchanged.
@testable import Breakdown
import BreakdownLensModel
import BreakdownPhysics
import BreakdownRules
import BreakdownTimeline
import Foundation
import XCTest

final class TableOpponentTests: XCTestCase {
    // MARK: Helpers

    private let bumperParameters = TableKind.bumperPool.parameters
    private let fivePinParameters = TableKind.fivePin.parameters

    private var bumperStart: [Vec2] { TableKind.bumperPool.startLayout ?? [] }
    private var fivePinStart: [Vec2] { TableKind.fivePin.startLayout ?? [] }

    /// A fresh game of `rules` with the computer in seat 2 to shoot, past the opening.
    private func state(_ rules: any MatchRules, level: ComputerLevel) -> MatchState {
        var s = rules.initialState(playerNames: ["Player 1", "Computer"])
        s.players[1].computer = level
        s.isBreak = false
        s.turn = .second
        return s
    }

    private func bumper(_ layout: [Vec2]? = nil, level: ComputerLevel, ballsLeft: [Int]? = nil) -> OpponentSnapshot {
        var s = state(BumperPoolRules(), level: level)
        if let left = ballsLeft { s.ballsLeft = left.sorted() }
        return OpponentSnapshot(layout: layout ?? bumperStart, state: s, rules: BumperPoolRules(),
                                parameters: bumperParameters, level: level, racked: false, noiseSeed: 0x5EED_0001)
    }

    private func fivePin(_ layout: [Vec2]? = nil, level: ComputerLevel) -> OpponentSnapshot {
        OpponentSnapshot(layout: layout ?? fivePinStart, state: state(FivePinRules(), level: level),
                         rules: FivePinRules(), parameters: fivePinParameters, level: level, racked: false,
                         noiseSeed: 0x5EED_0002)
    }

    /// The stroke solved without noise, read and ruled as the match would.
    private func solve(_ s: OpponentSnapshot, _ stroke: OpponentStroke) -> (facts: ShotFacts, ruling: Ruling) {
        let ball = s.rules.cueBall(for: s.state.turn, in: s.state)
        let tl = PoolSolver.simulate(NextShot.shot(from: s.layout, direction: stroke.direction, speed: stroke.speed,
                                                   tipUp: stroke.tipUp, tipSide: stroke.tipSide, seed: 1,
                                                   parameters: s.parameters, ballIndex: ball))
        let facts = ShotFacts(timeline: tl, start: s.layout, cueBall: ball)
        return (facts, s.rules.ruling(for: facts, call: nil, in: s.state))
    }

    /// True when some plain stroke (every 10 degrees at a gentle and a firm pace) is legal from the snapshot.
    private func someLegalStroke(_ s: OpponentSnapshot, speeds: [Double]) -> Bool {
        for a in stride(from: 0.0, to: 360.0, by: 10.0) {
            for v in speeds where !solve(s, OpponentStroke(aimDegrees: a, speed: v)).ruling.fouled { return true }
        }
        return false
    }

    /// A random bumper-pool layout from `seed`: all ten balls on the bed, clear of the cushions, the bumpers, the cups
    /// and each other.
    private func randomBumperLayout(seed: UInt64) -> [Vec2] {
        var rng = OpponentRandom(seed: seed)
        let p = bumperParameters, r = p.ballRadius
        var l = [Vec2](repeating: NextShot.offTable, count: 16)
        for b in BumperPoolRules.sides.flatMap({ $0 }) {
            for _ in 0..<500 {
                let spot = Vec2(r + 0.01 + rng.unit() * (p.tableLength - 2 * r - 0.02),
                                r + 0.01 + rng.unit() * (p.tableWidth - 2 * r - 0.02))
                let clearOfPosts = p.posts.allSatisfy { ($0.center - spot).length > $0.radius + r + 0.005 }
                let clearOfCups = p.bedHoles.allSatisfy { ($0.center - spot).length > $0.radius + r }
                let clearOfBalls = l.allSatisfy { !NextShot.isOnTable($0) || ($0 - spot).length > 2 * r + 0.005 }
                if clearOfPosts && clearOfCups && clearOfBalls { l[b] = spot; break }
            }
        }
        return l
    }

    // MARK: Bumper pool

    func testBumperOpeningFindsACupShot() {
        // Unverified by any run before this file was written (the builders may not run the app or its tests): the
        // coordinator checks this one first.
        let s = bumper(level: .hard)
        let plan = OpponentPlanner.plan(s)
        guard case .cup = plan.kind else { return XCTFail("hard should plan a cup shot from the start, got \(plan.kind)") }
        let f = solve(s, plan.stroke).facts
        XCTAssertTrue(f.holeDrops.contains { $0.ball == 9 && $0.hole == 0 },
                      "the noise-free stroke drops the marked ball in its own cup")
    }

    func testBumperNearCupIsWide() {
        // Ball 9 (the computer's marked ball, its striking ball) 18 cm straight out from its cup (bed hole 0) on the
        // cups' line, between the cup's two guard bumpers and the cross; the other player's marked ball moved off
        // that line; everything else on its start spot.
        var l = bumperStart
        let w = bumperParameters.tableWidth
        let cup = bumperParameters.bedHoles[0].center
        l[9] = Vec2(cup.x + 0.18, w / 2)
        l[0] = Vec2(0.85, 0.20)
        let s = bumper(l, level: .medium)
        let plan = OpponentPlanner.plan(s)
        guard case .cup(let ball, let marked, _) = plan.kind else { return XCTFail("expected a cup shot, got \(plan.kind)") }
        XCTAssertEqual(ball, 9)
        XCTAssertTrue(marked)
        XCTAssertGreaterThanOrEqual(plan.window ?? 0, 0.5, "a short straight cup shot leaves a wide aim window")
    }

    func testBumperNeverChoosesAFoulWhenALegalStrokeExists() {
        // A foul that also drops one of the computer's own balls in its own cup is not a mistake under the plan's
        // value: the ball stays down (+10) and the foul costs 8, so it beats a clean roll, and BumperPoolRules keeps
        // the sunk ball down on a foul. Only a foul with no ball of its own in its cup must never be chosen while a
        // legal stroke exists.
        for k in 0..<5 {
            let l = randomBumperLayout(seed: 0xB0B0 + UInt64(k))
            let onTable = BumperPoolRules.sides.flatMap { $0 }.filter { NextShot.isOnTable(l[$0]) }
            for level in ComputerLevel.allCases {
                let s = bumper(l, level: level, ballsLeft: onTable)
                let plan = OpponentPlanner.plan(s)
                let (facts, ruling) = solve(s, plan.stroke)
                guard ruling.fouled else { continue }
                let own = Set(BumperPoolRules.sides[s.state.turn.index])
                let cup = BumperPoolRules.targetHole[s.state.turn.index]
                if facts.holeDrops.contains(where: { own.contains($0.ball) && $0.hole == cup }) { continue }
                XCTAssertFalse(someLegalStroke(s, speeds: [0.9, 1.8]),
                               "layout \(k), \(level): the plan fouls although a legal stroke exists")
            }
        }
    }

    // MARK: Five-pin

    func testFivePinPlanIsLegalFromStart() {
        for level in [ComputerLevel.medium, .hard] {
            let s = fivePin(level: level)
            let plan = OpponentPlanner.plan(s)
            let (facts, ruling) = solve(s, plan.stroke)
            XCTAssertEqual(facts.firstContact?.ball, 0, "\(level): the yellow meets the white first")
            XCTAssertFalse(ruling.fouled, "\(level): no foul from the start")
        }
    }

    func testFivePinHardExpectsPoints() {
        let plan = OpponentPlanner.plan(fivePin(level: .hard))
        guard case .pins(let expected, _, _) = plan.kind else { return XCTFail("expected .pins, got \(plan.kind)") }
        XCTAssertGreaterThan(expected, 0)
    }

    func testFivePinEasyIsGeometryOnly() {
        let p = fivePinParameters, r = p.ballRadius
        let castle = FivePinPlanner.castleCentre(p)
        // A clear, gentle cut: the white (ball 0, the computer's target) on the long string short of the castle, the
        // yellow (the computer's ball) behind and a little across, the red well out of the way.
        var l = [Vec2](repeating: NextShot.offTable, count: 16)
        l[0] = Vec2(castle.x + 0.38, castle.y)
        l[1] = Vec2(castle.x + 0.88, castle.y + 0.09)
        l[FivePinRules.redBall] = Vec2(castle.x + 0.71, 0.30)
        let plan = OpponentPlanner.plan(fivePin(l, level: .easy))
        let ghost = FivePinPlanner.ghostAim(cue: l[1], object: l[0], toward: castle, radius: r)
        XCTAssertEqual(plan.stroke.aimDegrees, ghost, accuracy: 1e-9)
        XCTAssertEqual(plan.kind, .pins(expected: 0, clean: 0, kick: false))
        XCTAssertTrue(FivePinPlanner.easySpeeds.contains(plan.stroke.speed))

        // From the start the cut is too thin, so easy takes the plain full hit at the white, still with no solve.
        let start = fivePinStart
        let fromStart = OpponentPlanner.plan(fivePin(level: .easy))
        let full = start[0] - start[1]
        let fullAim = atan2(full.y, full.x) * 180 / Double.pi
        let ghostFromStart = FivePinPlanner.ghostAim(cue: start[1], object: start[0], toward: castle, radius: r)
        XCTAssertTrue(abs(fromStart.stroke.aimDegrees - fullAim) < 1e-9
                      || abs(fromStart.stroke.aimDegrees - ghostFromStart) < 1e-9,
                      "easy aims by geometry alone")
    }

    func testFivePinEasyNeverDrivesThroughTheCastle() {
        let p = fivePinParameters, r = p.ballRadius
        let castle = FivePinPlanner.castleCentre(p)
        // The white (the computer's target, ball 0) straight beyond the castle from the yellow (its own ball): the
        // cut, the full hit and every thinner hit across the white pass through the pins. The red is out of the way.
        var l = [Vec2](repeating: NextShot.offTable, count: 16)
        l[1] = Vec2(castle.x + 0.90, castle.y)
        l[0] = Vec2(castle.x - 0.60, castle.y)
        l[FivePinRules.redBall] = Vec2(castle.x + 0.50, 1.20)
        let plan = OpponentPlanner.plan(fivePin(l, level: .easy))
        XCTAssertEqual(plan.kind, .pins(expected: 0, clean: 0, kick: false))
        XCTAssertTrue(FivePinPlanner.easySpeeds.contains(plan.stroke.speed))
        // The castle's reach as easy judges it: the farthest pin, its contact radius and a ball.
        let reach = (p.pins.map { ($0.center - castle).length + $0.radius }.max() ?? 0) + r
        func gap(_ a: Vec2, _ b: Vec2) -> Double {
            let seg = b - a
            let t = min(max((castle - a).dot(seg) / max(seg.lengthSquared, 1e-12), 0), 1)
            return (castle - (a + seg * t)).length
        }
        // Follow the aim from the yellow to the first cushion line its centre meets (a radius in from each nose).
        let dir = plan.stroke.direction
        var hits: [Double] = []
        if dir.x > 1e-9 { hits.append((p.tableLength - r - l[1].x) / dir.x) }
        if dir.x < -1e-9 { hits.append((r - l[1].x) / dir.x) }
        if dir.y > 1e-9 { hits.append((p.tableWidth - r - l[1].y) / dir.y) }
        if dir.y < -1e-9 { hits.append((r - l[1].y) / dir.y) }
        let bounce = l[1] + dir * (hits.filter { $0 > 0 }.min() ?? 0)
        XCTAssertGreaterThanOrEqual(gap(l[1], bounce), reach, "the first leg clears the castle")
        XCTAssertGreaterThanOrEqual(gap(bounce, l[0]), reach, "the way back to the white clears the castle")
    }

    // MARK: Both tables

    func testPlansAreDeterministic() {
        for level in ComputerLevel.allCases {
            XCTAssertEqual(OpponentPlanner.plan(bumper(level: level)), OpponentPlanner.plan(bumper(level: level)),
                           "bumper pool, \(level)")
            XCTAssertEqual(OpponentPlanner.plan(fivePin(level: level)), OpponentPlanner.plan(fivePin(level: level)),
                           "five-pin, \(level)")
        }
    }

    func testNoiseSamplesDifferFromTheStrokeNoise() {
        let strokeSeed = OpponentNoise.seed(rackSeed: 4_242, shotCount: 9, seat: 1)
        let samples = TableOpponentSearch.sampleSeeds(noiseSeed: strokeSeed, count: 12)
        XCTAssertEqual(samples.count, 12)
        XCTAssertFalse(samples.contains(strokeSeed), "the check never deals the real stroke's own noise")
        XCTAssertEqual(Set(samples).count, samples.count, "every sample is its own draw")
        let real = OpponentNoise.draw(level: .hard, seed: strokeSeed, kind: .bumperPool)
        for seed in samples {
            XCTAssertNotEqual(OpponentNoise.draw(level: .hard, seed: seed, kind: .bumperPool), real)
        }
        XCTAssertEqual(TableOpponentSearch.sampleSeeds(noiseSeed: strokeSeed, count: 12), samples, "pure")
        XCTAssertTrue(TableOpponentSearch.sampleSeeds(noiseSeed: strokeSeed, count: 0).isEmpty)
        // Pool keeps its numbers: at the default scale the kind changes nothing.
        XCTAssertEqual(OpponentNoise.draw(level: .medium, seed: strokeSeed, kind: .eightBall),
                       OpponentNoise.draw(level: .medium, seed: strokeSeed))
    }

    func testWhyLinesForTableKinds() {
        let kinds: [OpponentPlan.Kind] = [
            .cup(ball: 9, marked: true, route: .straight), .cup(ball: 10, marked: false, route: .cushion),
            .cup(ball: 11, marked: false, route: .bumper), .cup(ball: 12, marked: false, route: .cushionAndBumper),
            .advance(ball: 9), .pins(expected: 3.4, clean: 6, kick: true), .pins(expected: 0, clean: 0, kick: false),
            .concede,
        ]
        let pocketTitles = EightBallPocket.allCases.map(\.title).filter { !$0.isEmpty }
        for level in ComputerLevel.allCases {
            for kind in kinds {
                for window in [nil, 0.8] as [Double?] {
                    let plan = OpponentPlan(kind: kind, stroke: OpponentStroke(aimDegrees: 12, speed: 2),
                                            placement: nil, call: nil, window: window, leavesNextShot: true)
                    let lines = OpponentWords.why(OpponentShot(seat: .second, level: level, plan: plan, noise: .none))
                    XCTAssertGreaterThanOrEqual(lines.count, 2, "\(kind): what it played for, then its hand")
                    XCTAssertTrue(lines.allSatisfy { !$0.isEmpty })
                    for line in lines {
                        XCTAssertFalse(pocketTitles.contains { line.contains($0) }, "\(kind) names a pocket: \(line)")
                    }
                }
            }
        }
    }

    // MARK: Self-play (SELF_PLAY=1 only)

    /// Hard (seat 2) against easy (seat 1), four seeded games per table, the first shot alternating. Every game must
    /// end within the cap, hard must win at least three of the four, and every planned speed must be one a player can
    /// strike. Long: thousands of solves per stroke.
    func testSelfPlay() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["SELF_PLAY"] == "1", "set SELF_PLAY=1 to run")
        let fivePinSpots: [Int: Vec2] = [FivePinRules.playerBalls[0]: FivePinTable.cueStart,
                                         FivePinRules.playerBalls[1]: FivePinTable.opponentSpot,
                                         FivePinRules.redBall: FivePinTable.redSpot]
        for kind in [MatchKind.bumperPool, .fivePin] {
            let rules: any MatchRules = kind == .bumperPool ? BumperPoolRules() : FivePinRules()
            let p = kind == .bumperPool ? bumperParameters : fivePinParameters
            let start = kind == .bumperPool ? bumperStart : fivePinStart
            let cap = kind == .bumperPool ? 120 : 200
            var hardWins = 0
            for game in 0..<4 {
                var st = rules.initialState(playerNames: ["Easy", "Hard"])
                st.players[0].computer = .easy
                st.players[1].computer = .hard
                st.isBreak = false
                st.turn = PlayerID(game % 2)
                var layout = start
                let rackSeed = 0xC0FFEE + UInt64(game)
                var shots = 0
                while st.result == nil && shots < cap {
                    let seat = st.turn
                    let level = st.players[seat.index].computer ?? .easy
                    let seed = OpponentNoise.seed(rackSeed: rackSeed, shotCount: st.shotCount, seat: seat.index)
                    let snap = OpponentSnapshot(layout: layout, state: st, rules: rules, parameters: p, level: level,
                                                racked: false, noiseSeed: seed)
                    let plan = OpponentPlanner.plan(snap)
                    XCTAssertTrue(PlayerShotSpeed.ordinary.contains(plan.stroke.speed), "\(kind) speed \(plan.stroke.speed)")
                    let stroke = plan.stroke.with(OpponentNoise.draw(level: level, seed: seed, kind: kind),
                                                  speeds: PlayerShotSpeed.ordinary, tipLimit: p.miscueOffsetLimit)
                    let ball = rules.cueBall(for: seat, in: st)
                    let tl = PoolSolver.simulate(NextShot.shot(from: layout, direction: stroke.direction,
                                                               speed: stroke.speed, tipUp: stroke.tipUp,
                                                               tipSide: stroke.tipSide, seed: 1, parameters: p,
                                                               ballIndex: ball))
                    let facts = ShotFacts(timeline: tl, start: layout, cueBall: ball)
                    let ruling = rules.ruling(for: facts, call: nil, in: st)
                    st = rules.applying(ruling, facts: facts, to: st)
                    layout = kind == .bumperPool
                        ? BumperPoolRules.nextLayout(after: facts, ruling: ruling, start: start, table: tl.table)
                        : FivePinRules.nextLayout(after: facts.resting, table: tl.table, spots: fivePinSpots)
                    shots += 1
                }
                XCTAssertNotNil(st.result, "\(kind) game \(game) did not end within \(cap) shots")
                if st.result?.winner == .second { hardWins += 1 }
                print("TableOpponentTests self-play \(kind) game \(game): \(shots) shots, scores \(st.scores), "
                      + "winner \(st.result?.winner?.index ?? -1)")
            }
            XCTAssertGreaterThanOrEqual(hardWins, 3, "\(kind): hard won \(hardWins) of 4 against easy")
        }
    }
}
