// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// PURPOSE: Bullet time's trigger judge (plans/23-Nov-2026-bullet-time-plan.md, version 0.7.7): reads a freshly
//          recorded shot once, at the strike, and says whether it has a ball-to-ball hit worth stopping the clock on,
//          and which. The freeze is always on a contact between two balls, because what it shows is the geometry of
//          two balls touching (LensContactGeometry), and only on a hit where the struck ball was at rest, because only
//          then does the momentum triangle close. Kinds, strongest first: a jump landing on its ball, the end of a
//          curving (masse) shot, a kiss that sends a ball in, a near-full-power break, and a thin cut that drops.
//          Pure: a recording, its ShotFacts and its captions in, a moment (or nil) out. No views, no model, no clock.
//          Read by BulletTime.arm (the model calls it from finishStrike) and by BreakdownTests/BulletTimePickTests.
//          How often a found moment is allowed to play is not decided here; that is BulletTimeBudget.
// SRP/DRY check: Pass - checked ShotHighlightJudge.swift: its ShotMoments event finders (first contact, contacts,
//          last contact before a drop, take-off, strike curl, largest bend, rail after the last contact) and its
//          thresholds (jumpSpeed, curveDegrees, curveCurl) are reused here, never copied, as its header asks.
//          ContactGeometry (LensContactGeometry.swift) is the one reading of a hit's striker, struck ball and speeds,
//          and CaptionEngine.restSpeed, through it, the one meaning of "at rest". ShotFacts gives the drops.
import BreakdownLensModel
import BreakdownTimeline
import Foundation

/// The kinds of hit bullet time stops on, in priority order: when one shot has more than one, the first wins.
enum BulletKind: String, CaseIterable, Sendable {
    case jumpHit, curveHit, kiss, hardBreak, bigCut

    /// Rare kinds freeze every time they happen; the common two are rationed (BulletTimeBudget).
    var isRare: Bool {
        switch self {
        case .jumpHit, .curveHit, .kiss: return true
        case .hardBreak, .bigCut: return false
        }
    }
}

/// One hit to stop the clock on.
struct BulletMoment: Equatable, Sendable {
    let kind: BulletKind
    /// Index into timeline.events of the ball-to-ball contact.
    let event: Int
    /// That event's clock time, seconds.
    let time: Double
    /// The striking ball and the struck one, as ContactGeometry reads them.
    let striker: Int
    let object: Int
    /// The striking ball's speed into the hit, m/s.
    let incomingSpeed: Double
}

enum BulletTimePick {
    /// A break freezes only when the struck ball meets the rack at this speed or faster, m/s. The break range is
    /// PlayerShotSpeed.rackBreak, 7 to 16 m/s at the strike, and the break panel's default of 10 arrives at the rack a
    /// little under 10: the default break must never qualify, so only the top part of the range does.
    static let breakSpeed = 13.0
    /// A cut is "big" from this angle between the striking ball's way in and the line of centres, degrees. A full,
    /// straight-on hit is near 0 and a half-ball hit about 30; 55 is a properly thin cut.
    static let cutDegrees = 55.0
    /// ...and only when the striking ball arrives at least this fast, m/s, so a dribble that just reaches a ball at an
    /// angle is not one.
    static let cutSpeed = 0.8
    /// A kiss counts only when the ball that touched the dropped ball was moving at least this fast, m/s: a ball that
    /// rolled up and barely leaned on another is not the kiss that sent it in.
    static let kissSpeed = 0.3

    /// Every kind this shot qualifies for, at most one per kind, in BulletKind order. On a break only the hard break is
    /// read (as ShotHighlightJudge reads a break only as a break: the rack's scatter would otherwise look like kisses).
    static func candidates(timeline: Timeline, facts: ShotFacts, captions: [Caption], isBreak: Bool) -> [BulletMoment] {
        let m = ShotMoments(timeline: timeline, captions: captions)
        let events = timeline.events
        let cue = facts.cueBall
        let first = m.firstContact(of: cue)

        /// The moment on event `i`, or nil unless it is a ball-to-ball contact whose struck ball was at rest.
        func moment(_ kind: BulletKind, _ i: Int?) -> BulletMoment? {
            guard let i, events.indices.contains(i), let g = ContactGeometry.at(events[i]), !g.objectWasMoving else {
                return nil
            }
            return BulletMoment(kind: kind, event: i, time: events[i].time, striker: g.striker, object: g.object,
                                incomingSpeed: g.incoming.length)
        }
        /// The geometry of event `i`, when it is a hit on a ball at rest.
        func geometry(_ i: Int?) -> ContactGeometry? {
            guard let i, events.indices.contains(i), let g = ContactGeometry.at(events[i]), !g.objectWasMoving else {
                return nil
            }
            return g
        }

        if isBreak {
            guard let g = geometry(first), g.striker == cue, g.incoming.length >= breakSpeed else { return [] }
            return [moment(.hardBreak, first)].compactMap { $0 }
        }

        var found: [BulletMoment] = []

        // Jump hit: the struck ball took off fast enough to be a jump, and the freeze is on its first contact with a
        // ball at or after that take-off (in the air or after it came down).
        if let up = m.takeOff(of: cue, minimumUp: ShotHighlightJudge.jumpSpeed) {
            let upTime = m.time(up)
            let hit = m.contacts(of: cue).first { m.time($0) >= upTime - ShotMoments.instant }
            if let j = moment(.jumpHit, hit) { found.append(j) }
        }

        // Curve hit: the judge's own curve test (a raised cue's curl, and a bend before the first contact), frozen on
        // that first contact, where the curve ends.
        if (m.strikeCurl(of: cue) ?? 0) >= ShotHighlightJudge.curveCurl, let f = first,
           let bend = m.largestBend(of: cue, atOrBefore: m.time(f)), abs(bend.degrees) >= ShotHighlightJudge.curveDegrees,
           let c = moment(.curveHit, f) {
            found.append(c)
        }

        // Kiss: an object ball dropped straight (no rail between) from a contact that was not the struck ball's own
        // first hit, with a ball moving into it while it sat at rest. The first such drop, in drop order.
        for drop in facts.objectBallsPocketed {
            guard let c = m.lastContact(of: drop.ball, atOrBefore: drop.time), c != first,
                  let g = geometry(c), g.object == drop.ball, g.incoming.length >= kissSpeed,
                  m.railAfterLastContact(of: drop.ball) == nil, let k = moment(.kiss, c) else { continue }
            found.append(k)
            break
        }

        // Big cut: the struck ball's first hit, on a ball at rest, thin, firm, and that ball dropped straight from it.
        if let f = first, let g = geometry(f), g.striker == cue,
           let drop = facts.pocketed.first(where: { $0.ball == g.object }),
           m.lastContact(of: g.object, atOrBefore: drop.time) == f, m.railAfterLastContact(of: g.object) == nil,
           g.incoming.length >= cutSpeed, cutAngle(g) >= cutDegrees, let b = moment(.bigCut, f) {
            found.append(b)
        }

        // Already in BulletKind order (jump, curve, kiss, then the cut; the break returned above), one of each.
        return found
    }

    /// The one moment to freeze on, or nil: the first candidate.
    static func pick(timeline: Timeline, facts: ShotFacts, captions: [Caption], isBreak: Bool) -> BulletMoment? {
        candidates(timeline: timeline, facts: facts, captions: captions, isBreak: isBreak).first
    }

    /// The cut angle of a hit, degrees: between the striking ball's way in and the line of centres. ContactGeometry's
    /// normal points from the striking ball into the struck one, so a full, straight-on hit is near 0 and a thin cut is
    /// large (a half-ball hit about 30, a very thin one towards 90). "At least cutDegrees" therefore means thin.
    static func cutAngle(_ g: ContactGeometry) -> Double {
        let c = max(-1, min(1, g.incoming.normalized.dot(g.normal)))
        return acos(c) * 180 / .pi
    }
}
