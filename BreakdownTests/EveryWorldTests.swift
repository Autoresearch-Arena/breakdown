// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// PURPOSE: "Same shot, every surface" in the app (0.7.7, plans/23-Nov-2026-every-world-plan.md, Tests). Pure checks
//          first: solveOne on the home surface reproduces the attempt's recording exactly (so the fan solves the same
//          way the model does), on the pool table and on bumper pool; thin keeps the ends and drops close runs; every
//          WorldContrast case gives a sentence, with the pool table's and bumper pool's ball names. Then the flow on a
//          real model: on the straight pot every other surface either solves or is reported too long, none missing;
//          ice's struck ball travels farther than home's and ice is not "much the same"; the entry is offered with the
//          what-if (after a free-play shot at rest, not while solving, on a break, with the menu open or in the
//          opening); a landing after close is dropped and the model is untouched; the what-if and the fan close each
//          other; Play on is offered in free play only (never in a trick shot's, a lesson's or a Behind the 8-Ball
//          situation's judged try) and plays exactly the line that was drawn; a trick's fan never judges or marks the
//          trick done. The time the nine solves take is printed, not asserted (a time bound is flaky on shared
//          machines).
// SRP/DRY check: Pass - WhatIfTests' helpers (freshModel, settle, freePlayShot, the straight pot) are private there,
//          so the ones needed are copied here under the same names, as the plan says; the package's
//          WorldContrastTests check BallTravel and WorldContrast themselves. These test only the fan.
@testable import Breakdown
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation
import XCTest

@MainActor
final class EveryWorldTests: XCTestCase {
    // MARK: Helpers

    /// The stored surface and table set to cloth and the pool table for the test, and put back after it, so a fresh
    /// model starts on cloth whatever an earlier test or the device left stored. Returns the put-back.
    private func keepChoices() -> () -> Void {
        let keys = [PlaySurface.storageKey, TableKind.storageKey]
        let before = keys.map { UserDefaults.standard.object(forKey: $0) }
        UserDefaults.standard.set(PlaySurface.cloth.rawValue, forKey: PlaySurface.storageKey)
        UserDefaults.standard.set(TableKind.standard.rawValue, forKey: TableKind.storageKey)
        return {
            for (key, value) in zip(keys, before) {
                if let value { UserDefaults.standard.set(value, forKey: key) } else {
                    UserDefaults.standard.removeObject(forKey: key)
                }
            }
        }
    }

    /// A model past the opening with the menu closed, in free play (WhatIfTests' helper).
    private func freshModel() -> ShowpieceModel {
        let m = ShowpieceModel()
        for _ in 0..<3 where m.openingStage != .none { m.skipOpening() }
        m.closeMenu()
        return m
    }

    /// Waits for the model's background solve to land, then lets the shot play out (the balls at rest).
    private func settle(_ m: ShowpieceModel) async {
        var waited = 0
        while m.isSolving && waited < 1000 { try? await Task.sleep(for: .milliseconds(10)); waited += 1 }
        m.scrub(to: m.duration)
    }

    /// Waits until no surface of the fan is still solving (up to a minute: the Moon and ice are the slow ones).
    private func solvedFan(_ fan: EveryWorldFan) async {
        var waited = 0
        while fan.solving && waited < 6000 { try? await Task.sleep(for: .milliseconds(10)); waited += 1 }
    }

    /// The straight pot of the Ride demo: the cue ball, one object ball and the far corner, with the demo's draw.
    private func straightPot() -> (start: [Vec2], aim: Double, tipUp: Double) {
        let input = RideDemo.straightPot()
        let d = input.strike.direction
        return (input.positions, atan2(d.y, d.x) * 180 / Double.pi, -0.008)
    }

    /// A free-play shot from `start`, played out.
    private func freePlayShot(_ m: ShowpieceModel, _ start: [Vec2], aim: Double, power: Double,
                              tipUp: Double = 0) async {
        m.loadTrickLayout(start, aim: aim, power: power, tipUp: tipUp, tipSide: 0)
        m.shootNow()
        XCTAssertFalse(m.everyWorld.canOpen, "never while the shot is being solved")
        await settle(m)
    }

    /// The straight pot played in free play on a fresh model on cloth.
    private func potModel() async -> ShowpieceModel {
        let m = freshModel()
        let pot = straightPot()
        await freePlayShot(m, pot.start, aim: pot.aim, power: 2.5, tipUp: pot.tipUp)
        return m
    }

    /// solveOne for an attempt on `surface`.
    private func solve(_ a: ShotAttempt, on surface: PlaySurface) -> EveryWorldFan.Landing {
        EveryWorldFan.solveOne(input: a.input, table: a.table, surface: surface, generation: a.generation,
                               start: a.start, cueBall: a.cueBall, home: a.timeline,
                               radius: a.timeline.table.ballRadius, budget: WhatIfFork.eventBudget)
    }

    // MARK: Pure checks

    func testSolveOneOnTheHomeSurfaceReproducesTheShot() async {
        let restore = keepChoices(); defer { restore() }
        let m = await potModel()
        guard let a = m.currentAttempt else { return XCTFail("no attempt on the pool table") }
        XCTAssertEqual(a.table, .standard)
        guard let tl = solve(a, on: a.surface).timeline else { return XCTFail("the home solve ran out of events") }
        XCTAssertEqual(a.resolved(on: tl, surface: a.surface).motionHash, a.motionHash,
                       "solveOne must take the model's own path on the pool table")

        // Bumper pool: its own table numbers, so a table mismatch cannot hide behind cloth.
        m.playTable(.bumperPool)
        m.shootNow()
        await settle(m)
        guard let b = m.currentAttempt else { return XCTFail("no attempt on bumper pool") }
        XCTAssertEqual(b.table, .bumperPool)
        guard let tlb = solve(b, on: b.surface).timeline else { return XCTFail("the bumper-pool solve ran out") }
        XCTAssertEqual(b.resolved(on: tlb, surface: b.surface).motionHash, b.motionHash,
                       "solveOne must take the model's own path on bumper pool")
        m.playTable(.standard)
    }

    func testThinKeepsTheEndsAndDropsCloseRuns() {
        let points = [Vec2(0, 0), Vec2(0.001, 0), Vec2(0.002, 0), Vec2(0.006, 0), Vec2(0.007, 0), Vec2(0.0075, 0)]
        let thinned = EveryWorldFan.thin(points)
        XCTAssertEqual(thinned.first, points.first)
        XCTAssertEqual(thinned.last, points.last)
        // 1 and 2 mm are within 5 mm of the start; 6 mm is kept; 7 mm is within 5 mm of it; the last is always kept.
        XCTAssertEqual(thinned, [Vec2(0, 0), Vec2(0.006, 0), Vec2(0.0075, 0)])
        XCTAssertEqual(EveryWorldFan.thin([Vec2(1, 1)]), [Vec2(1, 1)])
        XCTAssertEqual(EveryWorldFan.thin([]), [])
    }

    /// A pure attempt of the straight pot on cloth, labelled with `table` (for the ball names only).
    private func pureAttempt(table: TableKind) -> ShotAttempt {
        let input = RideDemo.straightPot()
        let generation = PoolParameters().modelGeneration
        let tl = PoolSolver.simulate(ShowpieceModel.solverCopy(input, table: .standard, surface: .cloth,
                                                               generation: generation))
        return ShotAttempt(isBreak: false, breakSeed: 0, start: input.positions, timeline: tl, aim: 0, power: 2.6,
                           powerRange: PlayerShotSpeed.ordinary, tipUp: -0.008, tipSide: 0, elevation: 0, seed: 7,
                           input: input, surface: .cloth, table: table, generation: generation)
    }

    func testEveryContrastGivesASentence() {
        let cases: [WorldContrast] = [
            .gainsDrop(ball: 3), .neverRolls(distance: 2.14), .neverReaches(ball: 1), .meetsOther(ball: 2, insteadOf: 1),
            .reaches(ball: 2), .losesDrop(ball: 1), .struckDrops, .struckStaysUp, .travel(world: 6.1, home: 2.0),
            .lasts(world: 14.2, home: 3.1), .alike,
        ]
        for table in [TableKind.standard, .bumperPool] {
            let real = pureAttempt(table: table)
            for c in cases {
                for s in PlaySurface.allCases {
                    XCTAssertFalse(EveryWorldWords.sentence(c, surface: s, real: real).isEmpty, "\(table) \(c) \(s)")
                }
            }
            XCTAssertFalse(EveryWorldWords.trickMade(.ice).isEmpty)
        }
        XCTAssertFalse(EveryWorldWords.fanAlike.isEmpty)
        XCTAssertFalse(EveryWorldWords.controllerAction.isEmpty)
    }

    // MARK: The fan on a real model

    func testEverySurfaceSolvesOrIsReportedTooLong() async {
        let restore = keepChoices(); defer { restore() }
        let m = await potModel()
        let fan = m.everyWorld
        XCTAssertTrue(fan.canOpen)
        let started = Date()
        fan.open()
        XCTAssertTrue(fan.isShowing)
        await solvedFan(fan)
        print("Every surface: the nine solves of the straight pot took \(Date().timeIntervalSince(started)) s")
        XCTAssertEqual(fan.home, .cloth)
        XCTAssertEqual(Set(fan.slots.keys), Set(PlaySurface.allCases.filter { $0 != .cloth }),
                       "every other surface must have a slot, and home none")
        for (s, slot) in fan.slots {
            switch slot {
            case .solving: XCTFail("\(s) is still solving")
            case .solved, .tooLong: break
            }
        }
        XCTAssertNotNil(fan.fanSentence, "the fan's sentence once every surface has landed")
        XCTAssertFalse(fan.solving)
        XCTAssertFalse(fan.showSpinner)
    }

    func testIceTravelsFartherAndIsNotAlike() async {
        let restore = keepChoices(); defer { restore() }
        let m = await potModel()
        let fan = m.everyWorld
        fan.open()
        await solvedFan(fan)
        guard let ice = fan.world(.ice), let home = fan.homeOutcome else { return XCTFail("ice did not solve") }
        // With the demo's draw, the cue ball on cloth has lost its spin by the hit and stops near it; on ice the draw
        // barely wears off, so it comes back a long way.
        XCTAssertGreaterThan(ice.outcome.travel.distance, home.travel.distance,
                             "the cue ball should travel farther on ice than on cloth")
        XCTAssertNotEqual(WorldContrast.key(home: home, world: ice.outcome), .alike)
        XCTAssertFalse(fan.sentence(for: .ice).isEmpty)
    }

    func testTheGateIsTheWhatIfsGate() async {
        let restore = keepChoices(); defer { restore() }
        let m = freshModel()
        XCTAssertEqual(m.everyWorld.canOpen, m.whatIf.canOpen)
        let pot = straightPot()
        await freePlayShot(m, pot.start, aim: pot.aim, power: 2.5)
        XCTAssertTrue(m.everyWorld.canOpen, "a free-play shot at rest should offer the fan")
        m.openMenu()
        XCTAssertFalse(m.everyWorld.canOpen, "not with the menu open")
        m.closeMenu()
        XCTAssertTrue(m.everyWorld.canOpen)
        // A break: never.
        m.startGame()
        m.breakNow()
        await settle(m)
        XCTAssertEqual(m.currentAttempt?.isBreak, true)
        XCTAssertFalse(m.everyWorld.canOpen, "never on a break")
        m.everyWorld.open()
        XCTAssertFalse(m.everyWorld.isShowing, "open() does nothing when the gate is shut")
    }

    func testNeverInTheOpening() async {
        let key = GameSettings.seenOpeningKey
        let before = UserDefaults.standard.object(forKey: key)
        UserDefaults.standard.set(false, forKey: key)
        defer { UserDefaults.standard.set(before, forKey: key) }
        let restore = keepChoices(); defer { restore() }
        let m = ShowpieceModel()
        XCTAssertFalse(m.everyWorld.canOpen)
        if m.openingStage != .none {
            m.breakNow()
            await settle(m)
            XCTAssertFalse(m.everyWorld.canOpen, "never in the first minute")
        }
    }

    func testALandingAfterCloseIsDroppedAndTheModelIsUntouched() async {
        let restore = keepChoices(); defer { restore() }
        let m = await potModel()
        let version = m.timelineVersion, layout = m.layout, surface = m.surface
        let attempt = m.currentAttempt?.motionHash
        m.everyWorld.open()
        XCTAssertTrue(m.everyWorld.solving)
        m.everyWorld.close()
        try? await Task.sleep(for: .milliseconds(1500))
        XCTAssertTrue(m.everyWorld.slots.isEmpty, "a closed fan's landings must be dropped")
        XCTAssertNil(m.everyWorld.headline)
        XCTAssertFalse(m.everyWorld.isShowing)
        XCTAssertEqual(m.timelineVersion, version)
        XCTAssertEqual(m.layout, layout)
        XCTAssertEqual(m.surface, surface)
        XCTAssertEqual(m.currentAttempt?.motionHash, attempt)
        XCTAssertFalse(m.isSolving)
    }

    func testTheWhatIfAndTheFanCloseEachOther() async {
        let restore = keepChoices(); defer { restore() }
        let m = await potModel()
        m.everyWorld.open()
        XCTAssertTrue(m.everyWorld.isShowing)
        m.whatIf.open()
        XCTAssertTrue(m.whatIf.isShowing)
        XCTAssertFalse(m.everyWorld.isShowing, "opening the what-if closes the fan")
        m.everyWorld.open()
        XCTAssertTrue(m.everyWorld.isShowing)
        XCTAssertFalse(m.whatIf.isShowing, "opening the fan closes the what-if")
        XCTAssertTrue(m.otherFutureShowing)
        m.everyWorld.close()
        XCTAssertFalse(m.otherFutureShowing)
    }

    func testPlayOnSwitchesToExactlyTheLineThatWasDrawn() async {
        let restore = keepChoices(); defer { restore() }
        let m = await potModel()
        let fan = m.everyWorld
        fan.open()
        await solvedFan(fan)
        XCTAssertFalse(fan.canSwitch, "nothing picked yet")
        guard let target = fan.others.first(where: { fan.world($0) != nil }), let world = fan.world(target) else {
            return XCTFail("no surface solved")
        }
        fan.pick(target)
        XCTAssertEqual(fan.picked, target)
        XCTAssertTrue(fan.canSwitch, "free play with a solved surface picked offers Play on")
        fan.switchToPicked()
        XCTAssertFalse(fan.isShowing, "the switch's load closes the fan")
        XCTAssertEqual(m.surface, target)
        XCTAssertEqual(m.currentAttempt?.motionHash, world.attempt.motionHash,
                       "Play on must play exactly the line that was drawn")
        m.setSurface(.cloth)
    }

    func testPickingAndSteppingSkipHomeAndWrapThroughAll() async {
        let restore = keepChoices(); defer { restore() }
        let m = await potModel()
        let fan = m.everyWorld
        fan.open()
        await solvedFan(fan)
        let solved = fan.others.filter { fan.world($0) != nil }
        guard let first = solved.first, let last = solved.last else { return XCTFail("no surface solved") }
        fan.pick(.cloth)
        XCTAssertNil(fan.picked, "picking home shows all")
        fan.step(by: 1)
        XCTAssertEqual(fan.picked, first)
        fan.step(by: -1)
        XCTAssertNil(fan.picked, "stepping back from the first surface is all again")
        fan.step(by: -1)
        XCTAssertEqual(fan.picked, last, "stepping back from all wraps to the last surface")
    }

    // MARK: Play on is free play's alone

    func testPlayOnIsNeverOfferedInATrickShotsJudgedTry() async {
        let restore = keepChoices(); defer { restore() }
        let m = freshModel()
        let mode = m.trickMode
        let trick = TrickShots.all.first { !$0.pending && !$0.isBreak && $0.solution.elevation == nil }!
        mode.begin(trick)
        defer { mode.end() }
        mode.yourTurn()
        let s = trick.solution
        m.aimDegrees = s.aim + 0.5; m.shotPower = s.power; m.shotTipUp = s.tipUp; m.shotTipSide = s.tipSide
        m.shootNow()
        await settle(m)
        mode.update()
        guard case .judged(let verdict) = mode.phase else { return XCTFail("the try should be judged") }
        let done = mode.doneIDs, version = m.timelineVersion
        XCTAssertTrue(m.everyWorld.canOpen)
        m.everyWorld.open()
        await solvedFan(m.everyWorld)
        if let p = m.everyWorld.others.first(where: { m.everyWorld.world($0) != nil }) {
            m.everyWorld.pick(p)
            XCTAssertNotNil(m.everyWorld.world(p)?.trickPasses, "a trick's fan says whether each surface makes it")
        }
        XCTAssertFalse(m.everyWorld.canSwitch, "never Play on in a trick shot")
        // The fan never judges or marks anything.
        mode.update()
        XCTAssertEqual(mode.phase, .judged(verdict), "the fan must not be judged")
        XCTAssertEqual(mode.doneIDs, done, "the fan must not mark the trick done")
        XCTAssertEqual(m.timelineVersion, version)
    }

    func testPlayOnIsNeverOfferedInALessonsJudgedTry() async {
        let restore = keepChoices(); defer { restore() }
        let m = freshModel()
        let mode = m.lessonMode
        mode.begin(Lessons.stop)
        defer { mode.end() }
        mode.yourTurn()
        m.shootNow()
        await settle(m)
        mode.update()
        guard case .judged = mode.phase else { return XCTFail("try 1 should be judged") }
        XCTAssertTrue(m.everyWorld.canOpen)
        m.everyWorld.open()
        await solvedFan(m.everyWorld)
        if let p = m.everyWorld.others.first(where: { m.everyWorld.world($0) != nil }) { m.everyWorld.pick(p) }
        XCTAssertNotNil(m.everyWorld.picked)
        XCTAssertFalse(m.everyWorld.canSwitch, "never Play on in a lesson")
    }

    func testPlayOnIsNeverOfferedInABehindTheEightBallTry() async {
        let restore = keepChoices(); defer { restore() }
        let m = freshModel()
        let mode = m.eightBallMode
        guard let situation = EightBallSituations.all.first(where: { !$0.escapes.isEmpty }),
              let escape = situation.escapes.first else { return XCTFail("no situation with an escape") }
        mode.begin(situation)
        defer { mode.end() }
        mode.playAsTry(escape)
        await settle(m)
        mode.update()
        // The judge works on a background task; wait for the score.
        var waited = 0
        while !isScored(mode.phase) && waited < 3000 {
            try? await Task.sleep(for: .milliseconds(10)); waited += 1
        }
        guard isScored(mode.phase) else { return XCTFail("the try should be scored") }
        XCTAssertTrue(m.everyWorld.canOpen)
        m.everyWorld.open()
        await solvedFan(m.everyWorld)
        if let p = m.everyWorld.others.first(where: { m.everyWorld.world($0) != nil }) { m.everyWorld.pick(p) }
        XCTAssertNotNil(m.everyWorld.picked)
        XCTAssertFalse(m.everyWorld.canSwitch, "never Play on in a Behind the 8-Ball situation")
    }

    private func isScored(_ phase: EightBallMode.Phase) -> Bool {
        if case .scored = phase { return true }
        return false
    }
}
