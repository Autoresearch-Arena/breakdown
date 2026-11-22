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
// SRP/DRY check: Pass - checks only. Solving and attempts come from TestShots (the model's own path); the verdicts are
//          TrickShotJudge's; the flow is LessonMode's.
@testable import Breakdown
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
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

        // Try 3: everything open, every band faint. Pass shot: everything open, nothing marked.
        mode.nextStep()
        XCTAssertEqual(mode.step, .try3)
        XCTAssertEqual(mode.openControls, .all)
        XCTAssertLessThan(mode.zones?.strength ?? 1, 1)
        XCTAssertNotNil(mode.zones?.power)
        mode.nextStep()
        XCTAssertEqual(mode.step, .pass)
        XCTAssertEqual(mode.openControls, .all)
        XCTAssertNil(mode.zones)
    }
}
