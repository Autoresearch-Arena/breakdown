// Author: Claude Opus 5.5 Medium
// Date: 24-November-2026
// PURPOSE: Checks for the jump replay (0.7.8, plans/24-Nov-2026-jump-replay-plan.md) on the authored jump over a
//          blocker, solved for real: the take-off card says the flight height once outside its worked equation and
//          leads with it; the take-off beat may be magnified further than other beats and its rectangle holds the
//          flight and the jumped ball but not the roll after landing; the side view's shape passes over that ball.
// SRP/DRY check: Pass - checks only; the shot is solved the way BulletTimePickTests solves it (TestShots.shot).
@testable import Breakdown
import BreakdownLensModel
import BreakdownTimeline
import XCTest

final class JumpReplayTests: XCTestCase {
    private func jump() throws -> (timeline: Timeline, captions: [Caption]) {
        let shot = try XCTUnwrap(TrickShots.shot(id: "jump-over"))
        guard case .layout(let start) = shot.setup else { throw XCTSkip("jump-over is not a laid-out shot") }
        let tl = TestShots.shot(from: start, shot.solution)
        return (tl, CaptionEngine.make(from: tl, surface: .cloth))
    }

    private func takeOff(_ captions: [Caption], in tl: Timeline) throws -> Caption {
        try XCTUnwrap(captions.first {
            tl.events.indices.contains($0.id) && tl.events[$0.id].flight == .takeOff
        }, "the jump never took off")
    }

    func testTheTakeOffCardSaysTheHeightOnce() throws {
        let (tl, captions) = try jump()
        let c = try takeOff(captions, in: tl)
        let height = try XCTUnwrap(c.figures.first, "no lead figure")
        XCTAssertEqual(height.unit, "cm", "the lead figure is not the flight height")
        XCTAssertFalse(c.detail.contains(height.value), "the sentence repeats the height: \(c.detail)")
        XCTAssertEqual(c.figures.filter { $0.value == height.value && $0.unit == "cm" }.count, 1,
                       "the tiles repeat the height")
        XCTAssertTrue(c.detail.contains("to spare"), "the gap over the jumped ball is not said: \(c.detail)")
    }

    func testTheTakeOffBeatComesInCloseOnTheFlight() throws {
        let (tl, captions) = try jump()
        let c = try takeOff(captions, in: tl)
        let plan = PacePlan(captions: captions, timeline: tl, style: .standard)
        let i = try XCTUnwrap(plan.beats.firstIndex { $0.caption.id == c.id }, "the take-off is not a beat")
        XCTAssertEqual(plan.focusZoom.count, plan.beats.count)
        XCTAssertEqual(plan.focusZoom[i], MomentFraming.flightMagnification)
        XCTAssertTrue(plan.focusZoom.enumerated().allSatisfy { $0.offset == i || $0.element <= MomentFraming.flightMagnification })

        let shape = try XCTUnwrap(FlightShape.make(caption: c, timeline: tl), "no side view for the take-off")
        XCTAssertNotNil(shape.blocker, "the side view does not show the jumped ball")
        XCTAssertGreaterThan(shape.peakGap, 0)
        // The rectangle holds the take-off and landing points, and stops near the landing rather than following the
        // roll-out for a quarter of a metre.
        let r = plan.focusRegions[i]
        for p in [shape.from, shape.to] {
            XCTAssertTrue(p.x >= r.minX - 1e-6 && p.x <= r.maxX + 1e-6 && p.y >= r.minY - 1e-6 && p.y <= r.maxY + 1e-6,
                          "the flight's ends are not in the take-off's rectangle")
        }
        let flightSpan = max(abs(shape.to.x - shape.from.x), abs(shape.to.y - shape.from.y))
        let rectSpan = max(r.maxX - r.minX, r.maxY - r.minY)
        XCTAssertLessThan(rectSpan, flightSpan + 0.18, "the take-off still frames the roll-out")
    }
}
