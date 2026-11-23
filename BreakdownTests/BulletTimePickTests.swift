// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// PURPOSE: Bullet time's trigger judge (App/BulletTimePick.swift; plans/23-Nov-2026-bullet-time-plan.md, version 0.7.7)
//          against real solves. The authored jump, masse and combination answers must read as a jump hit, a curve hit
//          and a kiss; a soft plain pot and a bank must not freeze as a kiss or a cut; a built thin cut must read as a
//          big cut and a fuller pot from the same place must not; a hard break must freeze and the panel's default
//          break must not; and every candidate is a ball-to-ball hit on a ball at rest, in priority order. Every test
//          that leans on a threshold prints what it measured, so the thresholds can be retuned from one run.
// SRP/DRY check: Pass - checks only. Solving reuses TestShots (EightBallJudge.solve and the break input), the reading of
//          the shot is ShotFacts', the captions CaptionEngine's and the event finders ShotMoments'; the rules are the
//          pick's, not restated. The layouts copy ShotHighlightJudgeTests' soft pot, as the plan asks.
@testable import Breakdown
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import XCTest

final class BulletTimePickTests: XCTestCase {
    /// A recorded shot with everything the pick reads.
    private struct Played {
        let timeline: Timeline
        let facts: ShotFacts
        let captions: [Caption]
    }

    private func play(_ start: [Vec2], _ s: TrickSettings) -> Played {
        let tl = TestShots.shot(from: start, s)
        return Played(timeline: tl, facts: ShotFacts(timeline: tl, start: start, cueBall: 0),
                      captions: CaptionEngine.make(from: tl, surface: .cloth))
    }

    private func answer(_ id: String, file: StaticString = #filePath, line: UInt = #line) -> Played? {
        guard let shot = TrickShots.shot(id: id), case .layout(let start) = shot.setup else {
            XCTFail("\(id): no laid-out trick shot with that id", file: file, line: line)
            return nil
        }
        return play(start, shot.solution)
    }

    private func candidates(_ p: Played, isBreak: Bool = false) -> [BulletMoment] {
        BulletTimePick.candidates(timeline: p.timeline, facts: p.facts, captions: p.captions, isBreak: isBreak)
    }

    private func pick(_ p: Played, isBreak: Bool = false) -> BulletMoment? {
        BulletTimePick.pick(timeline: p.timeline, facts: p.facts, captions: p.captions, isBreak: isBreak)
    }

    /// The moment is on a ball-to-ball contact whose struck ball was at rest, and its time is that event's.
    private func assertFreezable(_ m: BulletMoment, in p: Played, _ label: String,
                                 file: StaticString = #filePath, line: UInt = #line) {
        guard p.timeline.events.indices.contains(m.event) else {
            return XCTFail("\(label): event \(m.event) is not in the recording", file: file, line: line)
        }
        let e = p.timeline.events[m.event]
        XCTAssertEqual(e.kind, .ballBall, "\(label): not a ball-to-ball contact", file: file, line: line)
        guard let g = ContactGeometry.at(e) else {
            return XCTFail("\(label): no contact geometry", file: file, line: line)
        }
        XCTAssertFalse(g.objectWasMoving, "\(label): the struck ball was moving", file: file, line: line)
        XCTAssertEqual(m.time, e.time, "\(label): the moment's time is not its event's", file: file, line: line)
        XCTAssertEqual(m.striker, g.striker, label, file: file, line: line)
        XCTAssertEqual(m.object, g.object, label, file: file, line: line)
    }

    // MARK: The trick answers

    func testTheTrickAnswersReadAsTheirKinds() {
        let expected: [(id: String, kind: BulletKind)] = [("jump-over", .jumpHit), ("masse-curve", .curveHit),
                                                          ("combo-chain", .kiss)]
        for (id, kind) in expected {
            guard let p = answer(id) else { continue }
            let found = candidates(p)
            guard let m = pick(p) else {
                XCTFail("\(id): expected \(kind), found nothing")
                continue
            }
            XCTAssertEqual(m.kind, kind, "\(id): expected \(kind), candidates \(found.map(\.kind))")
            assertFreezable(m, in: p, id)
        }
    }

    func testTheJumpFreezesOnTheFirstContactAfterTakeOff() {
        guard let p = answer("jump-over") else { return }
        let moments = ShotMoments(timeline: p.timeline, captions: p.captions)
        guard let up = moments.takeOff(of: 0, minimumUp: ShotHighlightJudge.jumpSpeed) else {
            return XCTFail("jump-over: the cue ball never took off")
        }
        let expected = moments.contacts(of: 0).first { moments.time($0) >= moments.time(up) - ShotMoments.instant }
        guard let m = candidates(p).first(where: { $0.kind == .jumpHit }) else {
            return XCTFail("jump-over: no jump hit; candidates \(candidates(p).map(\.kind))")
        }
        XCTAssertEqual(Optional(m.event), expected, "jump-over: not the first contact at or after the take-off")
    }

    // MARK: Shots that must not freeze

    func testASoftPlainPotIsNothing() {
        // ShotHighlightJudgeTests.testASoftPlainPotIsNothingSpecial's layout: one object ball 0.8 m out from the
        // top-right corner, the cue ball 0.4 m behind it on the same line, struck softly with natural roll.
        let r = PoolParameters().ballRadius
        let pocket = Vec2(2.54, 1.27)
        let way = Vec2(0.34, 0.27).normalized
        var start = [Vec2](repeating: ShotFacts.offTable, count: 16)
        start[1] = pocket - way * 0.8
        start[0] = start[1] - way * 0.4
        let aim = atan2(way.y, way.x) * 180 / Double.pi
        let p = play(start, TrickSettings(aim: aim, power: 1.0, tipUp: 0.4 * r, tipSide: 0))
        XCTAssertNil(pick(p), "a soft straight pot froze as \(String(describing: pick(p)?.kind))")
    }

    func testABankIsNeverAKissOrACut() {
        guard let p = answer("cross-bank") else { return }
        let kinds = candidates(p).map(\.kind)
        XCTAssertFalse(kinds.contains(.kiss), "cross-bank: a rail comes between the contact and the drop; \(kinds)")
        XCTAssertFalse(kinds.contains(.bigCut), "cross-bank: a rail comes between the contact and the drop; \(kinds)")
    }

    // MARK: The cut

    /// A cut on the 1 towards the top-right corner, the 1 half a metre out, the cue ball coming in `degrees` off the
    /// line to the pocket, 0.6 m from the ghost ball, at 2 m/s with no tip.
    private func cut(degrees: Double) -> Played {
        let r = PoolParameters().ballRadius
        let pocket = Vec2(2.54, 1.27)
        let way = Vec2(0.34, 0.27).normalized
        var start = [Vec2](repeating: ShotFacts.offTable, count: 16)
        start[1] = pocket - way * 0.5
        let ghost = start[1] - way * (2 * r)
        let a = degrees * Double.pi / 180
        // The cue's line: the way to the pocket turned counter-clockwise by the cut.
        let d = Vec2(way.x * cos(a) - way.y * sin(a), way.x * sin(a) + way.y * cos(a))
        start[0] = ghost - d * 0.6
        let aim = atan2(d.y, d.x) * 180 / Double.pi
        return play(start, TrickSettings(aim: aim, power: 2.0, tipUp: 0, tipSide: 0))
    }

    func testAThinCutThatDropsIsABigCut() {
        let p = cut(degrees: 60)
        XCTAssertTrue(p.facts.objectBallsPocketed.contains { $0.ball == 1 },
                      "the thin cut no longer drops the 1: move it nearer the pocket")
        guard let m = pick(p) else { return XCTFail("the thin cut froze as nothing; candidates \(candidates(p).map(\.kind))") }
        XCTAssertEqual(m.kind, .bigCut)
        assertFreezable(m, in: p, "thin cut")
        guard let g = ContactGeometry.at(p.timeline.events[m.event]) else { return XCTFail("thin cut: no geometry") }
        let angle = BulletTimePick.cutAngle(g)
        XCTAssertGreaterThanOrEqual(angle, BulletTimePick.cutDegrees,
                                    "thin cut measured \(angle) degrees at \(g.incoming.length) m/s")
    }

    func testAFullerPotIsNotABigCut() {
        let p = cut(degrees: 20)
        let first = ShotMoments(timeline: p.timeline, captions: p.captions).firstContact(of: 0)
        let angle = first.flatMap { ContactGeometry.at(p.timeline.events[$0]) }.map(BulletTimePick.cutAngle)
        XCTAssertNil(pick(p), "a twenty-degree cut froze as \(String(describing: pick(p)?.kind)); measured angle \(String(describing: angle))")
    }

    // MARK: Breaks

    /// A break at `speed` m/s at the strike (TestShots' break input), with the layout it was struck from.
    private func breakShot(speed: Double) -> Played {
        let input = TestShots.breakInput(speed: speed)
        let tl = TestShots.solve(input)
        return Played(timeline: tl, facts: ShotFacts(timeline: tl, start: input.positions, cueBall: 0),
                      captions: CaptionEngine.make(from: tl, surface: .cloth))
    }

    /// The cue ball's speed into its first contact on a break, m/s (for the messages).
    private func rackSpeed(_ p: Played) -> Double? {
        ShotMoments(timeline: p.timeline, captions: p.captions).firstContact(of: 0)
            .flatMap { ContactGeometry.at(p.timeline.events[$0]) }?.incoming.length
    }

    func testAHardBreakFreezes() {
        let p = breakShot(speed: 15)
        let m = pick(p, isBreak: true)
        XCTAssertEqual(m?.kind, .hardBreak, "a fifteen m/s break met the rack at \(String(describing: rackSpeed(p))) m/s")
        if let m { assertFreezable(m, in: p, "hard break") }
    }

    func testTheDefaultBreakNeverFreezes() {
        let p = breakShot(speed: 10)
        XCTAssertNil(pick(p, isBreak: true),
                     "the default break met the rack at \(String(describing: rackSpeed(p))) m/s and froze")
    }

    func testAShotThatIsNotABreakIsNeverAHardBreak() {
        let p = breakShot(speed: 15)
        XCTAssertFalse(candidates(p, isBreak: false).contains { $0.kind == .hardBreak })
    }

    // MARK: Priority

    func testCandidatesAreInPriorityOrderAndFreezable() {
        let order = BulletKind.allCases
        for shot in TrickShots.all {
            guard case .layout(let start) = shot.setup else { continue }
            let p = play(start, shot.solution)
            let found = candidates(p)
            XCTAssertEqual(pick(p), found.first, shot.id)
            let ranks = found.compactMap { order.firstIndex(of: $0.kind) }
            XCTAssertEqual(ranks, ranks.sorted(), "\(shot.id): not in BulletKind order: \(found.map(\.kind))")
            XCTAssertEqual(Set(ranks).count, ranks.count, "\(shot.id): a kind twice: \(found.map(\.kind))")
            for m in found { assertFreezable(m, in: p, "\(shot.id) \(m.kind)") }
        }
    }
}
