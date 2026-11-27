// Author: Claude Opus 5.5 Medium
// Date: 24-November-2026
// Edited: Claude Opus 5.5 Medium, 25-November-2026 (0.7.9, the whole jump's story in the side view: the raised strike,
//          the take-off and every landing of the jump-over shot map to one story (one FlightStoryKey) with the right
//          part in focus; the cue's tilt is the take-off's own; the story's hops, arc and clock are well formed; the
//          picture's peak is the take-off title's height; a caption about no jump gets no side view; FlightSketch.make
//          frames the part in focus and keeps its clock inside the story; a ball that bounces after its first landing
//          gives at least two hops.)
// Edited: Claude Opus 5.5 Medium, 27-November-2026 (UI rethink package 9's leftover note: the flight height is checked
//          against NumberStyle.distance, the rule the card now prints with, not a fixed one-decimal format.)
// PURPOSE: Checks for the jump replay (0.7.8, plans/24-Nov-2026-jump-replay-plan.md) on the authored jump over a
//          blocker, solved for real: the take-off card says the flight height once outside its worked equation and
//          leads with it; the take-off beat may be magnified further than other beats and its rectangle holds the
//          flight and the jumped ball but not the roll after landing; the side view's shape passes over that ball.
//          Since 0.7.9 also the side view's whole story (FlightShape.story, FlightSketch.make): which captions it
//          belongs to and which part each is about, that its numbers are the captions' numbers, and that its
//          structure (hops, arc samples, clock) holds together whether or not the ball bounces after landing.
// SRP/DRY check: Pass - checks only; the shot is solved the way BulletTimePickTests solves it (TestShots.shot). The
//          peak and the cue's tilt are compared with CaptionEngine's own lookups (flightSegment, flightTop,
//          raisedCueAngle), not recomputed here, except the one atan2 the task states as the definition.
@testable import Breakdown
import BreakdownLensModel
import BreakdownTimeline
import CoreGraphics
import XCTest

final class JumpReplayTests: XCTestCase {
    private func jump() throws -> (timeline: Timeline, captions: [Caption]) {
        let shot = try XCTUnwrap(TrickShots.shot(id: "jump-over"))
        guard case .layout(let start) = shot.setup else { throw XCTSkip("jump-over is not a laid-out shot") }
        let tl = TestShots.shot(from: start, shot.solution)
        return (tl, CaptionEngine.make(from: tl, surface: .cloth))
    }

    private func takeOff(_ captions: [Caption], in tl: Timeline) throws -> Caption {
        try XCTUnwrap(captions.first {
            tl.events.indices.contains($0.id) && tl.events[$0.id].flight == .takeOff
        }, "the jump never took off")
    }

    /// The raised strike's caption, found by its event's kind: the strike and the take-off share the clock's first
    /// instant, so their places in the sorted list say nothing about which is which.
    private func strike(_ captions: [Caption], in tl: Timeline) throws -> Caption {
        try XCTUnwrap(captions.first {
            tl.events.indices.contains($0.id) && tl.events[$0.id].kind == .cueStrike
        }, "the strike has no caption")
    }

    /// The jump as the take-off caption sees it: the story, the part in focus, the take-off event and the caption.
    private func takeOffStory(_ tl: Timeline, _ captions: [Caption]) throws
        -> (shape: FlightShape, focus: FlightFocus, event: LensEvent, caption: Caption) {
        let c = try takeOff(captions, in: tl)
        let s = try XCTUnwrap(FlightShape.story(for: c, in: tl), "the take-off has no side view")
        return (s.shape, s.focus, tl.events[c.id], c)
    }

    /// The landing event of `ball` at clock `t` (the end of a hop), and its index in the timeline's events.
    private func landing(of ball: Int, at t: Double, in tl: Timeline) -> Int? {
        tl.events.firstIndex {
            $0.kind == .phaseTransition && $0.flight == .landing && $0.balls.first?.ball == ball && abs($0.time - t) < 1e-9
        }
    }

    func testTheTakeOffCardSaysTheHeightOnce() throws {
        let (tl, captions) = try jump()
        let c = try takeOff(captions, in: tl)
        let height = try XCTUnwrap(c.figures.first, "no lead figure")
        XCTAssertEqual(height.unit, "cm", "the lead figure is not the flight height")
        XCTAssertFalse(c.detail.contains(height.value), "the sentence repeats the height: \(c.detail)")
        XCTAssertEqual(c.figures.filter { $0.value == height.value && $0.unit == "cm" }.count, 1,
                       "the tiles repeat the height")
        XCTAssertTrue(c.detail.contains("to spare"), "the gap over the jumped ball is not said: \(c.detail)")
    }

    func testTheTakeOffBeatComesInCloseOnTheFlight() throws {
        let (tl, captions) = try jump()
        let c = try takeOff(captions, in: tl)
        let plan = PacePlan(captions: captions, timeline: tl, style: .standard)
        let i = try XCTUnwrap(plan.beats.firstIndex { $0.caption.id == c.id }, "the take-off is not a beat")
        XCTAssertEqual(plan.focusZoom.count, plan.beats.count)
        XCTAssertEqual(plan.focusZoom[i], MomentFraming.flightMagnification)
        XCTAssertTrue(plan.focusZoom.enumerated().allSatisfy { $0.offset == i || $0.element <= MomentFraming.flightMagnification })

        let shape = try XCTUnwrap(FlightShape.make(caption: c, timeline: tl), "no side view for the take-off")
        XCTAssertNotNil(shape.blocker, "the side view does not show the jumped ball")
        XCTAssertGreaterThan(shape.peakGap, 0)
        // The rectangle holds the take-off point, the jumped ball and the rise just past it (0.7.9: the clearance,
        // not the whole bouncing path, so the camera can come in close on the upright phone), and is no longer than
        // the first flight with a little run-up.
        let r = plan.focusRegions[i]
        let R = tl.table.ballRadius
        func inside(_ p: Vec2, _ slack: Double) -> Bool {
            p.x >= r.minX - slack && p.x <= r.maxX + slack && p.y >= r.minY - slack && p.y <= r.maxY + slack
        }
        let seg = try XCTUnwrap(CaptionEngine.flightSegment(ball: tl.events[c.id].balls[0].ball, startingAt: c.time, in: tl))
        let jumped = try XCTUnwrap(CaptionEngine.flightTop(seg, ball: tl.events[c.id].balls[0].ball, in: tl).over)
        XCTAssertTrue(inside(shape.from, 1e-6), "the take-off point is not in the take-off's rectangle")
        XCTAssertTrue(inside(tl.state(ball: jumped.ball, at: c.time).position, 1e-6), "the jumped ball is not in it")
        let span = shape.span(.takeOff(0))
        XCTAssertTrue(inside(span.1, R), "the rise past the jumped ball is not in it")
        let flightSpan = max(abs(shape.to.x - shape.from.x), abs(shape.to.y - shape.from.y))
        let rectSpan = max(r.maxX - r.minX, r.maxY - r.minY)
        XCTAssertLessThan(rectSpan, flightSpan + 0.18, "the take-off still frames the roll-out")
    }

    // MARK: The whole jump's story (0.7.9)

    /// The strike, the take-off and every landing of the jump are one story: the panel keeps one identity from the cue
    /// coming down to the ball staying on the cloth, and each caption puts the right part of it in focus.
    func testTheStrikeTheTakeOffAndEveryLandingTellOneStory() throws {
        let (tl, captions) = try jump()
        let (shape, focus, up, _) = try takeOffStory(tl, captions)
        XCTAssertEqual(focus, .takeOff(0), "the first take-off is not the story's first hop")
        XCTAssertEqual(shape.ball, up.balls.first?.ball, "the story is about another ball")
        XCTAssertEqual(shape.t0, up.time, accuracy: 1e-9, "the story does not start at the take-off")

        // The raised strike: the same jump, built from the same first flight, so the very same shape.
        let s = try strike(captions, in: tl)
        let fromStrike = try XCTUnwrap(FlightShape.story(for: s, in: tl), "the raised strike has no side view")
        XCTAssertEqual(fromStrike.focus, .strike)
        XCTAssertEqual(fromStrike.shape.key, shape.key, "the strike and the take-off are two stories")
        XCTAssertEqual(fromStrike.shape, shape, "the strike draws a different jump from the take-off")

        // Every hop that ends in a landing event: its caption is about that hop's landing, in the same story, and the
        // story's hop ends exactly when that landing happened. Driven from the story's own hops, so a landing of some
        // later jump in the shot is never mistaken for one of this one.
        var checked = Set<Int>()
        for (h, hop) in shape.hops.enumerated() {
            guard let i = landing(of: shape.ball, at: hop.t1, in: tl),
                  let c = captions.first(where: { $0.id == i }) else { continue }
            let e = tl.events[i]
            let landed = try XCTUnwrap(FlightShape.story(for: c, in: tl), "landing \(h) has no side view")
            XCTAssertEqual(landed.focus, .landing(h), "landing \(h) puts another part in focus")
            XCTAssertEqual(landed.shape.key, shape.key, "landing \(h) starts a story of its own")
            if case .landing(let k) = landed.focus, landed.shape.hops.indices.contains(k) {
                XCTAssertEqual(landed.shape.hops[k].t1, e.time, accuracy: 1e-9, "hop \(k) does not end at its landing")
                XCTAssertEqual(landed.shape.landings[k]?.down, e.verticalSpeedDown, "landing \(k)'s push down is not its own")
                XCTAssertEqual(landed.shape.landings[k]?.up, e.phaseTo == .airborne ? e.verticalSpeedUp : 0,
                               "landing \(k)'s push up is not its own")
            } else {
                XCTFail("landing \(h) is not a landing of its own story")
            }
            // The hops up to this landing are the take-off's hops: the backward walk always reaches the first take-off,
            // so even the panel built at a late landing draws the same first hops.
            XCTAssertEqual(Array(landed.shape.hops.prefix(h + 1)), Array(shape.hops.prefix(h + 1)),
                           "landing \(h) draws different hops")
            checked.insert(i)
        }
        XCTAssertFalse(checked.isEmpty, "no landing of the jump has a caption")

        // And those were every landing caption of this ball inside the story.
        let inside = captions.filter { c in
            guard tl.events.indices.contains(c.id) else { return false }
            let e = tl.events[c.id]
            return e.kind == .phaseTransition && e.flight == .landing && e.balls.first?.ball == shape.ball
                && e.time >= shape.t0 - 1e-9 && e.time <= shape.t1 + 1e-9
        }
        XCTAssertEqual(Set(inside.map(\.id)), checked, "a landing inside the story is not at the end of one of its hops")
    }

    /// The cue in the side view comes down at the strike's real tilt: the take-off's own downward and across speeds,
    /// the strike card's lead angle, and the shot's authored elevation all give the same angle.
    func testTheCueComesDownAtTheTakeOffsOwnTilt() throws {
        let (tl, captions) = try jump()
        let (shape, _, up, _) = try takeOffStory(tl, captions)
        let angle = try XCTUnwrap(shape.cueAngle, "a raised strike made this jump, but the side view has no cue")
        XCTAssertGreaterThan(angle, 0, "the cue is not tilted down")
        XCTAssertLessThan(angle, Double.pi / 2, "the cue points straight down or past it")

        // The definition: the strike drove the ball along the cue's line, across the cloth at the take-off's speed
        // before the slate and down at its verticalSpeedDown.
        let across = try XCTUnwrap(up.balls.first, "the take-off has no ball").velocityBefore.length
        XCTAssertEqual(angle, atan2(up.verticalSpeedDown, across), accuracy: 1e-12)
        XCTAssertEqual(CaptionEngine.raisedCueAngle(up, in: tl), angle)

        // The strike's card leads with that same angle, in degrees.
        let lead = try XCTUnwrap(try strike(captions, in: tl).figures.first, "the strike card has no lead figure")
        XCTAssertEqual(lead.unit, "°", "the strike card does not lead with the cue's angle")
        XCTAssertEqual(lead.amount, angle * 180 / Double.pi, accuracy: 1e-9, "the card and the picture tilt the cue apart")

        // The shot's elevation is the sine of the cue's angle (NextShot.shot), and a raised strike's horizontal and
        // downward speeds are speed times its cosine and its sine, so the angle read back is the authored one.
        let shot = try XCTUnwrap(TrickShots.shot(id: "jump-over"))
        let elevation = try XCTUnwrap(shot.solution.elevation, "jump-over is not a raised strike")
        XCTAssertEqual(angle, asin(elevation), accuracy: 1e-9, "the cue is not drawn at the shot's own angle")
    }

    /// The story holds together: hops in clock order and touching end to end, the arc sampled through the whole story
    /// with a clock that never runs back, one landing slot per hop, and the launch push the take-off's own. If the ball
    /// bounces again after its first landing, the story has at least two hops; if not, no count is assumed.
    func testTheStoryIsWellFormed() throws {
        let (tl, captions) = try jump()
        let (shape, _, up, _) = try takeOffStory(tl, captions)

        XCTAssertFalse(shape.hops.isEmpty, "the story has no hops")
        guard let firstHop = shape.hops.first, let lastHop = shape.hops.last else { return }
        XCTAssertEqual(shape.t0, firstHop.t0, "the story does not start with its first hop")
        XCTAssertEqual(shape.t1, lastHop.t1, "the story does not end with its last hop")
        for (h, hop) in shape.hops.enumerated() {
            XCTAssertGreaterThan(hop.t1, hop.t0, "hop \(h) takes no time")
            if h > 0 {
                // The build joins segments that meet within a tenth of a microsecond.
                XCTAssertEqual(hop.t0, shape.hops[h - 1].t1, accuracy: 1e-7, "hop \(h) does not start where hop \(h - 1) ended")
                XCTAssertGreaterThan(hop.t0, shape.hops[h - 1].t0, "hop \(h) is out of clock order")
            }
        }

        XCTAssertEqual(shape.arc.count, shape.times.count, "the arc and its clock do not match")
        XCTAssertEqual(shape.times.first, shape.t0, "the arc does not start at the take-off")
        XCTAssertEqual(try XCTUnwrap(shape.times.last), shape.t1, accuracy: 1e-9, "the arc does not run to the last landing")
        let back = shape.times.indices.dropFirst().first { shape.times[$0] < shape.times[$0 - 1] }
        XCTAssertNil(back, "the arc's clock runs backwards at sample \(back ?? -1)")

        XCTAssertEqual(shape.landings.count, shape.hops.count, "one landing slot per hop")
        let launch = try XCTUnwrap(shape.launch, "no push at the take-off")
        XCTAssertEqual(launch.down, up.verticalSpeedDown, "the launch's push down is not the take-off's")
        XCTAssertEqual(launch.up, up.verticalSpeedUp, "the launch's push up is not the take-off's")
        XCTAssertEqual(launch.along, 0, "the launch is not at the take-off point")

        // The ball's first landing after the take-off: when the slate sends it back up, the next flight is a hop of
        // the same story (the landing ends its segment on the cloth, which splits the hops there).
        let firstLanding = tl.events
            .filter { $0.kind == .phaseTransition && $0.flight == .landing && $0.balls.first?.ball == shape.ball
                && $0.time >= shape.t0 }
            .min { $0.time < $1.time }
        if let l = firstLanding, l.phaseTo == .airborne {
            XCTAssertGreaterThanOrEqual(shape.hops.count, 2, "the ball bounced after landing, but the story has one hop")
        }
    }

    /// The side view's top is exactly the height the take-off card's title gives: the same flight, the same lookup.
    func testThePictureAndTheTitleShareOnePeak() throws {
        let (tl, captions) = try jump()
        let (shape, _, up, c) = try takeOffStory(tl, captions)
        let first = try XCTUnwrap(CaptionEngine.flightSegment(ball: shape.ball, startingAt: up.time, in: tl),
                                  "no airborne segment starts at the take-off")
        let top = CaptionEngine.flightTop(first, ball: shape.ball, in: tl)
        // peakGap is the peak held at zero or above; the jump clears a ball, so its peak is above the cloth and the
        // two are the same number.
        XCTAssertGreaterThan(top.peak, 0, "the jump never rose")
        XCTAssertEqual(shape.peakGap, top.peak, "the picture's peak is not the title's")

        let height = try XCTUnwrap(c.figures.first, "the take-off card has no lead figure")
        XCTAssertEqual(height.unit, "cm", "the take-off card does not lead with the flight height")
        XCTAssertEqual(height.amount, shape.peakGap * 100, accuracy: 0.05, "the title and the picture disagree on the height")
        // Exactly as the card prints it: NumberStyle's one rule for distances (whole centimetres from 10 cm up, one
        // decimal below), so a higher jump cannot break the check.
        XCTAssertEqual(height.value, NumberStyle.distance(metres: shape.peakGap).number)
    }

    /// A caption about anything but a jump (a ball-ball hit, a cushion, a ball starting to roll) gets no side view.
    func testACaptionAboutNoJumpHasNoSideView() throws {
        let (tl, captions) = try jump()
        let others = captions.filter { c in
            guard tl.events.indices.contains(c.id) else { return true }
            let e = tl.events[c.id]
            return e.kind != .cueStrike && e.flight != .takeOff && e.flight != .landing
        }
        guard !others.isEmpty else { throw XCTSkip("every caption of this shot is about the jump") }
        for c in others {
            XCTAssertNil(FlightShape.story(for: c, in: tl), "\"\(c.title)\" (event \(c.id)) got a side view")
        }
    }

    /// FlightSketch.make, through a plain projection (table metres to points, a hundred to the metre): the sketch's
    /// screen rectangle holds both ends of the part in focus, its identity is the story's, and whatever clock it is
    /// given, its own clock stays inside the story.
    func testTheSketchFramesThePartInFocusAndKeepsItsClockInTheStory() throws {
        let (tl, captions) = try jump()
        let (shape, _, _, c) = try takeOffStory(tl, captions)
        func screen(_ p: Vec2) -> CGPoint { CGPoint(x: p.x * 100, y: p.y * 100) }
        let project: (Vec2) -> CGPoint? = { screen($0) }

        let clocks = [shape.t0 - 1, shape.t0, (shape.t0 + shape.t1) / 2, shape.t1, shape.t1 + 5]
        let focuses = [FlightFocus.strike, .takeOff(0)] + shape.hops.indices.map { FlightFocus.landing($0) }
        for focus in focuses {
            let (a, b) = shape.span(focus)
            for clock in clocks {
                let sketch = try XCTUnwrap(FlightSketch.make(captionID: c.id, shape: shape, focus: focus, clock: clock,
                                                             project: project), "no sketch for \(focus)")
                XCTAssertEqual(sketch.captionID, c.id)
                XCTAssertEqual(sketch.focus, focus)
                XCTAssertEqual(sketch.key, shape.key, "the sketch is not the story's")
                XCTAssertGreaterThanOrEqual(sketch.now, shape.t0, "the sketch's clock is before the story at \(clock)")
                XCTAssertLessThanOrEqual(sketch.now, shape.t1 + 1e-9, "the sketch's clock is after the story at \(clock)")
                // The rectangle is in whole points, its corner and its size each rounded, so an end may sit up to one
                // point outside it. (A landing that stays has both ends at one point: a rectangle of no size.)
                let r = sketch.screen
                for p in [screen(a), screen(b)] {
                    XCTAssertTrue(p.x >= r.minX - 1 && p.x <= r.maxX + 1 && p.y >= r.minY - 1 && p.y <= r.maxY + 1,
                                  "\(focus): \(p) is outside the sketch's rectangle \(r)")
                }
                // Which way the jump runs on screen comes from its first flight, whatever part is in focus.
                XCTAssertEqual(sketch.leftward, shape.to.x < shape.from.x, "\(focus) flips the panel")
            }
        }

        // The clock's steps: held to the story at both ends.
        XCTAssertEqual(shape.step(shape.t0 - 10), shape.t0)
        XCTAssertEqual(shape.step(shape.t0), shape.t0)
        XCTAssertEqual(shape.step(shape.t1), shape.t1, accuracy: 1e-9)
        XCTAssertEqual(shape.step(shape.t1 + 10), shape.t1, accuracy: 1e-9)
    }
}
