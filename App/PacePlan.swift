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
// Edited: Claude Opus 5.5 High, 23-November-2026 (a jump's take-off and landing are framed on the whole flight and
//          the ball it passes over, not a short stretch of path: the Boss found the jump replay showing one ball on an
//          empty grid.)
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
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.6 stream pacing, plans/22-Nov-2026-v076-phone-plan.md and
//          bug-hunt entries 4 and 5: a beat's reading time is no longer capped at six seconds, except on the first
//          launch (the plan keeps its Style and says which); two beats on the same picture (a few hundredths of a second
//          apart, nothing moved) are held once, the more important one kept (a signature or headline beat, then the
//          physics a shot is remembered for, then the rest, the strike last); and focusRegions, one rectangle on the
//          table per beat holding what that beat is about, for the camera's moment framing.)
// Edited: Claude Opus 5.5 High, 23-November-2026 (0.7.7 clips, plans/23-Nov-2026-clips-plan.md: keeping(_:), a copy of
//          the plan with only some of its beats and their focus rectangles, for the clip's cut plan. Nothing else
//          changes.)
// SRP/DRY check: Pass - choosing beats, where each one happens on the table and the between-beats speed only; the hold
//          itself and the clock live in ShowpieceModel, the words in CaptionEngine, the camera move in MomentFrame.
//          checked CameraFraming's FramingRect (screen points, y down) before adding TableRect (table metres): different
//          spaces, so neither stands in for the other.
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

/// An axis-aligned rectangle on the table, in the table's own coordinates: metres, the same Vec2 space as Timeline
/// positions (BallState.position, LensEvent.point), x along the table's length and y across it. Not screen points.
struct TableRect: Equatable, Sendable {
    var minX: Double
    var minY: Double
    var maxX: Double
    var maxY: Double

    /// The smallest rectangle holding one point.
    init(around p: Vec2) { minX = p.x; maxX = p.x; minY = p.y; maxY = p.y }

    init(minX: Double, minY: Double, maxX: Double, maxY: Double) {
        self.minX = minX; self.minY = minY; self.maxX = maxX; self.maxY = maxY
    }

    var center: Vec2 { Vec2((minX + maxX) * 0.5, (minY + maxY) * 0.5) }
    var width: Double { maxX - minX }
    var height: Double { maxY - minY }

    /// Grown to hold `p` as well.
    mutating func include(_ p: Vec2) {
        minX = min(minX, p.x); maxX = max(maxX, p.x)
        minY = min(minY, p.y); maxY = max(maxY, p.y)
    }

    /// The smallest rectangle holding both.
    func union(_ o: TableRect) -> TableRect {
        TableRect(minX: min(minX, o.minX), minY: min(minY, o.minY), maxX: max(maxX, o.maxX), maxY: max(maxY, o.maxY))
    }

    /// Every edge moved out by `d` metres (in by a negative `d`).
    func outset(by d: Double) -> TableRect {
        TableRect(minX: minX - d, minY: minY - d, maxX: maxX + d, maxY: maxY + d)
    }
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
    /// Where each beat happens (0.7.6, read by the camera's moment framing through model.pacePlan): one rectangle per
    /// beat, same order and count as `beats` (focusRegions[i] belongs to beats[i]), in TableRect's space, the table's
    /// own metres as Timeline positions. Each holds what its beat is about, with a ball radius of margin: for a hit,
    /// both balls and about 0.25 m of each one's path after it; for a skid turning into roll or the end of a bend, the
    /// slide's path; for the strike, the struck ball and the first 0.3 m of its path; for a cushion, a pocket, a jaw, a
    /// rim skip or a pin, the ball and 0.2 m around it; for a take-off, the ball and 0.25 m of its flight. A pure
    /// function of the recording, built once with the beats. Empty when there are no beats.
    private(set) var focusRegions: [TableRect] = []
    /// Which replay this plan was built for. The first launch keeps the capped reading time; see readingTime.
    private(set) var style: Style = .standard
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

    /// Reading time: about three words a second plus a second to find the card, at least 2.5 seconds. Only the first
    /// launch keeps the old ceiling of 6 seconds (0.7.6, bug-hunt entry 4: a sixty-word Throw card needs about twenty
    /// seconds and was let go after six); the menu backdrop has its own short dwell in the model.
    static let minDwell = 2.5
    static let maxDwell = 6.0

    var hasBeats: Bool { !beats.isEmpty }

    init() {}

    /// `signature`: event indices (Caption.id) a trick shot or a highlight needs held as headline beats (0.7.4). Each
    /// one with a caption is held, marked headline, even when it is the strike or the first hit; an index with no
    /// caption (or outside the recording) is ignored. Ignored entirely for `.firstLaunch`, which stays exactly as it was.
    init(captions: [Caption], timeline tl: Timeline, style: Style = .standard, signature: [Int] = []) {
        self.style = style
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

        // The physics a shot is remembered for (found once, used for both the picks below and their rank).
        let takeOff = Self.firstTakeOff(captions, in: tl)
        let thrown = Self.firstThrow(captions, in: tl)
        // The bends, keyed by the event that ends each bent slide (CaptionEngine's lookup, read once per plan).
        let bendsByEvent = CaptionEngine.bendEvents(in: tl)
        let bend = Self.biggestBend(bendsByEvent, captionOf: captionOf)
        let remembered = Set([takeOff, thrown, bend].compactMap { $0 })

        // Two beats on the same picture (0.7.6, bug-hunt entry 5): in a rack the second row's contact comes about a
        // millisecond after the first hit, so the replay stopped twice on one frozen frame. Such a pair is held once,
        // the more important one kept. Rank: a headline (signature, or the opening's two) is never given up, and two
        // headlines on one picture both stay; then the physics a shot is remembered for (a thrown ball beats a plain
        // first hit); then the rest; the strike lowest, so a hit at the very instant of the strike (a frozen ball) is
        // the one held. Equal ranks keep the one taken first. The first launch is left exactly as it was.
        let dedupe = style != .firstLaunch
        func rank(_ i: Int) -> Int {
            if headlines.contains(i) { return 3 }
            if remembered.contains(i) { return 2 }
            return kinds[i] == .strike ? 0 : 1
        }
        // Each pair is compared once (a break has dozens of captions within a few hundredths of its first hit, and the
        // greedy fill below asks again on every round).
        var pictureMemo: [Int: Bool] = [:]
        func onSamePicture(_ a: Int, _ b: Int) -> Bool {
            guard dedupe else { return false }
            let key = min(a, b) * captions.count + max(a, b)
            if let known = pictureMemo[key] { return known }
            let same = Self.samePicture(captions[a].time, captions[b].time, in: tl)
            pictureMemo[key] = same
            return same
        }
        func take(_ i: Int?) {
            guard let i, !chosen.contains(i) else { return }
            let clash = chosen.filter { onSamePicture($0, i) }
            // A clash with a beat that matters as much or more: this one is the repeat (unless both are headlines).
            if rank(i) < 3, clash.contains(where: { rank($0) >= rank(i) }) { return }
            // This one matters more: the lesser beats on its picture give way to it (their places are freed).
            chosen.removeAll { j in clash.contains(j) && rank(j) < rank(i) }
            guard chosen.count < cap else { return }
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
            take(takeOff)
            take(thrown)
            take(bend)
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
                // A moment on the same picture as a beat already chosen is never padding (entry 5).
                for i in captions.indices where !chosen.contains(i) && kinds[i] != .strike && captions[i].importance >= weakest
                    && !chosen.contains(where: { onSamePicture($0, i) }) {
                    let same = chosen.filter { kinds[$0] == kinds[i] }.count
                    let score = captions[i].importance * pow(0.55, Double(same))
                    if best == nil || score > best!.score { best = (i, score) }
                }
                guard let pick = best else { break }
                chosen.append(pick.index)
            }
        }

        let capped = style == .firstLaunch
        beats = chosen
            .sorted { (captions[$0].time, captions[$0].id) < (captions[$1].time, captions[$1].id) }
            .map { PaceBeat(caption: captions[$0], dwell: Self.readingTime(captions[$0].detail, capped: capped),
                            headline: headlines.contains($0)) }
        focusRegions = beats.map { Self.focusRegion(of: $0.caption.id, in: tl, bends: bendsByEvent) }
    }

    /// Reading time for this plan's own replay (the first launch capped, every other uncapped); the model uses it when
    /// the card shows more words than the beat's caption (the strike's stroke sentence).
    func dwell(for text: String) -> Double {
        Self.readingTime(text, capped: style == .firstLaunch)
    }

    // MARK: The same picture (entry 5)

    /// Two clock times this close can be the same picture...
    static let samePictureTime = 0.03
    /// ...when no ball moved more than this share of a ball radius between them.
    static let samePictureMove = 0.5

    /// True when the table looks the same at clock times `a` and `b`: they are a few hundredths of a second apart and
    /// no ball moved more than half a radius in between (a rack's contacts a millisecond apart). A strike and a hit
    /// 0.03 s later with the cue ball crossing 20 cm between them are two pictures, so both are held.
    private static func samePicture(_ a: Double, _ b: Double, in tl: Timeline) -> Bool {
        guard abs(a - b) <= samePictureTime else { return false }
        let limit = tl.table.ballRadius * samePictureMove
        for ball in 0..<tl.ballCount where tl.segments[ball].count > 0 {
            if (tl.state(ball: ball, at: a).position - tl.state(ball: ball, at: b).position).length > limit { return false }
        }
        return true
    }

    // MARK: Where a beat happens (focusRegions)

    /// Metres of path after a hit, after the strike, and around a still moment (cushion, pocket, jaw, pin).
    static let hitPath = 0.25
    static let strikePath = 0.3
    static let around = 0.2

    /// The rectangle on the table that holds what event `ev` is about (see focusRegions). An event the recording does
    /// not have (it never should) gets the whole table, so the framing simply stays out.
    private static func focusRegion(of ev: Int, in tl: Timeline,
                                    bends: [Int: [(ball: Int, degrees: Double)]]) -> TableRect {
        let table = TableRect(minX: 0, minY: 0, maxX: tl.table.length, maxY: tl.table.width)
        guard tl.events.indices.contains(ev) else { return table }
        let e = tl.events[ev]
        let balls = e.balls.map(\.ball).filter { tl.segments.indices.contains($0) && !tl.segments[$0].isEmpty }
        var rect = TableRect(around: e.point)
        // A still moment: the ball where it was, and the stated room around it.
        func surround(_ ball: Int) {
            rect = rect.union(TableRect(around: tl.state(ball: ball, at: e.time).position).outset(by: around))
        }
        switch e.kind {
        case .cueStrike:
            for b in balls.prefix(1) { rect = rect.union(path(of: b, from: e.time, metres: strikePath, in: tl)) }
        case .ballBall, .settledInContact:
            for b in balls.prefix(2) { rect = rect.union(path(of: b, from: e.time, metres: hitPath, in: tl)) }
        case .phaseTransition:
            if e.flight == .takeOff || e.flight == .landing {
                // A jump: the whole flight and any ball it passes over, so the player sees what was jumped. A short
                // stretch of path showed only the flying ball on an empty grid (the Boss, 23-Nov-2026).
                for b in balls.prefix(1) { rect = rect.union(flight(of: b, around: e.time, in: tl)) }
            } else if e.flight == FlightMark.none, e.phaseFrom == .sliding {
                // Skid turning into roll: the slide that has just ended.
                for b in balls.prefix(1) { rect = rect.union(slide(of: b, endingAt: e.time, in: tl)) }
            } else {
                for b in balls.prefix(1) { surround(b) }
            }
        case .cushion, .pocket, .rimSkip, .pinDown:
            for b in balls.prefix(1) { surround(b) }
        }
        // The end of a bent slide (the masse's curve, a swerve into a hit): the bend itself is what the caption's bend
        // sentence names, so its whole slide is in view too (CaptionEngine.bendEvents, the caption's own lookup).
        if let ended = bends[ev] {
            for b in ended where tl.segments.indices.contains(b.ball) && !tl.segments[b.ball].isEmpty {
                rect = rect.union(slide(of: b.ball, endingAt: e.time, in: tl))
            }
        }
        return rect.outset(by: tl.table.ballRadius)
    }

    /// The flight `ball` is in at clock time `t` (a take-off starts one, a landing ends one or starts a bounce): every
    /// airborne stretch within a second either side of `t`, joined, plus a little of the cloth before and after, and
    /// every other ball that sits within two ball widths of that flight while it flies (the ball that was jumped).
    /// Sampled every 1/120 s; a flight on a pool table lasts well under a second.
    private static func flight(of ball: Int, around t: Double, in tl: Timeline) -> TableRect {
        let step = 1.0 / 120
        let start = max(0, t - 1), end = min(tl.duration, t + 1)
        var points: [(time: Double, position: Vec2)] = []
        var now = start
        while now <= end {
            let s = tl.state(ball: ball, at: now)
            if s.phase == .airborne { points.append((now, s.position)) }
            now += step
        }
        var rect = TableRect(around: tl.state(ball: ball, at: t).position)
        guard let first = points.first, let last = points.last else {
            return rect.union(path(of: ball, from: t, metres: hitPath, in: tl))
        }
        for p in points { rect.include(p.position) }
        // A little of the run-up and the roll-out, so take-off and landing read as places on the table.
        rect.include(tl.state(ball: ball, at: max(0, first.time - 0.15)).position)
        rect = rect.union(path(of: ball, from: last.time, metres: hitPath, in: tl))
        // The ball (or balls) the flight passes over.
        let reach = tl.table.ballRadius * 4
        for other in 0..<tl.ballCount where other != ball && tl.segments.indices.contains(other)
            && !tl.segments[other].isEmpty {
            let o = tl.state(ball: other, at: first.time)
            if o.pocketed { continue }
            if points.contains(where: { ($0.position - o.position).length < reach }) { rect.include(o.position) }
        }
        return rect
    }

    /// Where `ball` goes from clock time `t` for about `metres` of path (less when it stops, drops or the recording
    /// ends first), as the rectangle holding it. Sampled every 1/120 s of clock for at most three seconds: plenty for
    /// a fraction of a metre at any speed the solver records.
    private static func path(of ball: Int, from t: Double, metres: Double, in tl: Timeline) -> TableRect {
        var p = tl.state(ball: ball, at: t).position
        var rect = TableRect(around: p)
        var travelled = 0.0
        let step = 1.0 / 120
        let end = min(tl.duration, t + 3)
        var now = t
        while travelled < metres, now < end {
            now = min(end, now + step)
            let s = tl.state(ball: ball, at: now)
            travelled += (s.position - p).length
            p = s.position
            rect.include(p)
            if s.pocketed || s.phase == .stationary { break }
        }
        return rect
    }

    /// The sliding path of `ball` that ends at clock time `t`: its sliding segment just before `t`, sampled along its
    /// curve (a slide under spin bends). Just the ball's place when it was not sliding.
    private static func slide(of ball: Int, endingAt t: Double, in tl: Timeline) -> TableRect {
        var rect = TableRect(around: tl.state(ball: ball, at: t).position)
        let segs = tl.segments[ball]
        let k = tl.segmentIndex(ball: ball, at: max(0, t - 1e-7))
        guard segs.indices.contains(k), segs[k].phase == .sliding else { return rect }
        let t0 = segs[k].t0
        let samples = 24
        for n in 0...samples {
            rect.include(tl.state(ball: ball, at: t0 + (t - t0) * Double(n) / Double(samples)).position)
        }
        return rect
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
    private static func biggestBend(_ bends: [Int: [(ball: Int, degrees: Double)]], captionOf: [Int: Int]) -> Int? {
        var best: (caption: Int, degrees: Double)?
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
    /// `capped`: the first launch's ceiling of maxDwell (entry 4); every other replay reads the whole caption.
    static func readingTime(_ text: String, capped: Bool) -> Double {
        let words = text.split(whereSeparator: \.isWhitespace).count
        let units = max(Double(words), Double(text.count) / 6)
        let time = max(minDwell, units / 3 + 1)
        return capped ? min(maxDwell, time) : time
    }

    // 0.7.7 clips: the clip's hook (ClipScript). A copy holding only beats[i] and focusRegions[i] for the given
    // indices (out-of-range ones ignored, duplicates once, kept in clock order). The caption times every burst slows
    // for (momentTimes) and the style are unchanged, so rate(at:) still eases through the other events exactly as
    // before; only the stops are fewer. The clip's speed curve, its words and its moment framing all read this one
    // cut plan, so they always agree on which moments are held.
    func keeping(_ indices: [Int]) -> PacePlan {
        let chosen = Array(Set(indices.filter { beats.indices.contains($0) })).sorted()
        var cut = self
        cut.beats = chosen.map { beats[$0] }
        cut.focusRegions = chosen.compactMap { focusRegions.indices.contains($0) ? focusRegions[$0] : nil }
        return cut
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
