// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: Checks for the jam guard (plans/21-Nov-2026-pockets-and-jams-plan.md, part B; spec 3.5 "Zeno guards"),
//          which runs at every physics generation. Spec 21: balls resting in contact with each other or with a rail
//          make no events until something reaches them. Known jams finish quickly: the frozen pair the throw shot's
//          author found (a cue ball following its object ball into a ball frozen a micrometre away, which used to
//          re-collide tens of thousands of times) and the band of jump speeds on the point-blank puzzle that wedged the
//          cue ball against the 8; each must finish in under two thousand events, end at rest with nothing overlapping
//          or in rubber, and never gain energy, with any settled-in-contact event removing energy only. And the guard
//          must leave a normal shot alone: breaks record no settling (JumpTests' pinned hashes prove them unchanged).
// Edited: Claude Opus 5.5 High, 21-November-2026 (proof plan package 4: the untouched-shots check names its
//          generation: the bit-for-bit breaks on generation one, the new showpiece break on the default.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (bug plan after 0.6.6, item 29: the seed-5 break is back in the
//          untouched-shots check on the default physics, now that a gentle contact pushes instead of bouncing
//          (Simulation.pushApart); and the jam sweep's fixtures are saved here: the twenty-five shots "BreakProbe jams"
//          flagged on 21-Nov-2026 before the fixes (twenty-four that hit the event limit at the instant a ball was struck
//          up from over a hole, and one chain of three balls pushed together), each of which must now finish cleanly.)
// SRP/DRY check: Pass - checked PhysicsTests (event budget), JumpTests (the bit-for-bit pins, unchanged) and BreakProbe's
//          "timing" command (the source of the frozen-pair layout). These are the jam guard's own checks.
import BreakdownLensModel
import BreakdownTimeline
@testable import BreakdownPhysics
import Foundation
import XCTest

final class JamGuardTests: XCTestCase {
    private func generations() -> [PoolParameters] {
        var p2 = PoolParameters()
        p2.modelGeneration = PoolParameters.newestGeneration
        return [PoolParameters(), p2]
    }

    private func unit(_ deg: Double) -> Vec2 { Vec2(cos(deg * Double.pi / 180), sin(deg * Double.pi / 180)) }

    /// Rotate a vector by degrees (counter-clockwise).
    private func rotate(_ v: Vec2, _ deg: Double) -> Vec2 {
        let a = deg * Double.pi / 180
        return Vec2(cos(a) * v.x - sin(a) * v.y, sin(a) * v.x + cos(a) * v.y)
    }

    /// The checks every jam must pass: finished well inside the budget, at rest, nothing overlapping or in rubber,
    /// no event that gains energy, and every settling removes energy.
    private func assertSettled(_ input: ShotInput, _ label: String, file: StaticString = #filePath, line: UInt = #line) {
        let (tl, report) = PoolSolver.simulateWithReport(input)
        let p = input.parameters
        let r = p.ballRadius
        XCTAssertLessThan(report.events, 2_000, "\(label): \(report.events) events", file: file, line: line)
        XCTAssertFalse(report.hitEventLimit, "\(label) hit the event limit", file: file, line: line)
        for e in tl.events where e.kind != .cueStrike {
            let before = e.balls.reduce(0.0) { $0 + $1.energyBefore }
            let after = e.balls.reduce(0.0) { $0 + $1.energyAfter }
            XCTAssertLessThanOrEqual(after, before * (1 + 1e-9) + 1e-12, "\(label): energy rose at \(e.kind) t=\(e.time)",
                                     file: file, line: line)
            if e.kind == .settledInContact {
                XCTAssertGreaterThanOrEqual(e.energyRemoved ?? -1, 0, file: file, line: line)
                XCTAssertEqual(e.energyRemoved ?? 0, before - after, accuracy: 1e-12, file: file, line: line)
                XCTAssertFalse(e.balls.isEmpty, file: file, line: line)
            }
        }
        var rest: [Vec2] = []
        for b in 0..<tl.ballCount where NextShot.isOnTable(input.positions[b]) {
            let s = tl.state(ball: b, at: tl.duration + 1)
            if s.pocketed { continue }
            XCTAssertEqual(s.velocity.length, 0, "\(label): ball \(b) still moving", file: file, line: line)
            for j in p.jaws {
                XCTAssertGreaterThanOrEqual((s.position - j.start).length, p.railContactDistance * (1 - 1e-6),
                                            "\(label): ball \(b) inside a knuckle", file: file, line: line)
            }
            rest.append(s.position)
        }
        for i in 0..<rest.count { for j in (i + 1)..<rest.count {
            XCTAssertGreaterThan((rest[i] - rest[j]).length, 2 * r * (1 - 1e-9), "\(label): overlap at rest", file: file, line: line)
        } }
        print("JAM \(label): \(report.events) events, \(report.jamsSettled) settled, \(tl.events.count) recorded")
    }

    // Spec 21: a pair of balls touching, and a ball touching a rail, all at rest; another ball is struck away from
    // them. No event may involve the resting balls, at either generation.
    func testRestingContactsStayQuiet() {
        for p in generations() {
            let r = p.ballRadius
            var pos = [Vec2](repeating: NextShot.offTable, count: 16)
            pos[0] = Vec2(2.0, 0.9)
            pos[1] = Vec2(0.7, 0.6)
            pos[2] = Vec2(0.7 + 2 * r, 0.6)                       // frozen to ball 1, exactly touching
            pos[3] = Vec2(0.9, p.railContactDistance)              // frozen to the bottom rail
            let tl = PoolSolver.simulate(ShotInput(parameters: p, positions: pos,
                                                   strike: CueStrike(direction: Vec2(0, 1), speed: 0.3), seed: 1))
            for e in tl.events {
                XCTAssertFalse(e.balls.contains { [1, 2, 3].contains($0.ball) }, "generation \(p.modelGeneration): \(e.kind) touched a resting ball")
            }
            for b in 1...3 { XCTAssertEqual(tl.state(ball: b, at: tl.duration + 1).position, pos[b]) }
        }
    }

    // The frozen pair from the throw shot's authoring (BreakProbe "timing"): the 2 and the 8 a micrometre apart, the cue
    // ball driving into the 2 along their line of centres with side spin, so it follows the 2 into the 8 and used to
    // re-collide tens of thousands of times. At every gap and both generations it must now finish quickly and cleanly.
    func testFrozenPairFollowChatterSettles() {
        for p in generations() {
            let r = p.ballRadius
            let corner = Vec2(0, 0)
            let b = corner + Vec2(1, 0.62).normalized * 0.45
            let v = rotate((corner - b).normalized, 5)
            for gap in [1e-6, 1e-5, 1e-4] {
                let a = b - v * (2 * r + gap)
                let c = a - v * 0.5
                var pos = [Vec2](repeating: NextShot.offTable, count: 16)
                pos[0] = c; pos[2] = a; pos[8] = b
                for (side, up) in [(0.012, 0.0), (0.0, 0.008), (0.0, 0.0)] {
                    let input = ShotInput(parameters: p, positions: pos,
                                          strike: CueStrike(direction: (a - c).normalized, speed: 2.5, tipUp: up, tipSide: side),
                                          seed: 1)
                    assertSettled(input, "gen \(p.modelGeneration) frozen pair gap \(gap) side \(side) up \(up)")
                }
            }
        }
    }

    // Point-blank (Behind the 8-Ball, situation 7): the steep jump over the 8 wedged the cue ball against it in a
    // narrow band of speeds. Sweep that band finely, at both generations.
    func testPointBlankJumpBandFinishes() {
        let d = 2.54 / 8                                         // one diamond, as EightBallTable lays it out
        func spot(_ across: Double, _ along: Double) -> Vec2 { Vec2(along * d, (4 - across) * d) }
        var pos = [Vec2](repeating: NextShot.offTable, count: 16)
        pos[0] = spot(1.0, 6.0); pos[8] = spot(1.3, 6.17)
        pos[14] = spot(2.6, 6.9); pos[1] = spot(3.4, 3.1); pos[3] = spot(0.6, 2.2); pos[6] = spot(2.2, 4.9); pos[7] = spot(3.7, 5.8)
        for p in generations() {
            var speed = 2.8
            while speed <= 4.2 + 1e-9 {
                let input = ShotInput(parameters: p, positions: pos,
                                      strike: CueStrike(direction: unit(-61.55), speed: speed, tipUp: -0.0045,
                                                        elevation: 0.85),
                                      seed: 1)
                assertSettled(input, String(format: "gen %ld point-blank jump at %.2f m/s", p.modelGeneration, speed))
                speed += 0.05
            }
        }
    }

    // A storm settles and says so: a cue ball driven at walking pace into a ball frozen against a rail, straight in. The
    // shot either never storms (then it is simply short) or every settling closes the energy ledger.
    func testWedgeAgainstARailSettlesCleanly() {
        for p in generations() {
            let r = p.ballRadius
            var pos = [Vec2](repeating: NextShot.offTable, count: 16)
            pos[1] = Vec2(0.8, p.railContactDistance + 1e-6)
            pos[0] = Vec2(0.8, p.railContactDistance + 2 * r + 0.2)
            for (speed, up) in [(0.5, 0.01), (1.0, 0.012), (2.0, 0.0)] {
                let input = ShotInput(parameters: p, positions: pos,
                                      strike: CueStrike(direction: Vec2(0, -1), speed: speed, tipUp: up), seed: 1)
                assertSettled(input, "gen \(p.modelGeneration) wedge on a rail at \(speed) m/s")
            }
        }
    }

    // The guard leaves normal shots alone: the showpiece break and another break pinned bit for bit in JumpTests (whose
    // content hashes prove they are unchanged; generation one on its old numbers since the flip), and the break the
    // momentum test uses, record no settling, never reach the event limit, and settle well inside two thousand events.
    // On the default generation two the new showpiece break, the momentum test's break and the seed-5 break are
    // untouched too. (The seed-5 break used to storm on generation two: balls 7 and 8 touched about six hundred times
    // inside one millisecond, the 8 rolling into the 7 as the 7 slowed, each bounce re-closed by the cloth. A gentle
    // contact is now a push, not a bounce, so the pair moves on together and the guard has nothing to do.)
    func testNormalShotsAreUntouched() {
        let old = PoolParameters.generationOne
        let shots: [ShotInput] = [
            Rack.generationOneShowpieceBreak(),
            Rack.breakShot(parameters: old, seed: 5, aimOffset: 0.01, speed: 10, tipUp: 0.008, tipSide: -0.007),
            Rack.breakShot(parameters: old, seed: 3, aimOffset: 0.004, speed: 9),
            Rack.showpieceBreak(),
            Rack.breakShot(seed: 3, aimOffset: 0.004, speed: 9),
            Rack.breakShot(seed: 5, aimOffset: 0.01, speed: 10, tipUp: 0.008, tipSide: -0.007),
        ]
        for (k, input) in shots.enumerated() {
            let (tl, report) = PoolSolver.simulateWithReport(input)
            XCTAssertEqual(report.jamsSettled, 0, "shot \(k) was settled by the jam guard")
            XCTAssertFalse(report.hitEventLimit)
            XCTAssertFalse(tl.events.contains { $0.kind == .settledInContact })
            XCTAssertLessThan(report.events, 2_000)
        }
    }

    // The jam sweep's fixtures (pockets-and-jams plan part B step 1; bug plan after 0.6.6, item 29). "BreakProbe jams"
    // solved ten thousand seeded random free-play shots on the default physics on 21-Nov-2026 and flagged these
    // twenty-five: twenty-four reached the event limit at t = 0 (a ball struck down from over a hole was treated as on
    // the cloth, marked as crossing, and offered the same hole again forever; it now drops, as a ball in the air does),
    // and one, shot 3389, stormed as three balls pushed one another (now a push that moves the free end of the chain).
    // After both fixes the same ten thousand shots run with no storm, no event limit and at most 925 events. Each
    // fixture must finish in under two thousand events, with no settling, nothing moving at the end, nothing
    // overlapping and no event that gains energy.
    func testJamSweepFixturesFinishCleanly() {
        for f in Self.sweepFixtures {
            let input = f.input(PoolParameters())
            let (_, report) = PoolSolver.simulateWithReport(input)
            XCTAssertEqual(report.jamsSettled, 0, "sweep shot \(f.shot) stormed")
            assertSettled(input, "sweep shot \(f.shot)")
        }
    }

    /// One saved shot of the jam sweep: its number there, the strike and the balls on the table (seed = the number).
    struct JamFixture {
        let shot: Int
        let direction: Vec2
        let speed, tipUp, tipSide, elevation: Double
        let balls: [Int: Vec2]

        func input(_ p: PoolParameters) -> ShotInput {
            var pos = [Vec2](repeating: NextShot.offTable, count: 16)
            for (k, v) in balls { pos[k] = v }
            return ShotInput(parameters: p, positions: pos,
                             strike: CueStrike(direction: direction, speed: speed, tipUp: tipUp, tipSide: tipSide,
                                               elevation: elevation),
                             seed: UInt64(shot))
        }
    }

    /// Printed by "BreakProbe jams 10000" on 21-Nov-2026 (the log is on the Team 4TB drive,
    /// breakdown-build/v07-jams-after-push.log), copied as printed.
    static let sweepFixtures: [JamFixture] = [
        JamFixture(shot: 178, direction: Vec2(0.952454278482, -0.304681550805), speed: 7.175377, tipUp: 0.016803,
                   tipSide: 0.006341, elevation: 0.894774, balls: [
                       0: Vec2(1.275537296, 1.221690999), 1: Vec2(2.102089698, 0.342893926),
                       2: Vec2(0.586969845, 0.209337139), 3: Vec2(0.634509437, 0.241058174),
                       4: Vec2(1.843203793, 0.103216180)]),
        JamFixture(shot: 215, direction: Vec2(0.015223122560, 0.999884121556), speed: 6.370408, tipUp: -0.000262,
                   tipSide: 0.013343, elevation: 0.315797, balls: [
                       0: Vec2(1.268126339, 0.028576000), 1: Vec2(1.379229418, 0.276482067),
                       2: Vec2(0.028576000, 0.543760436), 3: Vec2(0.456066232, 0.266928740),
                       4: Vec2(0.480404634, 0.318638303), 5: Vec2(0.528059625, 0.350185707),
                       6: Vec2(1.272550002, 0.125035440), 7: Vec2(2.393445722, 0.511768269),
                       8: Vec2(0.528335959, 0.076435255), 9: Vec2(0.028576000, 0.372170519),
                       10: Vec2(0.085056076, 0.363439093), 11: Vec2(1.087089668, 0.500265252),
                       12: Vec2(1.031371036, 0.202841587)]),
        JamFixture(shot: 367, direction: Vec2(0.997033096660, 0.076974048649), speed: 2.294424, tipUp: 0.011244,
                   tipSide: 0.011910, elevation: 0.802705, balls: [
                       0: Vec2(0.049568378, 0.028576000), 1: Vec2(1.625237036, 0.670500272),
                       2: Vec2(1.691794068, 0.299278795), 3: Vec2(0.860067228, 1.107307442),
                       4: Vec2(0.915122811, 1.091973831)]),
        JamFixture(shot: 1025, direction: Vec2(0.831752352578, 0.555146849024), speed: 7.815992, tipUp: 0.012424,
                   tipSide: 0.007778, elevation: 0.077417, balls: [
                       0: Vec2(0.028576000, 0.038549263), 1: Vec2(0.392878191, 0.702284363),
                       2: Vec2(1.388706322, 0.369049484), 3: Vec2(1.172856334, 0.130802715),
                       4: Vec2(0.525380230, 0.178680136), 5: Vec2(0.550043782, 0.230235407),
                       6: Vec2(1.640320556, 0.936680910), 7: Vec2(1.765976113, 0.696562866),
                       8: Vec2(1.738009064, 0.646722311), 9: Vec2(1.579697395, 1.005304925)]),
        JamFixture(shot: 1035, direction: Vec2(-0.184993859916, 0.982739676513), speed: 3.011332, tipUp: 0.007823,
                   tipSide: 0.013976, elevation: 0.881187, balls: [
                       0: Vec2(0.047405210, 0.028576000), 1: Vec2(0.945606352, 1.052723204),
                       2: Vec2(0.904356708, 1.013166869)]),
        JamFixture(shot: 1974, direction: Vec2(0.485513700613, -0.874229058381), speed: 7.476430, tipUp: -0.000611,
                   tipSide: 0.015794, elevation: 0.659976, balls: [
                       0: Vec2(0.028576000, 1.228135383), 1: Vec2(2.196753443, 0.280999540)]),
        JamFixture(shot: 1979, direction: Vec2(0.107236602554, 0.994233529445), speed: 2.806603, tipUp: 0.012063,
                   tipSide: -0.010473, elevation: 0.301633, balls: [
                       0: Vec2(2.505221802, 0.028576000), 1: Vec2(2.498517855, 1.235147270),
                       2: Vec2(0.478828510, 0.578950297), 3: Vec2(0.721009680, 0.216092588),
                       4: Vec2(2.258825865, 0.838929725), 5: Vec2(2.327173261, 0.319717543),
                       6: Vec2(0.028576000, 0.561821133), 7: Vec2(0.796739484, 0.368477615)]),
        JamFixture(shot: 2664, direction: Vec2(-0.423667649743, 0.905817709344), speed: 1.667570, tipUp: 0.003052,
                   tipSide: -0.005417, elevation: 0.893395, balls: [
                       0: Vec2(1.272277695, 0.028576000), 1: Vec2(0.789266874, 0.832197145),
                       2: Vec2(0.028576000, 1.120566554), 3: Vec2(1.690419338, 0.303196922),
                       4: Vec2(2.425808591, 0.119166982), 5: Vec2(2.068145810, 0.436412806),
                       6: Vec2(0.889879720, 0.095127878), 7: Vec2(0.028576000, 0.088278588),
                       8: Vec2(1.790069639, 0.830243586), 9: Vec2(1.078539477, 1.217095463),
                       10: Vec2(1.735298008, 0.110717785), 11: Vec2(1.403714374, 0.864340832)]),
        JamFixture(shot: 2754, direction: Vec2(-0.955629208973, -0.294572257616), speed: 2.657297, tipUp: 0.007060,
                   tipSide: 0.001633, elevation: 0.182540, balls: [
                       0: Vec2(1.230037905, 0.033006405), 1: Vec2(1.649826973, 0.261980638),
                       2: Vec2(1.401130748, 0.819509287), 3: Vec2(0.028576000, 0.153979144),
                       4: Vec2(2.130587387, 0.159036645), 5: Vec2(1.653036616, 0.989875726),
                       6: Vec2(1.649550791, 1.046920321), 7: Vec2(0.028576000, 0.055886383),
                       8: Vec2(0.076679060, 0.086746267), 9: Vec2(0.132409980, 0.099407285),
                       10: Vec2(2.093221613, 0.479729596), 11: Vec2(1.331878821, 0.341116565),
                       12: Vec2(1.615446199, 1.114409757), 13: Vec2(1.127917218, 0.602742022),
                       14: Vec2(0.807886467, 0.843008048)]),
        JamFixture(shot: 3389, direction: Vec2(0.353558237511, -0.935412514716), speed: 7.788352, tipUp: -0.006809,
                   tipSide: -0.016917, elevation: 0.000000, balls: [
                       0: Vec2(1.028350406, 0.028576000), 1: Vec2(1.030195890, 0.085697196),
                       2: Vec2(2.474497660, 0.164169517), 3: Vec2(1.309710279, 0.522424613),
                       4: Vec2(2.231512683, 0.232557096), 5: Vec2(0.329380514, 1.135306605),
                       6: Vec2(0.307946770, 1.082327067), 7: Vec2(2.316210556, 0.336787667),
                       8: Vec2(2.295267365, 0.389963032), 9: Vec2(2.288458314, 0.446706963),
                       10: Vec2(2.332991030, 0.482526985), 11: Vec2(2.057642379, 0.334684193),
                       12: Vec2(2.352769935, 0.894461988), 13: Vec2(2.350518986, 0.951568643),
                       14: Vec2(2.333607257, 0.644431151)]),
        JamFixture(shot: 4195, direction: Vec2(-0.051294044975, 0.998683594013), speed: 1.873981, tipUp: -0.009380,
                   tipSide: -0.001542, elevation: 0.327819, balls: [
                       0: Vec2(1.306618670, 0.028576000), 1: Vec2(1.569895912, 0.632686064),
                       2: Vec2(0.858305549, 0.304053980), 3: Vec2(0.033286651, 0.366815839),
                       4: Vec2(0.048173455, 0.421993913), 5: Vec2(1.086356246, 0.051308389),
                       6: Vec2(1.816826701, 0.947006285), 7: Vec2(0.933750079, 0.966437613),
                       8: Vec2(0.439397697, 0.940238771), 9: Vec2(0.471172486, 0.987742451),
                       10: Vec2(0.495041248, 1.039670469)]),
        JamFixture(shot: 4221, direction: Vec2(0.489441264597, 0.872036265593), speed: 5.007211, tipUp: -0.010800,
                   tipSide: -0.009901, elevation: 0.485343, balls: [
                       0: Vec2(1.242683870, 0.028576000), 1: Vec2(0.669701021, 0.028576000),
                       2: Vec2(0.028576000, 0.137532857), 3: Vec2(0.718449987, 0.245360376),
                       4: Vec2(1.385799471, 0.752474501), 5: Vec2(1.656800649, 1.073850037),
                       6: Vec2(2.328952497, 0.186489503), 7: Vec2(2.293375932, 1.117626205),
                       8: Vec2(2.131961726, 0.028576000), 9: Vec2(2.279990418, 0.641082054),
                       10: Vec2(2.286359126, 0.584287016), 11: Vec2(1.528576835, 0.291392117),
                       12: Vec2(1.508196409, 0.237998531), 13: Vec2(1.454196247, 0.219284383)]),
        JamFixture(shot: 5206, direction: Vec2(-0.097717650469, 0.995214178349), speed: 7.534487, tipUp: -0.009106,
                   tipSide: -0.009399, elevation: 0.708336, balls: [
                       0: Vec2(0.051209299, 0.028576000), 1: Vec2(2.344689855, 0.886771692),
                       2: Vec2(2.491525498, 0.275522507), 3: Vec2(2.506060509, 0.330794292),
                       4: Vec2(0.128899184, 0.414944860), 5: Vec2(2.189026996, 0.399187000),
                       6: Vec2(2.197195968, 0.330186170), 7: Vec2(0.583593831, 0.294255686),
                       8: Vec2(0.543233851, 0.334719359), 9: Vec2(2.384920257, 0.648530859)]),
        JamFixture(shot: 5525, direction: Vec2(0.616973538063, 0.786983896487), speed: 4.239171, tipUp: 0.002358,
                   tipSide: 0.009898, elevation: 0.860786, balls: [
                       0: Vec2(1.290993531, 0.028576000), 1: Vec2(1.254004405, 0.072142517),
                       2: Vec2(0.645914164, 0.036529740), 3: Vec2(0.898125965, 1.178447224),
                       4: Vec2(0.864517526, 1.132222668), 5: Vec2(0.581649328, 1.123667405),
                       6: Vec2(0.621978246, 1.083172774), 7: Vec2(0.581890612, 1.042439270),
                       8: Vec2(0.028576000, 0.894023629), 9: Vec2(1.806701595, 0.833114884),
                       10: Vec2(2.248920521, 0.340350927), 11: Vec2(1.845808478, 1.042470047),
                       12: Vec2(1.901017920, 1.057240093)]),
        JamFixture(shot: 6000, direction: Vec2(0.157674270958, 0.987491176810), speed: 3.555316, tipUp: -0.007691,
                   tipSide: -0.012514, elevation: 0.718315, balls: [
                       0: Vec2(0.028576000, 0.038886592), 1: Vec2(0.028576000, 0.428106745)]),
        JamFixture(shot: 6630, direction: Vec2(-0.906757415724, -0.421652687682), speed: 3.457984, tipUp: -0.013147,
                   tipSide: -0.010761, elevation: 0.234934, balls: [
                       0: Vec2(1.262389987, 0.028576000), 1: Vec2(0.949377934, 0.991536620),
                       2: Vec2(1.904545670, 0.343411156), 3: Vec2(1.832923547, 0.602471175),
                       4: Vec2(1.130587899, 0.741062520)]),
        JamFixture(shot: 6787, direction: Vec2(-0.998825806478, 0.048445931848), speed: 4.808940, tipUp: 0.010151,
                   tipSide: 0.017018, elevation: 0.783400, balls: [
                       0: Vec2(1.229138837, 0.028576000), 1: Vec2(2.006814214, 0.028576000),
                       2: Vec2(0.538803812, 0.174768212), 3: Vec2(1.003165988, 0.028576000),
                       4: Vec2(0.355198964, 1.078129558), 5: Vec2(1.981077176, 0.408527462),
                       6: Vec2(2.026196064, 0.443606269), 7: Vec2(2.382709646, 0.804614722),
                       8: Vec2(1.566358167, 0.950907351), 9: Vec2(2.328056152, 1.099083621),
                       10: Vec2(0.889094478, 0.596272251), 11: Vec2(0.952030363, 1.209410855),
                       12: Vec2(0.917842421, 1.163613241), 13: Vec2(2.011279665, 0.821636050),
                       14: Vec2(1.910830318, 1.150339982), 15: Vec2(1.858528693, 1.127301388)]),
        JamFixture(shot: 6857, direction: Vec2(0.569293839031, 0.822134128255), speed: 2.998929, tipUp: -0.009508,
                   tipSide: 0.015270, elevation: 0.844406, balls: [
                       0: Vec2(0.028576000, 0.055785937), 1: Vec2(0.028576000, 0.582135161)]),
        JamFixture(shot: 7651, direction: Vec2(0.519010957913, 0.854767585702), speed: 7.823203, tipUp: 0.002583,
                   tipSide: -0.009749, elevation: 0.117526, balls: [
                       0: Vec2(1.282805339, 0.028576000), 1: Vec2(1.576356840, 0.847439324),
                       2: Vec2(0.915979575, 0.652899756), 3: Vec2(1.554226114, 1.079230573),
                       4: Vec2(0.642903082, 0.028576000), 5: Vec2(1.119097560, 0.383308058),
                       6: Vec2(1.831121632, 0.028576000), 7: Vec2(1.435936455, 0.028576000),
                       8: Vec2(0.028576000, 0.641722256)]),
        JamFixture(shot: 7669, direction: Vec2(-0.523731962618, 0.851883108960), speed: 0.870937, tipUp: 0.010256,
                   tipSide: 0.004665, elevation: 0.679378, balls: [
                       0: Vec2(1.309501553, 0.028576000), 1: Vec2(1.508105562, 0.191242934)]),
        JamFixture(shot: 7936, direction: Vec2(0.998848187670, -0.047982267437), speed: 7.371854, tipUp: 0.004780,
                   tipSide: 0.015123, elevation: 0.669417, balls: [
                       0: Vec2(1.266167277, 0.031246758), 1: Vec2(0.585733570, 0.748050121),
                       2: Vec2(1.288082577, 0.429908358), 3: Vec2(1.434664038, 0.475274062)]),
        JamFixture(shot: 8308, direction: Vec2(0.999391580078, -0.034877925234), speed: 2.570774, tipUp: 0.012549,
                   tipSide: -0.011151, elevation: 0.486648, balls: [
                       0: Vec2(0.028576000, 1.228731266), 1: Vec2(1.822848141, 0.832323774),
                       2: Vec2(1.760104348, 1.040602046)]),
        JamFixture(shot: 9006, direction: Vec2(-0.940646275301, -0.339388545421), speed: 3.679312, tipUp: 0.004128,
                   tipSide: 0.005773, elevation: 0.855104, balls: [
                       0: Vec2(1.271213124, 0.050169274), 1: Vec2(0.945224293, 0.873549894),
                       2: Vec2(0.959847293, 0.028576000), 3: Vec2(0.938156999, 0.386461318),
                       4: Vec2(0.169783069, 0.373407206), 5: Vec2(1.705929427, 0.558029497),
                       6: Vec2(2.504394644, 0.979921348), 7: Vec2(1.769244503, 1.203915032)]),
        JamFixture(shot: 9053, direction: Vec2(-0.139127468479, 0.990274480896), speed: 3.334670, tipUp: -0.011876,
                   tipSide: 0.013942, elevation: 0.729709, balls: [
                       0: Vec2(0.028576000, 0.033069948), 1: Vec2(0.566212402, 0.719697442),
                       2: Vec2(0.509125475, 0.722402910), 3: Vec2(0.711220992, 1.218860064),
                       4: Vec2(1.079636482, 0.171157294), 5: Vec2(2.477345394, 0.038311174),
                       6: Vec2(0.938258652, 0.630011616), 7: Vec2(0.847328018, 0.028576000)]),
        JamFixture(shot: 9998, direction: Vec2(0.755815478948, -0.654784668255), speed: 6.823134, tipUp: 0.010135,
                   tipSide: 0.010036, elevation: 0.779697, balls: [
                       0: Vec2(0.028576000, 1.238621930), 1: Vec2(1.539207704, 0.296388407),
                       2: Vec2(2.021284709, 0.672945083), 3: Vec2(0.690032310, 1.124808580),
                       4: Vec2(0.577875280, 0.028576000), 5: Vec2(0.545499736, 0.899204885),
                       6: Vec2(1.308223606, 1.137894047), 7: Vec2(0.963566483, 1.112736519)]),
    ]
}
