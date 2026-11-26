// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// PURPOSE: 0.7.7 achievements' pure reading (App/Achievements/AchievementJudge.swift; plans/23-Nov-2026-achievements-plan.md,
//          Tests) against real solves and hand-made recordings: each authored trick answer, solved the way the app
//          solves it, earns the shot achievement it teaches (the jump also proves "Over the top"'s check that the cue
//          ball passed over a ball); a soft plain pot earns nothing; the first player break earns only the big break, and
//          only when three or more object balls dropped; hand-made recordings prove the jaw, rattle and carom checks; the
//          run of the rack starts, continues, ends and is earned as the plan says; the collections are earned exactly
//          when their content lists are complete (counts read from the lists, never written here); and the drawing for
//          any striking ball matches the trick list's drawing for ball 0.
// Edited: Claude Opus 5.5 Medium, 26-November-2026 (0.7.10 daily: the catalogue count includes the three shot of the day
//          achievements; the daily progress earns them exactly at seven days, thirty days and a first-try make.)
// SRP/DRY check: Pass - checks only. Solving reuses TestShots (EightBallJudge.solve and the break input), the reading of
//          the shot is ShotFacts', the captions CaptionEngine's; the rules are the judge's, not restated here.
@testable import Breakdown
import BreakdownLensModel
import BreakdownPhysics
import BreakdownRules
import BreakdownTimeline
import XCTest

final class AchievementJudgeTests: XCTestCase {
    /// The shot achievement each trick answer must earn, as the plan lists them.
    private let taught: [String: String] = [
        "stop-dead": "dead-stop", "bridge-draw": "draw-back", "masse-curve": "masse-curve", "jump-over": "jump-clear",
        "throw-it": "thrown-in", "combo-chain": "combination", "two-rail-kick": "kick", "cross-bank": "bank",
        "follow-train": "two-at-once",
    ]

    /// A laid-out shot as the model would read it after finishStrike (free play on the pool table, cloth).
    private func context(_ start: [Vec2], _ s: TrickSettings) -> AchievementShotContext {
        let tl = TestShots.shot(from: start, s)
        return AchievementShotContext(timeline: tl, facts: ShotFacts(timeline: tl, start: start, cueBall: 0),
                                      captions: CaptionEngine.make(from: tl, surface: .cloth), table: .standard,
                                      isBreak: false, freePlay: true,
                                      attempt: TestShots.attempt(start: start, timeline: tl, s))
    }

    private func answer(_ id: String, file: StaticString = #filePath, line: UInt = #line)
        -> (start: [Vec2], settings: TrickSettings)? {
        guard let shot = TrickShots.shot(id: id), case .layout(let start) = shot.setup else {
            XCTFail("\(id): no laid-out trick shot with that id", file: file, line: line)
            return nil
        }
        return (start, shot.solution)
    }

    // MARK: Real solves

    func testEachTrickAnswerEarnsWhatItTeaches() {
        for (trick, achievement) in taught.sorted(by: { $0.key < $1.key }) {
            guard let a = answer(trick) else { continue }
            let ids = AchievementJudge.shotAchievements(context(a.start, a.settings)).map(\.id)
            XCTAssertTrue(ids.contains(achievement), "\(trick): expected \(achievement), found \(ids)")
            // Catalogue order, each once.
            XCTAssertEqual(ids, Achievements.shotIDs.filter { ids.contains($0) }, "\(trick): not in catalogue order")
        }
    }

    func testASoftPlainPotEarnsNothing() {
        // ShotHighlightJudgeTests' soft plain pot: one object ball 0.8 m from the top-right corner, the cue ball 0.4 m
        // behind it on the same line, natural roll.
        let r = PoolParameters().ballRadius
        let pocket = Vec2(2.54, 1.27)
        let way = Vec2(0.34, 0.27).normalized
        var start = [Vec2](repeating: ShotFacts.offTable, count: 16)
        start[1] = pocket - way * 0.8
        start[0] = start[1] - way * 0.4
        let aim = atan2(way.y, way.x) * 180 / Double.pi
        let c = context(start, TrickSettings(aim: aim, power: 1.0, tipUp: 0.4 * r, tipSide: 0))
        XCTAssertEqual(c.facts.objectBallsPocketed.map(\.ball), [1], "the soft pot no longer drops the 1")
        XCTAssertEqual(AchievementJudge.shotAchievements(c).map(\.id), [])
    }

    func testTheFirstBreakEarnsOnlyTheBigBreak() {
        let input = TestShots.breakInput()
        let tl = TestShots.solve(input)
        let attempt = ShotAttempt(isBreak: true, breakSeed: 11, start: input.positions, timeline: tl, aim: 0, power: 10,
                                  powerRange: PlayerShotSpeed.ordinary, tipUp: 0, tipSide: 0, elevation: 0, seed: 11,
                                  input: input, surface: .cloth, table: .standard,
                                  generation: input.parameters.modelGeneration)
        let c = AchievementShotContext(timeline: tl, facts: ShotFacts(timeline: tl, start: input.positions, cueBall: 0),
                                       captions: CaptionEngine.make(from: tl, surface: .cloth), table: .standard,
                                       isBreak: true, freePlay: true, attempt: attempt)
        let dropped = Set(tl.events.filter { $0.kind == .pocket }.compactMap { $0.balls.first?.ball }.filter { $0 != 0 })
        let ids = AchievementJudge.shotAchievements(c).map(\.id)
        XCTAssertEqual(ids, dropped.count >= 3 ? ["big-break"] : [], "the break dropped \(dropped.count) object balls")
        // Not on another table.
        let elsewhere = AchievementShotContext(timeline: tl, facts: c.facts, captions: c.captions, table: .bumperPool,
                                               isBreak: true, freePlay: true, attempt: attempt)
        XCTAssertEqual(AchievementJudge.shotAchievements(elsewhere).map(\.id), [])
    }

    // MARK: Hand-made recordings

    private func contact(_ t: Double, _ a: Int, _ b: Int) -> LensEvent {
        LensEvent(time: t, kind: .ballBall, point: .zero, normal: Vec2(1, 0),
                  balls: [TestShots.ball(a, before: 2, after: 0.5), TestShots.ball(b, before: 0, after: 1.5)])
    }

    private func jaw(_ t: Double, ball: Int, pocket: Int) -> LensEvent {
        LensEvent(time: t, kind: .cushion, point: .zero, normal: Vec2(-1, 0),
                  balls: [TestShots.ball(ball, before: 1, after: -0.6)], pocket: pocket, edge: .jaw)
    }

    private func drop(_ t: Double, ball: Int, pocket: Int) -> LensEvent {
        LensEvent(time: t, kind: .pocket, point: .zero, normal: Vec2(1, 0),
                  balls: [TestShots.ball(ball, before: 0.5, after: 0)], pocket: pocket)
    }

    private func moments(_ tl: Timeline) -> ShotMoments { ShotMoments(timeline: tl, captions: []) }

    func testAJawTouchThenADropIsInOffTheJaw() {
        let tl = TestShots.recording([contact(0.2, 0, 1), jaw(0.5, ball: 1, pocket: 2), drop(0.6, ball: 1, pocket: 2)])
        XCTAssertNotNil(AchievementJudge.jawIn(moments(tl), tl))
        XCTAssertNil(AchievementJudge.rattleOut(moments(tl), tl))
    }

    func testAJawTouchOfAnotherPocketIsNotInOffTheJaw() {
        let tl = TestShots.recording([contact(0.2, 0, 1), jaw(0.5, ball: 1, pocket: 3), drop(0.6, ball: 1, pocket: 2)])
        XCTAssertNil(AchievementJudge.jawIn(moments(tl), tl))
    }

    func testTwoJawTouchesAndNoDropRattleOut() {
        let tl = TestShots.recording([contact(0.2, 0, 1), jaw(0.5, ball: 1, pocket: 2), jaw(0.55, ball: 1, pocket: 2)])
        XCTAssertNotNil(AchievementJudge.rattleOut(moments(tl), tl))
        XCTAssertNil(AchievementJudge.jawIn(moments(tl), tl))
    }

    func testOneJawTouchAndNoDropIsNeither() {
        let tl = TestShots.recording([contact(0.2, 0, 1), jaw(0.5, ball: 1, pocket: 2)])
        XCTAssertNil(AchievementJudge.rattleOut(moments(tl), tl))
        XCTAssertNil(AchievementJudge.jawIn(moments(tl), tl))
    }

    func testACaromNeedsTwoDifferentBallsAndTheSecondDrops() {
        let carom = TestShots.recording([contact(0.2, 0, 1), contact(0.4, 0, 2), drop(0.8, ball: 2, pocket: 4)])
        XCTAssertNotNil(AchievementJudge.carom(moments(carom), cue: 0))
        // The same ball twice (a double kiss) is not a carom.
        let kiss = TestShots.recording([contact(0.2, 0, 1), contact(0.4, 0, 1), drop(0.8, ball: 1, pocket: 4)])
        XCTAssertNil(AchievementJudge.carom(moments(kiss), cue: 0))
        // Two balls met, but the second stayed up.
        let up = TestShots.recording([contact(0.2, 0, 1), contact(0.4, 0, 2)])
        XCTAssertNil(AchievementJudge.carom(moments(up), cue: 0))
    }

    // MARK: Running the rack

    func testARunIsEarnedOnTheShotThatClearsTheTable() {
        var run = RunTracker()
        XCTAssertFalse(run.note(isBreak: true, poolRack: true, dropped: 1, scratched: false, objectBallsLeft: 2))
        XCTAssertFalse(run.note(isBreak: false, poolRack: true, dropped: 1, scratched: false, objectBallsLeft: 1))
        XCTAssertTrue(run.note(isBreak: false, poolRack: true, dropped: 1, scratched: false, objectBallsLeft: 0))
    }

    func testAMissAScratchOrADryBreakEndsTheRun() {
        var miss = RunTracker()
        _ = miss.note(isBreak: true, poolRack: true, dropped: 1, scratched: false, objectBallsLeft: 2)
        XCTAssertFalse(miss.note(isBreak: false, poolRack: true, dropped: 0, scratched: false, objectBallsLeft: 2))
        XCTAssertFalse(miss.note(isBreak: false, poolRack: true, dropped: 2, scratched: false, objectBallsLeft: 0))

        var scratch = RunTracker()
        _ = scratch.note(isBreak: true, poolRack: true, dropped: 1, scratched: false, objectBallsLeft: 1)
        XCTAssertFalse(scratch.note(isBreak: false, poolRack: true, dropped: 1, scratched: true, objectBallsLeft: 0))

        var dry = RunTracker()
        XCTAssertFalse(dry.note(isBreak: true, poolRack: true, dropped: 0, scratched: false, objectBallsLeft: 15))
        XCTAssertFalse(dry.note(isBreak: false, poolRack: true, dropped: 15, scratched: false, objectBallsLeft: 0))

        var elsewhere = RunTracker()
        XCTAssertFalse(elsewhere.note(isBreak: true, poolRack: false, dropped: 1, scratched: false, objectBallsLeft: 1))
        XCTAssertFalse(elsewhere.note(isBreak: false, poolRack: false, dropped: 1, scratched: false, objectBallsLeft: 0))
    }

    // MARK: Collections

    func testEveryLessonOnlyWhenAllAreDone() {
        var p = AchievementProgress()
        p.lessonsDone = Set(Lessons.all.map(\.id))
        XCTAssertTrue(AchievementProgress.earned(p).contains(Achievements.everyLesson))
        for lesson in Lessons.all {
            XCTAssertTrue(AchievementProgress.earned(p).contains(Achievements.lessonAchievementID(lesson.id)))
        }
        guard let first = Lessons.all.first else { return XCTFail("no lessons") }
        p.lessonsDone.remove(first.id)
        let earned = AchievementProgress.earned(p)
        XCTAssertFalse(earned.contains(Achievements.everyLesson))
        XCTAssertFalse(earned.contains(Achievements.lessonAchievementID(first.id)))
    }

    func testEveryTrickIgnoresPendingTricks() {
        var p = AchievementProgress()
        p.tricksDone = Set(TrickShots.all.filter { !$0.pending }.map(\.id))
        XCTAssertTrue(AchievementProgress.earned(p).contains(Achievements.everyTrick))
        // No achievement for a pending trick, made or not.
        for trick in TrickShots.all where trick.pending {
            XCTAssertNil(Achievements.achievement(id: Achievements.trickAchievementID(trick.id)))
        }
    }

    func testBeatHardOnlyFromAHardWin() {
        var p = AchievementProgress()
        p.levelsBeaten = [ComputerLevel.easy.rawValue, ComputerLevel.medium.rawValue]
        XCTAssertFalse(AchievementProgress.earned(p).contains(Achievements.levelAchievementID(.hard)))
        p.levelsBeaten.insert(ComputerLevel.hard.rawValue)
        XCTAssertTrue(AchievementProgress.earned(p).contains(Achievements.levelAchievementID(.hard)))
    }

    func testEverySurfaceNeedsEverySurfaceTheMoonIncluded() {
        var p = AchievementProgress()
        p.surfacesPlayed = Set(PlaySurface.allCases.map(\.rawValue)).subtracting([PlaySurface.moon.rawValue])
        XCTAssertFalse(AchievementProgress.earned(p).contains(Achievements.everySurface))
        p.surfacesPlayed.insert(PlaySurface.moon.rawValue)
        XCTAssertTrue(AchievementProgress.earned(p).contains(Achievements.everySurface))
        XCTAssertEqual(p.count(.surfaces).done, PlaySurface.allCases.count)
    }

    func testEveryEscapeNeedsAMedalOnEverySpot() {
        var p = AchievementProgress()
        p.escapesWon = Set(EightBallSituations.all.map(\.id).dropLast())
        XCTAssertFalse(AchievementProgress.earned(p).contains(Achievements.everyEscape))
        p.escapesWon = Set(EightBallSituations.all.map(\.id))
        XCTAssertTrue(AchievementProgress.earned(p).contains(Achievements.everyEscape))
    }

    // 0.7.10 daily: the streak and first-try achievements, from the progress alone.
    func testTheDailyAchievementsAreEarnedFromTheRecord() {
        var p = AchievementProgress()
        p.dailyBestStreak = Achievements.dailyWeekDays - 1
        XCTAssertFalse(AchievementProgress.earned(p).contains(Achievements.dailyStreakWeek))
        p.dailyBestStreak = Achievements.dailyWeekDays
        XCTAssertTrue(AchievementProgress.earned(p).contains(Achievements.dailyStreakWeek))
        XCTAssertFalse(AchievementProgress.earned(p).contains(Achievements.dailyStreakMonth))
        p.dailyBestStreak = Achievements.dailyMonthDays
        XCTAssertTrue(AchievementProgress.earned(p).contains(Achievements.dailyStreakMonth))
        XCTAssertFalse(AchievementProgress.earned(p).contains(Achievements.dailyFirstTry))
        p.dailyFirstTry = true
        XCTAssertTrue(AchievementProgress.earned(p).contains(Achievements.dailyFirstTry))
    }

    // MARK: The catalogue and the drawing

    func testTheCatalogueIsBuiltFromTheContent() {
        let ids = Achievements.all.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "duplicate achievement ids")
        XCTAssertEqual(ids.count, Achievements.shotIDs.count + ComputerLevel.allCases.count + 2 + Lessons.all.count + 1
                       + TrickShots.all.filter { !$0.pending }.count + 1 + 1
                       // 0.7.10 daily: the shot of the day's two streaks and its first-try make.
                       + 3)
        for a in Achievements.all {
            XCTAssertFalse(a.name.isEmpty, a.id)
            XCTAssertFalse(a.sentence.isEmpty, a.id)
            XCTAssertFalse(a.hint.isEmpty, a.id)
        }
    }

    func testTheDrawingForStrikerZeroIsTheTrickListsDrawing() {
        guard let a = answer("stop-dead") else { return }
        let tl = TestShots.shot(from: a.start, a.settings)
        XCTAssertNotNil(TrickPath.traced(tl, start: a.start))
        XCTAssertEqual(TrickPath.traced(tl, start: a.start, striker: 0), TrickPath.traced(tl, start: a.start))
    }
}
