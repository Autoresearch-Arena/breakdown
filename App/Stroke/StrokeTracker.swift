// Author: Claude Opus 5.5 High
// Date: 21-November-2026
// PURPOSE: The finger's stroke on the cue ball, measured (plans/21-Nov-2026-stroke-and-power-plan.md). Pure: it is fed
//          samples by StrokeGesture and answers four questions:
//          - powerDepth: how far behind the cue ball the power should be read from now. Normally where the finger is,
//            exactly as the pull-back has always set power; during a quick forward push it holds the depth of the
//            backswing the push started from, so pushing through to the ball plays the swing that was drawn back.
//          - delivered: a quick forward push has come back through the cue ball: the stroke is played.
//          - the wander: how far the finger strayed sideways from the groove (a line through where it first touched,
//            along the cue) over the last third of the stroke before release, as a share of the stroke's on-screen
//            length, so a phone and an iPad feel alike. Signed: positive is to the shooter's right.
//          - the rhythm: short back-and-forth practice strokes before the final one; when the final stroke keeps their
//            rhythm it comes out steadier (rhythmFactor).
//          Depth is in table metres (as the overlay's pull-back always measured it); along and across are on-screen
//          points. Nothing here reads the clock or the screen itself, so the same samples always give the same stroke.
// SRP/DRY check: Pass - checked AimOverlay (the pull-back's depth formula and its 10-point slop are the same here) and
//          PointerAim (its 2 cm minimum pull is the same "change of mind" floor used for a backswing). The drift that
//          the wander causes is StrokeModel's; this file only measures.
import BreakdownLensModel
import Foundation

struct StrokeTracker {
    struct Sample: Equatable {
        /// Seconds, any fixed origin.
        var time: Double
        /// Metres behind the cue ball along the aim line, on the table (the pull-back's own measure).
        var depth: Double
        /// On-screen points from the first touch: back along the groove (positive away from the ball) and across it
        /// (positive to the shooter's right).
        var along: Double
        var across: Double
        /// Where the finger is on the cloth, table metres, for the trace; nil where the touch missed the table plane.
        var spot: Vec2?
    }

    /// A backswing must reach this far, metres, before a push forward can play it: PointerAim's "change of mind" floor,
    /// four per cent of the full pull, below the softest deliberate shot.
    static let minimumBackswing = 0.02
    /// The finger must come forward (or go back) this far, metres, past the furthest point before the turn counts:
    /// the same floor, so a jitter at the end of a pull is never read as a stroke.
    static let turnDistance = 0.02
    /// Seconds: a forward push that reaches the ball within this time of leaving the back of the backswing is a stroke
    /// and plays the shot; a slower one is the player easing the power down, as the pull has always allowed. A real
    /// forward stroke into the ball takes a few tenths of a second.
    static let quickForward = 0.5
    /// On-screen points: below this the stroke is too short to measure a share of (the overlay's pull slop doubled).
    static let shortestStroke = 20.0

    private(set) var samples: [Sample] = []
    /// Times and depths of each backswing's furthest point, in order.
    private(set) var peaks: [(time: Double, depth: Double)] = []
    /// Index into samples where the current leg (backswing or forward push) began.
    private var legStart = 0
    /// True while the finger is coming forward after a backswing.
    private var forward = false
    /// The furthest-back depth of the current backswing, or the nearest depth of the current forward push.
    private var extreme = 0.0
    private var extremeTime = 0.0
    /// The time the current forward push left the back of its backswing.
    private var forwardSince = 0.0
    /// Practice strokes: forward pushes that turned back before reaching the ball.
    private(set) var practiceStrokes = 0
    /// True once a quick forward push has come back through the cue ball.
    private(set) var delivered = false

    init() {}

    mutating func add(_ s: Sample) {
        guard !delivered else { return }
        if samples.isEmpty { extreme = s.depth; extremeTime = s.time }
        samples.append(s)
        if !forward {
            if s.depth >= extreme { extreme = s.depth; extremeTime = s.time }
            else if extreme - s.depth >= Self.turnDistance, extreme >= Self.minimumBackswing {
                // The backswing turned: its furthest point is a peak, and a forward push begins there.
                peaks.append((extremeTime, extreme))
                forward = true
                forwardSince = extremeTime
                legStart = lastIndex(atOrAfter: extremeTime)
                extreme = s.depth; extremeTime = s.time
            }
        } else {
            if s.depth <= extreme { extreme = s.depth; extremeTime = s.time }
            else if s.depth - extreme >= Self.turnDistance {
                // The push turned back before the ball: a practice stroke. A new backswing begins at its nearest point.
                practiceStrokes += 1
                forward = false
                legStart = lastIndex(atOrAfter: extremeTime)
                extreme = s.depth; extremeTime = s.time
            }
        }
        if forward, s.depth <= 0, s.time - forwardSince <= Self.quickForward { delivered = true }
    }

    /// The depth the power follows now (see the file header).
    var powerDepth: Double {
        guard let last = samples.last else { return 0 }
        if forward, let peak = peaks.last, last.time - forwardSince <= Self.quickForward { return peak.depth }
        return last.depth
    }

    /// The last sample at or after a time, so a leg starts on a real sample.
    private func lastIndex(atOrAfter t: Double) -> Int {
        samples.firstIndex { $0.time >= t } ?? max(0, samples.count - 1)
    }

    // MARK: Measures

    /// The stroke's on-screen length: the furthest the finger went back along the groove.
    var strokeLength: Double { samples.map(\.along).max() ?? 0 }

    /// The signed sideways wander over the last third of the final leg (the push into the ball when delivered, the
    /// end of the pull otherwise), as a share of the stroke's on-screen length: the largest offset off the groove in
    /// that stretch, with its side. Zero for a stroke too short to measure.
    var wander: Double {
        let length = strokeLength
        guard length >= Self.shortestStroke, legStart < samples.count else { return 0 }
        let leg = samples[legStart...]
        guard let endDepth = leg.last?.depth, let startDepth = leg.first?.depth else { return 0 }
        let travel = abs(endDepth - startDepth)
        // Samples whose remaining travel to the release is within the last third of the leg's travel.
        let window = leg.filter { abs(endDepth - $0.depth) <= travel / 3 + 1e-12 }
        guard let worst = window.max(by: { abs($0.across) < abs($1.across) }) else { return 0 }
        return worst.across / length
    }

    /// Steadiness from practice: needs at least two practice strokes (two earlier periods to set a rhythm). The final
    /// stroke's period (its last two backswing peaks) is compared with the mean of the earlier ones: within a tenth of
    /// it the stroke is a third steadier, fading to no help at a quarter off. A third: enough that practice is worth
    /// doing, never enough to cancel the warm zone (at full power the wobble is several times the calm one).
    var rhythmFactor: Double {
        guard peaks.count >= 3 else { return 1 }
        var periods: [Double] = []
        for i in 1..<peaks.count { periods.append(peaks[i].time - peaks[i - 1].time) }
        let final = periods.removeLast()
        let mean = periods.reduce(0, +) / Double(periods.count)
        guard mean > 0 else { return 1 }
        let off = abs(final - mean) / mean
        let help = min(1, max(0, (0.25 - off) / 0.15))
        return 1 - help / 3
    }

    /// The stroke's shape for the drill card (StrokeRecord.shape).
    var shape: [Vec2] {
        let length = strokeLength
        guard length >= Self.shortestStroke else { return [] }
        return samples.map { Vec2($0.along / length, $0.across / length) }
    }

    /// The measured stroke for the model, or nil before the finger has drawn anything worth measuring.
    func record(power: Double, bridge: Double?) -> StrokeRecord? {
        guard strokeLength >= Self.shortestStroke else { return nil }
        return StrokeRecord(wander: wander, rhythm: rhythmFactor, bridge: bridge, power: power,
                            trace: samples.compactMap(\.spot), shape: shape, practiceStrokes: practiceStrokes)
    }
}
