// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// Edited: Claude Opus 5.5 High, 22-November-2026 (0.7.4 lens-pacing: the bodies filled in, and the shared event
//          finders (ShotMoments) that TrickSignature reads too.)
// PURPOSE: Reads a recorded shot and says which remarkable moments it had (plans/22-Nov-2026-v074-glow-up-plan.md,
//          F3 and stream lens-pacing): a jump, a curve, a thrown pot, a combination, a kick, a bank, two at once, a
//          big draw, a dead stop, a ball too fast for the pocket, a bumper into the cup, the red pin alone, or a break.
//          Pure: a recording, its ShotFacts and its captions in, a list out. Each moment names the events a guided Lens
//          replay holds on (its signature), and every one of those has a caption, because PacePlan can only hold a
//          captioned event. The model calls judge(...) after each free-play and match shot (watch-invite stream); the
//          match card and the Table cleared card replay what it found.
//          Also holds ShotMoments, the one set of event finders (first contact, rails before it, take-off and landing,
//          the end of the biggest bend, the last contact before a drop, the bank's cushion, the skid-to-roll after a
//          hit, pockets, rim skips, pins, posts) that both this judge and TrickSignature use, so neither copies them.
// SRP/DRY check: Pass - checked Captions (the moments' captions, throwFacts and the bend lookup, reused here, never
//          restated), ShotFacts (first contact, pots, resting places, pins; reused) and TrickShotJudge (judges a trick
//          shot's goal, not what kind of shot it was). Detection lives only here.
import BreakdownLensModel
import BreakdownRules
import BreakdownTimeline
import Foundation

// MARK: The shared event finders

/// Event finders over one recording. Every finder returns an index into `timeline.events` (which is also the Caption.id
/// of that event's caption). The finders themselves do not care about captions, so detection can read any event;
/// `signature(_:)` is the gate that keeps only captioned events for a replay to hold on.
/// Used by ShotHighlightJudge and TrickSignature (0.7.4); nothing else should grow its own copy of these.
struct ShotMoments {
    let timeline: Timeline
    /// The event indices that carry a caption (Caption.id is the event index).
    private let captioned: Set<Int>
    /// Bends keyed by the event that ended each bent slide (CaptionEngine's own lookup, so the bend held is the bend
    /// the caption names).
    private let bends: [Int: [(ball: Int, degrees: Double)]]

    /// Two events this close in clock time are at the same instant (the solver's times are exact; this only absorbs
    /// rounding).
    static let instant = 1e-9

    init(timeline: Timeline, captions: [Caption]) {
        self.timeline = timeline
        captioned = Set(captions.map(\.id))
        bends = CaptionEngine.bendEvents(in: timeline)
    }

    private var events: [LensEvent] { timeline.events }

    /// Clock time of an event.
    func time(_ i: Int) -> Double { events[i].time }

    /// True when the event has a caption, so a guided replay can hold on it.
    func isCaptioned(_ i: Int) -> Bool { captioned.contains(i) }

    /// The events a replay should hold, from candidates in order of preference: nils, uncaptioned and repeated events
    /// dropped, at most two kept, returned in clock order (ties by event index). Empty when nothing survives.
    func signature(_ candidates: [Int?]) -> [Int] {
        var kept: [Int] = []
        for c in candidates {
            guard let c, events.indices.contains(c), captioned.contains(c), !kept.contains(c) else { continue }
            kept.append(c)
            if kept.count == 2 { break }
        }
        return kept.sorted { (events[$0].time, $0) < (events[$1].time, $1) }
    }

    // Small readers over one event.
    private func names(_ e: LensEvent, _ ball: Int) -> Bool { e.balls.contains { $0.ball == ball } }
    private func leads(_ e: LensEvent, _ ball: Int) -> Bool { e.balls.first?.ball == ball }
    private func isContact(_ e: LensEvent) -> Bool { e.kind == .ballBall && e.balls.count >= 2 }

    // MARK: Ball-to-ball contacts

    /// Every ball-to-ball contact `ball` took part in, in recording (clock) order.
    func contacts(of ball: Int) -> [Int] {
        events.indices.filter { isContact(events[$0]) && names(events[$0], ball) }
    }

    /// The first ball-to-ball contact of `ball` (for the struck ball: its first hit), or nil when it touched none.
    func firstContact(of ball: Int) -> Int? { contacts(of: ball).first }

    /// The other ball in a ball-to-ball contact, seen from `ball`.
    func other(in i: Int, than ball: Int) -> Int? {
        let e = events[i]
        guard isContact(e) else { return nil }
        return e.balls.first { $0.ball != ball }?.ball
    }

    /// The last ball-to-ball contact of `ball` at or before clock time `t` (for a pocketed ball, its drop).
    func lastContact(of ball: Int, atOrBefore t: Double) -> Int? {
        contacts(of: ball).last { events[$0].time <= t + Self.instant }
    }

    /// The struck ball's second distinct hit: its first contact with a ball other than the one it hit first (a carom's
    /// second ball), or else its second contact of any kind (a double kiss). Nil when it touched fewer than two.
    func secondContact(of ball: Int) -> Int? {
        let all = contacts(of: ball)
        guard let first = all.first else { return nil }
        let firstBall = other(in: first, than: ball)
        return all.dropFirst().first { other(in: $0, than: ball) != firstBall } ?? all.dropFirst().first
    }

    /// The ball-to-ball contact with the largest throw (CaptionEngine.throwFacts: a ball at rest sent off the line of
    /// centres by friction), preferring one whose thrown ball went on to drop. Nil when no contact threw a ball.
    func throwContact() -> Int? {
        var best: (index: Int, dropped: Bool, degrees: Double)?
        for i in events.indices where isContact(events[i]) {
            guard let t = CaptionEngine.throwFacts(events[i]) else { continue }
            let dropped = pocket(of: t.object) != nil
            let candidate = (index: i, dropped: dropped, degrees: abs(t.degrees))
            // A dropped ball's throw beats any other; between equals, the bigger throw; between equal throws, the
            // earlier event (strict comparisons keep the first found).
            if let b = best {
                if (candidate.dropped && !b.dropped) || (candidate.dropped == b.dropped && candidate.degrees > b.degrees) {
                    best = candidate
                }
            } else {
                best = candidate
            }
        }
        return best?.index
    }

    // MARK: Cushions, posts, pockets, pins

    /// Straight-rail hits (edge .rail) of `ball` before its first ball-to-ball contact (all of them when it touched no
    /// ball). A touch while the ball is still within ShotFacts.railMoveMinimum of where it started is skipped: a ball
    /// frozen on a rail and pushed along it has not gone to the rail and come back (ShotFacts' own rule).
    func railsBeforeFirstContact(of ball: Int) -> [Int] {
        let until = firstContact(of: ball).map { events[$0].time } ?? .infinity
        guard timeline.segments.indices.contains(ball) else { return [] }
        let start = timeline.state(ball: ball, at: 0).position
        return events.indices.filter { i in
            let e = events[i]
            guard e.kind == .cushion, e.edge == .rail, leads(e, ball), e.time <= until + Self.instant else { return false }
            return (timeline.state(ball: ball, at: e.time).position - start).length >= ShotFacts.railMoveMinimum
        }
    }

    /// The first straight-rail hit of `ball` after its last ball-to-ball contact and, when it dropped, before its drop:
    /// the bank's cushion. Nil when it touched no ball, or met no rail after the last one.
    func railAfterLastContact(of ball: Int) -> Int? {
        let drop = pocket(of: ball)
        let end = drop.map { events[$0].time } ?? .infinity
        guard let last = lastContact(of: ball, atOrBefore: end) else { return nil }
        return events.indices.first { i in
            let e = events[i]
            return i > last && e.kind == .cushion && e.edge == .rail && leads(e, ball)
                && e.time >= events[last].time && e.time <= end + Self.instant
        }
    }

    /// The post hits (edge .post) of `ball` at or before clock time `t`, in order.
    func postHits(of ball: Int, atOrBefore t: Double) -> [Int] {
        events.indices.filter { i in
            let e = events[i]
            return e.kind == .cushion && e.edge == .post && leads(e, ball) && e.time <= t + Self.instant
        }
    }

    /// The capture radius of a hole a pocket event names (an edge pocket 0 to 5, or bed hole 6 + j): how close the ball's
    /// centre must come to the hole's centre to drop, the solver's own test. Nil when the table has no such hole.
    func captureRadius(pocket k: Int) -> Double? {
        let t = timeline.table
        if k >= 0 && k < TableSpec.edgePocketCount {
            return t.pocketsEnabled && k < t.pocketCaptureRadius.count ? t.pocketCaptureRadius[k] : nil
        }
        let j = k - TableSpec.edgePocketCount
        return t.bedHoles.indices.contains(j) ? t.bedHoles[j].captureRadius : nil
    }

    /// True when `ball`, sent from where it was at event `i` in a straight line along `direction`, would pass hole `k`
    /// farther from its centre than the capture radius, or head away from it: on that line it would have missed. False
    /// when the hole is unknown, so an unreadable case never claims a miss.
    func wouldMiss(ball: Int, from i: Int, along direction: Vec2, pocket k: Int) -> Bool {
        guard let centre = timeline.table.holeCenter(pocket: k), let r = captureRadius(pocket: k),
              timeline.segments.indices.contains(ball) else { return false }
        let from = timeline.state(ball: ball, at: events[i].time).position
        let w = centre - from
        let u = direction.normalized
        guard u.length > 0.5 else { return false }
        if w.dot(u) <= 0 { return true }
        // Distance from the hole's centre to the line: the cross product of the unit direction with the offset.
        return abs(u.x * w.y - u.y * w.x) > r
    }

    /// Every drop (pocket or bed hole), in order.
    func pockets() -> [Int] { events.indices.filter { events[$0].kind == .pocket } }

    /// The drop of `ball`, if it dropped.
    func pocket(of ball: Int) -> Int? { events.indices.first { events[$0].kind == .pocket && leads(events[$0], ball) } }

    /// Every rim skip (a ball crossing a hole too fast to fall in), in order.
    func rimSkips() -> [Int] { events.indices.filter { events[$0].kind == .rimSkip } }

    /// Every pin knocked down, in order.
    func pinDowns() -> [Int] { events.indices.filter { events[$0].kind == .pinDown } }

    // MARK: Flight and the slide

    /// How much of the spin the cue put on `ball` turns its path: the horizontal spin along the direction it was sent,
    /// as a share of rolling spin (|omega along the path| x R / speed), read from the cue-strike event. A level cue's
    /// topspin, backspin and side all lie across the path or about the vertical, so this is near zero for it (only the
    /// small squirt turn of the launch tilts it); a raised cue (a masse) tips the spin axis toward the path, and that is
    /// what makes a sliding ball curve before anything else touches it. Nil when the recording has no strike of `ball`.
    func strikeCurl(of ball: Int) -> Double? {
        guard let e = events.first(where: { $0.kind == .cueStrike && leads($0, ball) }),
              let b = e.balls.first(where: { $0.ball == ball }) else { return nil }
        let v = b.velocityAfter
        guard v.length > 1e-6 else { return 0 }
        let along = abs(Vec2(b.omegaAfter.x, b.omegaAfter.y).dot(v.normalized))
        return along * timeline.table.ballRadius / v.length
    }

    /// The first take-off of `ball` whose upward speed is at least `minimumUp` m/s.
    func takeOff(of ball: Int, minimumUp: Double = 0) -> Int? {
        events.indices.first { i in
            let e = events[i]
            return e.kind == .phaseTransition && e.flight == .takeOff && leads(e, ball) && e.verticalSpeedUp >= minimumUp
        }
    }

    /// The first landing of `ball` after the event `i` (its take-off).
    func landing(of ball: Int, after i: Int) -> Int? {
        events.indices.first { j in
            let e = events[j]
            return j > i && e.kind == .phaseTransition && e.flight == .landing && leads(e, ball)
        }
    }

    /// The first skid turning into roll of `ball` after the event `i` (for the struck ball after its hit: the moment a
    /// draw or follow takes hold).
    func firstRoll(of ball: Int, after i: Int) -> Int? {
        events.indices.first { j in
            let e = events[j]
            return j > i && e.kind == .phaseTransition && e.flight == .none && e.phaseFrom == .sliding
                && e.phaseTo == .rolling && leads(e, ball) && e.time >= events[i].time
        }
    }

    /// The event that ends the biggest bent slide of `ball` (CaptionEngine.bendEvents) strictly after clock time `t0`
    /// and at or before clock time `t`, with its signed degrees. Ties keep the earlier event. Nil when no slide of that
    /// ball in that stretch bent enough to name.
    func largestBend(of ball: Int, after t0: Double = -.infinity,
                     atOrBefore t: Double = .infinity) -> (event: Int, degrees: Double)? {
        var best: (event: Int, degrees: Double)?
        for i in bends.keys.sorted() where events.indices.contains(i) && events[i].time <= t + Self.instant
            && events[i].time > t0 + Self.instant {
            for b in bends[i] ?? [] where b.ball == ball {
                if best == nil || abs(b.degrees) > abs(best!.degrees) { best = (event: i, degrees: b.degrees) }
            }
        }
        return best
    }
}

// MARK: The judge

enum ShotHighlightJudge {
    /// Thresholds from the plan (plans/22-Nov-2026-v074-glow-up-plan.md, lens-pacing brief item 4), except the three
    /// whose notes say they were changed or added after measuring real solves (curveCurl, the throw's miss test and
    /// stopSpeed).
    /// A take-off counts as a jump from this upward speed, m/s (a raised stroke's small hop is not a jump).
    static let jumpSpeed = 0.5
    /// A slide before the first hit must bend at least this much, degrees, to be a curve (a masse, not a drift).
    static let curveDegrees = 10.0
    /// ...and the cue must have put at least this share of rolling spin along the ball's path (ShotMoments.strikeCurl),
    /// which only a raised cue does. Without it the rule fired on about four in ten ordinary level-cue shots: a ball
    /// coming off a rail with top or back spin bends too (measured on 22-Nov-2026 over 280 random level-cue shots,
    /// whose largest share was 0.03; the Masse answer has 0.43 and the Draw-Masse Carom 0.25).
    static let curveCurl = 0.1
    /// A pot's last contact must throw the ball at least this much, degrees, to be "thrown in"...
    static let throwDegrees = 1.5
    /// ...and the throw must have made the pot: on the line of centres alone the ball would have missed the hole
    /// (ShotMoments.wouldMiss). Without that, an ordinary cut pot threw 1.5 to 2.5 degrees often enough that the
    /// "rare" card came after most cut pots (Follow Train's and Combination Chain's pots throw about 2 degrees and
    /// would have dropped anyway; Throw It In's 8 is 71 mm off the hole on its line of centres, outside the 65 mm
    /// capture radius, and 52 mm off on its real path; measured on 22-Nov-2026).
    /// A drawn cue ball must come to rest at least this far behind where it hit, metres, along its way in.
    static let drawDistance = 0.6
    /// A dead stop needs at least this speed into the hit, m/s, so a dribble that dies beside the ball is not one. The
    /// plan's first figure was 1.2; the authored Stop Dead answer arrives at about 1.14 m/s (checked against a real
    /// solve on 22-Nov-2026), so the gate is a round 1.0 with room under the shot that teaches it.
    static let stopSpeed = 1.0

    /// Every remarkable moment of a recorded shot, strongest (HighlightKind.rank) first; empty for an ordinary shot. Pure.
    /// A moment whose signature has no captioned event is left out: a replay could not hold on it.
    static func detect(timeline: Timeline, facts: ShotFacts, captions: [Caption], table: TableKind, isBreak: Bool) -> [ShotHighlight] {
        let m = ShotMoments(timeline: timeline, captions: captions)
        let cue = facts.cueBall
        let first = m.firstContact(of: cue)
        let events = timeline.events

        // A break is judged as a break and nothing else: the rack's scatter would otherwise read as combinations,
        // banks and multiple pots on every break.
        if isBreak {
            let s = m.signature([first])
            return first == nil || s.isEmpty ? [] : [ShotHighlight(kind: .breakShot, signatureEvents: s, ball: cue)]
        }

        var found: [ShotHighlight] = []
        func add(_ kind: HighlightKind, _ candidates: [Int?], ball: Int) {
            let s = m.signature(candidates)
            guard !s.isEmpty else { return }
            found.append(ShotHighlight(kind: kind, signatureEvents: s, ball: ball))
        }
        let firstTime = first.map { events[$0].time } ?? .infinity
        let objectDrops = facts.objectBallsPocketed

        // Jump: the struck ball left the cloth fast enough to clear something; hold the take-off and the landing.
        if let up = m.takeOff(of: cue, minimumUp: jumpSpeed) {
            add(.jump, [up, m.landing(of: cue, after: up)], ball: cue)
        }

        // Curve: a raised cue spun the struck ball along its path, and its path bent while it slid before it reached
        // anything; hold where the bend ended.
        if (m.strikeCurl(of: cue) ?? 0) >= curveCurl,
           let bend = m.largestBend(of: cue, atOrBefore: firstTime), abs(bend.degrees) >= curveDegrees {
            add(.curve, [bend.event], ball: cue)
        }

        // Thrown in: a ball that dropped straight from its last contact (no rail between: that is a bank), which
        // friction sent off the line of centres by a visible angle, when the line of centres alone would have missed.
        for drop in objectDrops {
            guard let c = m.lastContact(of: drop.ball, atOrBefore: drop.time),
                  let t = CaptionEngine.throwFacts(events[c]), t.object == drop.ball,
                  abs(t.degrees) >= throwDegrees, m.railAfterLastContact(of: drop.ball) == nil,
                  m.wouldMiss(ball: drop.ball, from: c, along: t.lineOfCentres, pocket: drop.pocket) else { continue }
            add(.throwIn, [c], ball: drop.ball)
            break
        }

        // Combination: a ball that dropped was last struck by another object ball (not by the struck ball). The
        // dropped ball must be the slower one going in, so a ball that rolled into another and then fell is not one.
        for drop in objectDrops {
            guard let c = m.lastContact(of: drop.ball, atOrBefore: drop.time),
                  let hitter = m.other(in: c, than: drop.ball), hitter != cue,
                  let mine = events[c].balls.first(where: { $0.ball == drop.ball }),
                  let theirs = events[c].balls.first(where: { $0.ball == hitter }),
                  mine.velocityBefore.length < theirs.velocityBefore.length else { continue }
            add(.combination, [first, c], ball: drop.ball)
            break
        }

        // Kick: the struck ball went to the cushions before it found a ball: two rails, or one that still made
        // something drop.
        if first != nil {
            let rails = m.railsBeforeFirstContact(of: cue)
            if rails.count >= 2 || (rails.count == 1 && (!objectDrops.isEmpty || !facts.holeDrops.isEmpty)) {
                add(.kick, [rails.last, first], ball: cue)
            }
        }

        // Bank: a ball that dropped met a rail after its last contact; hold that cushion.
        for drop in objectDrops {
            guard let r = m.railAfterLastContact(of: drop.ball) else { continue }
            add(.bank, [r], ball: drop.ball)
            break
        }

        // Bumper pool: a ball that went into a cup off a post; hold its last post hit and the drop.
        if table == .bumperPool {
            for hd in facts.holeDrops {
                guard let post = m.postHits(of: hd.ball, atOrBefore: hd.time).last else { continue }
                add(.bumperCup, [post, m.pocket(of: hd.ball)], ball: hd.ball)
                break
            }
        }

        // Five-pin: the red centre pin and no other (the hardest pin result, worth the most).
        if table == .fivePin, facts.pinsDown.count == 1, let knock = facts.pinsDown.first,
           knock.pin == FivePinRules.redPin {
            add(.redPinAlone, [m.pinDowns().first], ball: knock.ball)
        }

        // Two at once: two or more object balls down from one stroke; hold the first two drops.
        if objectDrops.count >= 2 {
            let drops = m.pockets().filter { events[$0].balls.first?.ball != cue }
            add(.multiPot, [drops.first, drops.dropFirst().first], ball: objectDrops[0].ball)
        }

        // Draw and stop read the struck ball at its first hit: where it was, which way it came in, how fast.
        if let f = first, let mine = events[f].balls.first(where: { $0.ball == cue }),
           facts.resting.indices.contains(cue), ShotFacts.isOnTable(facts.resting[cue]) {
            let at = timeline.state(ball: cue, at: events[f].time).position
            let rest = facts.resting[cue]
            let way = mine.velocityBefore.normalized
            // Drawn back: it came to rest well behind the hit, measured along the way it came in.
            if way.length > 0.5, -(rest - at).dot(way) >= drawDistance {
                add(.drawBack, [f, m.firstRoll(of: cue, after: f)], ball: cue)
            }
            // Stopped dead: a firm hit, the ball it met went down, and it stayed within one ball radius of the spot.
            if mine.velocityBefore.length >= stopSpeed, let target = facts.firstContact?.ball,
               facts.pocket(of: target) != nil, (rest - at).length <= timeline.table.ballRadius {
                add(.stopDead, [f], ball: cue)
            }
        }

        // Too fast for the pocket: any ball that crossed a hole without dropping.
        if let skip = m.rimSkips().first, let ball = events[skip].balls.first?.ball {
            add(.rimSkip, [skip], ball: ball)
        }

        // Strongest first. Ranks are unique except the two other-table kinds, which never meet in one shot; the
        // declaration order breaks any tie anyway, so the order never depends on the sort.
        let order = HighlightKind.allCases
        return found.sorted {
            ($0.kind.rank, -(order.firstIndex(of: $0.kind) ?? 0)) > ($1.kind.rank, -(order.firstIndex(of: $1.kind) ?? 0))
        }
    }

    /// The strongest one, or nil.
    static func judge(timeline: Timeline, facts: ShotFacts, captions: [Caption], table: TableKind, isBreak: Bool) -> ShotHighlight? {
        detect(timeline: timeline, facts: facts, captions: captions, table: table, isBreak: isBreak).first
    }
}
