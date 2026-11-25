// Author: Claude Opus 5.5 Medium
// Date: 25-November-2026
// PURPOSE: Checks for the jump's side view in Lens clips (App/Clips/ClipFlight.swift, 0.7.9, the jump replay plan's
//          "Next"), on the authored jump over a blocker solved for real, in both replay budgets (the shared clip's and
//          the App Store preview's shorter one): some replay frames carry the side view and no other part of the film
//          does; every opacity is above 0 and at most 1; the panel stays up, at full strength, while the ball flies on
//          after the hold, right up to its first landing, rather than going with the note at the take-off; a shot with
//          no jump carries none; and the panel's place is always inside the canvas, under the header margin and above
//          the caption band, the same every time, falling back to the top of the frame when the flight covers the
//          table.
// SRP/DRY check: Pass - checks only; the jump is solved as JumpReplayTests solves it (TestShots.shot) and its clip made
//          as ClipScriptTests makes one, with the trick's own signature as the game passes it.
@testable import Breakdown
import BreakdownLensModel
import BreakdownTimeline
import CoreGraphics
import XCTest

// MainActor because the placement reads FlightSideView, a view.
@MainActor
final class ClipFlightTests: XCTestCase {
    private struct Jump {
        let timeline: Timeline
        let captions: [Caption]
        let signature: [Int]
    }

    private func jump() throws -> Jump {
        let shot = try XCTUnwrap(TrickShots.shot(id: "jump-over"))
        guard case .layout(let start) = shot.setup else { throw XCTSkip("jump-over is not a laid-out shot") }
        let tl = TestShots.shot(from: start, shot.solution)
        let captions = CaptionEngine.make(from: tl, surface: .cloth)
        return Jump(timeline: tl, captions: captions,
                    signature: TrickSignature.events(forTrick: "jump-over", in: tl, captions: captions))
    }

    /// The jump's clip in both budgets, each checked to keep at least one beat about the jump (else the rest of a test
    /// would fail for the wrong reason).
    private func scripts(_ j: Jump, file: StaticString = #filePath,
                         line: UInt = #line) throws -> [(name: String, script: ClipScript)] {
        let standard = try XCTUnwrap(ClipScript.make(timeline: j.timeline, captions: j.captions, signature: j.signature),
                                     "no clip for the jump", file: file, line: line)
        let store = try XCTUnwrap(ClipScript.make(timeline: j.timeline, captions: j.captions, signature: j.signature,
                                                  replayBudget: ClipShape.storePreview.replayBudget),
                                  "no store-preview clip for the jump", file: file, line: line)
        let all = [(name: "standard", script: standard), (name: "store preview", script: store)]
        for (name, s) in all {
            let aboutTheJump = s.beats.contains { FlightShape.story(for: $0.beat.caption, in: j.timeline) != nil }
            XCTAssertTrue(aboutTheJump, "\(name): no kept beat is about the jump", file: file, line: line)
        }
        return all
    }

    // MARK: Which frames

    func testReplayFramesCarryTheSideViewAndNoOtherPartDoes() throws {
        let j = try jump()
        for (name, s) in try scripts(j) {
            let track = ClipFlight.track(script: s, timeline: j.timeline)
            XCTAssertEqual(track.count, s.frames.count, name)
            XCTAssertTrue(zip(s.frames, track).contains { $0.part == .replay && $1 != nil },
                          "\(name): no replay frame carries the side view")
            for (i, (f, cue)) in zip(s.frames, track).enumerated() {
                guard let cue else { continue }
                XCTAssertEqual(f.part, .replay, "\(name): a \(f.part) frame (\(i)) carries the side view")
                XCTAssertGreaterThan(cue.opacity, 0, "\(name): frame \(i) carries an invisible side view")
                XCTAssertLessThanOrEqual(cue.opacity, 1, "\(name): frame \(i)'s side view is over full strength")
                XCTAssertTrue(s.beats.contains { $0.beat.caption.id == cue.captionID },
                              "\(name): frame \(i)'s side view is for a caption the clip does not keep")
            }
        }
    }

    func testThePanelStaysUpWhileTheBallFliesToItsLanding() throws {
        let j = try jump()
        for (name, s) in try scripts(j) {
            let track = ClipFlight.track(script: s, timeline: j.timeline)
            guard let shape = track.compactMap({ $0 }).first?.shape else {
                XCTFail("\(name): no frame carries the side view")
                continue
            }
            let landing = shape.hops[0].t1
            let frames = s.frames
            // The replay's clock only moves forward: the last replay frame at or before the first landing is the one
            // just before the first replay frame past it.
            guard let after = frames.indices.first(where: { frames[$0].part == .replay && frames[$0].clock > landing + 1e-9 }),
                  after > 0, frames[after - 1].part == .replay else {
                XCTFail("\(name): the replay never passes the first landing")
                continue
            }
            let atLanding = after - 1
            // That frame is inside the flight, so it shows the ball in the air, not still held at the take-off.
            XCTAssertGreaterThan(frames[atLanding].clock, shape.t0 + 1e-9,
                                 "\(name): no replay frame between the take-off and the first landing")
            XCTAssertEqual(track[atLanding]?.shape.key, shape.key,
                           "\(name): the side view is gone before the ball lands (clock \(frames[atLanding].clock))")
            XCTAssertEqual(track[atLanding]?.opacity ?? 0, 1, accuracy: 1e-9,
                           "\(name): the side view is fading before the ball lands")
            // Seen flying, not only held at the take-off: up, at full strength, while the clock is in mid-air.
            let midAir = frames.indices.contains { i in
                frames[i].part == .replay && frames[i].clock > shape.t0 + 1e-9 && frames[i].clock < landing - 1e-9
                    && (track[i]?.opacity ?? 0) >= 1 - 1e-9
            }
            XCTAssertTrue(midAir, "\(name): the side view is never up while the ball is in the air")
        }
    }

    func testAShotWithNoJumpCarriesNoSideView() throws {
        let tl = TestShots.straightPot()
        let s = try XCTUnwrap(ClipScript.make(timeline: tl, captions: CaptionEngine.make(from: tl, surface: .cloth),
                                              signature: []))
        XCTAssertTrue(ClipFlight.track(script: s, timeline: tl).allSatisfy { $0 == nil })
    }

    // MARK: Where it goes

    func testThePanelIsAlwaysOnTheFrameAboveTheWords() {
        for shape in [ClipShape.upright, .wide, .storePreview] {
            let canvas = shape.canvas
            let band = shape.captionBand
            let header = CGFloat(shape.framingRequest.headerBottom)
            let covering = CGRect(x: 12, y: header + 4, width: canvas.width - 24, height: band.minY - header - 16)
            let flights: [CGRect] = [
                CGRect(x: canvas.width * 0.4, y: band.minY * 0.45, width: 40, height: 20),  // a short hop mid-table
                CGRect(x: 10, y: header + 6, width: 60, height: 10),                         // up by the header
                CGRect(x: canvas.width - 70, y: band.minY - 40, width: 60, height: 20),     // down by the words
                CGRect(x: -50, y: band.minY * 0.5, width: 80, height: 30),                   // partly off the frame
                .zero,
                covering,                                                                    // most of the table
            ]
            for flight in flights {
                let r = ClipFlight.place(flight: flight, in: shape)
                let what = "\(shape), flight \(flight): panel \(r)"
                XCTAssertGreaterThan(r.width, 0, what)
                XCTAssertGreaterThan(r.height, 0, what)
                XCTAssertGreaterThanOrEqual(r.minX, 0, what)
                XCTAssertLessThanOrEqual(r.maxX, canvas.width, what)
                XCTAssertGreaterThanOrEqual(r.minY, header, "\(what) is over the header margin")
                XCTAssertLessThanOrEqual(r.maxY, band.minY, "\(what) reaches into the caption band")
                XCTAssertEqual(ClipFlight.place(flight: flight, in: shape), r, "\(what) is not the same twice")
            }
            // Nothing beside a flight across most of the table is free: the fixed place, centred across the top at
            // the largest size.
            let fixed = ClipFlight.place(flight: covering, in: shape)
            let largest = FlightSideView.sizes(in: CGRect(origin: .zero, size: canvas), gap: ClipFlight.gap).first
            XCTAssertEqual(fixed.midX, canvas.width / 2, accuracy: 0.5, "\(shape)")
            XCTAssertEqual(fixed.width, largest?.width ?? -1, accuracy: 0.5, "\(shape)")
            XCTAssertEqual(fixed.minY, header + ClipFlight.gap, accuracy: 0.5, "\(shape)")
        }
    }
}
