// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// PURPOSE: Checks for the Lens clip's script (App/Clips/ClipScript.swift, 0.7.7, plans/23-Nov-2026-clips-plan.md):
//          the seven parts in order and under the 40-second cap; the full-speed part at real speed then capped; the
//          rewind back to the start with the Lens up; every kept moment held for its reading time at exactly its clock;
//          the strike found by its event kind, never assumed to be the first beat; the cut plan driving the replay's
//          speed; the tail and its hold; silence where the film is silent; the same inputs always making the same
//          script; and no clip for a still table. Real solves (the break and the straight pot) and hand-made
//          recordings (TestShots).
// SRP/DRY check: Pass - checks only; the script, the pace plan and the captions are the app's own.
@testable import Breakdown
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import XCTest

final class ClipScriptTests: XCTestCase {
    private let dt = 1.0 / 30

    private func captions(_ tl: Timeline) -> [Caption] { CaptionEngine.make(from: tl, surface: .cloth) }

    private func script(_ tl: Timeline, signature: [Int] = [], file: StaticString = #filePath,
                        line: UInt = #line) -> ClipScript? {
        let s = ClipScript.make(timeline: tl, captions: captions(tl), signature: signature)
        XCTAssertNotNil(s, "no script for a shot with moments", file: file, line: line)
        return s
    }

    private func frames(_ s: ClipScript, _ part: ClipFrame.Part) -> [ClipFrame] { s.frames.filter { $0.part == part } }

    private var shots: [(name: String, timeline: Timeline)] {
        [("break", TestShots.breakShot()), ("straight pot", TestShots.straightPot())]
    }

    // MARK: The parts

    func testThePartsComeInOrderUnderTheCap() {
        for shot in shots {
            guard let s = script(shot.timeline) else { continue }
            XCTAssertLessThanOrEqual(s.duration, ClipScript.hardCap, "\(shot.name): past the 40-second cap")
            var order: [ClipFrame.Part] = []
            for f in s.frames where order.last != f.part { order.append(f.part) }
            XCTAssertEqual(order, [.lead, .fullSpeed, .pause, .melt, .rewind, .replay, .endCard], shot.name)
        }
    }

    func testTheFirstFrameFullSpeedRewindAndEndCard() throws {
        for shot in shots {
            let s = try XCTUnwrap(script(shot.timeline))
            let D = shot.timeline.duration
            XCTAssertEqual(s.frames[0].clock, 0)
            XCTAssertEqual(s.frames[0].melt, 0)
            let full = frames(s, .fullSpeed)
            XCTAssertLessThanOrEqual(Double(full.count) * dt, ClipScript.fullSpeedCap + dt, shot.name)
            XCTAssertGreaterThan(full[0].clock, 0, "\(shot.name): the first full-speed frame has not moved")
            XCTAssertTrue(full[0].sounds, "\(shot.name): the first full-speed frame carries the strike")
            XCTAssertEqual(full.last?.clock ?? -1, D, accuracy: 1e-12, "\(shot.name): full speed ends off the end")
            // Real speed while the clock is under six seconds: exactly a thirtieth of a second a frame.
            for j in 1..<max(1, full.count - 1) where full[j].clock <= ClipScript.realTimeFor - 1e-9 {
                XCTAssertEqual(full[j].clock - full[j - 1].clock, dt, accuracy: 1e-9, "\(shot.name) frame \(j)")
            }
            let rewind = frames(s, .rewind)
            XCTAssertEqual(rewind.last?.clock, 0, "\(shot.name): the rewind does not end at the start")
            XCTAssertEqual(rewind.last?.melt, 1)
            XCTAssertEqual(frames(s, .endCard).count, Int((ClipScript.endCard * 30).rounded()), shot.name)
        }
    }

    // MARK: Holds and beats

    func testEveryKeptMomentIsHeldForItsReadingTime() throws {
        for shot in shots {
            let s = try XCTUnwrap(script(shot.timeline))
            XCTAssertFalse(s.beats.isEmpty)
            XCTAssertLessThanOrEqual(s.beats.count, ClipScript.beatLimit)
            for b in s.beats {
                XCTAssertGreaterThanOrEqual(b.dwell, ClipScript.minDwell)
                XCTAssertLessThanOrEqual(b.dwell, ClipScript.maxDwell)
                let held = s.frames.filter {
                    $0.part == .replay && $0.heldEvent == b.beat.caption.id && $0.clock == b.beat.time
                }
                XCTAssertEqual(Double(held.count), (b.dwell * 30).rounded(), accuracy: 1,
                               "\(shot.name): the hold on event \(b.beat.caption.id) is not its dwell")
            }
            // In clock order.
            let times = s.beats.map(\.beat.time)
            XCTAssertEqual(times, times.sorted(), shot.name)
        }
    }

    func testTheStrikeIsFoundByItsEventKind() throws {
        let tl = TestShots.straightPot()
        let full = PacePlan(captions: captions(tl), timeline: tl, style: .standard)
        let s = try XCTUnwrap(script(tl))
        if let strike = full.beats.first(where: { tl.events[$0.caption.id].kind == .cueStrike }) {
            XCTAssertTrue(s.beats.contains { $0.beat.caption.id == strike.caption.id }, "the strike was not kept")
        }
        // A recording with no strike whose first beat is a cushion: the ranking puts the ball-to-ball hit first and
        // never treats the first beat as the strike.
        let cushion = LensEvent(time: 0.2, kind: .cushion, point: .zero, normal: Vec2(-1, 0), normalImpulse: 0.2,
                                balls: [TestShots.ball(1, before: 1.0, after: -0.8)])
        let hit = LensEvent(time: 0.5, kind: .ballBall, point: .zero, normal: Vec2(1, 0), normalImpulse: 0.3,
                            balls: [TestShots.ball(0, before: 1.0, after: 0.1), TestShots.ball(1, before: 0, after: 0.9)])
        let rec = TestShots.recording([cushion, hit])
        let plan = PacePlan(captions: captions(rec), timeline: rec, style: .standard)
        guard plan.beats.count >= 2 else { return XCTFail("the hand-made recording has fewer than two beats") }
        let ranked = ClipScript.rankedBeats(plan, timeline: rec)
        XCTAssertEqual(rec.events[plan.beats[ranked[0]].caption.id].kind, .ballBall,
                       "the first beat was taken for the strike")
    }

    func testASignatureMomentIsKept() throws {
        let tl = TestShots.breakShot()
        let caps = captions(tl)
        // The latest captioned event: the one the clip would otherwise most likely leave out.
        let last = try XCTUnwrap(caps.last)
        let s = try XCTUnwrap(script(tl, signature: [last.id]))
        XCTAssertTrue(s.beats.contains { $0.beat.caption.id == last.id }, "a signature moment was dropped")
    }

    func testTheCutPlanDrivesTheReplay() throws {
        for shot in shots {
            let s = try XCTUnwrap(script(shot.timeline))
            XCTAssertEqual(s.plan.beats.map(\.time), s.beats.map(\.beat.time), shot.name)
            XCTAssertEqual(s.plan.focusRegions.count, s.plan.beats.count, shot.name)
            // Before the last moment, every frame that moves without arriving steps by its rate over thirty, and
            // its rate is the cut plan's curve times one speed-up k for the whole replay.
            let replay = frames(s, .replay)
            let lastBeat = s.beats.last?.beat.time ?? 0
            var ks: [Double] = []
            for j in 1..<replay.count {
                let a = replay[j - 1], b = replay[j]
                guard b.clock > a.clock, b.heldEvent == nil, b.clock < lastBeat else { continue }
                XCTAssertEqual(b.clock - a.clock, b.rate * dt, accuracy: 1e-9, "\(shot.name) replay frame \(j)")
                ks.append(b.rate / s.plan.rate(at: a.clock))
            }
            if let k = ks.first {
                for other in ks { XCTAssertEqual(other, k, accuracy: 1e-9, "\(shot.name): k changed mid-replay") }
                XCTAssertGreaterThanOrEqual(k, 1 - 1e-9)
            }
        }
    }

    func testTheTailReachesTheEndThenHolds() throws {
        for shot in shots {
            let s = try XCTUnwrap(script(shot.timeline))
            let replay = frames(s, .replay)
            guard let lastHold = replay.lastIndex(where: { $0.heldEvent != nil }) else {
                return XCTFail("\(shot.name): no hold in the replay")
            }
            let tail = Array(replay[(lastHold + 1)...])
            let D = shot.timeline.duration
            // The frame index (within the tail) that first shows the end; -1 when the last moment is the end itself.
            let reach: Int
            if replay[lastHold].clock >= D - 1e-12 {
                reach = -1
            } else if let first = tail.firstIndex(where: { $0.clock >= D - 1e-12 }) {
                reach = first
            } else {
                return XCTFail("\(shot.name): the tail never reaches the end")
            }
            XCTAssertLessThanOrEqual(Double(reach + 1) * dt, ClipScript.tailCap + dt, shot.name)
            let held = tail.filter { $0.clock >= D - 1e-12 && !$0.sounds && $0.rate == 0 }
            XCTAssertGreaterThanOrEqual(held.count, Int((ClipScript.tailHold * 30).rounded()), shot.name)
        }
    }

    // MARK: Silence and sameness

    func testSilenceWhereTheFilmIsSilent() throws {
        for shot in shots {
            let s = try XCTUnwrap(script(shot.timeline))
            for f in s.frames where [.lead, .pause, .melt, .rewind, .endCard].contains(f.part) {
                XCTAssertFalse(f.sounds, "\(shot.name): a \(f.part) frame sounds")
            }
            // Held frames are silent after the arrival frame (which carries the moment's sound).
            let replay = frames(s, .replay)
            for j in 1..<replay.count where replay[j].heldEvent != nil && replay[j].clock == replay[j - 1].clock {
                XCTAssertFalse(replay[j].sounds, "\(shot.name): held frame \(j) sounds")
            }
        }
    }

    func testTheSameInputsMakeTheSameScript() {
        let tl = TestShots.breakShot()
        let caps = captions(tl)
        XCTAssertEqual(ClipScript.make(timeline: tl, captions: caps, signature: []),
                       ClipScript.make(timeline: tl, captions: caps, signature: []))
    }

    func testAStillTableMakesNoClip() {
        let still = TestShots.recording([])
        XCTAssertNil(ClipScript.make(timeline: still, captions: captions(still), signature: []))
    }

    func testKeepingKeepsTheChosenBeatsAndRegions() {
        let tl = TestShots.breakShot()
        let plan = PacePlan(captions: captions(tl), timeline: tl, style: .standard)
        guard plan.beats.count >= 3 else { return XCTFail("the break has fewer than three beats") }
        let chosen = [plan.beats.count - 1, 0]
        let cut = plan.keeping(chosen)
        XCTAssertEqual(cut.beats.count, 2)
        XCTAssertEqual(cut.beats.map(\.time), [plan.beats[0].time, plan.beats[plan.beats.count - 1].time])
        XCTAssertEqual(cut.focusRegions, [plan.focusRegions[0], plan.focusRegions[plan.beats.count - 1]])
    }
}
