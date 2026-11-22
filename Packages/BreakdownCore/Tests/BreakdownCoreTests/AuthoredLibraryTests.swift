// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The authored answers library (BreakdownAuthored; bug plan after 0.6.6, item 38) and the surfaces it holds
//          (item 27), checked as data: ids are unique; every authored stroke keeps its tip inside the miscue limit; every
//          window the judges divide by is above zero; a raised-cue lesson's elevation is exactly the sine of an angle the
//          cue-angle control offers, inside its own band; every escape's call names a pocket and its rail check holds
//          its own rail count. The two real cloths sit either side of the standard one in every number their words name
//          (tournament slicker, faster and livelier; dive-bar felt grabbier, slower and deader), and what a ball keeps
//          off a rail (PoolSolver.railRebound) orders them the same way. Whether each authored shot is still made is
//          BreakProbe's "verify" (the upload gate) and the app's judge tests; this file checks what can be checked without
//          a solve, plus the rail rebound.
// SRP/DRY check: Pass - data checks only; nothing here re-states an authored number.
import BreakdownAuthored
import BreakdownLensModel
@testable import BreakdownPhysics
import BreakdownRules
import Foundation
import XCTest

final class AuthoredLibraryTests: XCTestCase {
    private let grip = PoolParameters().miscueOffsetLimit

    private func inGrip(_ s: AuthoredStrike, _ what: String) {
        XCTAssertLessThanOrEqual((s.tipUp * s.tipUp + s.tipSide * s.tipSide).squareRoot(), grip + 1e-12,
                                 "\(what): the tip is past the miscue limit")
    }

    private func positive(_ w: AuthoredWindow, _ what: String) {
        XCTAssertGreaterThan(w.aim, 0, what)
        XCTAssertGreaterThan(w.power, 0, what)
        XCTAssertGreaterThan(w.tipUp, 0, what)
        XCTAssertGreaterThanOrEqual(w.tipSide, 0, what)
    }

    func testIdsAreUnique() {
        XCTAssertEqual(Set(AuthoredTricks.all.map(\.id)).count, AuthoredTricks.all.count)
        XCTAssertEqual(Set(AuthoredLessons.all.map(\.id)).count, AuthoredLessons.all.count)
        XCTAssertEqual(Set(AuthoredEscapes.all.map(\.id)).count, AuthoredEscapes.all.count)
        for s in AuthoredEscapes.all {
            XCTAssertEqual(Set(s.escapes.map(\.id)).count, s.escapes.count, s.id)
            XCTAssertFalse(s.escapes.isEmpty, s.id)
        }
        XCTAssertEqual(AuthoredLessons.all.map(\.number), Array(1...AuthoredLessons.all.count))
        XCTAssertEqual(AuthoredEscapes.all.map(\.number), Array(1...AuthoredEscapes.all.count))
    }

    func testTrickShotsAreWellFormed() {
        for t in AuthoredTricks.all {
            XCTAssertEqual(t.layout.count, 16, t.id)
            XCTAssertTrue(NextShot.isOnTable(t.layout[0]), "\(t.id): no cue ball")
            inGrip(t.solution, t.id)
            positive(t.window, t.id)
            XCTAssertTrue((1...3).contains(t.difficulty), t.id)
        }
    }

    func testLessonsAreWellFormed() {
        let offered = [0, 5, 10, 15, 20, 25, 30, 40, 50, 60, 70, 80]   // the cue-angle control's angles
        for l in AuthoredLessons.all {
            inGrip(l.reference, l.id)
            positive(l.window, l.id)
            if let angle = l.cueAngle, let band = l.cueAngles {
                XCTAssertTrue(offered.contains(angle), "\(l.id): \(angle) degrees is not an offered angle")
                XCTAssertTrue(band.contains(angle), "\(l.id): its angle is outside its own band")
                XCTAssertEqual(l.reference.elevation, AuthoredLessons.sine(forAngle: angle), accuracy: 0,
                               "\(l.id): the elevation must be exactly the control's sine")
            } else {
                XCTAssertNil(l.cueAngle, l.id)
                XCTAssertNil(l.cueAngles, l.id)
                XCTAssertEqual(l.reference.elevation, 0, "\(l.id): a level-cue lesson raises the cue")
            }
        }
        let e = AuthoredLessons.stopExercise
        inGrip(e.reference, "stop exercise")
        positive(e.window, "stop exercise")
        // The exercise keeps the stop lesson's line, aim and power; only the tip height may differ.
        XCTAssertEqual(e.reference.aim, AuthoredLessons.stop.reference.aim)
        XCTAssertEqual(e.reference.power, AuthoredLessons.stop.reference.power)
        XCTAssertEqual(e.layout[3], AuthoredLessons.stop.layout[3])
    }

    func testEscapesAreWellFormed() {
        for s in AuthoredEscapes.all {
            let lay = s.layout
            XCTAssertTrue(NextShot.isOnTable(lay[0]) && NextShot.isOnTable(lay[8]), s.id)
            for e in s.escapes {
                inGrip(e.strike, "\(s.id) \(e.id)")
                XCTAssertTrue((1...5).contains(e.rating), "\(s.id) \(e.id)")
                switch e.call {
                case .ball(let b, _): XCTAssertTrue(NextShot.isOnTable(lay[b]), "\(s.id) \(e.id): calls a ball not on the table")
                case .safety: XCTAssertEqual(e.check, .touch, "\(s.id) \(e.id): a safety is checked as a touch")
                }
                if e.check == .kick { XCTAssertTrue(e.railCheck.contains(e.rails), "\(s.id) \(e.id)") }
                if e.strike.elevation > 0 { XCTAssertTrue([.jump, .curve].contains(e.check), "\(s.id) \(e.id)") }
            }
        }
    }

    // Item 27: each real cloth's words hold against the standard cloth's numbers.
    func testRealClothsSitEitherSideOfTheStandard() {
        let std = TableSurface.cloth.parameters, tour = TableSurface.tournament.parameters, bar = TableSurface.diveBar.parameters
        XCTAssertLessThan(tour.slidingFriction, std.slidingFriction, "tournament cloth is slicker")
        XCTAssertLessThan(tour.rollingResistance, std.rollingResistance, "tournament cloth is faster")
        XCTAssertLessThan(tour.spinDecay, std.spinDecay, "spin lasts longer on tournament cloth")
        XCTAssertGreaterThan(tour.cushionRestitution, std.cushionRestitution, "tournament cushions are livelier")
        XCTAssertGreaterThan(bar.slidingFriction, std.slidingFriction, "dive-bar felt grabs")
        XCTAssertGreaterThan(bar.rollingResistance, std.rollingResistance, "dive-bar felt is slower")
        XCTAssertGreaterThan(bar.spinDecay, std.spinDecay)
        XCTAssertLessThan(bar.cushionRestitution, std.cushionRestitution, "dive-bar cushions are dead")
        // A ratio the words print must not round to one (the old caption read "skids about 1 times as far").
        XCTAssertNotEqual((std.slidingFriction / tour.slidingFriction * 10).rounded(), 10)
        XCTAssertNotEqual((std.rollingResistance / bar.rollingResistance * 10).rounded(), 10)
        // What a ball keeps off a rail at the stated pace, through the solver's own rail routine.
        let kept = [tour, std, bar].map { PoolSolver.railRebound(parameters: $0).speedKept }
        XCTAssertGreaterThan(kept[0], kept[1])
        XCTAssertGreaterThan(kept[1], kept[2])
        for k in kept { XCTAssertGreaterThan(k, 0); XCTAssertLessThan(k, 1) }
        print(String(format: "SURFACES rail keeps at 2 m/s: tournament %.3f, standard %.3f, dive bar %.3f", kept[0], kept[1], kept[2]))
        // Every surface's raw value round-trips, so the app's PlaySurface can map to it by name.
        for s in TableSurface.allCases { XCTAssertEqual(TableSurface(rawValue: s.rawValue), s) }
    }

    // The rail rebound helper is the solver's rail: on generation one, a naturally rolling ball straight into the flat
    // cushion keeps exactly the cushion's restitution of its speed; on the default it keeps less at a hard pace than at a
    // gentle one (the rail's bounce falls with pace), and a ball that comes in at no pace keeps nothing.
    func testRailReboundIsTheSolversRail() {
        let one = PoolSolver.railRebound(parameters: .generationOne)
        XCTAssertEqual(one.speedKept, PoolParameters.generationOne.cushionRestitution, accuracy: 1e-12)
        XCTAssertEqual(one.pace, PoolSolver.RailRebound.statedPace)
        let p = PoolParameters()
        let slow = PoolSolver.railRebound(pace: 1, parameters: p), hard = PoolSolver.railRebound(pace: 6, parameters: p)
        XCTAssertGreaterThan(slow.speedKept, hard.speedKept)
        XCTAssertGreaterThan(slow.energyKept, 0)
        XCTAssertLessThanOrEqual(slow.energyKept, 1)
        XCTAssertEqual(PoolSolver.railRebound(pace: 0, parameters: p).speedKept, 0)
    }
}
