// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// PURPOSE: 0.7.5 polish P1 (plans/22-Nov-2026-v075-whatif-and-gaps-plan.md, section 5b): the "worth watching" card stops
//          naming ordinary shots. Checks, against real solves, that a plain draw that sent nothing down is no longer
//          "Drawn back" (on the pool table, and on the five-pin table where the computer's shot that scored nothing was
//          offered as one), that a draw that pots still is, and that HighlightOffer.offersComputerShot lets a
//          computer's shot through only for a rare kind, the break, or a shot that scored. Each no-score case first
//          proves the old rule would have offered the draw (far enough back, a holdable signature), so the test shows
//          the new gate is what removes it, not some other change in the shot.
//          The layouts and speeds were measured on the package solver on 22-Nov-2026 (cloth, seed 1): the pool draw
//          comes back about 0.91 m, the five-pin one about 0.94 m (both between drawDistance and twice it), and the
//          potting draw about 1.13 m with the 1 down.
// SRP/DRY check: Pass - checks only. Solving reuses TestShots and EightBallJudge's path for the pool table and the
//          app's own TableKind and PlaySurface numbers for five-pin; the event finders are ShotMoments'; the thresholds
//          are read from ShotHighlightJudge, never retyped. ShotHighlightJudgeTests keeps every trick's own kind.
@testable import Breakdown
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import XCTest

final class HighlightNoiseTests: XCTestCase {
    /// A recorded shot with everything the judge reads.
    private struct Played {
        let timeline: Timeline
        let facts: ShotFacts
        let captions: [Caption]
        let table: TableKind
        let cue: Int
    }

    // MARK: Shots

    /// A pool-table shot from a layout, solved as the app solves it (TestShots, cloth, seed 1).
    private func pool(_ start: [Vec2], _ s: TrickSettings) -> Played {
        let tl = TestShots.shot(from: start, s)
        return Played(timeline: tl, facts: ShotFacts(timeline: tl, start: start, cueBall: 0),
                      captions: CaptionEngine.make(from: tl, surface: .cloth), table: .standard, cue: 0)
    }

    /// The pool no-score draw: the cue ball 0.4 m behind the 1 on a line along the table's length, well away from every
    /// pocket, struck at 4 m/s with heavy draw. The 1 runs to the foot rail's middle and stays out; the cue ball comes
    /// back about 0.91 m.
    private func poolPlainDraw() -> Played {
        let r = PoolParameters().ballRadius
        var start = [Vec2](repeating: ShotFacts.offTable, count: 16)
        start[0] = Vec2(1.0, 0.45)
        start[1] = Vec2(1.4, 0.45)
        return pool(start, TrickSettings(aim: 0, power: 4.0, tipUp: -0.6 * r, tipSide: 0))
    }

    /// The five-pin no-score draw, as the computer plays it with the yellow (ball 1): the yellow strikes the white full
    /// along the near long cushion toward the upper short cushion, with heavy draw, the red parked across the table.
    /// Nothing goes near the castle; no pin falls; the yellow comes back about 0.94 m.
    private func fivePinPlainDraw() -> Played {
        var p = TableKind.fivePin.parameters
        PlaySurface.cloth.apply(to: &p)
        var start = [Vec2](repeating: ShotFacts.offTable, count: 16)
        start[1] = Vec2(1.9, 0.35)
        start[0] = Vec2(2.3, 0.37)
        start[3] = Vec2(2.13, 1.01)
        let input = NextShot.shot(from: start, direction: Vec2(1, 0), speed: 5.0, tipUp: -0.6 * p.ballRadius,
                                  tipSide: 0, seed: 1, parameters: p, ballIndex: 1)
        let tl = PoolSolver.simulate(input)
        return Played(timeline: tl, facts: ShotFacts(timeline: tl, start: start, cueBall: 1),
                      captions: CaptionEngine.make(from: tl, surface: .cloth, table: .fivePin, striker: 1),
                      table: .fivePin, cue: 1)
    }

    /// A potting draw: the cue ball 0.5 m behind the 1, the 1 0.5 m out from the top-right corner on the same line,
    /// struck at 4.5 m/s with heavy draw. The 1 drops; the cue ball comes back about 1.13 m.
    private func poolPottingDraw() -> Played {
        let r = PoolParameters().ballRadius
        let pocket = Vec2(2.54, 1.27)
        let way = Vec2(0.34, 0.27).normalized
        var start = [Vec2](repeating: ShotFacts.offTable, count: 16)
        start[1] = pocket - way * 0.5
        start[0] = start[1] - way * 0.5
        let aim = atan2(way.y, way.x) * 180 / Double.pi
        return pool(start, TrickSettings(aim: aim, power: 4.5, tipUp: -0.6 * r, tipSide: 0))
    }

    // MARK: Readers

    private func detect(_ p: Played) -> [ShotHighlight] {
        ShotHighlightJudge.detect(timeline: p.timeline, facts: p.facts, captions: p.captions, table: p.table,
                                  isBreak: false)
    }

    /// How far behind its first hit the struck ball came to rest, along the way it came in (the draw rule's own
    /// measure), and whether the old rule's signature (the hit, then the roll taking hold) had a captioned event to
    /// hold. Nil when the struck ball touched no ball.
    private func oldDraw(_ p: Played) -> (behind: Double, holdable: Bool)? {
        let m = ShotMoments(timeline: p.timeline, captions: p.captions)
        guard let f = m.firstContact(of: p.cue),
              let mine = p.timeline.events[f].balls.first(where: { $0.ball == p.cue }) else { return nil }
        let at = p.timeline.state(ball: p.cue, at: p.timeline.events[f].time).position
        let behind = -(p.facts.resting[p.cue] - at).dot(mine.velocityBefore.normalized)
        return (behind, !m.signature([f, m.firstRoll(of: p.cue, after: f)]).isEmpty)
    }

    /// The draw is one the 0.7.4 rule offered: far enough back but under twice the distance, holdable, and the struck
    /// ball still on the table.
    private func assertOldRuleWouldOffer(_ p: Played, _ label: String, file: StaticString = #filePath, line: UInt = #line) {
        guard let d = oldDraw(p) else {
            XCTFail("\(label): the struck ball touched no ball", file: file, line: line)
            return
        }
        XCTAssertGreaterThanOrEqual(d.behind, ShotHighlightJudge.drawDistance,
                                    "\(label): the draw no longer comes back far enough to test the gate",
                                    file: file, line: line)
        XCTAssertLessThan(d.behind, ShotHighlightJudge.plainDrawFactor * ShotHighlightJudge.drawDistance,
                          "\(label): the draw is long enough to count on its own", file: file, line: line)
        XCTAssertTrue(d.holdable, "\(label): the old rule had nothing to hold", file: file, line: line)
        XCTAssertTrue(ShotFacts.isOnTable(p.facts.resting[p.cue]), "\(label): the struck ball left the table",
                      file: file, line: line)
    }

    /// What a computer's shot would offer: the judged moments HighlightOffer.offersComputerShot lets through.
    private func offeredForComputer(_ p: Played) -> [HighlightKind] {
        let scored = ShotHighlightJudge.sentBallDown(p.facts, table: p.table)
        return detect(p).map(\.kind).filter { HighlightOffer.offersComputerShot($0, scored: scored) }
    }

    // MARK: Tests

    func testAPlainDrawThatSentNothingDownIsNotDrawnBack() {
        let p = poolPlainDraw()
        XCTAssertEqual(p.facts.pocketed.map(\.ball), [], "the plain draw now pots a ball")
        XCTAssertFalse(ShotHighlightJudge.sentBallDown(p.facts, table: p.table))
        assertOldRuleWouldOffer(p, "pool plain draw")
        XCTAssertFalse(detect(p).contains { $0.kind == .drawBack }, "a plain draw is not worth a card")
        XCTAssertEqual(offeredForComputer(p), [], "the computer's plain draw offers nothing")
    }

    func testTheComputersFivePinDrawThatScoredNothingOffersNothing() {
        let p = fivePinPlainDraw()
        XCTAssertEqual(p.facts.pinsDown.map(\.pin), [], "the five-pin draw now knocks a pin")
        XCTAssertEqual(p.facts.pocketed.map(\.ball), [])
        XCTAssertFalse(ShotHighlightJudge.sentBallDown(p.facts, table: p.table))
        assertOldRuleWouldOffer(p, "five-pin plain draw")
        XCTAssertFalse(detect(p).contains { $0.kind == .drawBack }, "the reported case: no score, no Drawn back")
        XCTAssertEqual(offeredForComputer(p), [], "the computer's no-score shot offers nothing")
    }

    func testADrawThatPotsIsStillDrawnBack() {
        let p = poolPottingDraw()
        XCTAssertEqual(p.facts.objectBallsPocketed.map(\.ball), [1], "the potting draw no longer drops the 1")
        XCTAssertTrue(ShotHighlightJudge.sentBallDown(p.facts, table: p.table))
        if let d = oldDraw(p) {
            XCTAssertGreaterThanOrEqual(d.behind, ShotHighlightJudge.drawDistance, "the potting draw is too short")
        } else {
            XCTFail("the cue ball touched no ball")
        }
        XCTAssertTrue(detect(p).contains { $0.kind == .drawBack }, "a draw that pots is still worth a card")
        // The computer's potting draw scored, so it is offered too.
        XCTAssertTrue(offeredForComputer(p).contains(.drawBack))
    }

    func testTheComputersShotsAreOfferedOnlyWhenRareOrScored() {
        for kind in HighlightKind.allCases {
            XCTAssertTrue(HighlightOffer.offersComputerShot(kind, scored: true), "\(kind) on a shot that scored")
            let expected = kind.isRare || kind == .breakShot
            XCTAssertEqual(HighlightOffer.offersComputerShot(kind, scored: false), expected,
                           "\(kind) on a shot that scored nothing")
        }
        // The five kinds the person sees every time stay offered for the computer too.
        for kind in HighlightKind.allCases where kind.isRare {
            XCTAssertTrue(HighlightOffer.offersComputerShot(kind, scored: false), "\(kind) is rare")
        }
        XCTAssertFalse(HighlightOffer.offersComputerShot(.drawBack, scored: false))
        XCTAssertFalse(HighlightOffer.offersComputerShot(.stopDead, scored: false))
    }
}
