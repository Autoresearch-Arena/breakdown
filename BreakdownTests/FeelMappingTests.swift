// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: FeelMapping (App/FeelMapping.swift), the one place that turns the impacts crossed in a frame into the sound
//          and touch cues. Checks each rule the file states: the impulse-to-strength curve (0 at rest, full at 2 N s,
//          never falling as the impulse grows), the break collapsing into one crack plus at most three quieter trailing
//          clicks, ordinary contacts capped at two clicks a frame, inaudible contacts dropped, at most two cushion thumps
//          a frame, the cue strike as a tock, and one pocket rattle a frame whose strength comes from the arrival speed.
//          Also a real solved break, frame by frame, so the collapse holds on the solver's own events.
// SRP/DRY check: Pass - checks only; the limits are read from FeelMapping's own named constants, not retyped.
@testable import Breakdown
import BreakdownLensModel
import BreakdownTimeline
import XCTest

final class FeelMappingTests: XCTestCase {
    private func contact(_ impulse: Double, t: Double = 0) -> LensEvent {
        LensEvent(time: t, kind: .ballBall, point: .zero, normal: Vec2(1, 0), normalImpulse: impulse,
                  balls: [TestShots.ball(0, before: 2, after: 1), TestShots.ball(1, before: 0, after: 1)])
    }

    private func cushion(_ impulse: Double) -> LensEvent {
        LensEvent(time: 0, kind: .cushion, point: .zero, normal: Vec2(0, 1), normalImpulse: impulse,
                  balls: [TestShots.ball(2, before: 1, after: 0.8)])
    }

    private func drop(speed: Double) -> LensEvent {
        LensEvent(time: 0, kind: .pocket, point: .zero, normal: Vec2(1, 0),
                  balls: [TestShots.ball(3, before: speed, after: 0)], pocket: 1)
    }

    /// The impulse whose strength is exactly s (the inverse of the 0.6-power curve over 2 N s).
    private func impulse(forStrength s: Double) -> Double { 2 * pow(s, 1 / 0.6) }

    func testStrengthCurve() {
        XCTAssertEqual(FeelMapping.strength(impulse: 0), 0)
        XCTAssertEqual(FeelMapping.strength(impulse: -1), 0, "a negative impulse is clamped, never a negative strength")
        XCTAssertEqual(FeelMapping.strength(impulse: 2), 1, accuracy: 1e-12)
        XCTAssertEqual(FeelMapping.strength(impulse: 50), 1, "anything past 2 N s is full strength")
        var previous = -1.0
        for i in 0...300 {
            let s = FeelMapping.strength(impulse: Double(i) * 0.01)
            XCTAssertGreaterThanOrEqual(s, previous, "strength fell as the impulse grew at \(Double(i) * 0.01) N s")
            XCTAssertTrue((0...1).contains(s))
            previous = s
        }
    }

    func testABreakBurstIsOneCrackAndAFewQuieterClicks() {
        let impulses = [2.0, 1.2, 0.9, 0.6, 0.4, 0.3]
        let cues = FeelMapping.cues(for: impulses.map { contact($0) })
        let cracks = cues.filter { $0.kind == .crack }
        XCTAssertEqual(cracks.count, 1)
        XCTAssertEqual(cracks.first?.strength ?? 0, 1, accuracy: 1e-12, "the crack carries the hardest contact")
        XCTAssertEqual(cracks.first?.delay, 0)
        let clicks = cues.filter { $0.kind == .click }
        XCTAssertEqual(clicks.count, FeelMapping.maxScatter)
        // Each trailing click is the next-hardest contact at 60 percent, a little later than the one before.
        let sorted = impulses.map { FeelMapping.strength(impulse: $0) }.sorted(by: >)
        for (i, c) in clicks.enumerated() {
            XCTAssertEqual(c.strength, sorted[i + 1] * 0.6, accuracy: 1e-12)
            XCTAssertGreaterThan(c.delay, i == 0 ? 0 : clicks[i - 1].delay)
        }
    }

    func testABurstLedByASoftContactIsNotACrack() {
        // Three contacts, but the hardest is just under the crack threshold: ordinary clicks, at most two.
        let lead = impulse(forStrength: FeelMapping.crackMinStrength * 0.95)
        let cues = FeelMapping.cues(for: [contact(lead), contact(lead * 0.8), contact(lead * 0.6)])
        XCTAssertFalse(cues.contains { $0.kind == .crack })
        XCTAssertEqual(cues.filter { $0.kind == .click }.count, FeelMapping.maxPerKind)
        // Two hard contacts are not a break either: the burst needs crackMinContacts.
        let pair = FeelMapping.cues(for: (0..<(FeelMapping.crackMinContacts - 1)).map { _ in contact(2) })
        XCTAssertFalse(pair.contains { $0.kind == .crack })
    }

    func testInaudibleContactsAreDropped() {
        let quiet = impulse(forStrength: FeelMapping.floor * 0.5)
        XCTAssertTrue(FeelMapping.cues(for: [contact(quiet)]).isEmpty)
        XCTAssertTrue(FeelMapping.cues(for: [cushion(quiet)]).isEmpty)
        // Every cue that is played is at least as loud as the floor.
        let mixed = [contact(quiet), contact(0.5), cushion(quiet), cushion(0.4)]
        XCTAssertTrue(FeelMapping.cues(for: mixed).allSatisfy { $0.strength >= FeelMapping.floor })
    }

    func testCushionsAreCappedStrongestFirst() {
        let cues = FeelMapping.cues(for: [cushion(0.2), cushion(1.5), cushion(0.7), cushion(1.0)])
        let thumps = cues.filter { $0.kind == .cushion }
        XCTAssertEqual(thumps.count, FeelMapping.maxPerKind)
        XCTAssertEqual(thumps.first?.strength ?? 0, FeelMapping.strength(impulse: 1.5), accuracy: 1e-12)
        XCTAssertEqual(thumps.last?.strength ?? 0, FeelMapping.strength(impulse: 1.0), accuracy: 1e-12)
    }

    func testCueStrikeIsATock() {
        let strike = LensEvent(time: 0, kind: .cueStrike, point: .zero, normal: Vec2(1, 0), normalImpulse: 0.8,
                               balls: [TestShots.ball(0, before: 0, after: 4)])
        let cues = FeelMapping.cues(for: [strike])
        XCTAssertEqual(cues.count, 1)
        XCTAssertEqual(cues.first?.kind, .tock)
        XCTAssertEqual(cues.first?.strength ?? 0, FeelMapping.strength(impulse: 0.8), accuracy: 1e-12)
    }

    func testOnePocketRattleFromArrivalSpeed() {
        // Strength is speed / 2 m/s, held between 0.4 (a ball that trickles in is still heard) and 1.
        XCTAssertEqual(FeelMapping.pocketStrength(drop(speed: 0.2)), 0.4, accuracy: 1e-12)
        XCTAssertEqual(FeelMapping.pocketStrength(drop(speed: 1.2)), 0.6, accuracy: 1e-12)
        XCTAssertEqual(FeelMapping.pocketStrength(drop(speed: 3)), 1, accuracy: 1e-12)
        let cues = FeelMapping.cues(for: [drop(speed: 0.5), drop(speed: 1.6), drop(speed: 1.0)])
        // One pocket cue, then the settling knocks the sound stream added (timed from that same fastest drop).
        let drops = cues.filter { $0.kind == .pocket }
        XCTAssertEqual(drops.count, 1, "several drops in one frame are one rattle")
        XCTAssertEqual(drops.first?.strength ?? 0, 0.8, accuracy: 1e-12, "the fastest arrival decides")
        XCTAssertTrue(cues.allSatisfy { $0.kind == .pocket || $0.kind == .knock }, "only the drop and its knocks")
    }

    func testARealBreakNeverFloodsAFrame() {
        let tl = TestShots.breakShot()
        // Walk the break in 60 frames a second, as the screen does, handing FeelMapping the events each frame crosses.
        let frame = 1.0 / 60
        var t = 0.0
        var sawCrack = false
        while t < tl.duration {
            let crossed = tl.events.filter { $0.time >= t && $0.time < t + frame }
            let cues = FeelMapping.cues(for: crossed)
            // The most one frame can ever play: one crack and its scatter (or two clicks), two thumps, a tock, a rattle.
            let most = 1 + FeelMapping.maxScatter + FeelMapping.maxPerKind + 1 + 1
            XCTAssertLessThanOrEqual(cues.count, most, "frame at \(t) s played \(cues.count) cues")
            XCTAssertTrue(cues.allSatisfy { (0...1).contains($0.strength) && $0.delay >= 0 })
            XCTAssertLessThanOrEqual(cues.filter { $0.kind == .crack }.count, 1)
            if cues.contains(where: { $0.kind == .crack }) { sawCrack = true }
            t += frame
        }
        // The rack bursting apart is the one moment the mapping exists to collapse: some frame must be the crack.
        XCTAssertTrue(sawCrack, "a 10 m/s break produced no crack in any frame")
    }
}
