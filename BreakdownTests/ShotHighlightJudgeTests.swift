// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// PURPOSE: 0.7.4 G3's judge (App/ShotHighlightJudge.swift; plans/22-Nov-2026-v074-glow-up-plan.md, stream lens-pacing)
//          against real solves. Each authored trick answer, solved the way the app solves it, must be read as the kind
//          of shot it teaches (Stop Dead a dead stop, the Masse a curve, and so on); a soft plain pot with natural roll
//          must be read as nothing at all; every signature event the judge returns must carry a caption (so a replay
//          can hold it); and the break must be judged a break only when the shot is a break.
// SRP/DRY check: Pass - checks only. Solving reuses TestShots (EightBallJudge.solve and the break input); the reading
//          of the shot is ShotFacts', the captions CaptionEngine's; the kinds' rules are the judge's, not restated.
@testable import Breakdown
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import XCTest

final class ShotHighlightJudgeTests: XCTestCase {
    /// The kind each trick teaches, as the plan lists them.
    private let taught: [String: HighlightKind] = [
        "stop-dead": .stopDead, "bridge-draw": .drawBack, "follow-train": .multiPot, "two-rail-kick": .kick,
        "cross-bank": .bank, "combo-chain": .combination, "throw-it": .throwIn, "masse-curve": .curve,
        "jump-over": .jump,
    ]

    /// A recorded shot with everything the judge reads.
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

    private func detect(_ p: Played, isBreak: Bool = false) -> [ShotHighlight] {
        ShotHighlightJudge.detect(timeline: p.timeline, facts: p.facts, captions: p.captions, table: .standard,
                                  isBreak: isBreak)
    }

    /// Every signature event has a caption, there are one or two, and they are in clock order.
    private func assertHoldable(_ found: [ShotHighlight], in p: Played, _ label: String,
                                file: StaticString = #filePath, line: UInt = #line) {
        let captioned = Set(p.captions.map(\.id))
        for h in found {
            XCTAssertFalse(h.signatureEvents.isEmpty, "\(label) \(h.kind): empty signature", file: file, line: line)
            XCTAssertLessThanOrEqual(h.signatureEvents.count, 2, "\(label) \(h.kind)", file: file, line: line)
            for ev in h.signatureEvents {
                XCTAssertTrue(captioned.contains(ev), "\(label) \(h.kind): event \(ev) has no caption",
                              file: file, line: line)
            }
            let times = h.signatureEvents.map { p.timeline.events[$0].time }
            XCTAssertEqual(times, times.sorted(), "\(label) \(h.kind): not in clock order", file: file, line: line)
        }
    }

    func testEachTrickIsReadAsTheKindItTeaches() {
        for (id, kind) in taught.sorted(by: { $0.key < $1.key }) {
            guard let p = answer(id) else { continue }
            let found = detect(p)
            XCTAssertTrue(found.contains { $0.kind == kind }, "\(id): expected \(kind), found \(found.map(\.kind))")
            // Strongest first.
            let ranks = found.map(\.kind.rank)
            XCTAssertEqual(ranks, ranks.sorted(by: >), "\(id): not strongest first")
            // judge(...) is the first of detect(...).
            XCTAssertEqual(ShotHighlightJudge.judge(timeline: p.timeline, facts: p.facts, captions: p.captions,
                                                    table: .standard, isBreak: false), found.first, id)
        }
    }

    func testEverySignatureEventHasACaption() {
        for shot in TrickShots.all {
            guard case .layout(let start) = shot.setup else { continue }
            let p = play(start, shot.solution)
            assertHoldable(detect(p), in: p, shot.id)
        }
        let b = breakShot()
        assertHoldable(detect(b, isBreak: true), in: b, "break")
    }

    func testASoftPlainPotIsNothingSpecial() {
        // One object ball 0.8 m out from the top-right corner, the cue ball 0.4 m behind it on the same line, struck
        // softly with natural roll (tip two fifths of the radius above centre): it drops, the cue ball follows a
        // little, and nothing about it is remarkable.
        let r = PoolParameters().ballRadius
        let pocket = Vec2(2.54, 1.27)
        let way = Vec2(0.34, 0.27).normalized
        var start = [Vec2](repeating: ShotFacts.offTable, count: 16)
        start[1] = pocket - way * 0.8
        start[0] = start[1] - way * 0.4
        let aim = atan2(way.y, way.x) * 180 / Double.pi
        let p = play(start, TrickSettings(aim: aim, power: 1.0, tipUp: 0.4 * r, tipSide: 0))
        XCTAssertEqual(p.facts.objectBallsPocketed.map(\.ball), [1], "the soft pot no longer drops the 1")
        XCTAssertEqual(detect(p).map(\.kind), [])
    }

    func testABreakIsABreakOnlyWhenItIsOne() {
        let b = breakShot()
        XCTAssertEqual(detect(b, isBreak: true).map(\.kind), [.breakShot])
        XCTAssertFalse(detect(b, isBreak: false).contains { $0.kind == .breakShot })
    }

    /// The player's first break (TestShots' break input), with the layout it was struck from.
    private func breakShot() -> Played {
        let input = TestShots.breakInput()
        let tl = TestShots.solve(input)
        return Played(timeline: tl, facts: ShotFacts(timeline: tl, start: input.positions, cueBall: 0),
                      captions: CaptionEngine.make(from: tl, surface: .cloth))
    }
}
