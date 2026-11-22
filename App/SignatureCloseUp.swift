// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.4 lens-drawing, plans/22-Nov-2026-v074-glow-up-plan.md feature
//          G2: the body. When a guided replay starts holding one of its signature beats, the view eases in to 1.8 times
//          about that moment and springs back when the hold ends, but only from the fitted view and only if the player
//          has not zoomed in between.)
// PURPOSE: The gentle close-up on a held signature moment of a guided Lens replay (plans/22-Nov-2026-v074-glow-up-
//          plan.md, F7 and stream lens-drawing). TableStage calls step once per frame, after the scene is placed and
//          before the camera updates (so the caption leader, projected after the camera, still lands on its ball).
//          What it reads: model.heldSignatureEvent (the event index of a held signature beat, nil otherwise),
//          model.stage, model.rideActive, model.timeline, and TableCamera.reduceMotion. What it changes: only the
//          hand zoom (TableScene.zoom), through TableZoom.closeUp and springBack, so the move uses the zoom's own
//          clamping and spring.
//          Rules: a close-up starts only at the moment a signature hold begins, in the explore stage, with Ride off,
//          Reduce Motion off and the hand zoom at the fitted view (a player who has pinched keeps the view they chose).
//          It eases to 1.8 times about the moment: the contact point for a ball-to-ball hit, the ball's own position for
//          a take-off, landing or other phase change (and a strike), and the event's point for a cushion, a pocket, a
//          skip over a hole, a pin or a jam. When the hold ends, moves to another event, or Ride or Reduce Motion
//          comes on, the view springs back, but only if the zoom's goal is still exactly the one set here: a pinch or
//          double tap in between is the player's and is left alone. A new shot springs the zoom back by itself
//          (TableScene.load), which this then simply forgets.
//          Table metres become the zoom's plan coordinates exactly as TableZoomGestures does it (TableFrame.world, then
//          its x and z), since the across-table axis is flipped between the two.
// SRP/DRY check: Pass - checked TableZoom (owns the hand zoom and its spring; this only asks it to move), ShotCamera
//          (Ride, which this stays out of) and TableZoomGestures (the conversion is the same two lines, kept here
//          because that one is private to the gesture modifier).
import BreakdownLensModel
import BreakdownTimeline
import SwiftUI
import simd

@MainActor
enum SignatureCloseUp {
    /// How much larger the table looks at a signature moment: enough that the spotted cue ball's spin reads, little
    /// enough that both balls of a hit and the paths leaving them stay in view.
    static let magnification: Float = 1.8

    /// A close-up this code put up: which zoom, for which event, and the exact goal it left there, so the spring back
    /// can tell its own goal from one the player set since.
    private struct Placed {
        let zoom: ObjectIdentifier
        let event: Int
        let scale: Float
        let offset: SIMD2<Float>
    }
    private static var placed: Placed?
    /// The signature event that was wanted last frame, so a close-up starts once, when a hold begins, never again in
    /// the middle of the same hold (after a player's pinch there, for instance).
    private static var lastWanted: Int?

    /// Called once per frame before the camera updates: eases the hand zoom toward the moment of a held signature beat
    /// and back when the hold ends.
    static func step(model: ShowpieceModel, table: TableScene) {
        let zoom = table.zoom
        let id = ObjectIdentifier(zoom)
        // The signature being held, if a close-up is allowed now at all.
        let allowed = model.stage == .explore && !model.rideActive && !TableCamera.reduceMotion
        let wanted = allowed ? model.heldSignatureEvent : nil
        defer { lastWanted = wanted }

        // Take down a close-up that is no longer wanted for its event (the hold ended or moved on, or Ride or Reduce
        // Motion came on): spring back only when the goal is still the one set here.
        if let p = placed, p.event != wanted || p.zoom != id {
            if p.zoom == id, abs(zoom.goalScale - p.scale) < 1e-4, simd_length(zoom.goalOffset - p.offset) < 1e-4 {
                zoom.springBack()
            }
            placed = nil
        }

        // Start one when a signature hold begins and the view is the fitted one.
        guard let event = wanted, event != lastWanted, placed == nil, zoom.atFittedView,
              let point = moment(of: event, in: model.timeline) else { return }
        zoom.closeUp(on: point, scale: magnification)
        // Read back what the zoom kept (after its clamping), which is what a later frame will compare against.
        placed = Placed(zoom: id, event: event, scale: zoom.goalScale, offset: zoom.goalOffset)
    }

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
