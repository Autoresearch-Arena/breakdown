// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The Physics Lens scrub-exactness check, as one function that returns what it measured. It drives a Lens layer
//          to a list of clock times, records the layer's fingerprint (LensLayer.fingerprint: trails, rings, arrows, spin
//          markers, opacity) at each, then visits the same times backwards, then in a shuffled order with a jump to an
//          unrelated time before each, and counts every visit whose picture differs from the first. It also checks that
//          different times look different (so a fingerprint that ignored the clock could not pass) and that the trail
//          fade only ever dims with age.
//          Two callers: TableScene logs the result when the app is launched with -lensSelfTest (on the scene's own Lens),
//          and the unit tests (BreakdownTests/LensScrubTests) build a Lens layer for a solved shot and assert on it.
//          The body moved here unchanged from TableScene.runSelfTest so both callers run the same check.
// SRP/DRY check: Pass - the check only. The Lens drawing stays in LensLayer, the logging in TableScene.
import BreakdownTimeline
import Foundation

/// What the Lens scrub check measured, and its verdict.
struct LensScrubCheck: Equatable {
    /// Revisits (backward, then shuffled) whose fingerprint differed from the first visit. Must be 0.
    var mismatches: Int
    /// How many of the visited times gave distinct pictures, out of `timesVisited`. More than four must differ.
    var distinctStates: Int
    var timesVisited: Int
    /// True when the trail brightness never rises with age (sampled every 0.01 s up to 4 s).
    var fadeMonotone: Bool
    /// The trail brightness at a very old age (the floor the trails fade to), for the log.
    var fadeFloor: Double
    /// Whether the system bloom pass is on for this layer (logged only; the check holds either way).
    var bloomActive: Bool

    var passed: Bool { mismatches == 0 && fadeMonotone && distinctStates > 4 }

    /// Runs the check on `lens`, which must already be built for `timeline` (buildStatic, then rebuild). Leaves the
    /// layer showing the last time visited; the caller's next frame puts it back to the playback clock.
    @MainActor
    static func run(lens: LensLayer, timeline: Timeline, frame: TableFrame) -> LensScrubCheck {
        let d = timeline.duration
        // Fixed early times (the strike and the first impacts happen in the first second of most shots), then
        // fractions of the whole shot; each clamped to the shot's end so a short shot still visits valid times.
        let times = [0.0, 0.05, 0.3, 0.9, 1.7, 2.6, d * 0.5, d * 0.8, d].map { min($0, d) }
        let visible = [Bool](repeating: true, count: timeline.ballCount)
        func print(at t: Double) -> UInt64 {
            lens.apply(time: t, melt: 1, aim: nil, timeline: timeline, frame: frame, ballVisible: visible)
            return lens.fingerprint()
        }
        var first: [Double: UInt64] = [:]
        for t in times { first[t] = print(at: t) }                     // forward
        var mismatches = 0
        for t in times.reversed() where print(at: t) != first[t] { mismatches += 1 }   // backward
        for t in [times[5], times[1], times[8], times[0], times[6], times[3], times[2], times[7], times[4]] {
            _ = print(at: d * 0.37)                                    // jump somewhere unrelated first
            if print(at: t) != first[t] { mismatches += 1 }            // then back to a known time
        }
        // Different times should look different (guards against a fingerprint that ignores the clock).
        let distinct = Set(first.values).count
        var monotone = true
        var prev = 2.0
        for i in 0...400 {
            let b = LensLayer.trailBrightness(age: Double(i) * 0.01)
            if b > prev + 1e-12 { monotone = false }
            prev = b
        }
        return LensScrubCheck(mismatches: mismatches, distinctStates: distinct, timesVisited: times.count,
                              fadeMonotone: monotone, fadeFloor: LensLayer.trailBrightness(age: 99),
                              bloomActive: lens.bloomActive)
    }
}
