// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: Spec test 16 (docs/2026-11-02-breakdown-spec.md): every caption template fires only on events that meet its
//          rule, and never on events without the fields it needs. Two halves.
//          1. Hand-made events on both sides of every gate in CaptionEngine (App/Captions.swift): a ball-ball contact
//             needs two balls, a mover faster than 0.4 m/s and some energy; a rail hit needs more than 0.8 m/s; a post
//             more than 0.5 m/s; a jaw or knuckle is always worth saying; a pin knocked down always; skid-to-roll needs
//             sliding to rolling above 0.7 m/s, and off cloth also the recorded sliding segment that closes at the event
//             (no made-up skid time); a drop always; the cue strike whenever it sends the ball off faster than
//             0.05 m/s (0.7.5: a strike on a still table is not captioned); the two generation-two kinds never (yet).
//          2. Real solved shots (a break and a straight pot, on cloth, ice and the Moon): every caption's event (its id is
//             the event's index) meets its rule, every event that meets a rule has its caption, and captions come out in
//             clock order.
//          The rules are restated here on purpose, from the spec and the engine's comments: a test that read them back
//          out of the engine could not catch the engine drifting from them.
// Edited: Claude Opus 5.5 High, 21-November-2026 (version 0.7.0: the rules restated for what the engine now says: a
//          rim skip and a jam are captioned; take-off and landing are captioned as impacts and flying off the table as a
//          cushion moment; a skid-to-roll is also captioned below 0.7 m/s when its slide bent two degrees or more. New
//          checks: RailKeep against the flat wall at generation one and the tilted rail's bounds at generation two; the
//          jam's energy unit; throw's gates; the rail's spin words; the strike's spin words from the recorded spin.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 rules-lens: the strike rule gains its speed gate; a
//          zero-speed strike makes no caption; on bumper pool and bar billiards no caption names a ball by number,
//          says "pocket" or "the cue ball", and each says its own words (the bumper, the cup, the hole, a peg and what
//          it costs); the pool table's captions are the same with the table and striker passed as without.)
// SRP/DRY check: Pass - checks only. The wording of each caption is the engine's; only titles that decide which template
//          fired (jaw or knuckle) are compared, through the same String(localized:) lookup the engine uses.
@testable import Breakdown
import BreakdownLensModel
import BreakdownPhysics
import BreakdownRules
import BreakdownTimeline
import Foundation
import XCTest

final class CaptionEngineTests: XCTestCase {
    // MARK: The rules, restated

    /// The caption accent the rule says this event earns, or nil when no template may fire on it.
    private func expectedAccent(_ e: LensEvent, in tl: Timeline, surface: PlaySurface) -> CaptionAccent? {
        switch e.kind {
        case .cueStrike:
            // Faster than 0.05 m/s off the tip (0.7.5): a strike that moved nothing is not worth a caption.
            guard let b = e.balls.first else { return nil }
            return b.velocityAfter.length > 0.05 ? .strike : nil
        case .ballBall:
            guard e.balls.count == 2 else { return nil }
            let a = e.balls[0], b = e.balls[1]
            let mover = a.velocityBefore.length >= b.velocityBefore.length ? a : b
            return mover.velocityBefore.length > 0.4 && a.energyBefore + b.energyBefore > 0 ? .impact : nil
        case .cushion:
            guard let b = e.balls.first else { return nil }
            switch e.edge {
            case .post: return b.velocityBefore.length > 0.5 ? .cushion : nil
            case .jaw, .knuckle: return .cushion
            case .rail: return b.velocityBefore.length > 0.8 ? .cushion : nil
            }
        case .pinDown:
            return e.balls.isEmpty ? nil : .impact
        case .phaseTransition:
            // A jump: take-off and landing are slate impacts; leaving the table is a cushion moment.
            switch e.flight {
            case .takeOff, .landing: return e.balls.isEmpty ? nil : .impact
            case .offTable: return e.balls.isEmpty ? nil : .cushion
            case .none: break
            }
            guard e.phaseFrom == .sliding, e.phaseTo == .rolling, let b = e.balls.first else { return nil }
            let closing = tl.segments.indices.contains(b.ball)
                ? tl.segments[b.ball].last(where: { $0.phase == .sliding && abs($0.t1 - e.time) < 1e-9 }) : nil
            // Fast enough to be worth saying, or its slide bent two degrees or more (a masse often rolls on slowly).
            guard b.velocityAfter.length > 0.7 || closing.map(bentEnough) == true else { return nil }
            if surface == .cloth { return .friction }
            // Off cloth the caption quotes the skid's real length, so the sliding segment ending here must be recorded.
            return closing != nil ? .friction : nil
        case .pocket:
            return e.balls.isEmpty ? nil : .pocket
        case .rimSkip:
            return e.balls.isEmpty ? nil : .pocket
        case .settledInContact:
            return e.balls.isEmpty ? nil : .impact
        }
    }

    /// The bend rule, restated: a sliding segment whose velocity (v0 + a t, constant a) turned two degrees or more
    /// without the ball dropping under 0.15 m/s on the way.
    private func bentEnough(_ seg: BallSegment) -> Bool {
        guard seg.phase == .sliding, seg.t1.isFinite, seg.t1 > seg.t0 else { return false }
        let T = seg.t1 - seg.t0
        let v0 = seg.velocity0, a = seg.acceleration
        let v1 = v0 + a * T
        var slowest = min(v0.length, v1.length)
        let aa = a.lengthSquared
        if aa > 1e-18 {
            let t = min(T, max(0, -v0.dot(a) / aa))
            slowest = min(slowest, (v0 + a * t).length)
        }
        guard slowest >= 0.15 else { return false }
        let turn = atan2(v0.x * v1.y - v0.y * v1.x, v0.dot(v1)) * 180 / Double.pi
        return abs(turn) >= 2
    }

    // MARK: 1. Hand-made events either side of each gate

    private func captions(_ events: [LensEvent], surface: PlaySurface = .cloth, cue: [BallSegment]? = nil) -> [Caption] {
        CaptionEngine.make(from: TestShots.recording(events, cueSegments: cue), surface: surface)
    }

    private func ballBall(mover: Double, other: Double = 0, t: Double = 0.5) -> LensEvent {
        LensEvent(time: t, kind: .ballBall, point: .zero, normal: Vec2(1, 0), normalImpulse: 0.3,
                  balls: [TestShots.ball(0, before: mover, after: mover * 0.1),
                          TestShots.ball(1, before: other, after: mover * 0.9)])
    }

    private func cushion(_ speed: Double, edge: CushionEdge = .rail, t: Double = 0.5) -> LensEvent {
        LensEvent(time: t, kind: .cushion, point: .zero, normal: Vec2(-1, 0), normalImpulse: 0.2,
                  balls: [TestShots.ball(1, before: speed, after: -speed * 0.8)], pocket: edge == .rail ? -1 : 3,
                  edge: edge, feature: edge == .post ? 0 : -1)
    }

    private func skidToRoll(_ speed: Double, t: Double = 0.5, from: MotionPhase = .sliding,
                            to: MotionPhase = .rolling) -> LensEvent {
        LensEvent(time: t, kind: .phaseTransition, point: .zero, normal: Vec2(1, 0),
                  balls: [TestShots.ball(0, before: speed, after: speed)], phaseFrom: from, phaseTo: to)
    }

    func testBallBallNeedsTwoBallsAFastMoverAndEnergy() {
        XCTAssertEqual(captions([ballBall(mover: 0.41)]).map(\.accent), [.impact])
        XCTAssertTrue(captions([ballBall(mover: 0.39)]).isEmpty, "a nudge at walking pace is not captioned")
        // The mover is whichever ball was faster: the gate reads that one, not the first listed.
        XCTAssertEqual(captions([ballBall(mover: 0.1, other: 0.6)]).count, 1)
        // Without a second ball there is nothing to hand energy to.
        let lone = LensEvent(time: 0.5, kind: .ballBall, point: .zero, normal: Vec2(1, 0),
                             balls: [TestShots.ball(0, before: 2, after: 1)])
        XCTAssertTrue(captions([lone]).isEmpty)
        // No energy before the contact: no share can be worked out, so no caption.
        let still = ImpactBall(ball: 1, velocityBefore: Vec2(1, 0), velocityAfter: .zero, omegaBefore: .zero,
                               omegaAfter: .zero, translationalBefore: 0, rotationalBefore: 0, translationalAfter: 0,
                               rotationalAfter: 0)
        let empty = LensEvent(time: 0.5, kind: .ballBall, point: .zero, normal: Vec2(1, 0), balls: [still, still])
        XCTAssertTrue(captions([empty]).isEmpty)
    }

    func testCushionGates() {
        XCTAssertEqual(captions([cushion(0.81)]).map(\.accent), [.cushion])
        XCTAssertTrue(captions([cushion(0.79)]).isEmpty, "a slow rail touch is not captioned")
        XCTAssertEqual(captions([cushion(0.51, edge: .post)]).count, 1)
        XCTAssertTrue(captions([cushion(0.49, edge: .post)]).isEmpty)
        // A jaw or a knuckle answers "why didn't that go in?", so even a slow one is said, with its own title.
        let jaw = captions([cushion(0.1, edge: .jaw)])
        XCTAssertEqual(jaw.map(\.title), [String(localized: "Off the jaw")])
        let knuckle = captions([cushion(0.1, edge: .knuckle)])
        XCTAssertEqual(knuckle.map(\.title), [String(localized: "Clipped the point")])
    }

    func testSkidToRollOnCloth() {
        XCTAssertEqual(captions([skidToRoll(0.71)]).map(\.accent), [.friction])
        XCTAssertTrue(captions([skidToRoll(0.69)]).isEmpty)
        XCTAssertTrue(captions([skidToRoll(2, from: .rolling, to: .stationary)]).isEmpty, "only sliding to rolling")
        XCTAssertTrue(captions([skidToRoll(2, from: .rolling, to: .sliding)]).isEmpty)
    }

    func testSkidToRollOffClothNeedsTheRecordedSkid() {
        // Without a sliding segment that closes at the event, the caption would have to invent the skid time: none.
        XCTAssertTrue(captions([skidToRoll(1.5)], surface: .ice).isEmpty)
        // With the recorded skid (sliding from 0.2 s to the event at 0.5 s), the caption fires.
        let skid = BallSegment(t0: 0.2, t1: 0.5, phase: .sliding, position0: Vec2(0.4, 0.6), velocity0: Vec2(1.5, 0),
                               acceleration: .zero, omega0: .zero, alphaXY: .zero, spinDecay: 9,
                               radius: TestShots.ballRadius, orientation0: .identity)
        let before = TestShots.still(Vec2(0.4, 0.6))
        var waiting = before
        waiting.t1 = 0.2
        let cue = [waiting, skid, TestShots.still(Vec2(0.85, 0.6))]
        XCTAssertEqual(captions([skidToRoll(1.5)], surface: .ice, cue: cue).map(\.accent), [.friction])
        XCTAssertEqual(captions([skidToRoll(1.5)], surface: .moon, cue: cue).map(\.accent), [.friction])
    }

    func testAlwaysAndNeverTemplates() {
        let strike = LensEvent(time: 0, kind: .cueStrike, point: .zero, normal: Vec2(1, 0), normalImpulse: 0.5,
                               balls: [TestShots.ball(0, before: 0, after: 0.2)])
        XCTAssertEqual(captions([strike]).map(\.accent), [.strike], "the strike is always captioned, however soft")
        let drop = LensEvent(time: 1, kind: .pocket, point: .zero, normal: Vec2(1, 0),
                             balls: [TestShots.ball(1, before: 0.05, after: 0)], pocket: 3)
        XCTAssertEqual(captions([drop]).map(\.accent), [.pocket], "a drop is always captioned, however slow")
        let pin = LensEvent(time: 1, kind: .pinDown, point: .zero, normal: Vec2(1, 0), balls: [TestShots.ball(1, before: 0.3, after: 0.25)],
                            feature: 0)
        XCTAssertEqual(captions([pin]).count, 1)
        // The newer kinds have their own words: a rim skip is never captioned as a drop, a jam has its own line.
        let skip = LensEvent(time: 1, kind: .rimSkip, point: .zero, normal: Vec2(1, 0),
                             balls: [TestShots.ball(1, before: 3, after: 2.85)], pocket: 3,
                             entry: PocketEntry(speed: 3, sine: 0.1, cosine: 0.995))
        let jam = LensEvent(time: 1, kind: .settledInContact, point: .zero, normal: Vec2(1, 0),
                            balls: [TestShots.ball(1, before: 0.01, after: 0), TestShots.ball(2, before: 0.01, after: 0)],
                            energyRemoved: 0.0001)
        XCTAssertEqual(captions([skip]).map(\.title), [String(localized: "Too fast for the pocket")])
        XCTAssertEqual(captions([jam]).map(\.title), [String(localized: "Wedged and settled")])
    }

    func testCaptionsKeepTheEventIndexAndClockOrder() {
        let events = [cushion(1.2, t: 0.9), ballBall(mover: 2, t: 0.3), skidToRoll(1.0, t: 0.6)]
        let tl = TestShots.recording(events)
        let made = CaptionEngine.make(from: tl, surface: .cloth)
        XCTAssertEqual(made.map(\.time), made.map(\.time).sorted())
        for c in made { XCTAssertEqual(tl.events[c.id].time, c.time, "a caption's id is its event's index") }
    }

    // MARK: 2. Real solved shots

    func testRealShotsCaptionExactlyTheEventsThatMeetTheRules() {
        for surface in [PlaySurface.cloth, .ice, .moon] {
            for (name, tl) in [("break", TestShots.breakShot(on: surface)), ("straight pot", TestShots.straightPot(on: surface))] {
                let label = "\(name) on \(surface.rawValue)"
                let made = CaptionEngine.make(from: tl, surface: surface)
                XCTAssertFalse(made.isEmpty, "\(label): no captions at all")
                XCTAssertEqual(made.map(\.time), made.map(\.time).sorted(), "\(label): not in clock order")
                let byID = Dictionary(uniqueKeysWithValues: made.map { ($0.id, $0) })
                XCTAssertEqual(byID.count, made.count, "\(label): two captions for one event")
                for (i, e) in tl.events.enumerated() {
                    let want = expectedAccent(e, in: tl, surface: surface)
                    XCTAssertEqual(byID[i]?.accent, want, "\(label): event \(i) (\(e.kind), t \(e.time))")
                    if let c = byID[i] {
                        XCTAssertEqual(c.time, e.time, label)
                        XCTAssertFalse(c.title.isEmpty || c.detail.isEmpty || c.equation.isEmpty, label)
                    }
                }
            }
        }
    }

    // MARK: 3. The 0.7.0 words

    func testRailKeepMatchesTheFlatWallAndStaysInsideTheTiltedRailsBounds() {
        // Generation one is the flat wall: head on, a rolling ball keeps exactly the restitution.
        var flat = PoolParameters()
        flat.modelGeneration = 1
        XCTAssertEqual(RailKeep.share(at: 2, parameters: flat), flat.cushionRestitution, accuracy: 1e-12)
        // Generation two: the tilted normal alone gives (1 + e) cos^2 - 1 of the speed back; the nose's friction on a
        // rolling ball can only add to that (it pushes the ball out and up), and nothing gives back more than it got.
        let p = PoolParameters()
        let vIn = 2 * p.railContactCosine
        let e = min(p.cushionRestitution, max(p.railRestitutionFloor, p.cushionRestitution - p.railRestitutionSlope * vIn))
        let bare = (1 + e) * p.railContactCosine * p.railContactCosine - 1
        let share = RailKeep.share(at: 2, parameters: p)
        XCTAssertGreaterThanOrEqual(share, bare - 1e-9)
        XCTAssertLessThan(share, 1)
        // Dead rubber keeps less than the standard rail at the same pace.
        XCTAssertLessThan(RailKeep.share(parameters: PlaySurface.diveBar.parameters),
                          RailKeep.share(parameters: PlaySurface.cloth.parameters))
    }

    func testJamEnergyIsPrintedInAUnitThatReads() {
        let nine = CaptionEngine.energyPhrase(9e-6)
        XCTAssertEqual(nine, String(localized: "\(Double(9).formatted(.number.precision(.significantDigits(1...2)))) microjoules"))
        XCTAssertEqual(CaptionEngine.energyPhrase(0.0042),
                       String(localized: "\(Double(4.2).formatted(.number.precision(.significantDigits(1...2)))) millijoules"))
    }

    /// A ball at `speed` along x strikes ball 1 at rest; ball 1 leaves `degrees` off the line of centres (x).
    private func cut(throwDegrees degrees: Double, speed: Double = 1.0) -> LensEvent {
        let m = PoolParameters().ballMass
        let a = degrees * Double.pi / 180
        let out = Vec2(cos(a), sin(a)) * (speed * 0.8)
        let mover = ImpactBall(ball: 0, velocityBefore: Vec2(speed, 0), velocityAfter: Vec2(speed * 0.1, 0),
                               omegaBefore: .zero, omegaAfter: .zero, translationalBefore: 0.5 * m * speed * speed,
                               rotationalBefore: 0, translationalAfter: 0.5 * m * 0.01 * speed * speed, rotationalAfter: 0)
        let object = ImpactBall(ball: 1, velocityBefore: .zero, velocityAfter: out, omegaBefore: .zero, omegaAfter: .zero,
                                translationalBefore: 0, rotationalBefore: 0, translationalAfter: 0.5 * m * out.lengthSquared,
                                rotationalAfter: 0)
        return LensEvent(time: 0.5, kind: .ballBall, point: .zero, normal: Vec2(1, 0), normalImpulse: 0.2,
                         balls: [mover, object])
    }

    func testThrowIsSaidFromHalfADegreeOnABallAtRest() {
        let thrown = CaptionEngine.throwFacts(cut(throwDegrees: 2))
        XCTAssertEqual(thrown?.object, 1)
        XCTAssertEqual(thrown?.degrees ?? 0, 2, accuracy: 1e-9, "counter-clockwise from the line of centres is positive")
        XCTAssertEqual(captions([cut(throwDegrees: 2)]).map(\.title), [String(localized: "Throw")])
        XCTAssertNil(CaptionEngine.throwFacts(cut(throwDegrees: 0.3)), "under half a degree is not throw worth saying")
        XCTAssertEqual(captions([cut(throwDegrees: 0.3)]).map(\.title), [String(localized: "Energy handed off")])
        // Both balls moving: the line of centres no longer says where the struck ball would go, so no throw.
        XCTAssertNil(CaptionEngine.throwFacts(ballBall(mover: 2, other: 1)))
    }

    func testTheRailSaysWhatItDidToTheSpin() {
        // Rolling into the rail (n = -x pushes back toward -x): omega = (-vy, vx) / R for velocity (1.5, 0).
        let R = TestShots.ballRadius, m = PoolParameters().ballMass
        let b = ImpactBall(ball: 1, velocityBefore: Vec2(1.5, 0), velocityAfter: Vec2(-1.1, 0),
                           omegaBefore: Vec3(0, 1.5 / R, 0), omegaAfter: Vec3(0, 0.2 / R, 0),
                           translationalBefore: 0.5 * m * 2.25, rotationalBefore: 0, translationalAfter: 0.5 * m * 1.21,
                           rotationalAfter: 0)
        let hit = LensEvent(time: 0.5, kind: .cushion, point: .zero, normal: Vec2(-1, 0), normalImpulse: 0.4, balls: [b])
        let detail = captions([hit]).first?.detail ?? ""
        XCTAssertTrue(detail.contains(String(localized: "It came in rolling.")), detail)
        // Leaving along -x with spin about +y: against its new direction of travel that is backspin (share -0.18).
        XCTAssertTrue(detail.contains(String(localized: "It leaves with backspin, which the cloth must wear off before it rolls.")), detail)
    }

    func testStrikeSpinWordsComeFromTheRecordedSpin() {
        XCTAssertEqual(CaptionEngine.spinState(-0.5), .back)
        XCTAssertEqual(CaptionEngine.spinState(0.05), .stun)
        XCTAssertEqual(CaptionEngine.spinState(0.5), .partial)
        XCTAssertEqual(CaptionEngine.spinState(1.0), .rolling)
        XCTAssertEqual(CaptionEngine.spinState(1.4), .over)
        // Draw: spin about -y for a ball moving along +x is backwards against rolling.
        let R = TestShots.ballRadius
        XCTAssertEqual(CaptionEngine.rollShare(omega: Vec3(0, -2 / R, 0), velocity: Vec2(2, 0), radius: R) ?? 0, -1,
                       accuracy: 1e-12)
        XCTAssertNil(CaptionEngine.rollShare(omega: Vec3(0, 1, 0), velocity: Vec2(0.01, 0), radius: R),
                     "a ball barely moving has no direction of travel to compare its spin with")
    }

    // MARK: 4. The 0.7.5 words: still tables and the other tables' names

    func testAZeroSpeedStrikeMakesNoCaption() {
        let still = LensEvent(time: 0, kind: .cueStrike, point: .zero, normal: Vec2(1, 0), normalImpulse: 0,
                              balls: [TestShots.ball(0, before: 0, after: 0)])
        XCTAssertTrue(captions([still]).isEmpty, "a strike that moved nothing says nothing")
        let crawl = LensEvent(time: 0, kind: .cueStrike, point: .zero, normal: Vec2(1, 0), normalImpulse: 0.001,
                              balls: [TestShots.ball(0, before: 0, after: 0.04)])
        XCTAssertTrue(captions([crawl]).isEmpty)
        let soft = LensEvent(time: 0, kind: .cueStrike, point: .zero, normal: Vec2(1, 0), normalImpulse: 0.01,
                             balls: [TestShots.ball(0, before: 0, after: 0.06)])
        XCTAssertEqual(captions([soft]).map(\.accent), [.strike])
    }

    /// A recording on `table` holding these events, sixteen balls standing at spread-out spots.
    private func recording(on table: TableKind, _ events: [LensEvent]) -> Timeline {
        let spec = table.parameters.tableSpec
        let segments = (0..<16).map { b in
            [TestShots.still(Vec2(0.1 + 0.05 * Double(b), min(0.1 + 0.03 * Double(b), spec.width - 0.1)))]
        }
        let sorted = events.sorted { $0.time < $1.time }
        return Timeline(table: spec, seed: 1, parameterHash: 1, segments: segments, events: sorted,
                        pocketTime: [Double?](repeating: nil, count: 16), duration: (sorted.last?.time ?? 0) + 1)
    }

    /// Every kind of moment the small tables record, between the struck ball 0 and `other`: the strike, a hit, a
    /// cushion, a post (bumper pool), two pins (bar billiards: the black peg, then a white one), a drop and a skip at
    /// the first bed hole, a skid turning into roll, a jam of two balls.
    private func everyMoment(other: Int, posts: Bool, pins: Bool) -> [LensEvent] {
        var out: [LensEvent] = [
            LensEvent(time: 0, kind: .cueStrike, point: .zero, normal: Vec2(1, 0), normalImpulse: 0.4,
                      balls: [TestShots.ball(0, before: 0, after: 2.5)]),
            LensEvent(time: 0.3, kind: .ballBall, point: .zero, normal: Vec2(1, 0), normalImpulse: 0.3,
                      balls: [TestShots.ball(0, before: 2.4, after: 0.3), TestShots.ball(other, before: 0, after: 2.0)]),
            LensEvent(time: 0.5, kind: .cushion, point: .zero, normal: Vec2(-1, 0), normalImpulse: 0.2,
                      balls: [TestShots.ball(other, before: 1.8, after: -1.4)]),
            LensEvent(time: 0.6, kind: .phaseTransition, point: .zero, normal: Vec2(1, 0),
                      balls: [TestShots.ball(0, before: 1.0, after: 1.0)], phaseFrom: .sliding, phaseTo: .rolling),
            LensEvent(time: 0.9, kind: .pocket, point: .zero, normal: Vec2(1, 0),
                      balls: [TestShots.ball(other, before: 0.6, after: 0)], pocket: TableSpec.edgePocketCount),
            LensEvent(time: 1.0, kind: .rimSkip, point: .zero, normal: Vec2(1, 0),
                      balls: [TestShots.ball(0, before: 3, after: 2.8)], pocket: TableSpec.edgePocketCount,
                      entry: PocketEntry(speed: 3, sine: 0.1, cosine: 0.995)),
            LensEvent(time: 1.4, kind: .settledInContact, point: .zero, normal: Vec2(1, 0),
                      balls: [TestShots.ball(0, before: 0.01, after: 0), TestShots.ball(other, before: 0.01, after: 0)],
                      energyRemoved: 0.0001),
        ]
        if posts {
            out.append(LensEvent(time: 0.4, kind: .cushion, point: .zero, normal: Vec2(-1, 0), normalImpulse: 0.2,
                                 balls: [TestShots.ball(0, before: 1.5, after: -1.0)], edge: .post, feature: 0))
        }
        if pins {
            out.append(LensEvent(time: 0.7, kind: .pinDown, point: .zero, normal: Vec2(1, 0), normalImpulse: 0.05,
                                 balls: [TestShots.ball(other, before: 1.2, after: 1.0)],
                                 feature: BarBilliardsRules.blackPeg))
            out.append(LensEvent(time: 0.8, kind: .pinDown, point: .zero, normal: Vec2(1, 0), normalImpulse: 0.05,
                                 balls: [TestShots.ball(0, before: 0.9, after: 0.8)], feature: 1))
        }
        return out
    }

    func testTheSmallTablesNeverNameABallByNumberOrSayPocket() throws {
        // "the 3 ball", "ball 3": a number next to the word ball. "2 balls were wedged" counts balls, not a name.
        let numbered = try NSRegularExpression(pattern: #"\d+\s*ball\b|\bball\s*\d"#, options: [.caseInsensitive])
        for (table, other) in [(TableKind.bumperPool, 9), (.barBilliards, BarBilliardsRules.redBall)] {
            let tl = recording(on: table, everyMoment(other: other, posts: table == .bumperPool,
                                                      pins: table == .barBilliards))
            let made = CaptionEngine.make(from: tl, surface: .cloth, table: table, striker: 0)
            XCTAssertGreaterThanOrEqual(made.count, 7, "\(table): every moment is captioned")
            for c in made {
                for text in [c.title, c.detail] {
                    let range = NSRange(text.startIndex..., in: text)
                    XCTAssertNil(numbered.firstMatch(in: text, range: range), "\(table): \(text)")
                    XCTAssertFalse(text.lowercased().contains("pocket"), "\(table): \(text)")
                    XCTAssertFalse(text.lowercased().contains(String(localized: "the cue ball").lowercased()),
                                   "\(table): \(text)")
                }
            }
            let titles = made.map(\.title)
            if table == .bumperPool {
                XCTAssertTrue(titles.contains(String(localized: "Into the cup")))
                XCTAssertTrue(titles.contains(String(localized: "Too fast for the cup")))
                XCTAssertTrue(titles.contains(String(localized: "The bumper throws it back")))
            } else {
                XCTAssertTrue(titles.contains(String(localized: "Into the hole")))
                XCTAssertTrue(titles.contains(String(localized: "Too fast for the hole")))
                let pegs = made.filter { $0.title == String(localized: "Peg down") }
                XCTAssertEqual(pegs.count, 2)
                XCTAssertTrue(pegs.first?.detail.contains(String(localized: "The black peg down costs the whole score.")) == true)
                XCTAssertTrue(pegs.last?.detail.contains(String(localized: "A white peg down costs the points of this break.")) == true)
                // The red is named by its colour, the way the table names it.
                let red = TableWords.ballName(BarBilliardsRules.redBall, cueBall: 0, table: .barBilliards)
                XCTAssertTrue(made.contains { $0.detail.contains(red) }, "the red is called \(red)")
            }
        }
    }

    func testThePoolTablesCaptionsAreUnchanged() {
        // Passing the pool table and its striker gives exactly what the defaults always gave.
        for tl in [TestShots.breakShot(on: .cloth), TestShots.straightPot(on: .cloth)] {
            XCTAssertEqual(CaptionEngine.make(from: tl, surface: .cloth),
                           CaptionEngine.make(from: tl, surface: .cloth, table: .standard, striker: 0))
        }
        // And the pool names are the pool names: the cue ball and the numbered ball; a drop is "Pocketed".
        let hit = captions([ballBall(mover: 2)]).first?.detail ?? ""
        XCTAssertTrue(hit.hasPrefix(String(localized: "the cue ball").capitalizedFirst), hit)
        XCTAssertTrue(hit.contains(String(localized: "the \(1) ball")), hit)
        let drop = LensEvent(time: 1, kind: .pocket, point: .zero, normal: Vec2(1, 0),
                             balls: [TestShots.ball(1, before: 0.5, after: 0)], pocket: 3)
        XCTAssertEqual(captions([drop]).map(\.title), [String(localized: "Pocketed")])
    }
}
