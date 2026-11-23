// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// Edited: Claude Opus 5.5 High, 23-November-2026 (make takes the replay budget, so the App Store shape can be shorter.)
// PURPOSE: The script of a Lens clip (0.7.7, plans/23-Nov-2026-clips-plan.md, Step 4): for every frame of the film (30 a
//          second), the shot's clock, the Lens melt, the playback rate (for the sound's slow-motion stretch), whether the
//          contacts crossed on this frame sound, the moment being held, the note on screen and how opaque it is, whether
//          the camera may glide in on the moment, and how far the end card has faded in. Pure: the same recording,
//          captions and signature always give the same frames, so the same shot always makes the same film.
//          The film follows the game's own cold open, in seven parts:
//            1. lead       0.5 s still on the first frame (the camera's launch pull-back starts here);
//            2. fullSpeed  the shot at real speed for its first 6 s of clock, then faster (3 times, or more so this part
//                          never passes 9 s), with its contact sounds;
//            3. pause      0.4 s on the last frame;
//            4. melt       1.8 s, the table melting into the Physics Lens (silent);
//            5. rewind     1.2 s, the clock eased back to the start with the Lens up (silent);
//            6. replay     the explained replay: the clock moves at the cut pace plan's speed curve (rate(at:)) times a
//                          speed-up k, stops on each kept moment for its reading time (2.5 to 6 s) with its note, then plays
//                          to the end (at most 4 s) and holds 0.5 s. Held to 22 s by raising k a quarter at a time up to
//                          4, then dropping the least important moment (never the strike or a signature moment while
//                          another can go), down to two moments, then raising k further;
//            7. endCard    2.2 s, the end card fading in over the last Lens frame (silent).
//          The longest possible film is about 37 s, under the 40 s cap the script checks.
//          Sounds follow ShowpieceModel.fireSounds exactly: a frame that moves the clock forward from a to b sounds the
//          events after a up to b (and one stamped exactly 0 when a is 0); a held moment sounds on the frame the clock
//          arrives on it and then rings out; a moment at clock 0 (the strike) sounds as the clock leaves it, as in play.
//          Read by ClipRenderer (frames), ClipOverlay (beats, captions, end card), ClipSound (frames and rates) and the
//          tests (ClipScriptTests).
// SRP/DRY check: Pass - reuses PacePlan (the moments, their reading time, the speed curve and the focus rectangles, cut
//          with PacePlan.keeping) and the captions' own words; the cold open's order and smoothstep come from
//          ShowpieceModel.advance, copied here only as numbers on a fixed frame grid.
import BreakdownLensModel
import BreakdownTimeline
import Foundation

/// One frame of a clip.
struct ClipFrame: Equatable, Sendable {
    enum Part: Equatable, Sendable { case lead, fullSpeed, pause, melt, rewind, replay, endCard }

    /// The shot's clock (seconds of recorded time) drawn on this frame.
    var clock: Double
    /// 0 the warm table, 1 the Physics Lens.
    var melt: Double
    /// The playback rate for the sound's slow-motion stretch: 0 when the clock is held or moving backwards.
    var rate: Double
    /// True when the events this frame's clock crosses (forward) sound.
    var sounds: Bool
    /// The event of the moment being held (Caption.id), for the Lens's contact drawing; nil when nothing is held.
    var heldEvent: Int?
    /// The kept beat whose note shows (an index into ClipScript.beats), nil for none.
    var caption: Int?
    /// The note's opacity, 0 to 1.
    var captionOpacity: Double
    /// The camera may glide in on the moment (the game's moment framing), as in a guided Lens replay.
    var momentAllowed: Bool
    /// How far the end card has faded in, 0 to 1.
    var endCard: Double
    var part: Part
}

/// One moment the clip stops on, with the words its note shows.
struct ClipBeat: Equatable {
    let beat: PaceBeat
    /// Real seconds the clip holds here: the words' reading time, between 2.5 and 6 s.
    let dwell: Double
    /// The caption's title ("Throw") and its lead figure as text ("2.1°"), laid out side by side by the note.
    let title: String
    let figure: String?
    /// The caption's first sentence (the whole detail when it was not split), shown whole.
    let sentence: String
}

struct ClipScript: Equatable {
    let frames: [ClipFrame]
    let beats: [ClipBeat]
    /// The CUT plan (only the kept moments), never the full one: the replay's speed curve and the moment framing's
    /// request both read it, so the clock, the words and the camera follow the same moments.
    let plan: PacePlan
    var duration: Double { Double(frames.count) / Self.fps }

    // MARK: Timing (seconds of the film unless said otherwise)

    /// Frames a second.
    static let fps = 30.0
    /// The still first frame before the shot starts.
    static let lead = 0.5
    /// Seconds of the shot's clock played at real speed before the full-speed part speeds up.
    static let realTimeFor = 6.0
    /// The longest the full-speed part may take.
    static let fullSpeedCap = 9.0
    /// The still last frame before the melt.
    static let pause = 0.4
    /// The melt into the Lens, and the rewind with the Lens up.
    static let melt = 1.8
    static let rewind = 1.2
    /// The most moments the replay holds.
    static let beatLimit = 4
    /// A moment's hold: the game's own floor (PacePlan.minDwell) and the first launch's old ceiling (maxDwell).
    static let minDwell = PacePlan.minDwell
    static let maxDwell = PacePlan.maxDwell
    /// The longest the explained replay may take, holds, tail and its last hold included.
    static let replayBudget = 22.0
    /// After the last moment the clock reaches the end within this, then holds for tailHold.
    static let tailCap = 4.0
    static let tailHold = 0.5
    /// The note fades in as a hold starts and out after it ends.
    static let captionIn = 0.25
    static let captionOut = 0.4
    /// The end card, and its fade-in.
    static let endCard = 2.2
    static let endFade = 0.5
    /// The replay's speed-up k grows by this factor, normally up to speedMax.
    static let speedStep = 1.25
    static let speedMax = 4.0
    /// No clip is ever longer than this.
    static let hardCap = 40.0

    /// Frames in `seconds` of film, rounded to the nearest frame (at least one).
    private static func frameCount(_ seconds: Double) -> Int { max(1, Int((seconds * fps).rounded())) }

    /// Smoothstep, as the cold open eases its melt and rewind.
    private static func smooth(_ x: Double) -> Double { let c = min(1, max(0, x)); return c * c * (3 - 2 * c) }

    // MARK: Which moments

    /// Every beat of `plan` in the clip's order of priority: the headline (signature) moments first, then the strike
    /// (the beat whose event is the cue strike, if the plan kept one: it may have dropped it for a hit on the same
    /// picture, so beats[0] is never assumed to be it), then the first ball-to-ball hit, then the rest by importance
    /// (ties by time). Indices into plan.beats.
    static func rankedBeats(_ plan: PacePlan, timeline: Timeline) -> [Int] {
        let beats = plan.beats
        func kind(_ i: Int) -> LensEventKind? {
            let id = beats[i].caption.id
            return timeline.events.indices.contains(id) ? timeline.events[id].kind : nil
        }
        var order: [Int] = []
        func take(_ i: Int?) { if let i, !order.contains(i) { order.append(i) } }
        for i in beats.indices where beats[i].headline { take(i) }
        take(beats.indices.first { kind($0) == .cueStrike })
        take(beats.indices.first { kind($0) == .ballBall })
        let rest = beats.indices.filter { !order.contains($0) }.sorted { a, b in
            let ia = beats[a].caption.importance, ib = beats[b].caption.importance
            return ia != ib ? ia > ib : beats[a].time < beats[b].time
        }
        order += rest
        return order
    }

    /// The beats the clip keeps: the `limit` highest-priority ones, back in clock order. Indices into plan.beats.
    static func chooseBeats(_ plan: PacePlan, timeline: Timeline, limit: Int) -> [Int] {
        Array(rankedBeats(plan, timeline: timeline).prefix(max(0, limit))).sorted()
    }

    /// The words and hold of each beat of a cut plan.
    private static func clipBeats(_ cut: PacePlan) -> [ClipBeat] {
        cut.beats.map { beat in
            let c = beat.caption
            let sentence = c.sentences.first ?? c.detail
            // The title and sentence joined only to count the reading time; never shown joined.
            let dwell = min(maxDwell, max(minDwell, cut.dwell(for: c.title + " " + sentence)))
            return ClipBeat(beat: beat, dwell: dwell, title: c.title, figure: c.figures.first?.text, sentence: sentence)
        }
    }

    // MARK: Making the script

    /// The script for a recording, or nil when it has no moment worth holding (a still table makes no clip).
    static func make(timeline: Timeline, captions: [Caption], signature: [Int],
                     replayBudget: Double = ClipScript.replayBudget) -> ClipScript? {
        let full = PacePlan(captions: captions, timeline: timeline, style: .standard, signature: signature)
        guard full.hasBeats else { return nil }
        let D = timeline.duration
        let ranked = rankedBeats(full, timeline: timeline)
        var kept = chooseBeats(full, timeline: timeline, limit: beatLimit)

        // Fit the replay into its budget: raise k, then drop a moment and start again, down to two moments; with two
        // left (or fewer to begin with), k keeps growing. The holds alone are at most 2 x 6 s and the tail at most
        // 4.5 s, so a large enough k always fits.
        let budget = Int((replayBudget * fps).rounded())  // the shape's budget (shorter for the store's previews)
        var cut = full.keeping(kept)
        var beats = clipBeats(cut)
        var replay: [ClipFrame] = []
        fitting: while true {
            var k = 1.0
            while true {
                replay = replayFrames(plan: cut, beats: beats, duration: D, k: k)
                if replay.count <= budget { break fitting }
                if k >= speedMax { break }
                k = min(speedMax, k * speedStep)
            }
            if kept.count > 2 {
                kept = dropOne(kept, ranked: ranked, plan: full, timeline: timeline)
                cut = full.keeping(kept)
                beats = clipBeats(cut)
                continue fitting
            }
            // Two moments (or fewer) at k = 4 still too long: keep speeding up until it fits (bounded for safety).
            while replay.count > budget, k < 1_000 {
                k *= speedStep
                replay = replayFrames(plan: cut, beats: beats, duration: D, k: k)
            }
            break fitting
        }

        var frames: [ClipFrame] = []
        func still(_ clock: Double, melt: Double, part: ClipFrame.Part, endCard: Double = 0,
                   moment: Bool = false) -> ClipFrame {
            ClipFrame(clock: clock, melt: melt, rate: 0, sounds: false, heldEvent: nil, caption: nil, captionOpacity: 0,
                      momentAllowed: moment, endCard: endCard, part: part)
        }

        // 1. Lead: the first frame, still, silent.
        for _ in 0..<frameCount(lead) { frames.append(still(0, melt: 0, part: .lead)) }

        // 2. Full speed. Frame j shows the clock reached after (j + 1) / 30 s of this part, so its first frame has
        //    already moved and carries the strike's sound; the last frame is exactly the recording's end.
        let fast = max(3, (D - realTimeFor) / (fullSpeedCap - realTimeFor))
        let fullLength = min(D, realTimeFor) + max(0, D - realTimeFor) / fast
        let fullCount = max(1, Int((fullLength * fps).rounded(.up)))
        for j in 0..<fullCount {
            let u = Double(j + 1) / fps
            var clock = u <= realTimeFor ? u : realTimeFor + (u - realTimeFor) * fast
            if j == fullCount - 1 || clock > D { clock = D }
            let rate = u <= realTimeFor ? 1 : fast
            frames.append(ClipFrame(clock: clock, melt: 0, rate: rate, sounds: true, heldEvent: nil, caption: nil,
                                    captionOpacity: 0, momentAllowed: false, endCard: 0, part: .fullSpeed))
        }

        // 3. Pause on the last frame.
        for _ in 0..<frameCount(pause) { frames.append(still(D, melt: 0, part: .pause)) }

        // 4. Melt into the Lens at the last frame, eased as the cold open eases it.
        let meltCount = frameCount(melt)
        for j in 0..<meltCount {
            frames.append(still(D, melt: smooth(Double(j + 1) / Double(meltCount)), part: .melt))
        }

        // 5. Rewind to the start with the Lens up (silent; the clock runs backwards).
        let rewindCount = frameCount(rewind)
        for j in 0..<rewindCount {
            let x = smooth(Double(j + 1) / Double(rewindCount))
            frames.append(still(j == rewindCount - 1 ? 0 : D * (1 - x), melt: 1, part: .rewind))
        }

        // 6. The explained replay.
        frames += replay

        // 7. The end card over the last Lens frame.
        let last = frames.last
        let endCount = frameCount(endCard)
        for j in 0..<endCount {
            let fade = min(1, Double(j + 1) / (endFade * fps))
            frames.append(still(last?.clock ?? D, melt: last?.melt ?? 1, part: .endCard, endCard: fade,
                                moment: last?.momentAllowed ?? false))
        }

        assert(Double(frames.count) / fps <= hardCap, "a clip ran past the 40-second cap")
        return ClipScript(frames: frames, beats: beats, plan: cut)
    }

    /// The next moment to let go when the replay does not fit: the lowest-ranked one that is neither the strike nor a
    /// signature (headline) moment; once only those are left, the latest signature moment; failing that, the
    /// lowest-ranked of all. Returns the kept indices without it, still in clock order.
    private static func dropOne(_ kept: [Int], ranked: [Int], plan: PacePlan, timeline: Timeline) -> [Int] {
        func isStrike(_ i: Int) -> Bool {
            let id = plan.beats[i].caption.id
            return timeline.events.indices.contains(id) && timeline.events[id].kind == .cueStrike
        }
        let byRank: [Int] = ranked.filter { kept.contains($0) }
        let ordinary: Int? = byRank.last(where: { !isStrike($0) && !plan.beats[$0].headline })
        let headlines: [Int] = kept.filter { plan.beats[$0].headline }
        let latestHeadline: Int? = headlines.max(by: { plan.beats[$0].time < plan.beats[$1].time })
        guard let victim = ordinary ?? latestHeadline ?? byRank.last else { return kept }
        return kept.filter { $0 != victim }
    }

    /// The explained replay's frames for a cut plan at speed-up k: from clock 0, each frame moves the clock by
    /// (1 / 30) x rate(at: clock) x k, stopping exactly on the next moment; the arrival frame keeps its rate and its
    /// sound and starts the hold; the hold repeats that clock, silent, for the moment's dwell (the arrival frame
    /// included); then on to the next. After the last moment the clock plays to the end within tailCap and holds
    /// tailHold. The notes fade in over captionIn as a hold starts and out over captionOut after it ends.
    static func replayFrames(plan: PacePlan, beats: [ClipBeat], duration D: Double, k: Double) -> [ClipFrame] {
        let dt = 1 / fps
        let fadeIn = captionIn * fps, fadeOut = captionOut * fps
        var out: [ClipFrame] = []
        var clock = 0.0
        // The note fading out after its hold: which beat, and how many frames since the hold ended.
        var fading: (beat: Int, frames: Int)?

        // A moving frame, its note (if any) fading out.
        func moving(to next: Double, rate: Double) -> ClipFrame {
            var caption: Int?
            var opacity = 0.0
            if let f = fading {
                let n = f.frames + 1
                let o = 1 - Double(n) / fadeOut
                if o > 0 { caption = f.beat; opacity = o; fading = (f.beat, n) } else { fading = nil }
            }
            return ClipFrame(clock: next, melt: 1, rate: rate, sounds: true, heldEvent: nil, caption: caption,
                             captionOpacity: opacity, momentAllowed: true, endCard: 0, part: .replay)
        }

        for (b, beat) in beats.enumerated() {
            let t = min(D, max(0, beat.beat.time))
            let holdCount = frameCount(beat.dwell)
            var held = 0
            // Move toward the moment, stopping exactly on it.
            while clock < t {
                let rate = plan.rate(at: clock) * k
                var next = clock + dt * rate
                let arrived = next >= t
                if arrived { next = t }
                var f = moving(to: next, rate: rate)
                if arrived {
                    // The arrival frame: it sounds what it crossed (the moment's own event included) and starts the hold.
                    f.heldEvent = beat.beat.caption.id
                    f.caption = b
                    f.captionOpacity = min(1, 1 / fadeIn)
                    fading = nil
                    held = 1
                }
                clock = next
                out.append(f)
            }
            // The hold: the same clock, silent, the note fading in.
            while held < holdCount {
                held += 1
                out.append(ClipFrame(clock: clock, melt: 1, rate: 0, sounds: false, heldEvent: beat.beat.caption.id,
                                     caption: b, captionOpacity: min(1, Double(held) / fadeIn), momentAllowed: true,
                                     endCard: 0, part: .replay))
            }
            fading = (b, 0)
        }

        // The tail: on to the end within tailCap, faster than the curve if need be, then a short hold.
        var elapsed = 0.0
        while clock < D {
            let left = max(dt, tailCap - elapsed)
            let rate = max(plan.rate(at: clock) * k, (D - clock) / left)
            let next = min(D, clock + dt * rate)
            out.append(moving(to: next, rate: rate))
            clock = next
            elapsed += dt
        }
        for _ in 0..<frameCount(tailHold) {
            var f = moving(to: clock, rate: 0)
            f.sounds = false
            out.append(f)
        }
        return out
    }
}
