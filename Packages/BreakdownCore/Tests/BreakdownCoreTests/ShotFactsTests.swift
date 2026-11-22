// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: One hand-built shot per fact ShotFacts reports (plans/21-Nov-2026-rules-games-plan.md package 1 step 3 and
//          plans/21-Nov-2026-other-tables-games-plan.md package 1 step 1). Each test writes a small recording by hand
//          (balls standing still, or jumping from a start spot to an end spot at a chosen time, plus the events) so
//          the expected answer can be read straight off the test with no solver involved: first contact and its time,
//          a tie broken in favour of a legal ball, pockets in order, the cue ball pocketed or off the table, object
//          balls off the table, a rail (or a pocket) after contact, a frozen ball that does not count, object balls
//          reaching a rail, resting places, pins in order, posts, bed-hole drops, rim skips, and another cue ball.
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 rules-lens: the three head-line readings - where each
//          first-touched ball started, the cue ball's farthest point along the table before its first contact, worked
//          out exactly from a moving segment including a turn-back inside it, and the table's length.)
// SRP/DRY check: Pass - checked PhysicsTests, PocketTests, JumpTests and TableFeatureTests: those solve shots and check
//          the physics; these check only the reading of a recording, on recordings built by hand.
import BreakdownLensModel
import BreakdownTimeline
import XCTest

final class ShotFactsTests: XCTestCase {
    private let r = 0.028575
    private let off = ShotFacts.offTable

    // MARK: Building recordings by hand

    /// A ball standing still at `p` from `t0` to `t1`.
    private func still(_ p: Vec2, from t0: Double = 0, to t1: Double = .infinity) -> BallSegment {
        BallSegment(t0: t0, t1: t1, phase: .stationary, position0: p, velocity0: .zero, acceleration: .zero,
                    omega0: .zero, alphaXY: .zero, spinDecay: 9, radius: r, orientation0: .identity)
    }

    /// A ball at `start` that is at `end` from time `t` on (the facts only ever look up where a ball is, so a jump
    /// between two still segments is enough).
    private func moves(_ start: Vec2, to end: Vec2, at t: Double = 0.3) -> [BallSegment] {
        [still(start, to: t), still(end, from: t)]
    }

    private func ball(_ b: Int) -> ImpactBall {
        ImpactBall(ball: b, velocityBefore: Vec2(1, 0), velocityAfter: Vec2(0.5, 0), omegaBefore: .zero,
                   omegaAfter: .zero, translationalBefore: 0.085, rotationalBefore: 0, translationalAfter: 0.02,
                   rotationalAfter: 0)
    }

    private func contact(_ t: Double, _ a: Int, _ b: Int) -> LensEvent {
        LensEvent(time: t, kind: .ballBall, point: .zero, normal: Vec2(1, 0), balls: [ball(a), ball(b)])
    }

    private func cushion(_ t: Double, _ b: Int, edge: CushionEdge = .rail, feature: Int = -1) -> LensEvent {
        LensEvent(time: t, kind: .cushion, point: .zero, normal: Vec2(0, 1), balls: [ball(b)], edge: edge, feature: feature)
    }

    private func drop(_ t: Double, _ b: Int, pocket k: Int) -> LensEvent {
        LensEvent(time: t, kind: .pocket, point: .zero, normal: Vec2(1, 0), balls: [ball(b)], pocket: k)
    }

    private func flewOff(_ t: Double, _ b: Int) -> LensEvent {
        LensEvent(time: t, kind: .phaseTransition, point: .zero, normal: Vec2(0, -1), balls: [ball(b)],
                  phaseFrom: .airborne, phaseTo: .stationary, flight: .offTable)
    }

    private func pinDown(_ t: Double, _ b: Int, pin: Int) -> LensEvent {
        LensEvent(time: t, kind: .pinDown, point: .zero, normal: Vec2(1, 0), balls: [ball(b)], feature: pin)
    }

    /// A pool table (no pins or holes) unless asked; three pins and two bed holes when `features` is set.
    private func spec(features: Bool = false) -> TableSpec {
        TableSpec(length: 2.54, width: 1.27, ballRadius: r, pockets: [], pocketCaptureRadius: [],
                  pins: features ? [Pin(center: Vec2(1.0, 0.6), radius: 0.01), Pin(center: Vec2(1.2, 0.6), radius: 0.01),
                                    Pin(center: Vec2(1.4, 0.6), radius: 0.01)] : [],
                  bedHoles: features ? [BedHole(center: Vec2(2.0, 0.4), radius: 0.03, captureRadius: 0.02),
                                        BedHole(center: Vec2(2.0, 0.8), radius: 0.03, captureRadius: 0.02)] : [])
    }

    /// The recording: segments per ball, the events sorted into time order, the given pocket times.
    private func recording(_ segments: [[BallSegment]], _ events: [LensEvent], pocketTime: [Int: Double] = [:],
                           features: Bool = false) -> Timeline {
        let sorted = events.sorted { $0.time < $1.time }
        let times = (0..<segments.count).map { pocketTime[$0] }
        return Timeline(table: spec(features: features), seed: 1, parameterHash: 1, segments: segments, events: sorted,
                        pocketTime: times, duration: sorted.last?.time ?? 0)
    }

    /// Four balls: the cue ball and balls 1 to 3 at spread-out spots, all standing still unless replaced.
    private let start = [Vec2(0.6, 0.6), Vec2(1.5, 0.6), Vec2(1.7, 0.3), Vec2(1.9, 0.9)]
    private func stillBalls() -> [[BallSegment]] { start.map { [still($0)] } }

    // MARK: First contact

    func testFirstContactAndItsTime() {
        var segs = stillBalls()
        segs[0] = moves(start[0], to: Vec2(1.44, 0.6))
        segs[2] = moves(start[2], to: Vec2(2.0, 0.3), at: 0.5)
        let tl = recording(segs, [contact(0.4, 0, 2), contact(0.6, 2, 1)])
        let f = ShotFacts(timeline: tl, start: start)
        XCTAssertEqual(f.firstContact, ShotFacts.Contact(ball: 2, time: 0.4))
        XCTAssertEqual(f.firstContactTime, 0.4)
        XCTAssertEqual(f.firstContactBalls, [2])
    }

    func testTieWithinOneInstantCountsTheLegalBallFirst() {
        // Two contacts 5 microseconds apart (inside sameInstant): ball 1 first by the clock, ball 3 legal.
        let tl = recording(stillBalls(), [contact(0.4, 0, 1), contact(0.4 + 5e-6, 0, 3)])
        let f = ShotFacts(timeline: tl, start: start)
        XCTAssertEqual(f.firstContactBalls, [1, 3])
        XCTAssertEqual(f.firstContact?.ball, 1)
        XCTAssertEqual(f.firstContact(preferring: [3])?.ball, 3)
        XCTAssertEqual(f.firstContact(preferring: [3])?.time, 0.4)
        XCTAssertEqual(f.firstContact(preferring: [2])?.ball, 1, "no legal ball in the tie: the first by the clock")
        // Twenty microseconds apart is not a tie.
        let apart = ShotFacts(timeline: recording(stillBalls(), [contact(0.4, 0, 1), contact(0.4 + 2e-5, 0, 3)]),
                              start: start)
        XCTAssertEqual(apart.firstContactBalls, [1])
        XCTAssertEqual(apart.firstContact(preferring: [3])?.ball, 1)
    }

    func testNoContactMeansNoFirstBallAndNoRailAfterContact() {
        var segs = stillBalls()
        segs[0] = moves(start[0], to: Vec2(0.6, 1.24))
        let f = ShotFacts(timeline: recording(segs, [cushion(0.5, 0)]), start: start)
        XCTAssertNil(f.firstContact)
        XCTAssertNil(f.firstContactTime)
        XCTAssertNil(f.firstContact(preferring: [1, 2, 3]))
        XCTAssertFalse(f.railOrPocketAfterContact)
        XCTAssertEqual(f.ballsReachingRail, [])
    }

    // MARK: Pockets

    func testBallsPocketedInOrderWithPocketAndTime() {
        let tl = recording(stillBalls(), [contact(0.3, 0, 1), drop(1.5, 3, pocket: 4), drop(1.0, 1, pocket: 1)],
                           pocketTime: [1: 1.0, 3: 1.5])
        let f = ShotFacts(timeline: tl, start: start)
        XCTAssertEqual(f.pocketed, [ShotFacts.Drop(ball: 1, pocket: 1, time: 1.0), ShotFacts.Drop(ball: 3, pocket: 4, time: 1.5)])
        XCTAssertEqual(f.objectBallsPocketed.map(\.ball), [1, 3])
        XCTAssertEqual(f.pocket(of: 3), 4)
        XCTAssertNil(f.pocket(of: 2))
        XCTAssertFalse(f.cueBallPocketed)
        XCTAssertFalse(f.cueBallScratched)
        XCTAssertEqual(f.holeDrops, [])
    }

    func testCueBallPocketedIsAScratch() {
        let tl = recording(stillBalls(), [contact(0.3, 0, 1), drop(0.9, 0, pocket: 2)], pocketTime: [0: 0.9])
        let f = ShotFacts(timeline: tl, start: start)
        XCTAssertTrue(f.cueBallPocketed)
        XCTAssertFalse(f.cueBallOffTable)
        XCTAssertTrue(f.cueBallScratched)
        XCTAssertEqual(f.objectBallsPocketed, [])
    }

    func testCueBallOffTableIsAScratchButNotAPocket() {
        // The solver sets the pocket time of a ball that flies off the table too; the facts tell the two apart.
        let tl = recording(stillBalls(), [contact(0.3, 0, 1), flewOff(0.7, 0)], pocketTime: [0: 0.7])
        let f = ShotFacts(timeline: tl, start: start)
        XCTAssertFalse(f.cueBallPocketed)
        XCTAssertTrue(f.cueBallOffTable)
        XCTAssertTrue(f.cueBallScratched)
        XCTAssertEqual(f.objectBallsOffTable, [])
    }

    func testObjectBallsOffTable() {
        let tl = recording(stillBalls(), [contact(0.3, 0, 2), flewOff(0.6, 2), flewOff(0.8, 3)],
                           pocketTime: [2: 0.6, 3: 0.8])
        let f = ShotFacts(timeline: tl, start: start)
        XCTAssertEqual(f.objectBallsOffTable, [2, 3])
        XCTAssertFalse(f.cueBallScratched)
        XCTAssertTrue(f.railOrPocketAfterContact, "a ball leaving the table satisfies the rail after contact")
    }

    // MARK: Rails after contact

    func testRailAfterContactNeedsABallThatMoved() {
        var segs = stillBalls()
        segs[2] = moves(start[2], to: Vec2(1.9, r), at: 0.5)
        let moved = ShotFacts(timeline: recording(segs, [contact(0.4, 0, 2), cushion(0.8, 2)]), start: start)
        XCTAssertTrue(moved.railOrPocketAfterContact)
        XCTAssertEqual(moved.ballsReachingRail, [2])
        XCTAssertEqual(moved.objectBallsReachingRail, [2])

        // A ball frozen on the rail that is pushed into it has not reached a rail: it never moved from its start.
        var frozenStart = start
        frozenStart[3] = Vec2(1.9, 1.27 - r)
        let frozen = ShotFacts(timeline: recording(frozenStart.map { [still($0)] }, [contact(0.4, 0, 3), cushion(0.4, 3)]),
                               start: frozenStart)
        XCTAssertFalse(frozen.railOrPocketAfterContact)
        XCTAssertEqual(frozen.ballsReachingRail, [])

        // A rail before the first contact does not count, and a post is not a rail.
        var early = stillBalls()
        early[0] = moves(start[0], to: Vec2(0.6, r), at: 0.1)
        let before = ShotFacts(timeline: recording(early, [cushion(0.2, 0), contact(0.4, 0, 1),
                                                           cushion(0.6, 0, edge: .post, feature: 0)]), start: start)
        XCTAssertFalse(before.railOrPocketAfterContact)
    }

    func testAJawHitIsARailAfterContactButNotABallDrivenToARail() {
        var segs = stillBalls()
        segs[1] = moves(start[1], to: Vec2(2.45, 0.05), at: 0.5)
        let f = ShotFacts(timeline: recording(segs, [contact(0.4, 0, 1), cushion(0.8, 1, edge: .jaw)]), start: start)
        XCTAssertTrue(f.railOrPocketAfterContact, "the judge has always counted a jaw for rail after contact")
        XCTAssertEqual(f.ballsReachingRail, [], "a ball rattling in a jaw was not driven to a rail")
        XCTAssertEqual(f.objectBallsReachingRail, [])
    }

    func testPocketAfterContactSatisfiesTheRule() {
        let f = ShotFacts(timeline: recording(stillBalls(), [contact(0.4, 0, 1), drop(0.9, 1, pocket: 3)],
                                              pocketTime: [1: 0.9]), start: start)
        XCTAssertTrue(f.railOrPocketAfterContact)
        XCTAssertEqual(f.ballsReachingRail, [], "a pocket is not a rail")
    }

    func testObjectBallsReachingARailAreCountedOnce() {
        // A break-like shot: three object balls and the cue ball reach rails, ball 1 twice.
        var segs = stillBalls()
        segs[0] = moves(start[0], to: Vec2(0.9, r), at: 0.5)
        segs[1] = moves(start[1], to: Vec2(2.54 - r, 0.6), at: 0.5)
        segs[2] = moves(start[2], to: Vec2(1.7, r), at: 0.5)
        segs[3] = moves(start[3], to: Vec2(1.9, 1.27 - r), at: 0.5)
        let events = [contact(0.2, 0, 1), contact(0.25, 1, 2), contact(0.27, 1, 3),
                      cushion(0.6, 1), cushion(0.7, 2), cushion(0.8, 0), cushion(0.9, 1), cushion(1.0, 3)]
        let f = ShotFacts(timeline: recording(segs, events), start: start)
        XCTAssertEqual(f.ballsReachingRail, [1, 2, 0, 3])
        XCTAssertEqual(f.objectBallsReachingRail, [1, 2, 3])
    }

    // MARK: Resting places

    func testRestingPlaces() {
        var segs = stillBalls()
        segs[2] = moves(start[2], to: Vec2(2.2, 0.5), at: 0.5)
        var withGone = start
        withGone.append(off)                 // ball 4 was never on the table
        segs.append([still(off)])
        let tl = recording(segs, [contact(0.4, 0, 2), drop(1.2, 3, pocket: 5)], pocketTime: [3: 1.2])
        let f = ShotFacts(timeline: tl, start: withGone)
        XCTAssertEqual(f.resting, [start[0], start[1], Vec2(2.2, 0.5), off, off])
        XCTAssertFalse(ShotFacts.isOnTable(f.resting[3]))
        XCTAssertTrue(ShotFacts.isOnTable(f.resting[2]))
    }

    // MARK: Other tables

    func testPinsDownInOrderWithTheBallThatDidIt() {
        let tl = recording(stillBalls(), [contact(0.2, 0, 1), pinDown(0.5, 1, pin: 2), pinDown(0.7, 0, pin: 0)],
                           features: true)
        let f = ShotFacts(timeline: tl, start: start)
        XCTAssertEqual(f.pinsDown, [ShotFacts.PinKnock(pin: 2, ball: 1, time: 0.5, order: 0),
                                    ShotFacts.PinKnock(pin: 0, ball: 0, time: 0.7, order: 1)])
    }

    func testPostsTouched() {
        let tl = recording(stillBalls(), [cushion(0.3, 0, edge: .post, feature: 1), contact(0.5, 0, 2),
                                          cushion(0.8, 2, edge: .post, feature: 0)], features: true)
        let f = ShotFacts(timeline: tl, start: start)
        XCTAssertEqual(f.postsTouched, [ShotFacts.PostTouch(post: 1, ball: 0, time: 0.3),
                                        ShotFacts.PostTouch(post: 0, ball: 2, time: 0.8)])
    }

    func testBedHoleDropsCarryTheirHoleNumber() {
        // Pocket 7 is bed hole 1 (edge pockets are 0 to 5, bed hole j is 6 + j).
        let tl = recording(stillBalls(), [contact(0.2, 0, 3), drop(0.9, 3, pocket: 7)], pocketTime: [3: 0.9],
                           features: true)
        let f = ShotFacts(timeline: tl, start: start)
        XCTAssertEqual(f.holeDrops, [ShotFacts.HoleDrop(ball: 3, hole: 1, time: 0.9)])
        XCTAssertEqual(f.pocketed.first?.isBedHole, true)
    }

    func testRimSkipsAreListedButNotPocketed() {
        var skip = LensEvent(time: 0.6, kind: .rimSkip, point: Vec2(2.0, 0.4), normal: Vec2(1, 0), balls: [ball(2)],
                             pocket: 6)
        skip.entry = PocketEntry(speed: 2.5, sine: 0.6, cosine: 0.8)
        let tl = recording(stillBalls(), [contact(0.2, 0, 2), skip], features: true)
        let f = ShotFacts(timeline: tl, start: start)
        XCTAssertEqual(f.rimSkips, [ShotFacts.Drop(ball: 2, pocket: 6, time: 0.6,
                                                   entry: PocketEntry(speed: 2.5, sine: 0.6, cosine: 0.8))])
        XCTAssertEqual(f.pocketed, [])
        XCTAssertEqual(f.holeDrops, [])
    }

    func testAnotherCueBall() {
        // Ball 1 is the striker (five-pin, bumper pool): its first contact counts, and ball 0 is an object ball here.
        let tl = recording(stillBalls(), [contact(0.2, 1, 3), contact(0.5, 3, 0), flewOff(0.9, 0)], pocketTime: [0: 0.9])
        let f = ShotFacts(timeline: tl, start: start, cueBall: 1)
        XCTAssertEqual(f.cueBall, 1)
        XCTAssertEqual(f.firstContact, ShotFacts.Contact(ball: 3, time: 0.2))
        XCTAssertFalse(f.cueBallScratched)
        XCTAssertEqual(f.objectBallsOffTable, [0])
    }
    // MARK: The head-line readings (0.7.5)

    /// A ball moving from `p` at velocity `v` with constant acceleration `a` from `t0` to `t1`.
    private func sliding(_ p: Vec2, _ v: Vec2, _ a: Vec2, from t0: Double, to t1: Double) -> BallSegment {
        BallSegment(t0: t0, t1: t1, phase: .sliding, position0: p, velocity0: v, acceleration: a, omega0: .zero,
                    alphaXY: .zero, spinDecay: 9, radius: r, orientation0: .identity)
    }

    func testTheCueBallsFarthestPointBeforeItsFirstContact() {
        // The cue ball runs up the table from x 0.6 at 2 m/s while slowing at 4 m/s^2, so its x turns back at 0.5 s,
        // at 0.6 + 2 * 0.5 - 2 * 0.25 = 1.1 m, then comes back down and touches ball 2 at 0.8 s. Its farthest point is
        // the turn inside the segment, not either end (0.6 at the start, 0.92 at the contact).
        var segs = stillBalls()
        segs[0] = [sliding(start[0], Vec2(2, 0), Vec2(-4, 0), from: 0, to: 0.8), still(Vec2(0.92, 0.6), from: 0.8)]
        let f = ShotFacts(timeline: recording(segs, [contact(0.8, 0, 2)]), start: start)
        XCTAssertEqual(f.cueBallFarthestBeforeContact ?? 0, 1.1, accuracy: 1e-12)
        XCTAssertEqual(f.tableLength, 2.54)
        XCTAssertEqual(f.firstContactStarts, [start[2]])
        XCTAssertEqual(f.firstContactStart(of: 2), start[2])
        XCTAssertNil(f.firstContactStart(of: 1), "ball 1 was not touched first")

        // Only the time up to the first contact counts: after it the cue ball may go anywhere.
        var later = stillBalls()
        later[0] = [sliding(start[0], Vec2(1, 0), .zero, from: 0, to: 2), still(Vec2(2.6, 0.6), from: 2)]
        let g = ShotFacts(timeline: recording(later, [contact(0.2, 0, 1)]), start: start)
        XCTAssertEqual(g.cueBallFarthestBeforeContact ?? 0, 0.8, accuracy: 1e-12)
    }

    func testTheHeadLineReadingsWithNoContactAndInATie() {
        // Nothing touched: there is no "before the first contact", and no starts.
        let none = ShotFacts(timeline: recording(stillBalls(), []), start: start)
        XCTAssertNil(none.cueBallFarthestBeforeContact)
        XCTAssertEqual(none.firstContactStarts, [])
        // A tie: both balls touched inside sameInstant, each with its own start, in event order.
        let tl = recording(stillBalls(), [contact(0.2, 0, 3), contact(0.2 + 5e-6, 0, 1)])
        let tie = ShotFacts(timeline: tl, start: start)
        XCTAssertEqual(tie.firstContactBalls, [3, 1])
        XCTAssertEqual(tie.firstContactStarts, [start[3], start[1]])
        XCTAssertEqual(tie.cueBallFarthestBeforeContact, start[0].x, "a cue ball standing still never moved along")
    }
}
