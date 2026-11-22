// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The reach ladder (App/Stroke/Reach.swift): the rung boundaries along the cue line; the walk-around choice of
//          the easiest way to stand (behind the cue at whichever rail the line crosses, or beside a rail with the cue
//          behind the back, the lower rung winning); a ball under the cue's path near the cue ball found as a raised cue
//          (the hand bridge's path and the rest's longer one); the swing cap falling and the wobble rising rung by rung,
//          the rest steady; the authored bound held on every rung (through StrokeModel, from real geometry); the same
//          input always giving the same stance and the same delivery; and the retry comparison naming a changed stance
//          without naming it as the cause when a setting changed too.
// SRP/DRY check: Pass - checks only; every limit is read from the named constants in Reach, Stance and StrokeModel,
//          never retyped. Shots are solved through TestShots, the app's own path.
@testable import Breakdown
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import XCTest

final class ReachTests: XCTestCase {
    private let table = PoolParameters().tableSpec
    private let house = CueProfile.house
    private var radius: Double { table.ballRadius }

    /// Sixteen balls, all off the table except the cue ball (index 0) and any given others.
    private func layout(cue: Vec2, _ others: [Int: Vec2] = [:]) -> [Vec2] {
        var out = [Vec2](repeating: NextShot.offTable, count: 16)
        out[0] = cue
        for (i, p) in others { out[i] = p }
        return out
    }

    private func stance(cue: Vec2, aim: Vec2, others: [Int: Vec2] = [:], bridge: Double = StrokeModel.automaticBridge,
                        mechanical: Bool = false) -> Stance {
        guard let s = Reach.stance(layout: layout(cue: cue, others), cueBall: 0, aim: aim, table: table, bridge: bridge,
                                   mechanical: mechanical) else {
            XCTFail("a cue ball on the table always has a stance")
            return Stance(rung: .rest, raisedOver: nil, reach: .infinity, rail: .head, standing: Vec2(0, 0))
        }
        return s
    }

    /// A stance of a given rung, for the cost checks (where the player stands does not enter the cost).
    private func made(_ rung: Stance.Rung, raised: Int? = nil) -> Stance {
        Stance(rung: rung, raisedOver: raised, reach: 0, rail: .head, standing: Vec2(-Reach.railOuter, 0))
    }

    private func record(_ wander: Double, power: Double) -> StrokeRecord {
        StrokeRecord(wander: wander, rhythm: 1, bridge: nil, power: power, trace: [], shape: [], practiceStrokes: 0)
    }

    // MARK: Rung boundaries

    func testRungBoundariesAlongTheCueLine() {
        // The pure ladder, exactly at and just past each limit.
        XCTAssertEqual(Reach.rung(forReach: 0), .normal)
        XCTAssertEqual(Reach.rung(forReach: Reach.squareReach), .normal)
        XCTAssertEqual(Reach.rung(forReach: Reach.squareReach.nextUp), .stretch)
        XCTAssertEqual(Reach.rung(forReach: Reach.stretchReach), .stretch)
        XCTAssertEqual(Reach.rung(forReach: Reach.stretchReach.nextUp), .sittingOnRail)
        XCTAssertEqual(Reach.rung(forReach: Reach.sittingReach), .sittingOnRail)
        XCTAssertEqual(Reach.rung(forReach: Reach.sittingReach.nextUp), .rest)

        // On the table: the cue ball across the middle, the cue along the table toward the foot, so the player stands
        // at the head rail and the bridge hand is (x - bridge + rail) in from its outer edge. The long rails are too far
        // away for a stance beside them, so the line alone decides.
        let bridge = StrokeModel.automaticBridge
        let cases: [(reach: Double, rung: Stance.Rung)] = [
            (Reach.squareReach - 0.01, .normal), (Reach.squareReach + 0.01, .stretch),
            (Reach.stretchReach - 0.01, .stretch), (Reach.stretchReach + 0.01, .sittingOnRail),
            (Reach.sittingReach - 0.01, .sittingOnRail), (Reach.sittingReach + 0.01, .rest),
        ]
        for c in cases {
            let x = c.reach + bridge - Reach.railOuter
            let s = stance(cue: Vec2(x, table.width / 2), aim: Vec2(1, 0))
            XCTAssertEqual(s.rung, c.rung, "reach \(c.reach) m")
            XCTAssertEqual(s.reach, c.reach, accuracy: 1e-9)
            XCTAssertEqual(s.rail, .head)
            XCTAssertEqual(s.standing.x, -Reach.railOuter, accuracy: 1e-12, "the hip is at the head rail's outer edge")
            XCTAssertEqual(s.standing.y, table.width / 2, accuracy: 1e-12)
        }

        // A longer bridge brings the hand nearer the player: the same cue ball goes from a stretch to a square stance.
        let x = Reach.squareReach + 0.05 + bridge - Reach.railOuter
        XCTAssertEqual(stance(cue: Vec2(x, table.width / 2), aim: Vec2(1, 0)).rung, .stretch)
        XCTAssertEqual(stance(cue: Vec2(x, table.width / 2), aim: Vec2(1, 0), bridge: bridge + 0.1).rung, .normal)

        // The shot that shows the mechanical bridge is the rest, whatever the reach, and plays off the rest's head.
        let near = stance(cue: Vec2(0.5, table.width / 2), aim: Vec2(1, 0), mechanical: true)
        XCTAssertEqual(near.rung, .rest)
        XCTAssertEqual(near.bridge(hand: bridge), StrokeModel.mechanicalBridge)
        XCTAssertEqual(made(.stretch).bridge(hand: 0.27), 0.27, "a hand rung plays off the hand bridge")
    }

    // MARK: Walking round the table

    func testWalkAroundTakesTheEasiestWayToStand() {
        let close = radius + 0.03          // the cue ball a little off the near long cushion
        let L = table.length, W = table.width

        // Far up the table along the near long rail, the cue toward the foot: behind the cue it is out of reach (the
        // head rail is 1.8 m back along the line), but the line runs along the near rail, so the player stands there
        // and takes the cue behind the back.
        let far = stance(cue: Vec2(1.8, close), aim: Vec2(1, 0))
        XCTAssertEqual(Reach.behindTheCue(hand: Vec2(1.8 - StrokeModel.automaticBridge, close), back: Vec2(-1, 0),
                                          table: table).rung, .rest, "standing behind the cue is out of reach")
        XCTAssertEqual(far.rung, .behindTheBack)
        XCTAssertEqual(far.rail, .longNear)
        XCTAssertEqual(far.reach, close + Reach.railOuter, accuracy: 1e-12, "straight in from the near rail")
        XCTAssertEqual(far.standing.y, -Reach.railOuter, accuracy: 1e-12)
        XCTAssertEqual(far.standing.x, 1.8 - StrokeModel.tipToRearHand, accuracy: 1e-12, "level with the rear hand")

        // The same shot mirrored across the table, and end for end: the player walks round to the matching rail.
        let across = stance(cue: Vec2(1.8, W - close), aim: Vec2(1, 0))
        XCTAssertEqual(across.rung, .behindTheBack)
        XCTAssertEqual(across.rail, .longFar)
        XCTAssertEqual(across.reach, far.reach, accuracy: 1e-12)
        let endForEnd = stance(cue: Vec2(L - 1.8, close), aim: Vec2(-1, 0))
        XCTAssertEqual(endForEnd.rung, .behindTheBack)
        XCTAssertEqual(endForEnd.rail, .longNear)
        XCTAssertEqual(endForEnd.reach, far.reach, accuracy: 1e-12)

        // Nearer the head, standing behind the cue is a stretch: that beats the cue behind the back, which also works.
        let mid = Vec2(1.3, close)
        XCTAssertNotNil(Reach.besideRail(.longNear, ball: mid, hand: mid - Vec2(StrokeModel.automaticBridge, 0),
                                         back: Vec2(-1, 0), table: table), "behind the back works here too")
        XCTAssertEqual(stance(cue: mid, aim: Vec2(1, 0)).rung, .stretch)
        XCTAssertEqual(stance(cue: mid, aim: Vec2(1, 0)).rail, .head)

        // Nearer still, a square stance at the head rail.
        XCTAssertEqual(stance(cue: Vec2(0.6, close), aim: Vec2(1, 0)).rung, .normal)

        // Across the table from the middle: the player walks round to the near long rail and stands square.
        let side = stance(cue: Vec2(L / 2, W / 2), aim: Vec2(0, 1))
        XCTAssertEqual(side.rung, .normal)
        XCTAssertEqual(side.rail, .longNear)
        XCTAssertEqual(side.standing.x, L / 2, accuracy: 1e-12)
        XCTAssertEqual(side.reach, W / 2 - StrokeModel.automaticBridge + Reach.railOuter, accuracy: 1e-12)

        // A cue line far from every rail and out of reach behind the cue: nothing easier exists, so the rest.
        XCTAssertEqual(stance(cue: Vec2(1.9, W / 2), aim: Vec2(1, 0)).rung, .rest)

        // Whatever the direction, the player stands on the outer edge of the rail they are said to stand at.
        for k in 0..<36 {
            let a = Double(k) * 10 * Double.pi / 180
            let s = stance(cue: Vec2(1.1, 0.5), aim: Vec2(cos(a), sin(a)))
            XCTAssertEqual(Reach.depth(s.standing, inside: s.rail, table: table), 0, accuracy: 1e-9, "aim \(k * 10) degrees")
            XCTAssertTrue(Reach.alongsideRail(s.standing, s.rail, table: table))
        }
    }

    // MARK: A ball under the cue

    func testABallUnderTheCueNeedsTheCueRaised() {
        // The cue ball near enough the head rail for a square stance, the cue toward the foot.
        let cue = Vec2(0.7, 0.6), aim = Vec2(1, 0)
        // Straight behind, between the cue ball and the bridge hand: under the shaft.
        XCTAssertEqual(stance(cue: cue, aim: aim, others: [5: Vec2(0.6, 0.6)]).raisedOver, 5)
        // Just off the line but close enough for the shaft to touch it.
        XCTAssertEqual(stance(cue: cue, aim: aim, others: [4: Vec2(0.5, 0.63)]).raisedOver, 4)
        // Under the bridge hand itself, beside the line.
        XCTAssertEqual(stance(cue: cue, aim: aim, others: [6: Vec2(0.48, 0.65)]).raisedOver, 6)
        // Clear: well to the side, beyond the hand, or in front of the cue ball.
        XCTAssertNil(stance(cue: cue, aim: aim, others: [3: Vec2(0.6, 0.66)]).raisedOver)
        XCTAssertNil(stance(cue: cue, aim: aim, others: [3: Vec2(0.3, 0.6)]).raisedOver)
        XCTAssertNil(stance(cue: cue, aim: aim, others: [3: Vec2(0.9, 0.6)]).raisedOver)
        // Two in the way: the one nearer the cue ball is named.
        XCTAssertEqual(stance(cue: cue, aim: aim, others: [9: Vec2(0.52, 0.6), 2: Vec2(0.62, 0.6)]).raisedOver, 2)
        // The rest's head stands further back than a hand bridge: a ball the hand bridge clears is under its path.
        let beyondHand = [7: Vec2(0.41, 0.6)]
        XCTAssertNil(stance(cue: cue, aim: aim, others: beyondHand).raisedOver)
        XCTAssertEqual(stance(cue: cue, aim: aim, others: beyondHand, mechanical: true).raisedOver, 7)
        // A raised cue on a square stance is still worth a line; the line names the ball.
        let raised = stance(cue: cue, aim: aim, others: [5: Vec2(0.6, 0.6)])
        XCTAssertEqual(raised.rung, .normal)
        XCTAssertFalse(raised.isNormal)
        XCTAssertTrue(StanceWords.raisedLine(over: 5, kind: nil).contains("5"))
        XCTAssertEqual(StanceWords.lines(raised, kind: nil), [StanceWords.raisedLine(over: 5, kind: nil)])
        XCTAssertTrue(StanceWords.lines(stance(cue: cue, aim: aim), kind: nil).isEmpty, "a square, clear stance says nothing")
    }

    // MARK: The cost of each rung

    func testSwingCapFallsAndWobbleRisesByRung() {
        let rungs = Stance.Rung.allCases
        // The swing cap falls on every step of the ladder, the rest lowest of all.
        for (a, b) in zip(rungs, rungs.dropFirst()) {
            XCTAssertGreaterThan(a.swingFactor, b.swingFactor, "\(a) to \(b)")
        }
        // The wobble rises over the standing rungs; the rest is steady (its head stands on the cloth), no worse than a
        // square stance.
        let standing: [Stance.Rung] = [.normal, .stretch, .behindTheBack, .sittingOnRail]
        for (a, b) in zip(standing, standing.dropFirst()) {
            XCTAssertLessThan(a.wobbleFactor, b.wobbleFactor, "\(a) to \(b)")
        }
        XCTAssertEqual(Stance.Rung.rest.wobbleFactor, Stance.Rung.normal.wobbleFactor)
        // A raised cue costs a little more on top of any rung.
        for r in rungs {
            XCTAssertLessThan(made(r, raised: 5).swingFactor, made(r).swingFactor)
            XCTAssertGreaterThan(made(r, raised: 5).wobbleFactor, made(r).wobbleFactor)
        }

        // Through StrokeModel: the calm top falls rung by rung, and a free-play stroke drifts more on each standing
        // rung (same wander, same bridge, calm power).
        let bridge = StrokeModel.automaticBridge
        var lastTop = Double.infinity
        for r in rungs {
            let top = StrokeModel.zones(cue: house, bridge: bridge, stance: made(r)).calmTopSwing
            XCTAssertLessThan(top, lastTop, "\(r)")
            lastTop = top
        }
        var lastAim = -1.0
        for r in standing {
            let d = StrokeModel.delivery(power: 2, fraction: 0.1, record: record(0.03, power: 2), bridge: bridge, cue: house,
                                         authored: false, stance: made(r))
            XCTAssertGreaterThan(abs(d.aimError), lastAim, "\(r)")
            lastAim = abs(d.aimError)
            XCTAssertEqual(d.stance, made(r), "the delivery keeps its stance")
        }
        // A square stance costs exactly nothing: bit for bit the delivery with no stance at all.
        for power in [2.0, 6.0, 11.0] {
            for w: Double? in [nil, 0.04] {
                let plain = StrokeModel.delivery(power: power, fraction: 0.5, record: w.map { record($0, power: power) },
                                                 bridge: bridge, cue: house, authored: false)
                let square = StrokeModel.delivery(power: power, fraction: 0.5, record: w.map { record($0, power: power) },
                                                  bridge: bridge, cue: house, authored: false, stance: made(.normal))
                XCTAssertEqual(plain.aimError.bitPattern, square.aimError.bitPattern)
                XCTAssertEqual(plain.tipSideError.bitPattern, square.tipSideError.bitPattern)
                XCTAssertEqual(plain.calmTopSwing.bitPattern, square.calmTopSwing.bitPattern)
            }
        }
    }

    // MARK: Authored shots stay makeable

    func testAuthoredBoundHoldsForStancesFromTheTable() {
        // Stances worked out from real geometry: every rung the ladder can give, raised over a ball or not, and the
        // mechanical bridge's rest.
        let W = table.width
        let stances: [Stance] = [
            stance(cue: Vec2(0.6, W / 2), aim: Vec2(1, 0)),
            stance(cue: Vec2(1.3, W / 2), aim: Vec2(1, 0)),
            stance(cue: Vec2(1.8, radius + 0.03), aim: Vec2(1, 0)),
            stance(cue: Vec2(1.5, W / 2), aim: Vec2(1, 0)),
            stance(cue: Vec2(1.9, W / 2), aim: Vec2(1, 0)),
            stance(cue: Vec2(1.0, 0.6), aim: Vec2(1, 0), others: [5: Vec2(0.9, 0.6)]),
            stance(cue: Vec2(1.9, W / 2), aim: Vec2(1, 0), others: [5: Vec2(1.75, W / 2)], mechanical: true),
        ]
        XCTAssertEqual(Set(stances.map(\.rung.rawValue)), Set(Stance.Rung.allCases.map(\.rawValue)), "every rung is covered")
        XCTAssertTrue(stances.contains { $0.raisedOver != nil && $0.rung == .rest })
        for s in stances {
            let bridge = s.bridge(hand: StrokeModel.automaticBridge)
            for w in [0.001, 0.02, 0.1, 0.5, 1.0, -1.0] {
                // The hardest authored shot with its window: 6.60 m/s.
                for power in [1.0, 4.0, 6.60] {
                    let d = StrokeModel.delivery(power: power, fraction: 0.4, record: record(w, power: power), bridge: bridge,
                                                 cue: house, authored: true, stance: s)
                    XCTAssertLessThan(abs(d.aimError), StrokeModel.authoredAimBound, "\(s.rung)")
                    XCTAssertLessThan(abs(d.tipSideError), 0.0000625, "tip drift past 0.0625 mm on \(s.rung)")
                    XCTAssertFalse(d.warm, "an authored power stays in the calm zone on \(s.rung)")
                    // The stance never lowers the calm top in an authored mode.
                    let plain = StrokeModel.delivery(power: power, fraction: 0.4, record: record(w, power: power),
                                                     bridge: bridge, cue: house, authored: true)
                    XCTAssertEqual(d.calmTopSwing, plain.calmTopSwing)
                }
            }
        }
    }

    // MARK: Determinism

    func testSameInputSameStance() {
        let others = [3: Vec2(0.95, 0.62), 8: Vec2(2.0, 1.0)]
        for k in 0..<24 {
            let a = Double(k) * 15 * Double.pi / 180
            let aim = Vec2(cos(a), sin(a))
            let first = stance(cue: Vec2(1.05, 0.62), aim: aim, others: others, bridge: 0.27)
            let second = stance(cue: Vec2(1.05, 0.62), aim: aim, others: others, bridge: 0.27)
            XCTAssertEqual(first, second)
            let d1 = StrokeModel.delivery(power: 12, fraction: 0.9, record: record(0.05, power: 12),
                                          bridge: first.bridge(hand: 0.27), cue: house, authored: false, stance: first)
            let d2 = StrokeModel.delivery(power: 12, fraction: 0.9, record: record(0.05, power: 12),
                                          bridge: second.bridge(hand: 0.27), cue: house, authored: false, stance: second)
            XCTAssertEqual(d1, d2)
        }
        // A scaled aim is the same aim (equal to rounding: the direction is normalised).
        let long = stance(cue: Vec2(1.05, 0.62), aim: Vec2(3, 1)), short = stance(cue: Vec2(1.05, 0.62), aim: Vec2(0.3, 0.1))
        XCTAssertEqual(long.rung, short.rung)
        XCTAssertEqual(long.rail, short.rail)
        XCTAssertEqual(long.reach, short.reach, accuracy: 1e-12)
        // No cue ball on the table, or no direction: no stance.
        XCTAssertNil(Reach.stance(layout: layout(cue: NextShot.offTable), cueBall: 0, aim: Vec2(1, 0), table: table,
                                  bridge: 0.2, mechanical: false))
        XCTAssertNil(Reach.stance(layout: layout(cue: Vec2(1, 0.6)), cueBall: 0, aim: Vec2(0, 0), table: table,
                                  bridge: 0.2, mechanical: false))
    }

    // MARK: The retry comparison

    @MainActor
    func testComparisonNamesAChangedStanceWithoutClaimingTheCause() {
        var start = [Vec2](repeating: NextShot.offTable, count: 16)
        start[0] = Vec2(0.6, 0.635); start[1] = Vec2(1.5, 0.635)
        let s3 = TrickSettings(aim: 0, power: 3, tipUp: 0, tipSide: 0)
        let tl = TestShots.shot(from: start, s3)
        func delivery(_ s: Stance, bridge: Double = StrokeModel.automaticBridge) -> StrokeDelivery {
            StrokeModel.delivery(power: 3, fraction: 0.2, record: nil, bridge: bridge, cue: house, authored: false, stance: s)
        }
        var a = TestShots.attempt(start: start, timeline: tl, s3)
        a.stroke = delivery(made(.normal))
        var b = TestShots.attempt(start: start, timeline: tl, s3)
        b.stroke = delivery(made(.stretch))

        // Only the stance changed: it is named, it is not an exact repeat, and the stance each try had is said.
        let c = RetryComparison.between(a, b)
        XCTAssertNotNil(c.setup)
        XCTAssertTrue(c.inputChanges.isEmpty)
        XCTAssertNotEqual(c.key, .exactRepeat)
        let sentence = RetryWords.sentence(c)
        XCTAssertTrue(sentence.contains(StanceWords.rungLine(.stretch)), sentence)
        XCTAssertTrue(sentence.contains(String(localized: "your stance")), sentence)

        // The same stance and bridge: no setup fact, and the identical retry is still an exact repeat.
        var same = b
        same.stroke = delivery(made(.normal))
        let exact = RetryComparison.between(a, same)
        XCTAssertNil(exact.setup)
        XCTAssertEqual(exact.key, .exactRepeat)

        // The bridge hand moved along the cue: said as a bridge change.
        var longer = b
        longer.stroke = delivery(made(.normal), bridge: StrokeModel.automaticBridge + 0.1)
        XCTAssertEqual(RetryComparison.between(a, longer).setup?.bridgeChanged, true)
        XCTAssertEqual(RetryComparison.between(a, longer).setup?.stanceChanged, false)

        // The stance changed AND the power changed: several changes, so neither is named as the change on its own.
        let s4 = TrickSettings(aim: 0, power: 4.5, tipUp: 0, tipSide: 0)
        var harder = TestShots.attempt(start: start, timeline: TestShots.shot(from: start, s4), s4)
        harder.stroke = delivery(made(.stretch))
        let both = RetryComparison.between(a, harder)
        XCTAssertEqual(both.key, .severalChanges)
        XCTAssertTrue(RetryWords.sentence(both).contains(String(localized: "your stance")))
        // Without the stance change the power alone is the one change, as before.
        var harderOnly = harder
        harderOnly.stroke = delivery(made(.normal))
        XCTAssertEqual(RetryComparison.between(a, harderOnly).key, .oneChange(.power))
    }
}
