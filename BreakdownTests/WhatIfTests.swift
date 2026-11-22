// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// PURPOSE: The what-if replay in the app (plans/22-Nov-2026-v075-whatif-and-gaps-plan.md, stream whatif, tests). Pure
//          checks on shots struck the way ShowpieceModel.shootNow strikes them (the cue pick, the clearing raise, the
//          stroke's drift, solved through ShowpieceModel.solverCopy): a zero nudge reproduces the attempt's recording
//          on a straight pot, a shot raised to clear a ball, a massé-cue pick, a drifted stroke, another surface and an
//          authored trick layout; each setting's single click is big enough for the retry card to name it, and two
//          settings are "several changes"; every outcome sentence is non-empty. Then the flow on a real model: the
//          entry is offered after a free-play shot and not while solving, on a break, with the menu open, in the
//          opening or while a trick's answer plays; a dropped (stale) solve leaves the model untouched; Keep then Shoot
//          with nothing touched plays exactly the other future and the retry card names the one change; Keep is never
//          offered in a lesson's try 1, for the power while a lesson holds it, or off a trick's start; and a trick
//          what-if never judges or marks a trick done.
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 whatif-review: Keep is checked again with the clock left at
//          the parting point by Where they part.)
// SRP/DRY check: Pass - checked TestShots (its attempt() rebuilds the eight-ball judge's input, not the model's cue and
//          clearing path, so the strike helper here follows shootNow instead), LessonTests and TrickShotJudgeTests
//          (the modes' own verdicts); these test only the what-if.
@testable import Breakdown
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation
import XCTest

@MainActor
final class WhatIfTests: XCTestCase {
    // MARK: Shots struck as the model strikes them

    private let spec = TestShots.parameters().tableSpec
    private let seed: UInt64 = 4242

    /// A shot outside the authored modes as ShowpieceModel.shootNow strikes it: the cue the rule picks for the angle
    /// and tips, its launch speed for the power, the angle raised to clear any ball under the cue, the stroke's drift,
    /// solved through solverCopy on the standard table and `surface` at the default generation. `authored` keeps the
    /// house cue and the chosen angle, as a trick shot does.
    private func strike(_ start: [Vec2], aim: Double, power: Double, tipUp: Double = 0, tipSide: Double = 0,
                        elevation: Double = 0, surface: PlaySurface = .cloth, drift: StrokeDelivery? = nil,
                        authored: Bool = false) -> ShotAttempt {
        let a = aim * Double.pi / 180
        let direction = Vec2(cos(a), sin(a))
        let cue = authored ? CueChoice.standard
            : CueProfile.choice(isBreak: false, elevation: elevation, tipUp: tipUp, tipSide: tipSide)
        let profile = CueProfile.profile(for: cue.kind)
        let clearing = authored ? 0
            : Reach.clearingElevation(layout: start, cueBall: 0, aim: direction, table: spec,
                                      support: drift?.bridge ?? StrokeModel.automaticBridge, cueLength: profile.length)
        var input = NextShot.shot(from: start, direction: direction, speed: profile.launchSpeed(forPower: power),
                                  tipUp: tipUp, tipSide: tipSide, seed: seed,
                                  elevation: authored ? elevation : max(elevation, clearing))
        drift?.apply(to: &input.strike, ballRadius: PoolParameters().ballRadius)
        let generation = PoolParameters().modelGeneration
        let tl = PoolSolver.simulate(ShowpieceModel.solverCopy(input, table: .standard, surface: surface,
                                                               generation: generation))
        return ShotAttempt(isBreak: false, breakSeed: 0, start: start, timeline: tl, aim: aim, power: power,
                           powerRange: PlayerShotSpeed.ordinary, tipUp: tipUp, tipSide: tipSide, elevation: elevation,
                           seed: seed, input: input, surface: surface, table: .standard, generation: generation,
                           stroke: drift)
    }

    /// The other future for `steps`, solved exactly as the fork solves it (off the main actor there; here directly).
    private func future(_ real: ShotAttempt, _ steps: WhatIfFork.Steps, authored: Bool = false)
        -> (attempt: ShotAttempt, fork: TimelineFork)? {
        let built = WhatIfFork.build(real: real, steps: steps, authored: authored, tipLimit: 0.025)
        let solvable = ShowpieceModel.solverCopy(built.input, table: real.table, surface: real.surface,
                                                 generation: real.generation)
        guard let tl = PoolSolver.simulate(solvable, eventBudget: WhatIfFork.eventBudget) else { return nil }
        let fork = TimelineFork.find(real: real.timeline, alternate: tl, start: real.start, cueBall: real.cueBall,
                                     ballRadius: real.timeline.table.ballRadius)
        return (WhatIfFork.alternateAttempt(real: real, built: built, timeline: tl), fork)
    }

    /// The cue ball, the 1 half a metre ahead and three balls elsewhere; every other ball off the table.
    private func layout(blocker: Bool = false) -> [Vec2] {
        var l = [Vec2](repeating: NextShot.offTable, count: 16)
        l[0] = Vec2(0.70, 0.60)
        l[1] = Vec2(1.20, 0.60)
        l[2] = Vec2(1.90, 0.30)
        l[3] = Vec2(2.00, 1.00)
        // A ball just behind the cue ball, on the cue's line: the cue must be raised to clear it.
        if blocker { l[4] = Vec2(0.62, 0.61) }
        return l
    }

    /// The straight pot of the Ride demo: the cue ball, one object ball and the far corner.
    private func straightPotLayout() -> (start: [Vec2], aim: Double) {
        let input = RideDemo.straightPot()
        let d = input.strike.direction
        return (input.positions, atan2(d.y, d.x) * 180 / Double.pi)
    }

    // MARK: A zero nudge reproduces the shot

    private func assertZeroNudgeReproduces(_ real: ShotAttempt, authored: Bool = false, _ name: String,
                                           file: StaticString = #filePath, line: UInt = #line) {
        guard let f = future(real, WhatIfFork.Steps(), authored: authored) else {
            return XCTFail("\(name): the zero nudge ran out of events", file: file, line: line)
        }
        XCTAssertEqual(f.attempt.motionHash, real.motionHash, "\(name): the zero nudge changed the shot",
                       file: file, line: line)
        XCTAssertTrue(f.fork.identical, "\(name): the fork should see one future", file: file, line: line)
    }

    func testAZeroNudgeReproducesEveryKindOfShot() {
        let pot = straightPotLayout()
        assertZeroNudgeReproduces(strike(pot.start, aim: pot.aim, power: 2.5), "straight pot on cloth")
        let raised = strike(layout(blocker: true), aim: 0, power: 3)
        XCTAssertGreaterThan(raised.input.strike.elevation, 0, "precondition: the cue rose over the 4")
        assertZeroNudgeReproduces(raised, "a shot raised to clear a ball")
        let masse = strike(layout(), aim: 0, power: 2, tipSide: 0.006, elevation: CueAngleMenu.sine(forAngle: 50))
        XCTAssertEqual(CueProfile.choice(isBreak: false, elevation: masse.elevation, tipUp: 0, tipSide: 0.006).kind,
                       .masse, "precondition: the massé cue is picked")
        assertZeroNudgeReproduces(masse, "a massé-cue pick")
        let drift = StrokeDelivery(aimError: 0.002, tipSideError: 0.0007, swing: 1.2, calmTopSwing: 2, fullPower: false,
                                   bridge: 0.22)
        assertZeroNudgeReproduces(strike(layout(), aim: 1.5, power: 3, drift: drift), "a drifted stroke")
        assertZeroNudgeReproduces(strike(pot.start, aim: pot.aim, power: 2.5, surface: .ice), "another surface")
        let trick = TrickShots.all.first { !$0.pending && !$0.isBreak }!
        guard case .layout(let positions) = trick.setup else { return XCTFail("the first trick has a layout") }
        let s = trick.solution
        assertZeroNudgeReproduces(strike(positions, aim: s.aim, power: s.power, tipUp: s.tipUp, tipSide: s.tipSide,
                                         elevation: s.elevation ?? 0, authored: true),
                                  authored: true, "an authored trick layout")
    }

    // MARK: One click is always a nameable change

    func testEachSingleClickIsNamedAsTheOneChange() {
        let real = strike(layout(), aim: 0, power: 3, elevation: CueAngleMenu.sine(forAngle: 10))
        for control in WhatIfFork.Control.allCases {
            var steps = WhatIfFork.Steps()
            steps[control] = 1
            let after = WhatIfFork.value(control, real: real, steps: steps, tipLimit: 0.025)
            let change = RetryComparison.InputChange(control: control.comparison,
                                                     before: real.value(of: control.comparison), after: after)
            XCTAssertTrue(ShotComparison.isDescribable(change, in: real), "\(control): one click is too small to name")
            guard let f = future(real, steps) else { XCTFail("\(control): ran out of events"); continue }
            XCTAssertEqual(RetryComparison.between(real, f.attempt).key, .oneChange(control.comparison),
                           "\(control): the retry card would not name it")
        }
        var two = WhatIfFork.Steps()
        two.aim = 1
        two.power = -1
        guard let f = future(real, two) else { return XCTFail("two changes ran out of events") }
        XCTAssertEqual(RetryComparison.between(real, f.attempt).key, .severalChanges)
    }

    // MARK: The words

    func testEveryOutcomeGivesASentence() {
        let pot = straightPotLayout()
        let made = strike(pot.start, aim: pot.aim, power: 2.5)
        let missed = strike(pot.start, aim: pot.aim + 2, power: 2.5)
        let softer = strike(pot.start, aim: pot.aim, power: 1.2)
        let raised = strike(layout(blocker: true), aim: 0, power: 3)
        var pairs: [(ShotAttempt, WhatIfFork.Steps)] = []
        for real in [made, missed, softer, raised] {
            for control in [WhatIfFork.Control.aim, .power, .tipUp, .tipSide] {
                for n in [1, -1, 8, -8] {
                    var s = WhatIfFork.Steps()
                    s[control] = n
                    pairs.append((real, s))
                }
            }
        }
        var two = WhatIfFork.Steps()
        two.aim = 3; two.tipUp = -2
        pairs.append((made, two))
        for (real, steps) in pairs {
            guard let f = future(real, steps) else { continue }
            let r = WhatIfFork.Result(steps: steps, alternate: f.attempt, fork: f.fork,
                                      comparison: RetryComparison.between(real, f.attempt), passes: nil,
                                      realPasses: nil, raisedOver: nil)
            XCTAssertFalse(WhatIfWords.outcome(r, real: real).isEmpty)
            let all = WhatIfWords.sentences(r, real: real)
            XCTAssertFalse(all.isEmpty)
            XCTAssertTrue(all.allSatisfy { !$0.isEmpty })
        }
    }

    // MARK: The flow on a real model

    /// A model past the opening with the menu closed, in free play.
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

    /// Waits for the fork's solve.
    private func solved(_ w: WhatIfFork) async {
        var waited = 0
        while w.solving && waited < 1000 { try? await Task.sleep(for: .milliseconds(10)); waited += 1 }
    }

    /// A free-play shot from `start`, played out.
    private func freePlayShot(_ m: ShowpieceModel, _ start: [Vec2], aim: Double, power: Double) async {
        m.loadTrickLayout(start, aim: aim, power: power, tipUp: 0, tipSide: 0)
        m.shootNow()
        XCTAssertFalse(m.whatIf.canOpen, "never while the shot is being solved")
        await settle(m)
    }

    func testTheEntryIsOfferedOnlyAfterTheShotHasPlayedOut() async {
        let m = freshModel()
        let pot = straightPotLayout()
        await freePlayShot(m, pot.start, aim: pot.aim, power: 2.5)
        XCTAssertTrue(m.whatIf.canOpen, "a free-play shot at rest should offer the what-if")
        m.openMenu()
        XCTAssertFalse(m.whatIf.canOpen, "not with the menu open")
        m.closeMenu()
        XCTAssertTrue(m.whatIf.canOpen)
        // A break: never.
        m.startGame()
        m.breakNow()
        await settle(m)
        XCTAssertEqual(m.currentAttempt?.isBreak, true)
        XCTAssertFalse(m.whatIf.canOpen, "never on a break")
    }

    func testNeverInTheOpening() async {
        let key = GameSettings.seenOpeningKey
        let before = UserDefaults.standard.object(forKey: key)
        UserDefaults.standard.set(false, forKey: key)
        defer { UserDefaults.standard.set(before, forKey: key) }
        let m = ShowpieceModel()
        XCTAssertFalse(m.whatIf.canOpen)
        // The first stroke of the opening plays the part of the first break.
        if m.openingStage != .none {
            m.breakNow()
            await settle(m)
            XCTAssertFalse(m.whatIf.canOpen, "never in the first minute")
        }
    }

    func testAStaleSolveIsDroppedAndTheModelIsUntouched() async {
        let m = freshModel()
        let pot = straightPotLayout()
        await freePlayShot(m, pot.start, aim: pot.aim, power: 2.5)
        let version = m.timelineVersion, duration = m.duration, layout = m.layout
        let attempt = m.currentAttempt?.motionHash
        func unchanged(_ when: String) {
            XCTAssertFalse(m.isSolving, when)
            XCTAssertEqual(m.timelineVersion, version, when)
            XCTAssertEqual(m.duration, duration, when)
            XCTAssertEqual(m.layout, layout, when)
            XCTAssertEqual(m.currentAttempt?.motionHash, attempt, when)
        }
        m.whatIf.open()
        XCTAssertTrue(m.whatIf.isShowing)
        m.whatIf.nudge(.aim, by: 1)
        XCTAssertTrue(m.whatIf.solving)
        unchanged("while the what-if solves")
        m.whatIf.close()
        try? await Task.sleep(for: .milliseconds(800))
        XCTAssertNil(m.whatIf.result, "a closed what-if's solve must be dropped")
        XCTAssertFalse(m.whatIf.isShowing)
        unchanged("after the dropped solve")
        // Opened again and solved: still nothing on the model moves.
        m.whatIf.open()
        m.whatIf.nudge(.power, by: 1)
        await solved(m.whatIf)
        XCTAssertNotNil(m.whatIf.result)
        unchanged("after a solve that landed")
    }

    func testKeepThenShootPlaysTheOtherFutureExactly() async {
        let m = freshModel()
        let pot = straightPotLayout()
        await freePlayShot(m, pot.start, aim: pot.aim, power: 2.5)
        m.whatIf.open()
        m.whatIf.nudge(.aim, by: 1)
        await solved(m.whatIf)
        guard let alternate = m.whatIf.result?.alternate else { return XCTFail("no other future") }
        XCTAssertTrue(m.whatIf.canKeep)
        // Where they part leaves the clock part way through the shot: Keep stays offered and still arms the retry.
        m.whatIf.jumpToParting()
        XCTAssertTrue(m.whatIf.canKeep, "Keep must not drop out while the clock sits at the parting")
        m.whatIf.keep()
        XCTAssertFalse(m.whatIf.isShowing)
        XCTAssertNotNil(m.keptStrike, "the kept strike should be armed")
        XCTAssertEqual(m.aimDegrees, alternate.aim, accuracy: 1e-12)
        m.shootNow()
        await settle(m)
        XCTAssertEqual(m.currentAttempt?.motionHash, alternate.motionHash, "Shoot untouched must play the kept future")
        XCTAssertEqual(m.retryComparison?.key, .oneChange(.aim))
    }

    func testKeepIsNotOfferedInLessonTryOneOrForAHeldPower() async {
        let m = freshModel()
        let mode = m.lessonMode
        mode.begin(Lessons.stop)
        defer { mode.end() }
        // Try 1: everything locked to the lesson's stroke.
        mode.yourTurn()
        m.shootNow()
        m.scrub(to: m.duration)
        mode.update()
        guard case .judged(.try1, _) = mode.phase else { return XCTFail("try 1 should be judged") }
        XCTAssertTrue(m.whatIf.canOpen)
        m.whatIf.open()
        XCTAssertEqual(m.whatIf.sections, [.spin], "try 1 shows the lesson's own setting")
        // Toward the centre, so the click is never clamped by the tip's travel.
        m.whatIf.nudge(.tipUp, by: Lessons.stop.reference.tipUp < 0 ? 1 : -1)
        await solved(m.whatIf)
        XCTAssertNotNil(m.whatIf.result)
        XCTAssertFalse(m.whatIf.canKeep, "never in try 1")
        m.whatIf.close()
        // Try 3: the power is held at the lesson's stroke.
        mode.nextStep()
        mode.nextStep()
        XCTAssertTrue(mode.powerHeld)
        m.shootNow()
        m.scrub(to: m.duration)
        mode.update()
        guard case .judged(.try3, _) = mode.phase else { return XCTFail("try 3 should be judged") }
        m.whatIf.open()
        m.whatIf.nudge(.power, by: 1)
        await solved(m.whatIf)
        XCTAssertNotNil(m.whatIf.result)
        XCTAssertFalse(m.whatIf.canKeep, "never the power while the lesson holds it")
        m.whatIf.reset()
        m.whatIf.nudge(.tipUp, by: Lessons.stop.reference.tipUp < 0 ? 1 : -1)
        await solved(m.whatIf)
        XCTAssertTrue(m.whatIf.canKeep, "an open setting may be kept in try 3")
    }

    func testATrickWhatIfNeverJudgesOrMarksAnything() async {
        let m = freshModel()
        let mode = m.trickMode
        let trick = TrickShots.all.first { !$0.pending && !$0.isBreak && $0.solution.elevation == nil }!
        mode.begin(trick)
        defer { mode.end() }
        // While the answer plays (and after, before Your turn), the entry is never offered.
        mode.watch()
        m.scrub(to: m.duration)
        XCTAssertEqual(mode.phase, .watching)
        XCTAssertFalse(m.whatIf.canOpen, "never while the answer is the attempt on screen")
        mode.yourTurn()
        // The answer's stroke a little off line, judged as the player's try.
        let s = trick.solution
        m.aimDegrees = s.aim + 0.5; m.shotPower = s.power; m.shotTipUp = s.tipUp; m.shotTipSide = s.tipSide
        m.shootNow()
        m.scrub(to: m.duration)
        mode.update()
        guard case .judged(let verdict) = mode.phase else { return XCTFail("the try should be judged") }
        let done = mode.doneIDs, version = m.timelineVersion
        XCTAssertTrue(m.whatIf.canOpen)
        m.whatIf.open()
        m.whatIf.nudge(.aim, by: -2)
        await solved(m.whatIf)
        XCTAssertNotNil(m.whatIf.result?.passes, "a trick what-if says whether it makes the shot")
        mode.update()
        XCTAssertEqual(mode.phase, .judged(verdict), "the what-if must not be judged")
        XCTAssertEqual(mode.doneIDs, done, "the what-if must not mark the trick done")
        XCTAssertEqual(m.timelineVersion, version)
        // A shot from where the balls stopped is off the trick's start: no what-if, so nothing to keep. (Only when that
        // shot could be played: a scratch would leave the cue ball to be placed first.)
        m.whatIf.close()
        m.shootNow()
        m.scrub(to: m.duration)
        mode.update()
        if mode.phase == .offScript {
            XCTAssertFalse(m.whatIf.canOpen)
            m.whatIf.open()
            XCTAssertFalse(m.whatIf.isShowing)
        }
        XCTAssertFalse(m.whatIf.canKeep)
    }

    func testSolverCopyReproducesTheRecordingOnScreen() async {
        let m = freshModel()
        let pot = straightPotLayout()
        await freePlayShot(m, pot.start, aim: pot.aim, power: 2.5)
        guard let a = m.currentAttempt else { return XCTFail("no attempt") }
        let again = PoolSolver.simulate(ShowpieceModel.solverCopy(a.input, table: a.table, surface: a.surface,
                                                                  generation: a.generation))
        XCTAssertEqual(again.contentHash, a.timeline.contentHash)
    }
}
