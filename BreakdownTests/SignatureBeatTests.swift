// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// PURPOSE: 0.7.4 G1, "signature beats" (plans/22-Nov-2026-v074-glow-up-plan.md, stream lens-pacing). Every authored
//          trick answer is solved exactly as the app solves it (TestShots.shot, the trick-shot path: the standard table
//          and cloth written into a NextShot.shot from the authored layout, then PoolSolver.simulate) and captioned with
//          CaptionEngine. Then: TrickSignature finds at least one captioned event for each of the eleven shots (at most
//          two, in clock order); a standard PacePlan given that signature holds every one of those events as a headline
//          beat and stays short; the jump's signature is its take-off and landing and the masse's ends a bend; the
//          jump's standard plan with NO signature still holds its take-off; an unknown id has no signature; and the
//          first launch's plan of the showpiece break is untouched (four beats at most, no flight beat, and a
//          signature changes nothing).
// SRP/DRY check: Pass - checks only. Solving reuses TestShots (EightBallJudge.solve); the signatures, the plan and the
//          captions are the app's own; nothing here decides which events a shot is about.
@testable import Breakdown
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import XCTest

final class SignatureBeatTests: XCTestCase {
    /// The eleven shots of the library when 0.7.4 began. The two new ones (squirt, side-off-rail) are the trick-shots
    /// stream's; TrickSignature maps them already, and their own tests come with them.
    private let elevenIDs = ["called-break", "stop-dead", "bridge-draw", "follow-train", "two-rail-kick", "cross-bank",
                             "combo-chain", "throw-it", "masse-curve", "jump-over", "draw-masse-carom"]

    /// A trick's authored answer, solved and captioned the way the app shows it. Every authored shot is a laid-out
    /// position (the Called Break too), so a missing layout is a failure, not a skip.
    private func answer(_ id: String, file: StaticString = #filePath, line: UInt = #line)
        -> (timeline: Timeline, captions: [Caption])? {
        guard let shot = TrickShots.shot(id: id) else {
            XCTFail("\(id): no such trick shot", file: file, line: line)
            return nil
        }
        guard case .layout(let start) = shot.setup else {
            XCTFail("\(id): not a laid-out position", file: file, line: line)
            return nil
        }
        let tl = TestShots.shot(from: start, shot.solution)
        return (tl, CaptionEngine.make(from: tl, surface: .cloth))
    }

    func testEveryTrickHasACaptionedSignature() {
        for id in elevenIDs {
            guard let a = answer(id) else { continue }
            let sig = TrickSignature.events(forTrick: id, in: a.timeline, captions: a.captions)
            XCTAssertFalse(sig.isEmpty, "\(id): no signature event")
            XCTAssertLessThanOrEqual(sig.count, 2, id)
            let captioned = Set(a.captions.map(\.id))
            for ev in sig { XCTAssertTrue(captioned.contains(ev), "\(id): signature event \(ev) has no caption") }
            let times = sig.map { a.timeline.events[$0].time }
            XCTAssertEqual(times, times.sorted(), "\(id): signature not in clock order")
            XCTAssertEqual(Set(sig).count, sig.count, "\(id): an event twice")
        }
    }

    func testEverySignatureEventIsHeldAsAHeadlineBeat() {
        for id in elevenIDs {
            guard let a = answer(id) else { continue }
            let sig = TrickSignature.events(forTrick: id, in: a.timeline, captions: a.captions)
            let plan = PacePlan(captions: a.captions, timeline: a.timeline, style: .standard, signature: sig)
            for ev in sig {
                XCTAssertTrue(plan.beats.contains { $0.caption.id == ev && $0.headline },
                              "\(id): signature event \(ev) is not a headline beat")
            }
            // A signature replay is short: the strike, the first hit, the signature and little else.
            XCTAssertLessThanOrEqual(plan.beats.count, max(3, sig.count + 3), id)
            // Only signature beats are headlines in a standard plan (the opening's two belong to .opening).
            for beat in plan.beats where beat.headline {
                XCTAssertTrue(sig.contains(beat.caption.id), "\(id): beat \(beat.caption.id) is a headline but not signature")
            }
        }
    }

    func testTheJumpHoldsItsTakeOffAndLanding() {
        guard let a = answer("jump-over") else { return }
        let sig = TrickSignature.events(forTrick: "jump-over", in: a.timeline, captions: a.captions)
        XCTAssertEqual(sig.map { a.timeline.events[$0].flight }, [.takeOff, .landing])
    }

    func testTheMasseHoldsTheEndOfItsBend() {
        guard let a = answer("masse-curve") else { return }
        let sig = TrickSignature.events(forTrick: "masse-curve", in: a.timeline, captions: a.captions)
        let bends = CaptionEngine.bendEvents(in: a.timeline)
        XCTAssertTrue(sig.contains { ev in (bends[ev] ?? []).contains { bend in bend.ball == 0 } },
                      "the masse's signature is not the end of a bend of the cue ball")
    }

    func testTheJumpHoldsItsTakeOffWithoutASignature() {
        guard let a = answer("jump-over") else { return }
        let plan = PacePlan(captions: a.captions, timeline: a.timeline, style: .standard)
        XCTAssertTrue(plan.beats.contains { a.timeline.events[$0.caption.id].flight == .takeOff },
                      "the jump's standard plan has no take-off beat")
        XCTAssertFalse(plan.beats.contains { $0.headline }, "a plan with no signature has no headline beats")
    }

    func testAnUnknownTrickHasNoSignature() {
        guard let a = answer("stop-dead") else { return }
        XCTAssertEqual(TrickSignature.events(forTrick: "no-such-shot", in: a.timeline, captions: a.captions), [])
    }

    func testTheFirstLaunchPlanIsUntouched() {
        let tl = TestShots.solve(TableKind.standard.openingShot)
        let captions = CaptionEngine.make(from: tl, surface: .cloth)
        let plan = PacePlan(captions: captions, timeline: tl, style: .firstLaunch)
        XCTAssertTrue(plan.hasBeats)
        XCTAssertLessThanOrEqual(plan.beats.count, PacePlan.firstLaunchBeats)
        XCTAssertLessThanOrEqual(plan.beats.count, 4)
        // No flight slot: the new take-off beat is for the standard and opening plans only.
        XCTAssertFalse(plan.beats.contains { tl.events[$0.caption.id].flight != .none })
        // The first launch never takes a signature: any signature leaves its plan exactly as it was.
        let signature = Array(captions.map(\.id).suffix(2))
        XCTAssertEqual(PacePlan(captions: captions, timeline: tl, style: .firstLaunch, signature: signature), plan)
    }
}
