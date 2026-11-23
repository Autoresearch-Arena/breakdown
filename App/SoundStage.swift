// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: Where the listener is, for sound and touch (sound plan packages 2 and 3). Two small things every voice needs:
//          1. Pan: which way "screen right" runs across the table right now, so a hit on the left of the drawn table is
//             heard on the left. The camera reports its own right-hand direction and the table frame once a frame
//             (TableCamera.update calls listen(frame:cameraRight:)); a table point goes through TableFrame.world, the
//             same mapping the drawing uses, and is projected onto that direction. This follows the table turning
//             between portrait and landscape and the Ride camera without knowing about either. Kept gentle: a hit on
//             the far edge is panned a little over half way, never hard into one ear.
//          2. Pace: the playback rate (slow motion, guided pacing, Ride), reported every frame by SoundBoard.follow, so
//             the small delays inside a cue (a pocket's settling knocks, the scatter after the crack) stretch in slow
//             motion for sound and haptics alike.
// Edited: Claude Opus 5.5 High, 23-November-2026 (0.7.7 clips, plans/23-Nov-2026-clips-plan.md: the pan and the
//          stretch are also offered as pure functions of their inputs (pan(_:frame:right:), stretch(_:rate:)), which the
//          live ones call with the stored listener and rate, so the clip's sound plan can place and pace its cues the
//          same way off the main actor. Behaviour identical.)
// SRP/DRY check: Pass - checked TableFrame (the table-to-world mapping, reused here, not copied) and TableCamera (owns
//          the camera; this only receives its direction). No other file turns table points into stereo positions.
import BreakdownLensModel
import simd

@MainActor
enum SoundStage {
    /// How far a hit at the very edge of the table is panned (1 would be fully into one ear). A little over half way:
    /// enough to place a bank shot with the phone held sideways, gentle enough that one ear is never left empty.
    nonisolated static let panWidth: Float = 0.55  // 0.7.7 clips: read by the pure pan below, off the main actor

    /// The table as drawn and the camera's right-hand direction in world space, from the last camera update. Before
    /// the first one, the landscape view is assumed (the table's long side runs left to right).
    private static var frame: TableFrame?
    private static var right = SIMD3<Float>(1, 0, 0)

    /// Called by the camera every frame, after it is placed.
    static func listen(frame f: TableFrame, cameraRight r: SIMD3<Float>) {
        frame = f
        right = r
    }

    /// The stereo pan (-1 left to 1 right, already scaled by panWidth) of a point on the table.
    static func pan(_ p: Vec2) -> Float {
        guard let f = frame else { return 0 }
        return pan(p, frame: f, right: right)
    }

    // 0.7.7 clips: the pan as a pure function of the table frame and the camera's right-hand direction (the body the
    // live pan(_:) used to hold), so the clip's sound plan (ClipSound) pans with each clip frame's own camera.
    nonisolated static func pan(_ p: Vec2, frame f: TableFrame, right: SIMD3<Float>) -> Float {
        let w = f.world(p)
        // Only the horizontal part of the camera's right matters: looking down at the table, it says which way across
        // the screen the table runs. Normalised so a tilted camera pans as much as a level one.
        let h = SIMD2<Float>(right.x, right.z)
        let len = simd_length(h)
        guard len > 1e-4 else { return 0 }
        let dir = h / len
        let along = w.x * dir.x + w.z * dir.y
        // Half the table's extent along that direction: the edge of the table maps to the full pan width.
        let half = abs(dir.x) * f.length * 0.5 + abs(dir.y) * f.width * 0.5
        guard half > 0 else { return 0 }
        return max(-1, min(1, along / half)) * panWidth
    }

    /// The playback rate of the last frame (1 is real time, below 1 is slow motion).
    static var rate = 1.0

    /// A delay inside a cue (seconds of shot time) as heard and felt at the current playback rate: stretched in slow
    /// motion, down to a quarter speed (slower than that, a rattle would stop sounding like one), never squeezed when
    /// playing fast (the spacing is what keeps quick hits apart).
    static func stretch(_ delay: Double) -> Double {
        stretch(delay, rate: rate)
    }

    // 0.7.7 clips: the stretch with the rate as a parameter (the body the live stretch(_:) used to hold), for the
    // clip's sound plan, which knows each frame's playback rate.
    nonisolated static func stretch(_ delay: Double, rate: Double) -> Double {
        guard delay > 0 else { return 0 }
        return delay / min(1, max(0.25, rate))
    }
}
