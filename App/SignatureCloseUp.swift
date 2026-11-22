// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.4 lens-drawing, plans/22-Nov-2026-v074-glow-up-plan.md feature
//          G2: the body. When a guided replay starts holding one of its signature beats, the view eases in to 1.8 times
//          about that moment and springs back when the hold ends, but only from the fitted view and only if the player
//          has not zoomed in between.)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 stream camera: retired. The moment framing (MomentFrame.swift)
//          replaces the close-up: it glides in on every beat of a guided replay, not only signature beats, as a pure
//          function of the clock, and fits the moment to the free space instead of a fixed 1.8 times. step() and its
//          call in TableStage are gone; the two pure helpers below stay only because the app's unit tests
//          (BreakdownTests/LensContactGeometryTests.swift) still call them. Delete this file together with those two
//          tests.)
// PURPOSE: What is left of the 0.7.4 signature close-up: the event-to-zoom-point conversion and its old magnification,
//          kept for the unit tests. Nothing in the app calls it any more.
// SRP/DRY check: Pass - checked MomentFrame (the camera move now lives there) and TableZoomGestures (the conversion is
//          the same two lines, kept here because that one is private to the gesture modifier).
import BreakdownLensModel
import BreakdownTimeline
import SwiftUI
import simd

@MainActor
enum SignatureCloseUp {
    /// The 0.7.4 close-up's magnification (unused by the app since 0.7.6; the tests still read it).
    static let magnification: Float = 1.8

    /// Where on the table an event happened, as the zoom's plan point (world x, z, metres), or nil for an index
    /// outside the recording. A phase change (a take-off, a landing, skid turning to roll) and a strike happen at the
    /// ball, so the ball's own position at that time is used; every other event carries its own point (for a
    /// ball-to-ball hit that is the contact, midway between the centres).
    static func moment(of index: Int, in timeline: Timeline) -> SIMD2<Float>? {
        guard timeline.events.indices.contains(index) else { return nil }
        let e = timeline.events[index]
        var p = e.point
        if e.kind == .phaseTransition || e.kind == .cueStrike {
            guard let b = e.balls.first, b.ball < timeline.ballCount else { return nil }
            p = timeline.state(ball: b.ball, at: e.time).position
        }
        // As TableZoomGestures.worldPlan: the table's own point in world space, then its plan coordinates.
        let w = TableFrame(timeline.table).world(p)
        return SIMD2(w.x, w.z)
    }
}
