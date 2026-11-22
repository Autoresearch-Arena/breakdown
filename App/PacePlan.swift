// Author: Claude Opus 5.5 High
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.4 foundation: hooks for signature beats, the held Lens beat, the shared computer level and the highlight offer; plans/22-Nov-2026-v074-glow-up-plan.md)
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.4 lens-pacing, G1 "signature beats": a plan can be given a
//          SIGNATURE, the events a trick shot or a highlight is about (TrickSignature, ShotHighlightJudge). Those are
//          held right after the strike and the first hit, every one of them, as headline beats (equation filled in),
//          and the plan is kept short around them: at most the signature plus three beats. Every standard and opening
//          plan, signature or not, also takes the physics a shot is famous for before the usual variety: the first
//          take-off (a jump), the first ball-to-ball hit that threw a ball a degree or more, and the end of the
//          biggest bend (a masse). The first launch is untouched and never takes a signature.)
// Date: 20-November-2026
// PURPOSE: Guided pacing for the Physics Lens replay. Built once per recorded shot from its captions (the way
//          RidePlan is built once per shot), it picks the BEATS: the handful of moments worth stopping on so the
//          explanation can be read (always the cue strike and the first ball-to-ball hit; then the strongest other
//          moments, with variety: the first cushion, the first skid-to-roll, the first ball potted, any jaw or knuckle
//          hit, before a fifth near-identical impact). Each beat carries a reading time in REAL seconds worked out from
//          the length of its caption. It also gives the playback speed between beats as a function of the shot clock:
//          slow as a beat or a burst of events comes near, so the motion into each hit is seen, quick through quiet
//          stretches. That speed never reaches zero; the stop itself is not a speed but a separate hold that
//          ShowpieceModel runs with its own real-time counter, so the clock can never stall forever.
//          Everything is read from the recorded event times; nothing is tuned to the showpiece rack.
// Edited: Claude Opus 5.5 High, 21-November-2026 (other tables: a post rebound paces like a rail, a pin knocked down like an impact).
// Edited: Claude Opus 5.5 High, 21-November-2026 (the two generation-two event kinds: a rim skip paces like a jaw hit,
//          a jam brought to rest like an impact).
// Edited: Claude Opus 5.5 High, 21-November-2026 (0.7.0, plans/21-Nov-2026-bugs-after-0-6-6-plan.md items 6 and 55: a
//          plan now has a Style. The first launch (.firstLaunch) holds only three or four beats, the strike, the first
//          hit and one skid-to-roll (plus the first pot when there is one), so the opening and the player's own first
//          break each stay well inside a minute; the showpiece opening (.opening: Watch the intro and the menu
//          backdrop) keeps the usual selection but always holds the same two moments. Those two, the cue ball handing
//          its speed to the rack and skid turning into roll, are the HEADLINE beats: PaceBeat.headline marks them, and
//          the model's holdingHeadline lets the caption show their equation with the event's own numbers even with
//          Show the maths off. A take-off or landing is no longer counted as a skid-to-roll.)
// SRP/DRY check: Pass - choosing beats and the between-beats speed only; the hold itself and the clock live in
//          ShowpieceModel, the words in CaptionEngine.
import BreakdownLensModel
import BreakdownTimeline
import Foundation

/// One moment the guided replay stops on.
struct PaceBeat: Equatable {
    let caption: Caption
    /// How long to hold here, in real seconds, so the caption can be read.
    let dwell: Double
    /// True for a headline moment: one of the opening's two (the cue ball handing its speed to the rack, skid turning
    /// into roll), or since 0.7.4 a signature beat (the moment a trick shot or a highlight is about). While it is held
    /// its equation is shown with the event's own numbers whatever the maths setting says.
    var headline = false
    var time: Double { caption.time }
}

struct PacePlan: Equatable {
    /// Which replay the plan is for: the beats a replay holds depend on who is watching it and why.
    enum Style: Equatable, Sendable {
        /// Every player shot and break, trick shot, lesson and match shot: the usual selection, up to nine beats.
        case standard
        /// The showpiece opening watched again (Watch the intro, and the silent replay behind the menu on later
        /// launches): the usual selection, with the two headline moments always among the beats and marked.
        case opening
        /// The first launch, the showpiece and the player's own first break: only the strike, the first hit and one
        /// skid-to-roll, plus the first pot when there is one, so each replay stays well inside a minute.
        case firstLaunch
    }

    /// The moments to hold on, in clock order (ties broken by event order, so the order never changes).
    private(set) var beats: [PaceBeat] = []
    /// Clock times of every caption, beats or not, sorted: a burst of them slows playback even between beats.
    private var momentTimes: [Double] = []

    static let none = PacePlan()

    /// Speeds, as fractions of real time. The floor is a safety net: the curve itself never goes under `slow`.
    static let floor = 0.03
    static let slow = 0.05            // right at a beat
    static let busy = 0.14            // in a burst of events that are not beats
    static let fast = 0.72            // a long quiet stretch
    /// Shot-clock seconds over which playback eases down into a beat, back up after one, and down near any event.
    static let approach = 0.5
    static let departure = 0.25
    static let cluster = 0.12

    /// Reading time: about three words a second plus a second to find the card, kept between 2.5 and 6 seconds.
    static let minDwell = 2.5
    static let maxDwell = 6.0

    var hasBeats: Bool { !beats.isEmpty }

    init() {}

    /// `signature`: event indices (Caption.id) a trick shot or a highlight needs held as headline beats (0.7.4). Each
    /// one with a caption is held, marked headline, even when it is the strike or the first hit; an index with no
    /// caption (or outside the recording) is ignored. Ignored entirely for `.firstLaunch`, which stays exactly as it was.
    init(captions: [Caption], timeline tl: Timeline, style: Style = .standard, signature: [Int] = []) {
        // A still table (a re-rack or a laid-out trick position records a zero-speed strike) has nothing to pace.
        guard tl.duration > 0.3, !captions.isEmpty else { return }
        momentTimes = captions.map(\.time).sorted()

        // What sort of moment each caption is, read from its event (not from its translated title).
        func kind(_ c: Caption) -> MomentKind {
            guard tl.events.indices.contains(c.id) else { return .impact }
            let e = tl.events[c.id]
            switch e.kind {
            case .cueStrike: return .strike
            case .ballBall: return .impact
            case .cushion: return e.edge == .rail || e.edge == .post ? .rail : .jaw
            case .pinDown: return .impact
            case .phaseTransition:
                // Only a skid turning into roll is a roll moment; a take-off or a landing (the jump's flight marks) is
                // its own kind, so the opening's skid-to-roll beat is never a landing.
                if e.flight == FlightMark.none, e.phaseFrom == .sliding, e.phaseTo == .rolling { return .roll }
                return .flight
            case .pocket: return .pocket
            // Generation-two kinds: a ball skipping over a hole is a near miss at the pocket, like a jaw rattle; a
            // jam brought to rest is a contact between balls.
            case .rimSkip: return .jaw
            case .settledInContact: return .impact
            }
        }
        let kinds = captions.map(kind)

        func first(_ k: MomentKind) -> Int? { kinds.firstIndex(of: k) }
        // The headline moments. The first hit: the cue ball handing its speed on (into the rack, for a break). The
        // skid-to-roll: the first one after that hit, because a rack ball sent skidding and then settling into a roll
        // is what the opening shows; a cue ball that settles before it reaches anything is the fallback.
        let firstHit = first(.impact)
        let hitTime = firstHit.map { captions[$0].time } ?? -Double.infinity
        let skidToRoll = kinds.indices.first { kinds[$0] == .roll && captions[$0].time > hitTime } ?? first(.roll)
        var headlines: Set<Int> = style == .standard ? [] : Set([firstHit, skidToRoll].compactMap { $0 })

        // Caption index of each event index, for the signature and the bend (two different index spaces: events in
        // the recording, captions in this list; only events with a caption can be held).
        var captionOf: [Int: Int] = [:]
        for i in captions.indices where captionOf[captions[i].id] == nil { captionOf[captions[i].id] = i }

        // The signature as caption indices, in the order given, each once. Never on the first launch: its few beats
        // are fixed (FIRST-MINUTE CHECK in the 0.7.4 plan).
        var signatureCaptions: [Int] = []
        if style != .firstLaunch {
            for ev in signature where tl.events.indices.contains(ev) {
                if let i = captionOf[ev], !signatureCaptions.contains(i) { signatureCaptions.append(i) }
            }
        }
        headlines.formUnion(signatureCaptions)

        // How many beats this shot earns: a short follow-up shot gets a few, a long break up to nine, so the replay
        // never drags; the first launch holds four at most (firstLaunchBeats says why). A signature replay is short:
        // the strike, the first hit, the signature and one more, three at the least. Never more than there are
        // captions.
        let usual = min(9, max(2, Int((tl.duration * 1.5).rounded()) + 2))
        let limit: Int
        if style == .firstLaunch {
            limit = Self.firstLaunchBeats
        } else if !signatureCaptions.isEmpty {
            limit = max(3, signatureCaptions.count + 3)
        } else {
            limit = usual
        }
        let cap = min(captions.count, limit)
        var chosen: [Int] = []          // indices into captions
        func take(_ i: Int?) {
            guard let i, chosen.count < cap, !chosen.contains(i) else { return }
            chosen.append(i)
        }

        // The two that always tell the story's start: the strike, and the first hit (into the rack, for a break).
        take(first(.strike))
        take(firstHit)
        if style == .firstLaunch {
            // The first launch: one skid-to-roll, then the first pot if there is one. A shot with no skid-to-roll
            // caption (too slow to caption one) holds its first cushion instead, so there are still three beats.
            take(skidToRoll)
            take(first(.pocket))
            if chosen.count < Self.firstLaunchBeats - 1 { take(first(.rail)) }
        } else {
            // The opening always holds its second headline moment, whatever the variety rule below would pick first.
            if style == .opening { take(skidToRoll) }
            // The signature, every beat of it (the cap above leaves room for all of them).
            for i in signatureCaptions { take(i) }
            // The physics a shot is remembered for, before the usual variety: the jump's take-off, a hit that threw
            // a ball off the line of centres by a degree or more, and the end of the biggest bend (the masse's curve).
            take(Self.firstTakeOff(captions, in: tl))
            take(Self.firstThrow(captions, in: tl))
            take(Self.biggestBend(in: tl, captionOf: captionOf))
            // Variety before volume: a jaw or knuckle answers "why didn't it drop?", then the first pot, the first
            // cushion and the first skid-to-roll each show a different piece of physics.
            for i in kinds.indices where kinds[i] == .jaw && chosen.filter({ kinds[$0] == .jaw }).count < 2 { take(i) }
            take(first(.pocket))
            take(first(.rail))
            take(first(.roll))

            // Fill what is left greedily by importance, each further moment of a kind already chosen counting for
            // less, so the fifth similar impact loses to something new. Very weak moments are never padding.
            let strongest = captions.indices.filter { kinds[$0] != .strike }.map { captions[$0].importance }.max() ?? 0
            let weakest = strongest * 0.08
            while chosen.count < cap {
                var best: (index: Int, score: Double)?
                for i in captions.indices where !chosen.contains(i) && kinds[i] != .strike && captions[i].importance >= weakest {
                    let same = chosen.filter { kinds[$0] == kinds[i] }.count
                    let score = captions[i].importance * pow(0.55, Double(same))
                    if best == nil || score > best!.score { best = (i, score) }
                }
                guard let pick = best else { break }
                chosen.append(pick.index)
            }
        }

        beats = chosen
            .sorted { (captions[$0].time, captions[$0].id) < (captions[$1].time, captions[$1].id) }
            .map { PaceBeat(caption: captions[$0], dwell: Self.readingTime(captions[$0].detail),
                            headline: headlines.contains($0)) }
    }

    /// Smallest throw, degrees, that earns its hit a beat of its own (twice the half degree the caption starts naming
    /// throw at, so the beat is spent on a throw that can be seen).
    static let throwBeatDegrees = 1.0

    /// The first caption on a take-off (a ball leaving the cloth), as a caption index. Read from the event's flight
    /// mark, not the moment kind: a landing is a flight moment too, and the beat is the take-off.
    private static func firstTakeOff(_ captions: [Caption], in tl: Timeline) -> Int? {
        captions.indices.first { i in
            tl.events.indices.contains(captions[i].id) && tl.events[captions[i].id].flight == .takeOff
        }
    }

    /// The first ball-to-ball caption whose contact threw a ball at least throwBeatDegrees off the line of centres
    /// (CaptionEngine.throwFacts, the same reading the caption's words use).
    private static func firstThrow(_ captions: [Caption], in tl: Timeline) -> Int? {
        captions.indices.first { i in
            guard tl.events.indices.contains(captions[i].id) else { return false }
            let e = tl.events[captions[i].id]
            guard e.kind == .ballBall, let t = CaptionEngine.throwFacts(e) else { return false }
            return abs(t.degrees) >= throwBeatDegrees
        }
    }

    /// The caption of the event that ends the biggest bent slide of the shot, any ball (CaptionEngine.bendEvents, the
    /// lookup the caption's bend sentence comes from). Only captioned events count; ties keep the earlier event.
    private static func biggestBend(in tl: Timeline, captionOf: [Int: Int]) -> Int? {
        var best: (caption: Int, degrees: Double)?
        let bends = CaptionEngine.bendEvents(in: tl)
        for ev in bends.keys.sorted() {
            guard let c = captionOf[ev] else { continue }
            for b in bends[ev] ?? [] where best == nil || abs(b.degrees) > best!.degrees {
                best = (caption: c, degrees: abs(b.degrees))
            }
        }
        return best?.caption
    }

    /// The most beats the first launch holds. The plan asks for three or four (the strike, the first hit, one
    /// skid-to-roll, and the first pot when the break makes one): at the longest reading time (maxDwell, six seconds)
    /// plus the slow approach into each, four beats keep a break's replay near half a minute, so the showpiece and the
    /// player's own first break each stay well inside a minute.
    static let firstLaunchBeats = 4

    /// True when any beat is a headline moment.
    var hasHeadlines: Bool { beats.contains { $0.headline } }

    /// Real seconds to read a caption. Words are counted by spaces; for languages written without spaces (Japanese,
    /// Chinese) the character count stands in, at about six characters a word.
    static func readingTime(_ text: String) -> Double {
        let words = text.split(whereSeparator: \.isWhitespace).count
        let units = max(Double(words), Double(text.count) / 6)
        return min(maxDwell, max(minDwell, units / 3 + 1))
    }

    /// Index of the first beat at or after clock time `t` (beats.count when there is none).
    func firstBeat(atOrAfter t: Double) -> Int {
        var lo = 0, hi = beats.count
        while lo < hi {
            let mid = (lo + hi) / 2
            if beats[mid].time < t { lo = mid + 1 } else { hi = mid }
        }
        return lo
    }

    /// Playback speed between beats at clock time `t`. Two smooth dips multiplied into one curve: a deep one around
    /// each beat (easing in over `approach` before it and out over `departure` after it) and a shallow one around any
    /// other captioned event. Always at least `floor`, so the clock always moves.
    func rate(at t: Double) -> Double {
        guard hasBeats else { return Self.fast }
        // First beat strictly after t (a beat at exactly t has just been held and is behind us).
        var next = firstBeat(atOrAfter: t)
        while next < beats.count, beats[next].time <= t { next += 1 }
        let toNext = next < beats.count ? beats[next].time - t : .infinity
        let sincePrev = next > 0 ? t - beats[next - 1].time : .infinity
        let nearBeat = min(toNext / Self.approach, sincePrev / Self.departure)
        let beatRate = Self.ease(Self.slow, Self.fast, nearBeat)
        let eventRate = Self.ease(Self.busy, Self.fast, nearestMoment(to: t) / Self.cluster)
        return max(Self.floor, min(beatRate, eventRate))
    }

    /// Shot-clock distance from `t` to the nearest captioned event, either side.
    private func nearestMoment(to t: Double) -> Double {
        var lo = 0, hi = momentTimes.count
        while lo < hi {
            let mid = (lo + hi) / 2
            if momentTimes[mid] < t { lo = mid + 1 } else { hi = mid }
        }
        var d = Double.infinity
        if lo < momentTimes.count { d = min(d, momentTimes[lo] - t) }
        if lo > 0 { d = min(d, t - momentTimes[lo - 1]) }
        return d
    }

    /// From `low` at x = 0 to `high` at x >= 1 along a smoothstep, so speed changes never jolt.
    private static func ease(_ low: Double, _ high: Double, _ x: Double) -> Double {
        let u = min(1, max(0, x.isFinite ? x : 1))
        return low + (high - low) * u * u * (3 - 2 * u)
    }

    /// `flight` is a take-off or a landing of a jump (a phase change that is not a skid turning into roll).
    private enum MomentKind { case strike, impact, rail, jaw, roll, pocket, flight }
}
