// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The stroke (plans/21-Nov-2026-stroke-and-power-plan.md): the house cue changes nothing (its multiplier is
//          exactly one, and a strike built through it is bit for bit the strike built from the power, down to the solved
//          recording); a perfectly straight calm stroke has no drift; drift grows with the stroke's wander and, past the
//          calm zone, faster than the swing; the same input always gives the same delivery and the same measured
//          stroke; the bridge scales the tip as the lever says and a short bridge lowers the calm zone; authored shots
//          stay inside the bound; the tracker reads a push through the ball, practice rhythm and wander; the retry
//          comparison's stroke fact; and the drill's judge on real solved shots.
// Edited: Claude Opus 5.5 High, 21-November-2026 (reach: the authored-bound test gains a stance case, every rung of the
//          reach ladder with and without a raised cue, which must stay inside the same bound; ReachTests holds the rest.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0 items 3, 4, 5 and 45: a finger inside the drawn groove is a
//          straight stroke and plays exactly as the keys do, the groove's floor widens it on a short stroke; the break's
//          own calm zone covers the default break; a long bridge raises the calm top, the rest does not; the result
//          line's comparison of the shot as played and as aimed, and the strike as aimed undoes the drift; the button-
//          only option is off on a fresh install.)
// SRP/DRY check: Pass - checks only; every limit is read from the named constants in CueProfile, StrokeModel,
//          StrokeTracker and StrokeDrill, never retyped. Shots are solved through TestShots, the app's own path.
@testable import Breakdown
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import XCTest

final class StrokeTests: XCTestCase {
    private let house = CueProfile.house

    /// A finger stroke with a given wander and nothing else.
    private func record(_ wander: Double, power: Double = 3, rhythm: Double = 1, bridge: Double? = nil) -> StrokeRecord {
        StrokeRecord(wander: wander, rhythm: rhythm, bridge: bridge, power: power, trace: [], shape: [],
                     practiceStrokes: 0)
    }

    private func delivery(power: Double, wander: Double?, bridge: Double = StrokeModel.automaticBridge,
                          authored: Bool = false, isBreak: Bool = false) -> StrokeDelivery {
        StrokeModel.delivery(power: power, fraction: 0.5, record: wander.map { record($0, power: power) },
                             bridge: bridge, cue: house, authored: authored, isBreak: isBreak)
    }

    /// The calm zone's top as a power, with the automatic bridge.
    private var calmTopPower: Double {
        StrokeModel.zones(cue: house, bridge: StrokeModel.automaticBridge).calmTopPower
    }

    // MARK: The house cue changes nothing

    func testHouseCueMultiplierIsExactlyOne() {
        XCTAssertTrue(CueProfile.selected.isHouse, "only the house cue exists until the equipment work adds more")
        for p in [0.5, 0.95, 1.75, 3.0, 0.1 + 0.2, 6.45, 13.0, 16.0, 7.123456789] {
            XCTAssertEqual(house.launchSpeed(forPower: p).bitPattern, p.bitPattern, "house cue changed power \(p)")
            XCTAssertEqual(CueProfile.selected.launchSpeed(forPower: p).bitPattern, p.bitPattern)
        }
    }

    func testHouseCueStrikesAndRecordingsAreBitIdentical() {
        var layout = [Vec2](repeating: NextShot.offTable, count: 16)
        layout[0] = Vec2(0.6, 0.6); layout[1] = Vec2(1.5, 0.65)
        let d = Vec2(1, 0.05).normalized
        for power in [1.2, 3.0, 9.5] {
            let plain = NextShot.shot(from: layout, direction: d, speed: power, tipUp: 0.004, tipSide: -0.003, seed: 7)
            var played = NextShot.shot(from: layout, direction: d, speed: house.launchSpeed(forPower: power),
                                       tipUp: 0.004, tipSide: -0.003, seed: 7)
            // A calm keyboard shot's delivery is exactly nothing, and applying it changes nothing.
            let calm = delivery(power: min(power, calmTopPower * 0.9), wander: nil)
            XCTAssertTrue(calm.isZero)
            calm.apply(to: &played.strike, ballRadius: TestShots.ballRadius)
            XCTAssertEqual(played.strike.speed.bitPattern, plain.strike.speed.bitPattern)
            XCTAssertEqual(played.strike.direction.x.bitPattern, plain.strike.direction.x.bitPattern)
            XCTAssertEqual(played.strike.direction.y.bitPattern, plain.strike.direction.y.bitPattern)
            XCTAssertEqual(played.strike.tipUp.bitPattern, plain.strike.tipUp.bitPattern)
            XCTAssertEqual(played.strike.tipSide.bitPattern, plain.strike.tipSide.bitPattern)
            XCTAssertEqual(played.strike.elevation.bitPattern, plain.strike.elevation.bitPattern)
            XCTAssertEqual(TestShots.solve(played).contentHash, TestShots.solve(plain).contentHash,
                           "the house cue must leave the recording unchanged at \(power) m/s")
        }
    }

    func testHouseCalmTopIsTheSoftestBreak() {
        // The calm zone ends at the swing that launches the softest break, and every authored shot is inside it.
        XCTAssertEqual(calmTopPower, PlayerShotSpeed.rackBreak.lowerBound, accuracy: 1e-12)
        XCTAssertGreaterThan(calmTopPower, 6.60, "The Called Break's window reaches 6.60 m/s and must stay calm")
        XCTAssertGreaterThanOrEqual(StrokeModel.zones(cue: house, bridge: StrokeModel.mechanicalBridge).calmTopSwing,
                                    house.comfortableTopSwing, "the mechanical bridge does not shorten the calm zone")
    }

    func testTheBreakHasItsOwnCalmZone() {
        let ordinary = StrokeModel.zones(cue: house, bridge: StrokeModel.automaticBridge)
        let breakZones = StrokeModel.zones(cue: house, bridge: StrokeModel.automaticBridge, isBreak: true)
        XCTAssertEqual(breakZones.calmTopSwing / ordinary.calmTopSwing, StrokeModel.breakCalmFactor, accuracy: 1e-12)
        // Part-way up the break range: above the default break (11 m/s, ShowpieceModel.power), below the hardest.
        let range = PlayerShotSpeed.rackBreak
        XCTAssertGreaterThan(breakZones.calmTopPower, 11)
        XCTAssertLessThan(breakZones.calmTopPower, range.upperBound)
        XCTAssertGreaterThan(breakZones.calmTopPower, range.lowerBound + (range.upperBound - range.lowerBound) / 3)
        // A tapped break at the default power: no drift at all, so nothing to scold.
        XCTAssertTrue(delivery(power: 11, wander: nil, isBreak: true).isZero)
        XCTAssertFalse(delivery(power: 11, wander: nil, isBreak: true).warm)
        // A finger break that stays in the groove is just as calm.
        XCTAssertTrue(delivery(power: 11, wander: StrokeModel.steadyWander * 0.9, isBreak: true).isZero)
        // The hardest break is still warm and still drifts.
        let hardest = delivery(power: range.upperBound, wander: nil, isBreak: true)
        XCTAssertTrue(hardest.warm)
        XCTAssertFalse(hardest.isZero)
        // The same power as an ordinary shot is warm: only a break gets the body's longer stroke.
        XCTAssertTrue(delivery(power: 11, wander: nil).warm)
        // The strike's rule and the bar's are the same function.
        XCTAssertEqual(StrokeModel.strikeZones(cue: house, bridge: StrokeModel.automaticBridge, stance: nil,
                                               authored: false, isBreak: true), breakZones)
    }

    func testALongBridgeRaisesTheCalmTop() {
        let auto = StrokeModel.zones(cue: house, bridge: StrokeModel.automaticBridge).calmTopSwing
        let longest = StrokeModel.zones(cue: house, bridge: StrokeModel.bridgeRange.upperBound).calmTopSwing
        XCTAssertEqual(longest / auto, (StrokeModel.bridgeRange.upperBound / StrokeModel.automaticBridge).squareRoot(),
                       accuracy: 1e-12)
        // Never past the longest bridge in range, whatever length is passed.
        XCTAssertEqual(StrokeModel.zones(cue: house, bridge: 2).calmTopSwing, longest, accuracy: 1e-12)
        // A power that is warm off the automatic bridge is calm off a long one...
        let between = (CueProfile.power(forSwing: auto) + CueProfile.power(forSwing: longest)) / 2
        XCTAssertTrue(delivery(power: between, wander: nil).warm)
        XCTAssertFalse(delivery(power: between, wander: nil, bridge: StrokeModel.bridgeRange.upperBound).warm)
        // ...and the long lever still moves the tip further for the same wander (the trade).
        let short = delivery(power: 3, wander: 0.06), long = delivery(power: 3, wander: 0.06, bridge: 0.32)
        XCTAssertGreaterThan(abs(long.tipSideError), abs(short.tipSideError))
        // The rest gets no raise: its own rung sets how hard a stroke over its head can go.
        let rest = Stance(rung: .rest, raisedOver: nil, reach: 0, rail: .head, standing: Vec2(-Reach.railOuter, 0))
        XCTAssertEqual(StrokeModel.zones(cue: house, bridge: StrokeModel.mechanicalBridge, stance: rest).calmTopSwing,
                       house.comfortableTopSwing * Stance.Rung.rest.swingFactor, accuracy: 1e-12)
    }

    // MARK: The groove

    func testAStrokeInsideTheGrooveIsStraight() {
        let groove = StrokeModel.steadyWander
        // Calm: anywhere inside the groove is no drift at all, either side.
        for w in [0, groove * 0.5, -groove * 0.5, groove, -groove] {
            XCTAssertTrue(delivery(power: 3, wander: w).isZero, "calm wander \(w) inside the groove drifted")
        }
        // Warm: inside the groove a finger plays exactly as the keys do.
        let keys = delivery(power: 11, wander: nil)
        for w in [0, groove * 0.5, -groove * 0.5] {
            let finger = delivery(power: 11, wander: w)
            XCTAssertEqual(finger.aimError, keys.aimError, accuracy: 1e-15)
            XCTAssertEqual(finger.tipSideError, keys.tipSideError, accuracy: 1e-15)
        }
        // Past the groove's edge only the part outside counts.
        let a = delivery(power: 3, wander: groove + 0.01), b = delivery(power: 3, wander: groove + 0.02)
        XCTAssertFalse(a.isZero)
        XCTAssertEqual(b.aimError / a.aimError, 2, accuracy: 1e-9)
        // On a short stroke the drawn groove's floor widens it, and the finger is forgiven what it can see.
        let short = 60.0
        XCTAssertEqual(StrokeModel.grooveHalfWidth(strokeLength: short), StrokeModel.grooveFloor)
        XCTAssertEqual(StrokeModel.grooveShare(strokeLength: short), StrokeModel.grooveFloor / short, accuracy: 1e-15)
        XCTAssertEqual(StrokeModel.grooveShare(strokeLength: 400), groove, accuracy: 1e-15)
        var wide = record(0.04, power: 3)
        wide.grooveHalfWidth = StrokeModel.grooveShare(strokeLength: short)
        XCTAssertTrue(StrokeModel.delivery(power: 3, fraction: 0.2, record: wide, bridge: StrokeModel.automaticBridge,
                                           cue: house, authored: false).isZero)
        // The tracker hands the groove's share over with the stroke it measured.
        var t = StrokeTracker()
        for i in 0...30 {
            let k = Double(i) / 30
            t.add(.init(time: k * 0.6, depth: 0.3 * k, along: short * k, across: 2 * k, spot: nil))
        }
        let measured = t.record(power: 3, bridge: nil)
        XCTAssertEqual(measured?.grooveHalfWidth ?? 0, StrokeModel.grooveShare(strokeLength: short), accuracy: 1e-15)
        if let measured {
            XCTAssertTrue(StrokeModel.delivery(power: 3, fraction: 0.2, record: measured,
                                               bridge: StrokeModel.automaticBridge, cue: house, authored: false).isZero,
                          "two points off on a 60-point stroke is inside the drawn groove")
        }
    }

    // MARK: Drift

    func testPerfectlyStraightCalmStrokeHasNoDrift() {
        for authored in [false, true] {
            let d = delivery(power: 3, wander: 0, authored: authored)
            XCTAssertEqual(d.aimError, 0)
            XCTAssertEqual(d.tipSideError, 0)
            XCTAssertTrue(d.isZero)
        }
        // The fixed drift (keyboard, controller, VoiceOver, sliders) is zero anywhere in the calm zone.
        for p in stride(from: 0.5, through: calmTopPower, by: 0.25) {
            XCTAssertTrue(delivery(power: p, wander: nil).isZero, "fixed drift at \(p) m/s")
        }
        // And a straight finger stroke measures no wander.
        var t = StrokeTracker()
        for i in 0...30 {
            let k = Double(i) / 30
            t.add(.init(time: k * 0.6, depth: 0.3 * k, along: 200 * k, across: 0, spot: nil))
        }
        XCTAssertEqual(t.wander, 0)
    }

    func testDriftGrowsWithWander() {
        // Past the groove's edge (inside it the stroke is straight, testAStrokeInsideTheGrooveIsStraight).
        for (power, authored) in [(3.0, false), (3.0, true), (11.0, false), (11.0, true)] {
            var previous = -1.0
            for w in stride(from: StrokeModel.steadyWander + 0.01, through: 0.3, by: 0.01) {
                let d = delivery(power: power, wander: w, authored: authored)
                XCTAssertGreaterThan(abs(d.aimError), previous, "aim drift did not grow at wander \(w), \(power) m/s")
                previous = abs(d.aimError)
            }
        }
        // The side follows the wander: the finger (rear hand) to the right turns the cue and the tip to the left.
        let right = delivery(power: 11, wander: 0.05), left = delivery(power: 11, wander: -0.05)
        XCTAssertGreaterThan(right.aimError, 0)
        XCTAssertLessThan(right.tipSideError, 0)
        XCTAssertLessThan(left.aimError, 0)
        // Past the calm zone the steady stroke's strain (always to the right) is added to either side's own wander,
        // so the two sides' drifts sum to twice the keys' fixed drift.
        XCTAssertEqual(left.aimError + right.aimError, 2 * delivery(power: 11, wander: nil).aimError, accuracy: 1e-15)
    }

    func testWarmDriftGrowsFasterThanTheSwing() {
        let top = calmTopPower
        var previous = (drift: 0.0, perSwing: 0.0)
        for p in stride(from: top + 0.5, through: PlayerShotSpeed.rackBreak.upperBound, by: 0.5) {
            let fixed = delivery(power: p, wander: nil)
            let swing = CueProfile.swing(forPower: p)
            let perSwing = abs(fixed.aimError) / swing
            XCTAssertGreaterThan(abs(fixed.aimError), previous.drift, "fixed drift did not grow at \(p) m/s")
            XCTAssertGreaterThan(perSwing, previous.perSwing, "drift did not outgrow the swing at \(p) m/s")
            previous = (abs(fixed.aimError), perSwing)
            XCTAssertTrue(fixed.warm)
            // A finger stroke grows with the warm swing too.
            XCTAssertGreaterThan(abs(delivery(power: p, wander: 0.03).aimError),
                                 abs(delivery(power: p - 0.5, wander: 0.03).aimError))
        }
    }

    func testSameInputSameDelivery() {
        let a = delivery(power: 12.5, wander: 0.041, bridge: 0.27)
        let b = delivery(power: 12.5, wander: 0.041, bridge: 0.27)
        XCTAssertEqual(a, b)
        // The same finger samples always measure the same stroke.
        func measured() -> StrokeRecord? {
            var t = StrokeTracker()
            for i in 0...40 {
                let k = Double(i) / 40
                t.add(.init(time: k, depth: 0.25 * sin(k * 3), along: 180 * sin(k * 3), across: 7 * sin(k * 11),
                            spot: Vec2(0.5 - 0.2 * k, 0.6)))
            }
            return t.record(power: 4, bridge: 0.2)
        }
        XCTAssertNotNil(measured())
        XCTAssertEqual(measured(), measured())
        // And a delivered strike is the same strike every time.
        var s1 = NextShot.shot(from: [Vec2(0.6, 0.6)], direction: Vec2(1, 0), speed: 12.5, tipUp: 0, tipSide: 0.01, seed: 3)
        var s2 = s1
        a.apply(to: &s1.strike, ballRadius: TestShots.ballRadius)
        b.apply(to: &s2.strike, ballRadius: TestShots.ballRadius)
        XCTAssertEqual(s1.strike.direction, s2.strike.direction)
        XCTAssertEqual(s1.strike.tipSide.bitPattern, s2.strike.tipSide.bitPattern)
    }

    // MARK: The bridge

    func testBridgeLengthScalesTheTipByTheLever() {
        // In the calm zone of free play the wobble does not depend on the bridge, so the tip's drift is in the ratio of
        // the levers (tip-to-bridge over bridge-to-hand) and the aim's in the inverse ratio of bridge-to-hand.
        let short = 0.20, long = 0.32
        let a = delivery(power: 3, wander: 0.04, bridge: short)
        let b = delivery(power: 3, wander: 0.04, bridge: long)
        XCTAssertEqual(b.tipSideError / a.tipSideError, StrokeModel.lever(bridge: long) / StrokeModel.lever(bridge: short),
                       accuracy: 1e-12)
        let h = StrokeModel.tipToRearHand
        XCTAssertEqual(b.aimError / a.aimError, (h - short) / (h - long), accuracy: 1e-12)
        XCTAssertGreaterThan(abs(b.tipSideError), abs(a.tipSideError), "a longer bridge moves the tip more")
        // A bridge shorter than the automatic one lowers the calm top, as the square root of the length.
        let auto = StrokeModel.zones(cue: house, bridge: StrokeModel.automaticBridge).calmTopSwing
        let shortest = StrokeModel.zones(cue: house, bridge: StrokeModel.bridgeRange.lowerBound).calmTopSwing
        XCTAssertEqual(shortest / auto, (StrokeModel.bridgeRange.lowerBound / StrokeModel.automaticBridge).squareRoot(),
                       accuracy: 1e-12)
        // A finger outside the range is clamped; no finger is the automatic bridge.
        XCTAssertEqual(StrokeModel.bridgeLength(finger: 0.01, mechanical: false), StrokeModel.bridgeRange.lowerBound)
        XCTAssertEqual(StrokeModel.bridgeLength(finger: 2, mechanical: false), StrokeModel.bridgeRange.upperBound)
        XCTAssertEqual(StrokeModel.bridgeLength(finger: nil, mechanical: false), StrokeModel.automaticBridge)
        XCTAssertEqual(StrokeModel.bridgeLength(finger: 0.15, mechanical: true), StrokeModel.mechanicalBridge)
    }

    // MARK: Authored shots stay makeable

    func testAuthoredCalmDriftStaysInsideTheBound() {
        for bridge in [StrokeModel.bridgeRange.lowerBound, StrokeModel.automaticBridge, StrokeModel.mechanicalBridge,
                       StrokeModel.bridgeRange.upperBound] {
            for w in [0.001, 0.02, 0.1, 0.5, 1.0, -1.0] {
                // The hardest authored shot with its window: 6.60 m/s.
                for power in [1.0, 4.0, 6.60] {
                    let d = delivery(power: power, wander: w, bridge: bridge, authored: true)
                    XCTAssertLessThan(abs(d.aimError), StrokeModel.authoredAimBound)
                    XCTAssertLessThan(abs(d.tipSideError), 0.0000625, "tip drift past 0.0625 mm")
                    // The stance case: every rung of the reach ladder, the cue raised over a ball or not, stays inside
                    // the same bound and never lowers the calm top.
                    for rung in Stance.Rung.allCases {
                        for raised in [nil, 5] as [Int?] {
                            let stance = Stance(rung: rung, raisedOver: raised, reach: 0, rail: .head,
                                                standing: Vec2(-Reach.railOuter, 0))
                            let s = StrokeModel.delivery(power: power, fraction: 0.5, record: record(w, power: power),
                                                         bridge: stance.bridge(hand: bridge), cue: house, authored: true,
                                                         stance: stance)
                            XCTAssertLessThan(abs(s.aimError), StrokeModel.authoredAimBound, "\(rung)")
                            XCTAssertLessThan(abs(s.tipSideError), 0.0000625, "tip drift past 0.0625 mm on \(rung)")
                            XCTAssertFalse(s.warm, "\(rung) put an authored power in the warm zone")
                        }
                    }
                }
            }
        }
    }

    // MARK: The tracker

    func testAQuickPushThroughTheBallPlaysTheBackswing() {
        var t = StrokeTracker()
        // Back to 0.2 m over half a second...
        for i in 0...20 { let k = Double(i) / 20; t.add(.init(time: 0.5 * k, depth: 0.2 * k, along: 150 * k, across: 0, spot: nil)) }
        XCTAssertEqual(t.powerDepth, 0.2, accuracy: 1e-12)
        // ...then quickly forward: the power holds at the backswing, and through the ball the stroke is delivered.
        for i in 1...10 {
            let k = Double(i) / 10
            t.add(.init(time: 0.5 + 0.2 * k, depth: 0.2 - 0.21 * k, along: 150 - 157 * k, across: 2 * k, spot: nil))
            if !t.delivered { XCTAssertEqual(t.powerDepth, 0.2, accuracy: 1e-12, "power must hold during the push") }
        }
        XCTAssertTrue(t.delivered)
        // A slow push is the player easing the power down: no shot, power follows the finger.
        var slow = StrokeTracker()
        for i in 0...20 { let k = Double(i) / 20; slow.add(.init(time: 0.5 * k, depth: 0.2 * k, along: 150 * k, across: 0, spot: nil)) }
        for i in 1...20 {
            let k = Double(i) / 20
            slow.add(.init(time: 0.5 + 2 * k, depth: 0.2 - 0.21 * k, along: 150 - 157 * k, across: 0, spot: nil))
        }
        XCTAssertFalse(slow.delivered)
        XCTAssertEqual(slow.powerDepth, 0.2 - 0.21, accuracy: 1e-12)
    }

    func testWanderIsMeasuredNearTheEndAndNormalisedByStrokeLength() {
        // The same shape at two screen sizes (a phone and an iPad) measures the same wander.
        func wander(scale: Double, endOffset: Double) -> Double {
            var t = StrokeTracker()
            for i in 0...30 {
                let k = Double(i) / 30
                // Early wobble well off the groove that is gone by the last third, then the end offset.
                let early = k < 0.5 ? 10 * scale * sin(k * .pi * 2) : 0
                let late = k > 0.8 ? endOffset * scale : 0
                t.add(.init(time: k, depth: 0.3 * k, along: 200 * scale * k, across: early + late, spot: nil))
            }
            return t.wander
        }
        XCTAssertEqual(wander(scale: 1, endOffset: 6), wander(scale: 2, endOffset: 6), accuracy: 1e-12)
        XCTAssertEqual(wander(scale: 1, endOffset: 6), 6.0 / 200, accuracy: 1e-12)
        XCTAssertEqual(wander(scale: 1, endOffset: 0), 0, "wobble early in the stroke is not the delivery")
        XCTAssertLessThan(wander(scale: 1, endOffset: -6), 0, "the side is kept")
    }

    func testPracticeRhythmSteadiesTheFinalStroke() {
        // Back-and-forth strokes every 0.6 s, then the final one in the same rhythm.
        func strokes(finalPeriod: Double) -> StrokeTracker {
            var t = StrokeTracker()
            var time = 0.0
            func leg(from a: Double, to b: Double, over d: Double) {
                for i in 1...10 {
                    let k = Double(i) / 10
                    let depth = a + (b - a) * k
                    t.add(.init(time: time + d * k, depth: depth, along: depth * 600, across: 0, spot: nil))
                }
                time += d
            }
            t.add(.init(time: 0, depth: 0, along: 0, across: 0, spot: nil))
            leg(from: 0, to: 0.15, over: 0.3)
            for _ in 0..<3 { leg(from: 0.15, to: 0.05, over: 0.3); leg(from: 0.05, to: 0.15, over: 0.3) }
            leg(from: 0.15, to: 0.05, over: finalPeriod / 2)
            leg(from: 0.05, to: 0.15, over: finalPeriod / 2)
            leg(from: 0.15, to: 0.10, over: 0.1)
            return t
        }
        XCTAssertGreaterThanOrEqual(strokes(finalPeriod: 0.6).practiceStrokes, 3)
        XCTAssertEqual(strokes(finalPeriod: 0.6).rhythmFactor, 2.0 / 3.0, accuracy: 1e-12, "matched rhythm: a third steadier")
        XCTAssertEqual(strokes(finalPeriod: 1.2).rhythmFactor, 1, "a broken rhythm gives no help")
        XCTAssertEqual(StrokeTracker().rhythmFactor, 1, "no practice, no change")
    }

    // MARK: The retry comparison

    func testComparisonSaysWhenTheStrokeWasStraighter() {
        let wild = delivery(power: 12, wander: 0.08), calmer = delivery(power: 12, wander: 0.01)
        XCTAssertEqual(RetryComparison.strokeChange(wild, calmer), .straighter)
        XCTAssertEqual(RetryComparison.strokeChange(calmer, wild), .wilder)
        XCTAssertNil(RetryComparison.strokeChange(calmer, calmer))
        XCTAssertNil(RetryComparison.strokeChange(nil, calmer))
    }

    // MARK: The drill

    @MainActor
    func testDrillJudgesAStraightAndACrookedReturn() {
        let p = PoolParameters()
        var layout = [Vec2](repeating: NextShot.offTable, count: 16)
        layout[0] = Vec2(NextShot.headLineX(parameters: p), p.tableWidth / 2)
        let straight = TrickSettings(aim: 0, power: StrokeDrill.startPower, tipUp: 0, tipSide: 0)
        let a = TestShots.attempt(start: layout, timeline: TestShots.shot(from: layout, straight), straight)
        guard case .back(let off, let grade) = StrokeDrill.judge(a) else { return XCTFail("a straight stroke comes back") }
        XCTAssertLessThan(off, 1e-6)
        XCTAssertEqual(grade, .deadStraight)
        // The same settings struck half a degree off line: the ball comes back well off the cue line.
        let crooked = TrickSettings(aim: 0.5, power: StrokeDrill.startPower, tipUp: 0, tipSide: 0)
        var b = TestShots.attempt(start: layout, timeline: TestShots.shot(from: layout, crooked), crooked)
        b = ShotAttempt(isBreak: false, breakSeed: 0, start: b.start, timeline: b.timeline, aim: 0, power: b.power,
                        powerRange: b.powerRange, tipUp: 0, tipSide: 0, elevation: 0, seed: b.seed, input: b.input,
                        surface: b.surface, table: b.table, generation: b.generation)
        guard case .back(let off2, let grade2) = StrokeDrill.judge(b) else { return XCTFail("still comes back") }
        XCTAssertGreaterThan(off2, StrokeDrill.deadStraight)
        XCTAssertNotEqual(grade2, .deadStraight)
        // Too soft to reach the far rail.
        let soft = TrickSettings(aim: 0, power: 0.5, tipUp: 0, tipSide: 0)
        let c = TestShots.attempt(start: layout, timeline: TestShots.shot(from: layout, soft), soft)
        XCTAssertEqual(StrokeDrill.judge(c), .noRail)
    }

    func testShootWithTheButtonOnlyIsOffOnAFreshInstall() {
        // The push through the ball is the game's own way to shoot: a missing key reads as off.
        let defaults = UserDefaults.standard
        let saved = defaults.object(forKey: GameSettings.buttonOnlyKey)
        defaults.removeObject(forKey: GameSettings.buttonOnlyKey)
        XCTAssertFalse(GameSettings.shootWithButtonOnly)
        defaults.set(true, forKey: GameSettings.buttonOnlyKey)
        XCTAssertTrue(GameSettings.shootWithButtonOnly)
        if let saved { defaults.set(saved, forKey: GameSettings.buttonOnlyKey) } else {
            defaults.removeObject(forKey: GameSettings.buttonOnlyKey)
        }
    }

    // MARK: Did the stroke change what happened

    func testTheResultLineComparesTheShotAsPlayedAndAsAimed() {
        typealias O = StrokeEffect.Outcome
        let base = O(firstBall: 3, pocketed: [3], scratched: false)
        XCTAssertNil(StrokeEffect.change(actual: base, straight: base, isBreak: false), "same outcome: nothing to say")
        XCTAssertEqual(StrokeEffect.change(actual: O(firstBall: 5, pocketed: [], scratched: false), straight: base,
                                           isBreak: false), .firstBall)
        XCTAssertEqual(StrokeEffect.change(actual: O(firstBall: 3, pocketed: [], scratched: false), straight: base,
                                           isBreak: false), .potMissed)
        XCTAssertEqual(StrokeEffect.change(actual: O(firstBall: 3, pocketed: [3], scratched: true), straight: base,
                                           isBreak: false), .scratched)
        XCTAssertEqual(StrokeEffect.change(actual: O(firstBall: 3, pocketed: [3, 7], scratched: false), straight: base,
                                           isBreak: false), .potMade)
        XCTAssertEqual(StrokeEffect.change(actual: base, straight: O(firstBall: 3, pocketed: [3], scratched: true),
                                           isBreak: false), .scratchAvoided)
        // A break's pots are a scatter the smallest change reshuffles: only its first ball is put down to the stroke.
        XCTAssertNil(StrokeEffect.change(actual: O(firstBall: 1, pocketed: [2, 9], scratched: true),
                                         straight: O(firstBall: 1, pocketed: [4], scratched: false), isBreak: true))
        XCTAssertEqual(StrokeEffect.change(actual: O(firstBall: 2, pocketed: [], scratched: false),
                                           straight: O(firstBall: 1, pocketed: [], scratched: false), isBreak: true),
                       .firstBall)
        // The words: the turn, what the aimed shot would have done, and why past the calm zone.
        let calm = delivery(power: 3, wander: 0.06)
        let line = StrokeWords.resultLine(calm, change: .potMissed)
        XCTAssertTrue(line.hasPrefix(StrokeWords.turnLine(calm) ?? "-"))
        XCTAssertTrue(line.contains(StrokeWords.consequence(.potMissed) ?? "-"))
        XCTAssertNil(StrokeWords.warmReason(calm), "no hard-swing reason inside the calm zone")
        XCTAssertNotNil(StrokeWords.warmReason(delivery(power: 11, wander: 0.06)))
        XCTAssertNil(StrokeWords.turnLine(delivery(power: 3, wander: 0)), "a straight stroke turned nothing")
    }

    func testTheShotAsAimedTakesTheStrokeBackOff() {
        var layout = [Vec2](repeating: NextShot.offTable, count: 16)
        layout[0] = Vec2(0.6, 0.6); layout[1] = Vec2(1.5, 0.65)
        let s = TrickSettings(aim: 3, power: 9, tipUp: 0, tipSide: 0.004)
        let aimed = TestShots.attempt(start: layout, timeline: TestShots.shot(from: layout, s), s)
        let d = delivery(power: 9, wander: 0.08)
        XCTAssertFalse(d.isZero)
        var drifted = aimed.input
        d.apply(to: &drifted.strike, ballRadius: TestShots.ballRadius)
        var played = ShotAttempt(isBreak: false, breakSeed: 0, start: aimed.start, timeline: aimed.timeline,
                                 aim: aimed.aim, power: aimed.power, powerRange: aimed.powerRange, tipUp: aimed.tipUp,
                                 tipSide: aimed.tipSide, elevation: aimed.elevation, seed: aimed.seed, input: drifted,
                                 surface: aimed.surface, table: aimed.table, generation: aimed.generation)
        XCTAssertNil(StrokeEffect.straightInput(of: played), "no stroke: nothing to take back off")
        played.stroke = d
        guard let straight = StrokeEffect.straightInput(of: played) else { return XCTFail("a drifted stroke") }
        XCTAssertEqual(straight.strike.direction.x, aimed.input.strike.direction.x, accuracy: 1e-12)
        XCTAssertEqual(straight.strike.direction.y, aimed.input.strike.direction.y, accuracy: 1e-12)
        XCTAssertEqual(straight.strike.tipSide, aimed.input.strike.tipSide, accuracy: 1e-15)
        XCTAssertEqual(straight.strike.speed, aimed.input.strike.speed, accuracy: 1e-15)
        XCTAssertEqual(straight.parameters.modelGeneration, aimed.generation)
    }
}
