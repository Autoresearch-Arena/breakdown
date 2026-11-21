// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: Checks the rules work's physics-side helpers (plans/21-Nov-2026-rules-games-plan.md packages 2 to 4):
//            - Rack.swift: the fifteen-ball triangle and its break come out exactly as before, compared bit for bit
//              with a copy of the code as it stood before the nine-ball work (todayTriangle below, frozen on purpose:
//              never edit it to make a test pass); the nine-ball diamond has the 1 at the front on the foot spot, the
//              9 in the middle, the 2 to 8 in the other places with the seed choosing the order, the 10 to 15 off the
//              table, no two balls overlapping, the same layout for the same seed; its break aims at the 1.
//            - NextShot.swift: where a lifted cue ball may go (CueBallSpot: on the bed, clear of pockets, posts,
//              pins, holes and balls, behind the head line when asked, and the order the reasons are checked in);
//              spotting a ball on the foot spot or the nearest free place straight behind it (or in front when the
//              line behind is full); and shot(from:...) handing the struck ball's index to the strike.
// SRP/DRY check: Pass - checked PhysicsTests (which solves the showpiece break; this does not solve anything) and
//          TableFeatureTests (the features' physics); these test layouts and legality only.
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import XCTest

final class RackAndPlacementTests: XCTestCase {
    private let p = PoolParameters()
    private var r: Double { p.ballRadius }

    // MARK: The triangle is unchanged

    /// Rack.positions exactly as it was written on 3-November-2026, before the nine-ball diamond was added. Frozen.
    private func todayTriangle(parameters p: PoolParameters, seed: UInt64) -> [Vec2] {
        let layout: [[Int]] = [[1], [9, 2], [10, 8, 3], [11, 7, 14, 4], [5, 13, 15, 6, 12]]
        var rng = SeededGenerator(seed: seed)
        var out = [Vec2](repeating: .zero, count: 16)
        let r = p.ballRadius
        out[0] = Vec2(p.tableLength * 0.25, p.tableWidth * 0.5)
        let footX = p.tableLength * 0.75
        let rowStep = 3.0.squareRoot() * (r + p.rackGap * 0.5)
        let side = 2 * r + p.rackGap
        for (row, numbers) in layout.enumerated() {
            for (k, number) in numbers.enumerated() {
                let jx = rng.signedUnit() * p.rackJitter
                let jy = rng.signedUnit() * p.rackJitter
                let offset = (Double(k) - Double(row) * 0.5) * side
                out[number] = Vec2(footX + Double(row) * rowStep + jx, p.tableWidth * 0.5 + offset + jy)
            }
        }
        return out
    }

    func testTheTriangleAndItsBreakAreExactlyAsBefore() {
        for seed: UInt64 in [0, 1, 3, 7, 42, 2026, 0xDEAD_BEEF] {
            XCTAssertEqual(Rack.positions(parameters: p, seed: seed), todayTriangle(parameters: p, seed: seed),
                           "seed \(seed)")
            let b = Rack.breakShot(parameters: p, seed: seed, aimOffset: 0.004, speed: 9, tipUp: -0.005, tipSide: 0.002)
            let old = todayTriangle(parameters: p, seed: seed)
            XCTAssertEqual(b.positions, old)
            // breakShot normalises the aim and CueStrike normalises it again, so the expected one is too.
            XCTAssertEqual(b.strike.direction, (old[1] + Vec2(0, 0.004) - old[0]).normalized.normalized)
            XCTAssertEqual(b.strike.speed, 9)
            XCTAssertEqual(b.strike.ballIndex, 0)
        }
        XCTAssertEqual(Rack.showpieceBreak().positions, todayTriangle(parameters: p, seed: 3))
    }

    // MARK: The nine-ball diamond

    func testTheDiamond() {
        let rowStep = 3.0.squareRoot() * (r + p.rackGap * 0.5)
        let side = 2 * r + p.rackGap
        let foot = NextShot.footSpot(parameters: p)
        // The seven non-apex, non-centre places, in front-to-back order, and the two fixed ones.
        let rowAndAcross: [(row: Int, across: Double)] = [(0, 0), (1, -0.5), (1, 0.5), (2, -1), (2, 0), (2, 1),
                                                          (3, -0.5), (3, 0.5), (4, 0)]
        let places = rowAndAcross.map { Vec2(foot.x + Double($0.row) * rowStep, foot.y + $0.across * side) }
        let slack = 2 * p.rackJitter * 1.0001   // jitter is below rackJitter per axis, so well inside this

        var orders = Set<[Int]>()
        for seed: UInt64 in [1, 2, 3, 4, 5, 6, 7, 8] {
            let pos = Rack.nineBallPositions(parameters: p, seed: seed)
            XCTAssertEqual(pos.count, 16)
            XCTAssertEqual(pos, Rack.nineBallPositions(parameters: p, seed: seed), "the same seed, the same rack")
            XCTAssertEqual(pos[0], Vec2(p.tableLength * 0.25, p.tableWidth * 0.5), "cue ball on the head spot")
            XCTAssertLessThan((pos[1] - places[0]).length, slack, "the 1 at the front, on the foot spot")
            XCTAssertLessThan((pos[9] - places[4]).length, slack, "the 9 in the middle")
            for b in 10...15 { XCTAssertEqual(pos[b], NextShot.offTable, "ball \(b) parked") }
            // Every ball 1 to 9 sits on its own place of the diamond.
            var used = Set<Int>()
            for b in 1...9 {
                let k = places.indices.min { i, j in (pos[b] - places[i]).length < (pos[b] - places[j]).length }!
                XCTAssertLessThan((pos[b] - places[k]).length, slack, "ball \(b) on a place")
                used.insert(k)
            }
            XCTAssertEqual(used.count, 9)
            // No two balls overlap (centres at least a diameter apart, less the jitter).
            for a in 1...8 {
                for b in (a + 1)...9 { XCTAssertGreaterThan((pos[a] - pos[b]).length, 2 * r) }
            }
            orders.insert((1...9).map { ball in
                places.indices.min { i, j in (pos[ball] - places[i]).length < (pos[ball] - places[j]).length }!
            })
        }
        XCTAssertGreaterThan(orders.count, 1, "the seed changes where the 2 to 8 go")
    }

    func testTheNineBallBreakAimsAtTheOne() {
        let b = Rack.nineBallBreakShot(parameters: p, seed: 5, aimOffset: 0, speed: 10, tipUp: -0.004)
        XCTAssertEqual(b.positions, Rack.nineBallPositions(parameters: p, seed: 5))
        XCTAssertEqual(b.strike.direction, (b.positions[1] - b.positions[0]).normalized.normalized)
        XCTAssertEqual(b.strike.speed, 10)
        XCTAssertEqual(b.strike.tipUp, -0.004)
        XCTAssertEqual(b.seed, 5)
    }

    // MARK: Where a lifted cue ball may go

    /// The cue ball (to be placed) and two object balls in the open.
    private var layout: [Vec2] {
        var out = [Vec2](repeating: NextShot.offTable, count: 16)
        out[0] = Vec2(0.5, 0.5)
        out[1] = Vec2(1.6, 0.6)
        out[2] = Vec2(1.66, 0.6)
        return out
    }

    func testOpenClothIsLegal() {
        XCTAssertEqual(NextShot.placement(of: Vec2(1.0, 0.4), among: layout, behindHeadLine: false, parameters: p),
                       .legal)
        // The cue ball's own old place is ignored, so putting it back where it was is fine.
        XCTAssertEqual(NextShot.placement(of: layout[0], among: layout, behindHeadLine: false, parameters: p), .legal)
    }

    func testOverlappingABallIsNotLegal() {
        XCTAssertEqual(NextShot.placement(of: Vec2(1.6 - 1.5 * r, 0.6), among: layout, behindHeadLine: false,
                                          parameters: p), .overlapsBall(1))
        // Touching exactly (a hair more than a diameter apart) is allowed.
        XCTAssertEqual(NextShot.placement(of: Vec2(1.6 - 2 * r - 1e-6, 0.6), among: layout, behindHeadLine: false,
                                          parameters: p), .legal)
        // Overlapping two balls, the nearer one is named.
        XCTAssertEqual(NextShot.placement(of: Vec2(1.635, 0.62), among: layout, behindHeadLine: false, parameters: p),
                       .overlapsBall(2))
    }

    func testOffTheBedPocketsAndJawsAreNotLegal() {
        let place = { (q: Vec2) in NextShot.placement(of: q, among: self.layout, behindHeadLine: false, parameters: self.p) }
        XCTAssertEqual(place(Vec2(1.0, r * 0.5)), .offBed, "over the cushion")
        XCTAssertEqual(place(Vec2(p.tableLength - r * 0.9, 0.6)), .offBed)
        XCTAssertEqual(place(Vec2(1.0, r)), .legal, "frozen to the rail is on the bed")
        XCTAssertEqual(place(Vec2(r + 0.01, r + 0.01)), .offBed, "in a corner pocket's mouth")
        XCTAssertEqual(place(Vec2(p.tableLength * 0.5, r + 0.005)), .offBed, "in a side pocket's mouth")
        XCTAssertEqual(place(Vec2(p.tableLength * 0.5 + 0.1, r)), .legal, "beside the side pocket, on the rail")
    }

    func testBehindTheHeadLine() {
        let head = NextShot.headLineX(parameters: p)
        XCTAssertEqual(head, p.tableLength * 0.25)
        XCTAssertEqual(NextShot.placement(of: Vec2(head, 0.6), among: layout, behindHeadLine: true, parameters: p),
                       .legal, "on the line is behind it")
        XCTAssertEqual(NextShot.placement(of: Vec2(head + 0.01, 0.6), among: layout, behindHeadLine: true,
                                          parameters: p), .outsideHeadArea)
        XCTAssertEqual(NextShot.placement(of: Vec2(head + 0.01, 0.6), among: layout, behindHeadLine: false,
                                          parameters: p), .legal)
        // The bed comes before the head line: a spot off the bed past the line is off the bed.
        XCTAssertEqual(NextShot.placement(of: Vec2(2.0, 0.001), among: layout, behindHeadLine: true, parameters: p),
                       .offBed)
    }

    func testPostsPinsAndHolesAreNotLegal() {
        var t = PoolParameters()
        t.posts = [Post(center: Vec2(1.0, 0.3), radius: 0.02)]
        t.pins = [Pin(center: Vec2(1.0, 0.6), radius: 0.008)]
        t.bedHoles = [BedHole(center: Vec2(1.0, 0.9), radius: 0.03, captureRadius: 0.02)]
        let place = { (q: Vec2) in NextShot.placement(of: q, among: self.layout, behindHeadLine: false, parameters: t) }
        XCTAssertEqual(place(Vec2(1.0 + r + 0.019, 0.3)), .onFeature, "against the post")
        XCTAssertEqual(place(Vec2(1.0 + r + 0.021, 0.3)), .legal)
        XCTAssertEqual(place(Vec2(1.0, 0.6 + r + 0.007)), .onFeature, "against the pin")
        XCTAssertEqual(place(Vec2(1.0 + r + 0.029, 0.9)), .onFeature, "over the hole's edge")
        XCTAssertEqual(place(Vec2(1.0 + r + 0.031, 0.9)), .legal)
        // A feature comes before a ball: a spot on a post that also overlaps a ball names the post.
        var crowded = layout
        crowded[3] = Vec2(1.0 + 0.03, 0.3)
        XCTAssertEqual(NextShot.placement(of: Vec2(1.0 + 0.04, 0.3), among: crowded, behindHeadLine: false,
                                          parameters: t), .onFeature)
    }

    // MARK: Spotting a ball

    func testSpotOnAFreeFootSpot() {
        XCTAssertEqual(NextShot.spot(8, among: layout, parameters: p), NextShot.footSpot(parameters: p))
        XCTAssertEqual(NextShot.footSpot(parameters: p), Vec2(p.tableLength * 0.75, p.tableWidth * 0.5))
    }

    func testSpotBehindABallOnTheFootSpot() {
        let foot = NextShot.footSpot(parameters: p)
        var pos = layout
        pos[3] = foot
        let s = NextShot.spot(9, among: pos, parameters: p)
        XCTAssertEqual(s.y, foot.y)
        XCTAssertGreaterThan(s.x, foot.x, "straight behind the spot, toward the foot rail")
        XCTAssertEqual(s.x - foot.x, 2 * r + p.rackGap, accuracy: 1e-12, "frozen to it, with the rack's gap")
        XCTAssertEqual(NextShot.placement(of: s, cueBall: 9, among: pos, behindHeadLine: false, parameters: p), .legal)

        // A ball a little off the line behind the first: the spot goes past both, as near as it can.
        pos[4] = Vec2(foot.x + 2 * r + 0.01, foot.y + r)
        let s2 = NextShot.spot(9, among: pos, parameters: p)
        let dy = r
        let expected = pos[4].x + ((2 * r + p.rackGap) * (2 * r + p.rackGap) - dy * dy).squareRoot()
        XCTAssertEqual(s2.x, expected, accuracy: 1e-12)
        XCTAssertEqual(NextShot.placement(of: s2, cueBall: 9, among: pos, behindHeadLine: false, parameters: p), .legal)
    }

    func testSpotInFrontWhenTheLineBehindIsFull() {
        let foot = NextShot.footSpot(parameters: p)
        var pos = [Vec2](repeating: NextShot.offTable, count: 16)
        pos[0] = Vec2(0.5, 0.5)
        // Balls frozen along the centre line from the foot spot to the foot rail.
        var x = foot.x, b = 1
        while x <= p.tableLength - r, b < 16 {
            pos[b] = Vec2(x, foot.y); x += 2 * r + 1e-4; b += 1
        }
        XCTAssertLessThan(b, 16, "the line fits in the balls available")
        let s = NextShot.spot(15, among: pos, parameters: p)
        XCTAssertLessThan(s.x, foot.x, "in front of the spot")
        XCTAssertEqual(foot.x - s.x, 2 * r + p.rackGap, accuracy: 1e-12)
    }

    // MARK: The struck ball

    func testShotPassesTheStruckBall() {
        let s = NextShot.shot(from: layout, direction: Vec2(1, 0), speed: 2, tipUp: 0, tipSide: 0, seed: 1,
                              ballIndex: 2)
        XCTAssertEqual(s.strike.ballIndex, 2)
        XCTAssertEqual(NextShot.shot(from: layout, direction: Vec2(1, 0), speed: 2, tipUp: 0, tipSide: 0, seed: 1)
                        .strike.ballIndex, 0)
    }
}
