// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The cues and the automatic pick (plan item 57, plans/21-Nov-2026-bugs-after-0-6-6-plan.md): the house cue is
//          still exactly the solver's cue (its launch speed is the power, bit for bit); every cue kind has one profile
//          with the art's length; power stays swing speed, so at the same power a heavier cue launches the ball faster
//          and a lighter one slower; power(forLaunchSpeed:) undoes launchSpeed(forPower:); the pick gives the break
//          cue for a break, the jump cue for a steep strike without side, the massé cue for a raised strike with side
//          and the house cue otherwise, on the authored shots' own settings; the indicator line names every pick but
//          the house cue's; and the 3D cue's pose on the rest is never below the strike's angle (item 23).
// SRP/DRY check: Pass - checks only; thresholds and lengths are read from CueProfile's and CueRig's named constants.
//          StrokeTests keeps the stroke and the house cue's place in it; this file covers the other cues and the pick.
@testable import Breakdown
import BreakdownPhysics
import XCTest

final class CueProfileTests: XCTestCase {
    private let r = PoolParameters().ballRadius

    // MARK: The house cue

    func testHouseCueIsUnchanged() {
        let house = CueProfile.profile(for: .house)
        XCTAssertEqual(house, CueProfile.house)
        XCTAssertTrue(house.isHouse)
        XCTAssertEqual(house.cueMass, PoolParameters().cueMass)
        XCTAssertEqual(house.length, CueProfile.houseLength)
        for p in stride(from: 0.25, through: 16, by: 0.25) {
            XCTAssertEqual(house.launchSpeed(forPower: p).bitPattern, p.bitPattern)
            XCTAssertEqual(house.power(forLaunchSpeed: p).bitPattern, p.bitPattern)
        }
    }

    // MARK: The set

    func testEveryKindHasItsOwnProfile() {
        XCTAssertEqual(CueProfile.all.count, CueKind.allCases.count)
        XCTAssertEqual(Set(CueProfile.all.map(\.id)).count, CueKind.allCases.count, "ids are unique")
        for kind in CueKind.allCases {
            let cue = CueProfile.profile(for: kind)
            XCTAssertEqual(cue.kind, kind)
            XCTAssertEqual(cue.id, kind.rawValue)
            XCTAssertFalse(cue.name.isEmpty)
            XCTAssertGreaterThan(cue.length, 1.0)
            XCTAssertEqual(cue.isHouse, kind == .house)
        }
        // The art's lengths (export_equipment.py checks the models against the same figures).
        XCTAssertEqual(CueProfile.jump.length, 1.05)
        XCTAssertEqual(CueProfile.masse.length, 1.26)
        XCTAssertEqual(CueProfile.breakCue.length, 1.47)
    }

    // MARK: Power is swing speed

    func testAHeavierCueSendsTheBallFasterAtTheSameSwing() {
        let power = 5.0
        let byMass = CueProfile.all.sorted { $0.cueMass < $1.cueMass }
        for (light, heavy) in zip(byMass, byMass.dropFirst()) {
            XCTAssertLessThan(light.launchSpeed(forPower: power), heavy.launchSpeed(forPower: power),
                              "\(light.id) is lighter than \(heavy.id)")
        }
        XCTAssertGreaterThan(CueProfile.breakCue.launchSpeed(forPower: power), power)
        XCTAssertLessThan(CueProfile.jump.launchSpeed(forPower: power), power)
    }

    func testPowerForLaunchSpeedUndoesLaunchSpeed() {
        for cue in CueProfile.all {
            for speed in [0.5, 1.6, 4.55, 9.0, 13.0] {
                XCTAssertEqual(cue.launchSpeed(forPower: cue.power(forLaunchSpeed: speed)), speed, accuracy: 1e-12)
            }
        }
    }

    // MARK: The pick

    func testTheBreakGetsTheBreakCue() {
        let pick = CueProfile.choice(isBreak: true, elevation: 0, tipUp: 0, tipSide: 0)
        XCTAssertEqual(pick, CueChoice(kind: .breakCue, reason: .breakShot))
    }

    func testAnOrdinaryShotKeepsTheHouseCue() {
        XCTAssertEqual(CueProfile.choice(isBreak: false, elevation: 0, tipUp: -0.01, tipSide: 0.01), .standard)
        // A swerve: a slightly raised cue with side stays with the house cue.
        XCTAssertEqual(CueProfile.choice(isBreak: false, elevation: sin(10 * Double.pi / 180), tipUp: 0,
                                         tipSide: 0.01), .standard)
        // A jacked-up stroke over a ball, raised but short of a jump, with no side.
        XCTAssertEqual(CueProfile.choice(isBreak: false, elevation: CueProfile.jumpElevation - 0.01, tipUp: 0,
                                         tipSide: 0), .standard)
    }

    func testAuthoredJumpsGetTheJumpCue() {
        // Jump the Blocker (sine 0.55, no side) and the jump lesson (40 degrees), from their authored settings.
        for elevation in [0.55, sin(40 * Double.pi / 180), 0.85] {
            XCTAssertEqual(CueProfile.choice(isBreak: false, elevation: elevation, tipUp: -0.005, tipSide: 0),
                           CueChoice(kind: .jump, reason: .jump))
        }
        XCTAssertEqual(CueProfile.choice(isBreak: false, elevation: CueProfile.jumpElevation, tipUp: 0,
                                         tipSide: CueProfile.masseSide * 0.5).kind, .jump)
    }

    func testAuthoredCurvesGetTheMasseCue() {
        // The Massé (sine 0.40, 13.5 mm), the Draw-Massé Carom (0.45, 6 mm), the curve lesson (25 degrees, 8 mm).
        for (elevation, side) in [(0.40, 0.0135), (0.45, 0.006), (sin(25 * Double.pi / 180), -0.008)] {
            XCTAssertEqual(CueProfile.choice(isBreak: false, elevation: elevation, tipUp: -0.0025, tipSide: side),
                           CueChoice(kind: .masse, reason: .steepMasse))
        }
        XCTAssertEqual(CueProfile.choice(isBreak: false, elevation: CueProfile.masseElevation, tipUp: 0,
                                         tipSide: CueProfile.masseSide).kind, .masse)
    }

    func testTheIndicatorNamesEveryPickButTheHouseCue() {
        XCTAssertNil(StanceWords.cueLine(.standard))
        for reason in CueChoice.Reason.allCases where reason != .standard {
            let line = StanceWords.cueLine(CueChoice(kind: .house, reason: reason))
            XCTAssertFalse(line?.isEmpty ?? true, "\(reason)")
        }
    }

    // MARK: The 3D cue's pose (item 23)

    @MainActor
    func testTheDrawnCueIsNeverBelowTheStrike() {
        let contact = Float(r)
        for degrees in stride(from: Float(0), through: 80, by: 5) {
            let sine = sin(degrees * .pi / 180)
            let strike = asin(sine)
            for rest in [false, true] {
                for cue in CueKind.allCases {
                    let pose = CueRig.pose(elevation: sine, contactHeight: contact, rest: rest, cue: cue)
                    XCTAssertGreaterThanOrEqual(pose.pitch, strike - 1e-6, "\(degrees) degrees, rest \(rest)")
                    if rest {
                        XCTAssertGreaterThanOrEqual(pose.restDistance, CueRig.restClosest)
                        XCTAssertLessThanOrEqual(pose.restDistance, CueRig.bridgeSetback)
                    }
                }
            }
        }
    }

    @MainActor
    func testTheCueLiesInTheRestsCradle() {
        // A level strike on the rest: the rest stands at its usual setback and the cue is raised to its seat.
        let contact = Float(r)
        let level = CueRig.pose(elevation: 0, contactHeight: contact, rest: true, cue: .house)
        XCTAssertEqual(level.restDistance, CueRig.bridgeSetback)
        XCTAssertEqual(contact + level.restDistance * tan(level.pitch), CueRig.restSeat(.house), accuracy: 1e-5)
        // A steeper strike: the rest moves in until its cradle meets the raised cue.
        let steep = CueRig.pose(elevation: sin(20 * .pi / 180), contactHeight: contact, rest: true, cue: .house)
        XCTAssertLessThan(steep.restDistance, CueRig.bridgeSetback)
        XCTAssertEqual(contact + steep.restDistance * tan(steep.pitch), CueRig.restSeat(.house), accuracy: 1e-5)
    }
}
