// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// PURPOSE: Make it again (0.7.7, plans/23-Nov-2026-make-it-again-plan.md, tests 1 to 10): a free-play shot turned into
//          the player's own challenge (App/OwnShot.swift), proved and measured (App/OwnShotProof.swift), and kept on the
//          shelf (App/OwnShotShelf.swift). Every attempt here is built exactly as a free-play stroke keeps it (the
//          effective input with its own seed and default parameters, solved through ShowpieceModel.solverCopy), never
//          through TestShots.attempt, which rebuilds the input with seed 1 and the surface's numbers already in it.
//          Shelves are memory only (fileURL nil), so the player's own file is never read or written by a test.
// SRP/DRY check: Pass - reuses TestShots (hand-made recordings, the break), RideDemo.straightPot and the authored
//          tricks' layouts and answers; only the free-play attempt builder is new, because nothing else builds an
//          attempt the way finishStrike records a free-play stroke.
@testable import Breakdown
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation
import XCTest

@MainActor
final class OwnShotTests: XCTestCase {
    // MARK: Helpers

    /// Thrown (so the test fails) when a trick these tests read is a rack, not a layout.
    private struct NotLaidOut: Error { let id: String }

    /// The attempt ShowpieceModel.finishStrike records for a free-play stroke struck with this effective input: the
    /// input as built (default parameters), solved on the table and surface through solverCopy, the struck settings.
    private func freePlayAttempt(_ input: ShotInput, table: TableKind = .standard,
                                 surface: PlaySurface = .cloth) -> ShotAttempt {
        let g = PoolParameters().modelGeneration
        let tl = PoolSolver.simulate(ShowpieceModel.solverCopy(input, table: table, surface: surface, generation: g))
        return attempt(input, timeline: tl, table: table, surface: surface, generation: g)
    }

    /// An attempt around any recording, with the input's struck settings.
    private func attempt(_ input: ShotInput, timeline: Timeline, table: TableKind = .standard,
                         surface: PlaySurface = .cloth,
                         generation: Int = PoolParameters().modelGeneration) -> ShotAttempt {
        let s = input.strike
        return ShotAttempt(isBreak: false, breakSeed: 0, start: input.positions, timeline: timeline,
                           aim: atan2(s.direction.y, s.direction.x) * 180 / Double.pi, power: s.speed,
                           powerRange: PlayerShotSpeed.ordinary, tipUp: s.tipUp, tipSide: s.tipSide,
                           elevation: s.elevation, seed: input.seed, input: input, surface: surface, table: table,
                           generation: generation)
    }

    /// An authored trick's answer as an input from its layout (seed 1, default parameters).
    private func answerInput(_ id: String) throws -> ShotInput {
        let shot = try XCTUnwrap(TrickShots.shot(id: id), "no trick shot \(id)")
        guard case .layout(let layout) = shot.setup else { throw NotLaidOut(id: id) }
        let s = shot.solution
        let a = s.aim * Double.pi / 180
        return NextShot.shot(from: layout, direction: Vec2(cos(a), sin(a)), speed: s.power, tipUp: s.tipUp,
                             tipSide: s.tipSide, seed: 1, elevation: s.elevation ?? 0)
    }

    /// The input rotated by `degrees` (counter-clockwise), the direction written straight in.
    private func rotated(_ input: ShotInput, degrees: Double) -> ShotInput {
        var i = input
        let r = degrees * Double.pi / 180
        let d = input.strike.direction
        i.strike.direction = Vec2(d.x * cos(r) - d.y * sin(r), d.x * sin(r) + d.y * cos(r))
        return i
    }

    /// A hand-made recording of sixteen still balls holding `events`, with these balls marked as gone at these times.
    private func recording(_ events: [LensEvent], gone: [Int: Double] = [:]) -> Timeline {
        let base = TestShots.recording(events, balls: 16)
        var times = [Double?](repeating: nil, count: 16)
        for (b, t) in gone { times[b] = t }
        return Timeline(table: base.table, seed: 1, parameterHash: 1, segments: base.segments, events: base.events,
                        pocketTime: times, duration: base.duration)
    }

    private func contact(_ t: Double, _ a: Int, _ b: Int) -> LensEvent {
        LensEvent(time: t, kind: .ballBall, point: .zero, normal: Vec2(1, 0), normalImpulse: 0.3,
                  balls: [TestShots.ball(a, before: 2, after: 0.5), TestShots.ball(b, before: 0, after: 1.5)])
    }

    private func drop(_ t: Double, _ ball: Int, into pocket: Int) -> LensEvent {
        LensEvent(time: t, kind: .pocket, point: .zero, normal: Vec2(1, 0),
                  balls: [TestShots.ball(ball, before: 1, after: 0)], pocket: pocket)
    }

    /// Test 1's shot: the straight pot saved from free play.
    private func straightPotShot() throws -> (own: OwnShot, attempt: ShotAttempt) {
        let a = freePlayAttempt(RideDemo.straightPot())
        return (try XCTUnwrap(OwnShot.make(from: a, kind: nil, number: 1)), a)
    }

    /// A shot built by hand on bumper pool from the table's own opening shot (test 8; its goal need not hold).
    private func bumperPoolShot() -> OwnShot {
        let input = TableKind.bumperPool.openingShot
        let s = input.strike
        return OwnShot(id: OwnShot.idPrefix + "bumper-test", name: "Bumper", saved: Date(timeIntervalSince1970: 0),
                       tableRaw: "bumperPool", surfaceRaw: "cloth", generation: PoolParameters().modelGeneration,
                       start: input.positions,
                       strike: OwnStrike(directionX: s.direction.x, directionY: s.direction.y, speed: s.speed,
                                         tipUp: s.tipUp, tipSide: s.tipSide, elevation: s.elevation, seed: input.seed),
                       drops: [OwnDrop(ball: 1, pocket: 6)], firstHit: 1, bank: nil, kindRaw: nil,
                       motionHash: "0", window: nil, made: false)
    }

    // MARK: 1. A pot becomes a challenge

    func testAPotBecomesAChallenge() throws {
        let input = RideDemo.straightPot()
        let (own, a) = try straightPotShot()
        XCTAssertNil(OwnShot.refusal(for: a))
        XCTAssertEqual(own.drops.count, 1)
        XCTAssertEqual(own.drops.first?.ball, 1)
        XCTAssertEqual(own.drops.first?.pocket, TrickShotJudge.pocket(of: 1, in: a.timeline))
        XCTAssertEqual(own.firstHit, 1)
        XCTAssertNil(own.bank)
        XCTAssertEqual(own.table, .standard)
        XCTAssertEqual(own.surface, .cloth)
        XCTAssertTrue(own.id.hasPrefix(OwnShot.idPrefix))
        XCTAssertEqual(own.strike.seed, 7)
        XCTAssertFalse(own.made)
        XCTAssertNil(own.window)
        // The rebuilt input is the original bit for bit (the direction is written back after CueStrike's init).
        let rebuilt = own.input
        XCTAssertEqual(rebuilt.strike.direction.x, input.strike.direction.x)
        XCTAssertEqual(rebuilt.strike.direction.y, input.strike.direction.y)
        XCTAssertEqual(rebuilt.strike.speed, input.strike.speed)
        XCTAssertEqual(rebuilt.strike.tipUp, input.strike.tipUp)
        XCTAssertEqual(rebuilt.strike.tipSide, input.strike.tipSide)
        XCTAssertEqual(rebuilt.strike.elevation, input.strike.elevation)
        XCTAssertEqual(rebuilt.strike.ballIndex, 0)
        XCTAssertEqual(rebuilt.seed, input.seed)
        XCTAssertEqual(rebuilt.positions, input.positions)
        // Not a named kind: the plain name with its number, and the plain idea.
        XCTAssertEqual(own.name, OwnShotWords.defaultName(kind: nil, number: 1))
        XCTAssertEqual(OwnShotWords.idea(own), OwnShotWords.plainIdea)
    }

    // MARK: 2. The same balls in the same pockets, in any order

    func testTwoBallsAnyOrderSamePockets() throws {
        let a = freePlayAttempt(try answerInput("follow-train"))
        let own = try XCTUnwrap(OwnShot.make(from: a, kind: nil, number: 1), "the follow-train answer was refused")
        XCTAssertEqual(own.drops.count, 2)
        guard own.drops.count == 2 else { return }
        // In drop order: the order of the recording's pocket events.
        let order = a.timeline.events.filter { $0.kind == .pocket }.compactMap { $0.balls.first?.ball }.filter { $0 != 0 }
        XCTAssertEqual(own.drops.map(\.ball), Array(order.prefix(2)))

        let first = try XCTUnwrap(own.firstHit)
        let d0 = own.drops[0], d1 = own.drops[1]
        // The bank is left out of these hand-made checks: the recordings hold no cushion events.
        let goal = TrickGoal(drops: own.goal.drops, firstHit: own.firstHit)
        // The same two balls in the same pockets, the other way round: made.
        let reversed = recording([contact(0.1, 0, first), drop(0.5, d1.ball, into: d1.pocket),
                                  drop(0.8, d0.ball, into: d0.pocket)],
                                 gone: [d1.ball: 0.5, d0.ball: 0.8])
        XCTAssertNil(TrickShotJudge.failure(goal, attempt(own.input, timeline: reversed)))
        // One ball in another pocket: the wrong pocket.
        let other = (d1.pocket + 1) % TableSpec.edgePocketCount
        let wrong = recording([contact(0.1, 0, first), drop(0.5, d0.ball, into: d0.pocket),
                               drop(0.8, d1.ball, into: other)],
                              gone: [d0.ball: 0.5, d1.ball: 0.8])
        XCTAssertEqual(TrickShotJudge.failure(goal, attempt(own.input, timeline: wrong)), .wrongPocket(d1.ball))
        // Both down, but the cue ball too: a scratch.
        let scratch = recording([contact(0.1, 0, first), drop(0.5, d0.ball, into: d0.pocket),
                                 drop(0.8, d1.ball, into: d1.pocket), drop(1.0, 0, into: 0)],
                                gone: [d0.ball: 0.5, d1.ball: 0.8, 0: 1.0])
        XCTAssertEqual(TrickShotJudge.failure(goal, attempt(own.input, timeline: scratch)), .scratch)
    }

    // MARK: 3. What cannot be saved, and the answer is the struck stroke

    func testRefusals() throws {
        // A break.
        let breakInput = TestShots.breakInput()
        let broke = TestShots.attempt(start: breakInput.positions, timeline: TestShots.breakShot(),
                                      TrickSettings(aim: 0, power: 10, tipUp: 0, tipSide: 0),
                                      isBreak: true, breakSeed: 11)
        XCTAssertEqual(OwnShot.refusal(for: broke), .isBreak)
        // Far too soft to pot anything.
        var soft = RideDemo.straightPot()
        soft.strike.speed *= 0.1
        XCTAssertEqual(OwnShot.refusal(for: freePlayAttempt(soft)), .nothingDropped)
        XCTAssertNil(OwnShot.make(from: freePlayAttempt(soft), kind: nil, number: 1))
        // The cue ball dropped.
        let input = RideDemo.straightPot()
        let cueDown = recording([contact(0.1, 0, 1), drop(0.5, 1, into: 3), drop(0.9, 0, into: 2)],
                                gone: [1: 0.5, 0: 0.9])
        XCTAssertEqual(OwnShot.refusal(for: attempt(input, timeline: cueDown)), .cueBallDropped)
        // Another physics generation.
        let potted = recording([contact(0.1, 0, 1), drop(0.5, 1, into: 3)], gone: [1: 0.5])
        XCTAssertNil(OwnShot.refusal(for: attempt(input, timeline: potted)))
        XCTAssertEqual(OwnShot.refusal(for: attempt(input, timeline: potted, generation: 1)), .otherPhysics)

        // The answer is the stroke as struck (here a raised, harder stroke), not any chosen power.
        let raised = OwnShot(id: OwnShot.idPrefix + "raised", name: "Raised", saved: Date(timeIntervalSince1970: 0),
                             tableRaw: TableKind.standard.rawValue, surfaceRaw: PlaySurface.cloth.rawValue,
                             generation: PoolParameters().modelGeneration, start: input.positions,
                             strike: OwnStrike(directionX: 1, directionY: 0, speed: 4, tipUp: 0.004, tipSide: -0.002,
                                               elevation: 0.6, seed: 9),
                             drops: [OwnDrop(ball: 1, pocket: 3)], firstHit: 1, bank: nil, kindRaw: nil,
                             motionHash: "0", window: nil, made: false)
        XCTAssertEqual(raised.solution.power, 4)
        XCTAssertEqual(raised.solution.elevation, 0.6)
        XCTAssertEqual(raised.solution.tipUp, 0.004)
        XCTAssertEqual(raised.solution.tipSide, -0.002)
        XCTAssertEqual(raised.solution.aim, 0, accuracy: 1e-12)
    }

    // MARK: 4. The file round-trips exactly

    func testRoundTripsThroughJSON() throws {
        let (own, _) = try straightPotShot()
        let back = try JSONDecoder().decode(OwnShot.self, from: JSONEncoder().encode(own))
        XCTAssertEqual(back, own)
        // Every double of the strike comes back exactly, so Watch it can strike it bit for bit.
        XCTAssertEqual(back.input.strike.direction, own.input.strike.direction)

        var measured = bumperPoolShot()
        measured.window = OwnWindow(aim: 0.4, power: 0.3, tipUp: 0.002, tipSide: 0.001, build: "test")
        measured.made = true
        let file = OwnShotFile(format: OwnShotShelf.format, shots: [own, measured])
        let backFile = try JSONDecoder().decode(OwnShotFile.self, from: JSONEncoder().encode(file))
        XCTAssertEqual(backFile, file)
    }

    // MARK: 5. The saved stroke proves the shot

    func testTheSavedStrokeProvesTheShot() throws {
        let (pot, _) = try straightPotShot()
        let follow = try XCTUnwrap(OwnShot.make(from: freePlayAttempt(try answerInput("follow-train")), kind: nil,
                                                number: 2))
        for own in [pot, follow] {
            XCTAssertTrue(OwnShotProof.holds(own), "\(own.name): the saved stroke no longer makes it")
            let check = OwnShotProof.check(own)
            let tl = try XCTUnwrap(check.timeline)
            let again = OwnShotProof.attempt(own, input: own.input, timeline: tl)
            XCTAssertEqual(String(again.motionHash, radix: 16), own.motionHash, "\(own.name): the re-solve moved")
        }
    }

    // MARK: 6. A bank is asked for only when a ball came off a rail

    func testABankIsNeededOnlyWhenTheBallCameOffARail() throws {
        let cross = try XCTUnwrap(TrickShots.shot(id: "cross-bank"))
        let own = try XCTUnwrap(OwnShot.make(from: freePlayAttempt(try answerInput("cross-bank")), kind: nil,
                                             number: 1))
        XCTAssertNotNil(cross.goal.bank)
        XCTAssertEqual(own.bank, cross.goal.bank)
        let (pot, _) = try straightPotShot()
        XCTAssertNil(pot.bank)
    }

    // MARK: 7. The measured window holds the shot

    func testTheWindowHoldsTheShot() throws {
        let (own, _) = try straightPotShot()
        let w = OwnShotProof.measureWindow(own, build: "test")
        XCTAssertEqual(w.build, "test")
        XCTAssertGreaterThan(w.aim, 0)
        XCTAssertGreaterThan(w.power, 0)
        XCTAssertGreaterThan(w.tipUp, 0)
        XCTAssertGreaterThan(w.tipSide, 0)
        // Half the aim window either way still makes it; past the furthest push tried, it misses.
        XCTAssertTrue(OwnShotProof.passes(own, input: rotated(own.input, degrees: w.aim / 2)))
        XCTAssertTrue(OwnShotProof.passes(own, input: rotated(own.input, degrees: -w.aim / 2)))
        XCTAssertFalse(OwnShotProof.passes(own, input: rotated(own.input, degrees: 5)))
    }

    // MARK: 8. The trick shot carries the table, and the original is made

    func testTheTrickShotCarriesTheTableAndJudgesTheOriginalMade() throws {
        let (own, a) = try straightPotShot()
        let shot = try XCTUnwrap(own.trickShot)
        XCTAssertEqual(shot.id, own.id)
        XCTAssertEqual(shot.table, .standard)
        XCTAssertEqual(shot.setup, .layout(own.start))
        XCTAssertEqual(shot.goal, own.goal)
        XCTAssertEqual(shot.praise, OwnShotWords.praise)
        XCTAssertFalse(shot.pending)
        XCTAssertFalse(shot.isBreak)
        let verdict = TrickShotJudge.verdict(for: shot, attempt: a)
        XCTAssertTrue(verdict.made, verdict.line)
        XCTAssertEqual(verdict.line, OwnShotWords.praise)

        var bumper = bumperPoolShot()
        XCTAssertEqual(bumper.trickShot?.table, .bumperPool)
        let shelf = OwnShotShelf(fileURL: nil)
        XCTAssertTrue(shelf.isUnmeasured(try XCTUnwrap(bumper.trickShot)))
        bumper.window = OwnWindow(aim: 0.8, power: 0.4, tipUp: 0.003, tipSide: 0.002, build: "test")
        XCTAssertFalse(shelf.isUnmeasured(try XCTUnwrap(bumper.trickShot)))
        XCTAssertEqual(bumper.trickShot?.difficulty, .easy)
        // An authored shot is never "unmeasured".
        XCTAssertFalse(shelf.isUnmeasured(try XCTUnwrap(TrickShots.shot(id: "follow-train"))))
        // A table this build does not know: no trick shot, and the row says so.
        let unknown = OwnShot(id: OwnShot.idPrefix + "unknown", name: "Unknown", saved: Date(timeIntervalSince1970: 0),
                              tableRaw: "noSuchTable", surfaceRaw: "cloth", generation: bumper.generation,
                              start: bumper.start, strike: bumper.strike, drops: bumper.drops, firstHit: 1, bank: nil,
                              kindRaw: nil, motionHash: "0", window: nil, made: false)
        XCTAssertNil(unknown.trickShot)
        XCTAssertEqual(OwnShotWords.proofLine(unknown, proof: nil), OwnShotWords.unplayable)
    }

    // MARK: 9. The Lens replay holds the hit and the pocket

    func testSignatureHoldsTheHitAndThePocket() throws {
        let (own, a) = try straightPotShot()
        let tl = a.timeline
        let captions = CaptionEngine.make(from: tl, surface: .cloth)
        let events = TrickSignature.events(forTrick: own.id, in: tl, captions: captions)
        XCTAssertFalse(events.isEmpty)
        XCTAssertLessThanOrEqual(events.count, 2)
        let captioned = Set(captions.map(\.id))
        for e in events { XCTAssertTrue(captioned.contains(e), "event \(e) is not captioned") }
        let first = ShotMoments(timeline: tl, captions: captions).firstContact(of: 0)
        XCTAssertNotNil(first)
        if let first { XCTAssertTrue(events.contains(first), "the cue ball's first contact is not held") }
        // An id that is neither authored nor saved still gets nothing.
        XCTAssertTrue(TrickSignature.events(forTrick: "no-such-shot", in: tl, captions: captions).isEmpty)
    }

    // MARK: 10. The shelf's rules, in memory

    func testShelfRulesInMemory() throws {
        let shelf = OwnShotShelf(fileURL: nil)
        let base = bumperPoolShot()
        // The first shots are on a known table, so adding them starts their checks (their proof is then set, and
        // delete must clear it); the filler shots up to sixty name a table this build lacks, so no solve is started
        // for each of them.
        func shot(_ n: Int, playable: Bool = true) -> OwnShot {
            OwnShot(id: OwnShot.idPrefix + "shelf-\(n)", name: "Shot \(n)", saved: Date(timeIntervalSince1970: Double(n)),
                    tableRaw: playable ? base.tableRaw : "noSuchTable", surfaceRaw: base.surfaceRaw,
                    generation: base.generation,
                    start: base.start, strike: base.strike, drops: base.drops, firstHit: base.firstHit, bank: nil,
                    kindRaw: nil, motionHash: "0", window: nil, made: false)
        }
        XCTAssertTrue(shelf.add(shot(1)))
        XCTAssertTrue(shelf.add(shot(2)))
        XCTAssertTrue(shelf.add(shot(3)))
        XCTAssertFalse(shelf.add(shot(3)), "the same shot was added twice")
        XCTAssertEqual(shelf.shots.count, 3)
        XCTAssertEqual(shelf.proof[OwnShot.idPrefix + "shelf-2"], .checking)

        // Rename: trimmed, capped, and an empty name keeps the old one.
        let id1 = OwnShot.idPrefix + "shelf-1"
        shelf.rename(id: id1, to: "   Corner kick  ")
        XCTAssertEqual(shelf.shot(id: id1)?.name, "Corner kick")
        shelf.rename(id: id1, to: String(repeating: "x", count: 50))
        XCTAssertEqual(shelf.shot(id: id1)?.name.count, OwnShotShelf.nameLimit)
        shelf.rename(id: id1, to: "   ")
        XCTAssertEqual(shelf.shot(id: id1)?.name, String(repeating: "x", count: OwnShotShelf.nameLimit))

        // Made again.
        shelf.noteMade(id: id1)
        XCTAssertEqual(shelf.shot(id: id1)?.made, true)

        // Next walks newest first, then nil after the last.
        XCTAssertEqual(shelf.next(after: OwnShot.idPrefix + "shelf-3")?.id, OwnShot.idPrefix + "shelf-2")
        XCTAssertEqual(shelf.next(after: OwnShot.idPrefix + "shelf-2")?.id, id1)
        XCTAssertNil(shelf.next(after: id1))

        // Delete removes the shot and its check.
        let id2 = OwnShot.idPrefix + "shelf-2"
        shelf.delete(id: id2)
        XCTAssertNil(shelf.shot(id: id2))
        XCTAssertNil(shelf.proof[id2])
        XCTAssertEqual(shelf.shots.count, 2)

        // Full at sixty: a sixty-first is refused.
        var n = 100
        while shelf.shots.count < OwnShotShelf.capacity {
            XCTAssertTrue(shelf.add(shot(n, playable: false)))
            n += 1
        }
        XCTAssertFalse(shelf.add(shot(n, playable: false)), "a sixty-first shot was added")
        XCTAssertEqual(shelf.shots.count, OwnShotShelf.capacity)
    }
}
