// Author: Claude Opus 5.5 Medium
// Date: 25-November-2026
// PURPOSE: Which frames of a Lens clip carry the jump's side view, and where it goes on the frame (0.7.9, the jump
//          replay plan's "Next": the side view in clips). Pure, like ClipScript: the same script and recording always
//          give the same panel on the same frames, so the same jump always makes the same film.
//          The rules:
//            - only frames of the explained replay carry it (never the lead, full speed, pause, melt, rewind or end card);
//            - the beat in effect on a frame is the kept beat it holds, else the latest kept beat at or before its
//              clock; when that beat is about a jump (FlightShape.story: the raised strike, a take-off or a landing),
//              the panel shows while the clock is still inside the jump (up to its last landing) or while the frame
//              holds that beat. Its life follows the jump's clock, never the note: the note only shows during a hold
//              and a short fade, and the take-off's beat sits at the take-off instant, so following the note would
//              take the panel away before the ball has flown;
//            - it fades in over ClipScript.captionIn as a run of such frames starts, and after the run ends it stays
//              on the same jump and part for ClipScript.captionOut, fading out, unless a new run takes over at once.
//              A run that goes on with the same jump (strike, then take-off, then landing) keeps its opacity: one
//              panel for the whole story, as the game keeps it (FlightStoryKey);
//            - placement: beside the flight on the table, under the header margin and above the caption band
//              (FlightSideView.center, the game's own rules); when nothing fits there, a fixed place centred across
//              the top of the frame at the largest size, so the panel is never dropped for want of room.
//          Read by ClipOverlay (draws the panel) and the tests (ClipFlightTests).
// SRP/DRY check: Pass - reuses FlightShape.story (the jump and the part in focus), FlightSideView.center and sizes (the
//          panel's place and size), ClipShape (canvas, header margin, caption band) and ClipScript's fade lengths; the
//          fade arithmetic mirrors ClipScript.replayFrames' note fade on purpose, so the two read the same.
import BreakdownLensModel
import BreakdownTimeline
import CoreGraphics
import Foundation

/// The side view on one clip frame: the caption whose jump it shows, the jump, the part in focus and how opaque it is.
struct ClipFlightCue: Equatable {
    var captionID: Int
    var shape: FlightShape
    var focus: FlightFocus
    /// 0 to 1, never 0 on a frame that carries a cue.
    var opacity: Double
}

enum ClipFlight {
    /// Clear space round the panel, canvas points (the game's own gap beside the flight).
    static let gap: CGFloat = 8

    /// One entry per frame of `script`: the side view that frame carries, or nil for none.
    static func track(script: ClipScript, timeline: Timeline) -> [ClipFlightCue?] {
        let D = timeline.duration
        let beats = script.beats
        // Each kept beat's jump and the part it is about, built once (nil for a beat about no jump).
        let stories = beats.map { FlightShape.story(for: $0.beat.caption, in: timeline) }
        // The clock each beat is held at: the script clamps a beat's time to the recording.
        let times = beats.map { min(D, max(0, $0.beat.time)) }
        let fadeIn = ClipScript.captionIn * ClipScript.fps, fadeOut = ClipScript.captionOut * ClipScript.fps

        // The beat in effect: the one the frame holds (two beats at one instant, like a raised strike and its take-off,
        // are held one after the other at the same clock, so the clock alone cannot tell them apart), else the latest
        // kept beat at or before the frame's clock.
        func beat(of f: ClipFrame) -> Int? {
            if let held = f.heldEvent, let b = beats.firstIndex(where: { $0.beat.caption.id == held }) { return b }
            return times.lastIndex { $0 <= f.clock + 1e-9 }
        }

        var out: [ClipFlightCue?] = []
        out.reserveCapacity(script.frames.count)
        // The panel on the previous frame, and while it fades out after its run, the opacity it started fading from
        // and how many frames it has faded.
        var shown: ClipFlightCue?
        var fading: (from: Double, frames: Int)?
        for f in script.frames {
            guard f.part == .replay else {
                out.append(nil)
                shown = nil
                fading = nil
                continue
            }
            if let b = beat(of: f), let story = stories[b],
               f.clock <= story.shape.t1 + 1e-9 || f.heldEvent == beats[b].beat.caption.id {
                // In a run. The same jump as the panel already up (in its run, or fading out) carries on up from its
                // opacity; a different jump, or none, starts from nothing, so its first frame is already above 0.
                let base = shown.map { $0.shape.key == story.shape.key ? $0.opacity : 0 } ?? 0
                let cue = ClipFlightCue(captionID: beats[b].beat.caption.id, shape: story.shape, focus: story.focus,
                                        opacity: min(1, base + 1 / fadeIn))
                out.append(cue)
                shown = cue
                fading = nil
            } else if var cue = shown {
                // The run has ended: the same jump and part, fading out from where the run left it.
                let from = fading?.from ?? cue.opacity
                let n = (fading?.frames ?? 0) + 1
                let o = from * (1 - Double(n) / fadeOut)
                if o > 1e-6 {
                    cue.opacity = o
                    out.append(cue)
                    shown = cue
                    fading = (from, n)
                } else {
                    out.append(nil)
                    shown = nil
                    fading = nil
                }
            } else {
                out.append(nil)
            }
        }
        return out
    }

    /// Where the panel goes on a clip's canvas (points, origin top left), for the part in focus at `flight` on screen:
    /// beside it on the table, under the header margin and above the caption band (FlightSideView.center); when
    /// nothing fits there, centred across the top at the largest size, held inside the canvas and above the band.
    /// MainActor only because FlightSideView, a view, is.
    @MainActor static func place(flight: CGRect, in shape: ClipShape) -> CGRect {
        let bounds = CGRect(origin: .zero, size: shape.canvas)
        let top = CGFloat(shape.framingRequest.headerBottom) + gap
        let bottom = shape.captionBand.minY - gap
        if let at = FlightSideView.center(flight: flight, bounds: bounds, top: top, bottom: bottom, avoid: [],
                                          gap: gap) {
            return CGRect(x: at.point.x - at.size.width / 2, y: at.point.y - at.size.height / 2,
                          width: at.size.width, height: at.size.height)
        }
        // The fixed place: nothing beside the flight is free (a long flight across most of the table). The sizes list
        // is never empty for the clip's canvases, but a compact panel stands in if it ever is.
        let largest = FlightSideView.sizes(in: bounds, gap: gap).first ?? CGSize(width: 184, height: 92)
        let w = min(largest.width, bounds.width - 2 * gap)
        let h = min(largest.height, max(0, bottom - top))
        let x = (bounds.width - w) / 2
        let y = min(top, max(0, bottom - h))
        return CGRect(x: x, y: y, width: w, height: h)
    }
}
