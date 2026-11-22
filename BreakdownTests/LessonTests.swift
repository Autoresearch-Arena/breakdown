// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The lesson path's shipping data (App/Lessons/Lessons.swift) against real solves on the standard cloth, so the
//          file that ships is checked, not only the copy the package's content check holds (BreakProbe's ContentVerify):
//          every lesson's reference settings are judged made by the trick-shot judge with the lesson's own praise; every
//          lesson's Watch beat finds its moment in the reference recording; the stop shot's second exercise is made with
//          its own answer and MISSED when the stop lesson's settings are copied onto it (plan 14, section 4); and the
//          target bands lie inside what the controls can set (the tip travel, the player's power range, the cue angles
//          the menu offers). Also the lesson flow's locks: which controls each step opens.
// Edited: Claude Opus 5.5 High, 21-November-2026 (proof plan package 4: the reach check is the miscue limit of the
//          default physics instead of the old 20 mm tip travel.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.5 learn-modes stream: the lesson's cue-angle line comes out
//          through the trick judge's shared check, handed the lesson's band.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0 integration: try 3 and the pass shot of a lesson not about power
//          keep the power held, so the steps test expects every control but the power, and no power band.)
// Edited: Claude Opus 5.5 High, 21-November-2026 (bug plan after 0.6.6, item 10: every lesson and the exercise must be
//          played from a square stance by the app's own reach ladder. The numbers now come from the package library.)
// SRP/DRY check: Pass - checks only. Solving and attempts come from TestShots (the model's own path); the verdicts are
//          TrickShotJudge's; the flow is LessonMode's.
@testable import Breakdown
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation
import XCTest

@MainActor
final class LessonTests: XCTestCase {
    private func play(_ layout: [Vec2], _ s: TrickSettings) -> ShotAttempt {
        TestShots.attempt(start: layout, timeline: TestShots.shot(from: layout, s), s)
    }

    func testTheSixLessonsAreInTheirOrder() {
        XCTAssertEqual(Lessons.all.map(\.id), ["lesson-stop", "lesson-follow", "lesson-draw", "lesson-cut",
                                               "lesson-curve", "lesson-jump"])
        XCTAssertEqual(Lessons.all.map(\.number), [1, 2, 3, 4, 5, 6])
        for lesson in Lessons.all {
            XCTAssertNotNil(TrickShots.shot(id: lesson.trickID), "\(lesson.id): suggests a trick shot that does not exist")
        }
    }

    func testEveryReferenceIsMade() {
        for lesson in Lessons.all {
            let attempt = play(lesson.layout, lesson.reference)
            let verdict = TrickShotJudge.verdict(for: lesson.trick, attempt: attempt)
            XCTAssertTrue(verdict.made, "\(lesson.id): the reference no longer works (\(verdict.line))")
            XCTAssertEqual(verdict.line, lesson.praise, lesson.id)
        }
    }

    func testEveryWatchBeatFindsItsMoment() {
        for lesson in Lessons.all {
            let tl = TestShots.shot(from: lesson.layout, lesson.reference)
            guard let t = lesson.moment.time(in: tl) else { XCTFail("\(lesson.id): no \(lesson.moment) in the reference"); continue }
            XCTAssertGreaterThan(t, 0, lesson.id)
            XCTAssertLessThan(t, tl.duration, lesson.id)
        }
    }

    func testTheSecondExerciseNeedsATipChange() {
        let exercise = Lessons.stopExercise
        let own = TrickShotJudge.verdict(for: exercise.trick, attempt: play(exercise.layout, exercise.reference))
        XCTAssertTrue(own.made, "the exercise's own answer no longer works (\(own.line))")
        // Copying the stop lesson: its aim (the same line), power and tip, from the further-back cue ball.
        let copied = TrickSettings(aim: exercise.reference.aim, power: Lessons.stop.reference.power,
                                   tipUp: Lessons.stop.reference.tipUp, tipSide: 0)
        XCTAssertEqual(copied.aim, Lessons.stop.reference.aim, accuracy: 1e-9, "the exercise must keep the lesson's line")
        XCTAssertFalse(TrickShotJudge.verdict(for: exercise.trick, attempt: play(exercise.layout, copied)).made,
                       "copying the stop lesson's settings makes the exercise, so it no longer tests anything")
    }

    func testTargetBandsAreWithinReach() {
        // Every reference keeps its tip inside the miscue limit of the default physics (generation two since the proof
        // plan's package 4): a lesson must never ask for a stroke that slips.
        let grip = PoolParameters().miscueOffsetLimit
        for lesson in Lessons.all {
            let r = lesson.reference, w = lesson.window
            XCTAssertLessThanOrEqual((r.tipUp * r.tipUp + r.tipSide * r.tipSide).squareRoot(), grip,
                                     "\(lesson.id): reference tip past the miscue limit")
            XCTAssertTrue(PlayerShotSpeed.ordinary.contains(r.power), "\(lesson.id): reference power out of range")
            XCTAssertGreaterThan(w.tipUp, 0, lesson.id)
            XCTAssertGreaterThan(w.power, 0, lesson.id)
            XCTAssertGreaterThan(w.aim, 0, lesson.id)
            if let angles = lesson.cueAngles {
                XCTAssertTrue(CueAngleMenu.angles.contains(angles.lowerBound), lesson.id)
                XCTAssertTrue(CueAngleMenu.angles.contains(angles.upperBound), lesson.id)
                let referenceAngle = CueAngleMenu.nearestAngle(toSine: r.elevation ?? 0)
                XCTAssertTrue(angles.contains(referenceAngle), "\(lesson.id): reference angle outside its own band")
                XCTAssertEqual(CueAngleMenu.sine(forAngle: referenceAngle), r.elevation ?? 0, accuracy: 1e-12,
                               "\(lesson.id): the reference cue angle is not one the menu can set exactly")
            } else {
                XCTAssertEqual(r.elevation ?? 0, 0, "\(lesson.id): a level-cue lesson raises the cue")
            }
        }
    }

    // Item 10 of the bug plan after 0.6.6: every lesson, and the stop shot's exercise, is played from a square stance,
    // as the app's own reach ladder works it out with the automatic hand bridge (a lesson never uses the mechanical
    // bridge), so the stance card stays away and no lesson opens with a card about a rest it never uses.
    func testEveryLessonIsPlayedStandingSquare() {
        let table = PoolParameters().tableSpec
        func square(_ layout: [Vec2], _ s: TrickSettings, _ name: String) {
            let a = s.aim * Double.pi / 180
            guard let stance = Reach.stance(layout: layout, cueBall: 0, aim: Vec2(cos(a), sin(a)), table: table,
                                            bridge: StrokeModel.automaticBridge, mechanical: false) else {
                XCTFail("\(name): no stance"); return
            }
            XCTAssertTrue(stance.isNormal, "\(name): \(stance.rung) with a reach of \(stance.reach) m")
        }
        for lesson in Lessons.all { square(lesson.layout, lesson.reference, lesson.id) }
        square(Lessons.stopExercise.layout, Lessons.stopExercise.reference, "lesson-stop-exercise")
    }

    // 0.7.5: the lesson's cue-angle line now comes from the trick judge's shared check (TrickShotJudge.cueAngleLine),
    // handed the lesson's own marked band, as LessonMode.judge does. A level cue at the jump lesson is told to raise it;
    // the curve lesson struck at 80 degrees, far above its 25 to 30 degree band (BreakProbe verify: it makes it only at
    // 25 and 30), is told to lower it; and the reference itself, inside its band, is made with its praise.
    func testTheCueAngleLineComesFromTheSharedCheck() throws {
        let jump = try XCTUnwrap(Lessons.all.first { $0.id == "lesson-jump" })
        let curve = try XCTUnwrap(Lessons.all.first { $0.id == "lesson-curve" })
        var level = jump.reference
        level.elevation = nil
        let levelVerdict = TrickShotJudge.verdict(for: jump.trick, attempt: play(jump.layout, level), cueAngles: jump.cueAngles)
        XCTAssertFalse(levelVerdict.made, "a level cue made the jump lesson")
        XCTAssertEqual(levelVerdict.line, String(localized: "Raise the cue more. A level cue cannot do this one."))
        var steep = curve.reference
        steep.elevation = CueAngleMenu.sine(forAngle: 80)
        let steepVerdict = TrickShotJudge.verdict(for: curve.trick, attempt: play(curve.layout, steep), cueAngles: curve.cueAngles)
        XCTAssertFalse(steepVerdict.made, "the curve lesson was made at 80 degrees")
        XCTAssertEqual(steepVerdict.line, String(localized: "The cue is too steep. Lower it a little."))
        let own = TrickShotJudge.verdict(for: curve.trick, attempt: play(curve.layout, curve.reference), cueAngles: curve.cueAngles)
        XCTAssertTrue(own.made, own.line)
        XCTAssertEqual(own.line, curve.praise)
    }

    func testEachStepOpensTheRightControls() {
        let model = ShowpieceModel()
        let mode = model.lessonMode
        XCTAssertEqual(mode.openControls, .all, "outside a lesson everything is open")
        mode.begin(Lessons.stop)
        defer { mode.end() }
        XCTAssertEqual(mode.phase, .ready)
        XCTAssertEqual(mode.openControls, .all)

        // Try 1: everything set to the reference and locked; the model refuses a change from any route.
        mode.yourTurn()
        XCTAssertEqual(mode.step, .try1)
        XCTAssertEqual(mode.openControls, [])
        XCTAssertNil(mode.zones)
        XCTAssertEqual(model.shotTipUp, Lessons.stop.reference.tipUp, accuracy: 1e-12)
        model.activeTipUp = 0.015
        XCTAssertEqual(model.shotTipUp, Lessons.stop.reference.tipUp, accuracy: 1e-12, "try 1 let the tip move")
        let aim = model.aimDegrees
        model.nudgeAim(8)
        XCTAssertEqual(model.aimDegrees, aim, accuracy: 1e-12, "try 1 let the aim move")

        // Try 2: only the lesson's control, starting from neutral, with its band at the reference plus its window.
        mode.nextStep()
        XCTAssertEqual(mode.step, .try2)
        XCTAssertEqual(mode.openControls, .tipUp)
        XCTAssertEqual(model.shotTipUp, 0, accuracy: 1e-12, "try 2 must start the lesson's control from neutral")
        let r = Lessons.stop.reference, w = Lessons.stop.window
        XCTAssertEqual(mode.zones?.tipUp, (r.tipUp - w.tipUp)...(r.tipUp + w.tipUp))
        XCTAssertNil(mode.zones?.power)
        model.activeTipUp = r.tipUp
        XCTAssertEqual(model.shotTipUp, r.tipUp, accuracy: 1e-12, "try 2 must let the tip height move")
        model.activeTipSide = 0.01
        XCTAssertEqual(model.shotTipSide, 0, accuracy: 1e-12, "try 2 let the side move")

        // Try 3: everything open but the power, every band faint. Stop is not a power lesson, so its power stays held
        // at the lesson's stroke (0.7.0 bug plan item 11, LessonMode.powerHeld) and carries no band. Pass shot: the
        // same controls, nothing marked.
        mode.nextStep()
        XCTAssertEqual(mode.step, .try3)
        XCTAssertTrue(mode.powerHeld)
        XCTAssertEqual(mode.openControls, ShotControls.all.subtracting(.power))
        XCTAssertLessThan(mode.zones?.strength ?? 1, 1)
        XCTAssertNil(mode.zones?.power)
        mode.nextStep()
        XCTAssertEqual(mode.step, .pass)
        XCTAssertEqual(mode.openControls, ShotControls.all.subtracting(.power))
        XCTAssertNil(mode.zones)
    }
}
