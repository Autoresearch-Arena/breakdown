// Author: Claude Opus 5.5 Medium
// Date: 22-November-2026
// PURPOSE: The upright phone's blurb placement (App/Phone/BlurbPlacement.swift), checked on a regular iPhone held
//          upright (402 x 874 points, the table area between a title row at about 106 and a strip at about 760). Each
//          case asserts the plan's rules (plans/22-Nov-2026-phone-ui-plan.md, Part 3 "Placement"): an anchored blurb is
//          above or below its anchor and centred on its x where the margins allow, never over the keep-clear rectangle,
//          never above the table area's top (the title row or docked blurbs) nor below its bottom (the strip), inside
//          the 16-point margin, steady (the same answer for the same beat, keeping the side it was given while it fits),
//          and nil when neither side has room; docked blurbs stack top down in order, 6 apart.
// SRP/DRY check: Pass - no placement logic here; the numbers are the plan's phone measurements.
@testable import Breakdown
import CoreGraphics
import XCTest

final class BlurbPlacementTests: XCTestCase {
    /// The table area on a regular iPhone held upright: under the title row, above the strip.
    private let area = CGRect(x: 0, y: 106, width: 402, height: 654)
    private let size = CGSize(width: 240, height: 70)

    /// Every anchored rule the plan states, for one result.
    private func assertRules(_ placed: BlurbPlacement.Anchored, anchor: CGPoint, keepClear: CGRect?,
                             file: StaticString = #filePath, line: UInt = #line) {
        let f = placed.frame
        XCTAssertGreaterThanOrEqual(f.minY, area.minY, "under the title row", file: file, line: line)
        XCTAssertLessThanOrEqual(f.maxY, area.maxY, "under the strip", file: file, line: line)
        XCTAssertGreaterThanOrEqual(f.minX, area.minX + BlurbPlacement.margin - 0.001, "left margin", file: file, line: line)
        XCTAssertLessThanOrEqual(f.maxX, area.maxX - BlurbPlacement.margin + 0.001, "right margin", file: file, line: line)
        if let keepClear { XCTAssertFalse(f.intersects(keepClear), "over the keep-clear rectangle", file: file, line: line) }
        switch placed.side {
        case .below: XCTAssertGreaterThan(f.minY, anchor.y, "below its anchor", file: file, line: line)
        case .above: XCTAssertLessThan(f.maxY, anchor.y, "above its anchor", file: file, line: line)
        }
        // Never beside: the anchor's height is outside the blurb's.
        XCTAssertFalse(f.minY <= anchor.y && anchor.y <= f.maxY, "beside its anchor", file: file, line: line)
    }

    func testCentredBelowTheMomentAtItsFramedHeight() throws {
        // The moment framed at 35 per cent of the table area's height, in the middle.
        let anchor = CGPoint(x: 201, y: area.minY + area.height * 0.35)
        let ring = CGRect(x: 181, y: anchor.y - 20, width: 40, height: 40)
        let placed = try XCTUnwrap(BlurbPlacement.anchored(anchor: anchor, size: size, tableArea: area, keepClear: ring))
        XCTAssertEqual(placed.side, .below)
        XCTAssertEqual(placed.frame.midX, anchor.x, accuracy: 0.001, "centred on the anchor")
        XCTAssertEqual(placed.frame.minY, ring.maxY + BlurbPlacement.gap, accuracy: 0.001, "just clear of the ring")
        assertRules(placed, anchor: anchor, keepClear: ring)
        // The leader runs from the anchor to the blurb's near edge.
        XCTAssertEqual(placed.leaderFrom, anchor)
        XCTAssertEqual(placed.leaderTo.y, placed.frame.minY, accuracy: 0.001)
    }

    func testGoesAboveWhenBelowHasNoRoom() throws {
        let anchor = CGPoint(x: 201, y: area.maxY - 40)
        let placed = try XCTUnwrap(BlurbPlacement.anchored(anchor: anchor, size: size, tableArea: area))
        XCTAssertEqual(placed.side, .above)
        XCTAssertEqual(placed.leaderTo.y, placed.frame.maxY, accuracy: 0.001)
        assertRules(placed, anchor: anchor, keepClear: nil)
    }

    func testGoesBelowWhenAboveWouldReachTheTitleRow() throws {
        let anchor = CGPoint(x: 201, y: area.minY + 30)
        let placed = try XCTUnwrap(BlurbPlacement.anchored(anchor: anchor, size: size, tableArea: area, preferred: .above))
        XCTAssertEqual(placed.side, .below)
        assertRules(placed, anchor: anchor, keepClear: nil)
    }

    func testKeptInsideTheMarginsNearAnEdge() throws {
        for x in [CGFloat(0), 10, 60, 342, 395, 402] {
            let anchor = CGPoint(x: x, y: 380)
            let placed = try XCTUnwrap(BlurbPlacement.anchored(anchor: anchor, size: size, tableArea: area))
            assertRules(placed, anchor: anchor, keepClear: nil)
            // The leader still meets a straight edge, as near the anchor's x as the blurb allows.
            XCTAssertGreaterThanOrEqual(placed.leaderTo.x, placed.frame.minX + BlurbPlacement.leaderInset - 0.001)
            XCTAssertLessThanOrEqual(placed.leaderTo.x, placed.frame.maxX - BlurbPlacement.leaderInset + 0.001)
        }
    }

    func testNeverOverATallKeepClearRectangle() throws {
        // A keep-clear rectangle reaching well below the anchor (a moment with a long Lens drawing under it).
        let anchor = CGPoint(x: 201, y: 300)
        let keep = CGRect(x: 150, y: 260, width: 100, height: 200)
        let placed = try XCTUnwrap(BlurbPlacement.anchored(anchor: anchor, size: size, tableArea: area, keepClear: keep))
        assertRules(placed, anchor: anchor, keepClear: keep)
    }

    func testKeepClearToTheSideDoesNotPushTheBlurb() throws {
        // A keep-clear rectangle that shares no width with the blurb leaves it right by its anchor.
        let anchor = CGPoint(x: 140, y: 300)
        let keep = CGRect(x: 300, y: 200, width: 60, height: 300)
        let placed = try XCTUnwrap(BlurbPlacement.anchored(anchor: anchor, size: CGSize(width: 200, height: 60),
                                                           tableArea: area, keepClear: keep))
        XCTAssertEqual(placed.frame.minY, anchor.y + BlurbPlacement.gap, accuracy: 0.001)
        assertRules(placed, anchor: anchor, keepClear: keep)
    }

    func testNilWhenNeitherSideHasRoom() {
        // A short table area (the largest text sizes): the blurb fits neither above nor below.
        let short = CGRect(x: 0, y: 300, width: 402, height: 120)
        let anchor = CGPoint(x: 201, y: 360)
        XCTAssertNil(BlurbPlacement.anchored(anchor: anchor, size: size, tableArea: short))
        // A keep-clear rectangle filling the area leaves no room either.
        XCTAssertNil(BlurbPlacement.anchored(anchor: CGPoint(x: 201, y: 400), size: size, tableArea: area,
                                             keepClear: area.insetBy(dx: 0, dy: 10)))
    }

    func testSteadyThroughABeat() throws {
        // Same beat, same answer; and the side it was given is kept while it fits, though the other side fits too.
        let anchor = CGPoint(x: 220, y: 430)
        let ring = CGRect(x: 200, y: 410, width: 40, height: 40)
        let first = try XCTUnwrap(BlurbPlacement.anchored(anchor: anchor, size: size, tableArea: area, keepClear: ring,
                                                          preferred: .above))
        XCTAssertEqual(first.side, .above)
        for _ in 0..<5 {
            XCTAssertEqual(BlurbPlacement.anchored(anchor: anchor, size: size, tableArea: area, keepClear: ring,
                                                   preferred: first.side), first)
        }
    }

    func testDockedStackInOrderSixApart() {
        let sizes = [CGSize(width: 170, height: 26), CGSize(width: 260, height: 58), CGSize(width: 200, height: 40)]
        let frames = BlurbPlacement.dockedFrames(sizes: sizes, top: 112, area: area)
        XCTAssertEqual(frames.count, 3)
        XCTAssertEqual(frames[0].minY, 112, accuracy: 0.001)
        for i in 1..<frames.count {
            XCTAssertEqual(frames[i].minY - frames[i - 1].maxY, BlurbPlacement.dockSpacing, accuracy: 0.001, "6 apart")
        }
        for (f, s) in zip(frames, sizes) {
            XCTAssertEqual(f.size, s)
            XCTAssertEqual(f.minX, area.minX + BlurbPlacement.margin, accuracy: 0.001)
        }
        XCTAssertEqual(BlurbPlacement.dockedBottom(sizes: sizes, top: 112), frames[2].maxY, accuracy: 0.001)
        XCTAssertEqual(BlurbPlacement.dockedBottom(sizes: [], top: 112), 112, accuracy: 0.001, "nothing docked")
    }
}
