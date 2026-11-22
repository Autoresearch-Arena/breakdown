// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: Guards the physics switch (plans/21-Nov-2026-physics-proof-plan.md, package 1). The default parameters must
//          hash exactly as they did before modelGeneration and the generation-two numbers existed; the generation joins
//          the hash only off its default, and the generation-two numbers only above generation 1. The new CueStrike
//          field (ballIndex) and the new LensEvent fields must leave today's recordings bit for bit unchanged. Also
//          checks the reasons written beside the new starting values (the shaft end mass gives 2 to 3 degrees of
//          deflection at half-radius side offset; the miscue limit sits at about half the radius; the rail restitution
//          reaches its floor at break speed).
// Edited: Claude Opus 5.5 High, 21-November-2026 (the flip: the pre-switch hash is now PoolParameters.generationOne's,
//          and a new check pins the default to generation two with the tuned numbers.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (bug plan after 0.6.6: the new generation-two numbers, the miscue's
//          full-turn overshoot and the gentle-contact rule's, join the hash checks.)
// SRP/DRY check: Pass - checked JumpTests (its testLevelStrikesAreBitForBitUnchanged pins five recordings' content
//          hashes, which include the parameter hash) and TableFeatureTests (the table-feature hash marker). These are the
//          switch's own checks; nothing here repeats a solver test.
import BreakdownLensModel
import BreakdownTimeline
@testable import BreakdownPhysics
import Foundation
import XCTest

final class PhysicsSwitchTests: XCTestCase {
    /// The default parameter hash exactly as Parameters.swift computed it on 21 November 2026, before the switch:
    /// the fixed list of numbers, then the version, with the jump marker and the table-feature marker both absent
    /// (they add nothing at their defaults). The values are typed out here from the pre-switch defaults rather than
    /// read from PoolParameters, so a changed default fails this test as well as a changed hash. (The literal hash
    /// itself is not written down: it cannot be worked out by hand with certainty and the package is not compiled while
    /// this batch is written. JumpTests' content-hash literals pin it a second way, because every recording's content
    /// hash starts from its parameter hash.) IF THIS FAILS while JumpTests.testLevelStrikesAreBitForBitUnchanged
    /// passes, check this typed list against the loop in PoolParameters.hash first: the hash is then fine and the
    /// list is wrong. If both fail, the hash changed.
    private func preSwitchDefaultHash() -> UInt64 {
        var h = StableHasher()
        let numbers: [Double] = [
            0.028575, 0.170, 9.81, 0.2, 0.01, 9.0, 0.95,          // radius, mass, gravity, cloth, roll, spin, ball e
            0.00995, 0.108, 1.088, 0.85, 0.17,                    // ball-ball friction fit, cushion e and friction
            2.54, 1.27, 0.1207, 0.1334,                           // table size, corner and side mouths
            -0.788011, -0.615661, -0.241922, -0.970296,           // corner jaw, side jaw directions
            0.06, 0.065, 0.052, 0.0,                              // jaw length, capture radii, side setback
            1e-6, 2e-7,                                           // rack gap and jitter
        ]
        for d in numbers { h.combine(d) }
        h.combine(2)                                              // version
        return h.value
    }

    // Since the flip (21-Nov-2026) the old defaults live in PoolParameters.generationOne: it must still hash exactly as
    // the default did before the switch existed, so every recording made before the flip keeps its hash.
    func testGenerationOnePresetHashIsUnchanged() {
        let p = PoolParameters.generationOne
        XCTAssertEqual(p.modelGeneration, 1)
        XCTAssertFalse(p.usesGenerationTwo)
        XCTAssertEqual(p.hash, preSwitchDefaultHash())
        // The recorded parameter hash of a solve is the same value.
        XCTAssertEqual(PoolSolver.simulate(Rack.generationOneShowpieceBreak()).parameterHash, preSwitchDefaultHash())
    }

    // The flip (proof plan package 4): the default is generation two with the numbers the real-table sweep chose.
    func testDefaultIsGenerationTwoWithTheTunedNumbers() {
        let p = PoolParameters()
        XCTAssertEqual(p.modelGeneration, 2)
        XCTAssertEqual(p.modelGeneration, PoolParameters.newestGeneration)
        XCTAssertTrue(p.usesGenerationTwo)
        XCTAssertEqual(p.slidingFriction, 0.15)
        XCTAssertEqual(p.rollingResistance, 0.015)
        XCTAssertEqual(p.spinDecay, 9.5)
        XCTAssertEqual(p.cushionRestitution, 0.96)
        XCTAssertEqual(p.cushionFriction, 0.15)
        XCTAssertEqual(p.railCrossGrip, 0.10)
        XCTAssertEqual(p.railRestitutionSlope, 0.035)
        XCTAssertEqual(p.railRestitutionFloor, 0.6)
        XCTAssertEqual(p.cueMass, 0.54)
        XCTAssertEqual(p.shaftEndMass, 0.0073)
        XCTAssertNotEqual(p.hash, preSwitchDefaultHash())
        XCTAssertEqual(PoolSolver.simulate(Rack.showpieceBreak()).parameterHash, p.hash)
        // The preset differs from the default only in the generation and the five tuned numbers.
        var back = PoolParameters.generationOne
        back.modelGeneration = 2
        back.slidingFriction = 0.15; back.rollingResistance = 0.015; back.spinDecay = 9.5; back.cushionRestitution = 0.96
        back.cushionFriction = 0.15
        XCTAssertEqual(back.hash, p.hash)
    }

    func testGenerationJoinsTheHashOnlyOffItsDefault() {
        let base = PoolParameters.generationOne.hash

        // Generation-two numbers do nothing at generation 1, so changing them there leaves the hash alone.
        var g1 = PoolParameters.generationOne
        g1.railRestitutionSlope = 0.05; g1.railRestitutionFloor = 0.5; g1.cueMass = 0.6; g1.shaftEndMass = 0.009
        g1.tipGrip = 0.6; g1.miscueSpeedFraction = 0.4; g1.miscueMaxDeflection = 0.1
        g1.pocketCaptureFallFraction = 0.5; g1.rimSkipSpeedLoss = 0.1; g1.miscueFullTurnOvershoot = 0.2; g1.gentleContactSpeed = 0.01
        g1.railCrossGrip = 0.3
        XCTAssertEqual(g1.hash, base)

        // The generation itself changes it, and above 1 every generation-two number does too.
        var g2 = PoolParameters.generationOne
        g2.modelGeneration = PoolParameters.newestGeneration
        XCTAssertTrue(g2.usesGenerationTwo)
        XCTAssertNotEqual(g2.hash, base)
        var hashes: Set<UInt64> = [base, g2.hash]
        let tweaks: [(inout PoolParameters) -> Void] = [
            { $0.railRestitutionSlope += 0.001 }, { $0.railRestitutionFloor += 0.01 }, { $0.cueMass += 0.01 },
            { $0.shaftEndMass += 0.0001 }, { $0.tipGrip += 0.01 }, { $0.miscueSpeedFraction += 0.01 },
            { $0.miscueMaxDeflection += 0.001 }, { $0.pocketCaptureFallFraction += 0.01 }, { $0.rimSkipSpeedLoss += 0.01 },
            { $0.miscueFullTurnOvershoot += 0.01 }, { $0.gentleContactSpeed += 0.001 }, { $0.railCrossGrip += 0.01 },
        ]
        for tweak in tweaks {
            var q = g2
            tweak(&q)
            hashes.insert(q.hash)
        }
        XCTAssertEqual(hashes.count, tweaks.count + 2, "every generation-two number must reach the hash above generation 1")
    }

    // A strike that names no ball strikes ball 0, and today's level shots record exactly what they did (the literal is
    // JumpTests' first, printed by the unchanged solver on 20-Nov-2026).
    func testStrikeBallIndexDefaultsToTheCueBallAndChangesNothing() {
        let input = Rack.generationOneShowpieceBreak()
        XCTAssertEqual(input.strike.ballIndex, 0)
        XCTAssertEqual(CueStrike(direction: Vec2(1, 0), speed: 2).ballIndex, 0)
        let tl = PoolSolver.simulate(input)
        XCTAssertEqual(tl.contentHash, 8_237_982_394_174_342_167)
        // Generation 1 records none of the generation-two event fields and neither new kind.
        for e in tl.events {
            XCTAssertNil(e.entry); XCTAssertNil(e.miscue); XCTAssertNil(e.deflectionSine)
            XCTAssertNil(e.bedImpulse); XCTAssertNil(e.energyRemoved)
            XCTAssertNotEqual(e.kind, .rimSkip); XCTAssertNotEqual(e.kind, .settledInContact)
        }
    }

    // Each new event field joins the content hash only when it is set.
    func testNewEventFieldsJoinTheContentHashOnlyWhenSet() {
        let ball = ImpactBall(ball: 1, velocityBefore: Vec2(1, 0), velocityAfter: .zero, omegaBefore: .zero,
                              omegaAfter: .zero, translationalBefore: 0.085, rotationalBefore: 0,
                              translationalAfter: 0, rotationalAfter: 0)
        func hash(_ e: LensEvent) -> UInt64 {
            let still = BallSegment(t0: 0, t1: .infinity, phase: .stationary, position0: Vec2(1, 0.5), velocity0: .zero,
                                    acceleration: .zero, omega0: .zero, alphaXY: .zero, spinDecay: 9, radius: 0.028575,
                                    orientation0: .identity)
            let spec = TableSpec(length: 2.54, width: 1.27, ballRadius: 0.028575, pockets: [], pocketCaptureRadius: [])
            return Timeline(table: spec, seed: 1, parameterHash: 7, segments: [[still], [still]], events: [e],
                            pocketTime: [nil, nil], duration: e.time).contentHash
        }
        let plain = LensEvent(time: 0.5, kind: .pocket, point: Vec2(2.54, 0), normal: Vec2(1, 0), balls: [ball], pocket: 1)
        var variants: [LensEvent] = []
        var a = plain; a.entry = PocketEntry(speed: 1, sine: 0.1, cosine: 0.99498743710662); variants.append(a)
        var b = plain; b.miscue = false; variants.append(b)
        var c = plain; c.deflectionSine = 0.04; variants.append(c)
        var d = plain; d.bedImpulse = 0.02; variants.append(d)
        var f = plain; f.energyRemoved = 0.001; variants.append(f)
        let hashes = Set([hash(plain)] + variants.map(hash))
        XCTAssertEqual(hashes.count, variants.count + 1)
    }

    // The starting values' written reasons hold.
    func testGenerationTwoStartingValuesMatchTheirReasons() {
        let p = PoolParameters()
        // Shaft end mass: 2 to 3 degrees of deflection at half-radius side offset (cue-strike plan, spec 3.3).
        let x = 0.5
        let tangent = 2.5 * x * (1 - x * x).squareRoot() / (1 + p.ballMass / p.shaftEndMass + 2.5 * x * x)
        let degrees = atan(tangent) * 180 / Double.pi
        XCTAssertGreaterThanOrEqual(degrees, 2)
        XCTAssertLessThanOrEqual(degrees, 3)
        // Miscue limit: about half the radius.
        let limit = p.tipGrip / (1 + p.tipGrip * p.tipGrip).squareRoot()
        XCTAssertEqual(limit, 0.5, accuracy: 0.01)
        // Rail restitution: the tuned cushionRestitution at walking pace, the floor reached inside the break range
        // (8 to 13 m/s, spec 3.4), at (0.96 - 0.6) / 0.035 = 10.3 m/s since the rail sweep of the bug plan's item 26.
        let floorPace = (p.cushionRestitution - p.railRestitutionFloor) / p.railRestitutionSlope
        XCTAssertGreaterThanOrEqual(floorPace, 8)
        XCTAssertLessThanOrEqual(floorPace, 13)
        // Pocket capture: a third of the radius.
        XCTAssertEqual(p.pocketCaptureFallFraction, 1.0 / 3.0)
        // Miscue deflection: tan 5 degrees.
        XCTAssertEqual(p.miscueMaxDeflection, tan(5 * Double.pi / 180), accuracy: 1e-4)
    }
}
