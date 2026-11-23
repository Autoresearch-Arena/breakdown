// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// PURPOSE: How often bullet time may stop the clock (plans/23-Nov-2026-bullet-time-plan.md, version 0.7.7), so it stays
//          special. Pure bookkeeping, no views and no model: BulletTime keeps one budget, tells it each struck shot
//          (noteShot) and each fresh rack, table or mode (startRack), and asks it whether a moment BulletTimePick found
//          may play (shouldPlay). The rules, which BreakdownTests/BulletTimeRunTests pins:
//            - a rare kind (a jump hit, a curve hit, a kiss) freezes every time;
//            - a big cut freezes at most once per rack, and only when at least cutGap shots have passed since the
//              last freeze of any kind;
//            - a hard break freezes only when it is the hardest frozen break of the session by at least breakBeatBy
//              m/s (the first that qualifies sets the mark), and in free play never on the session's first break
//              (the rule the break's highlight card keeps);
//            - a shot the computer played freezes only for a rare kind.
// SRP/DRY check: Pass - checked HighlightOffer.swift, the "worth watching" card's frequency rule: the shape is mirrored
//          (noteShot, startRack, a yes uses the moment up) but not shared, because the rules differ (a three-shot gap
//          against four, per-kind racks against one cut per rack, and a session-long hardest break it has no use for).
import Foundation

struct BulletTimeBudget: Equatable {
    /// The smallest gap, in shots, between any freeze and a big cut's freeze.
    static let cutGap = 4
    /// How much harder, m/s at the rack, a break must be than the hardest frozen one to freeze again.
    static let breakBeatBy = 0.3

    /// Shots noted so far. Counts across racks; only differences between two counts are used.
    private(set) var shotsNoted = 0
    /// The shot count at the last freeze of any kind; nil before the first.
    private(set) var lastFreezeShot: Int?
    /// True once a big cut has frozen on this rack.
    private(set) var cutUsedThisRack = false
    /// The speed into the rack of the hardest break that froze this session (it lives as long as the model).
    private(set) var hardestBreak: Double?

    /// A shot was struck and recorded (whether or not it has a moment).
    mutating func noteShot() {
        shotsNoted += 1
    }

    /// A fresh rack, a new table or a mode starting: only the rack's cut is forgotten. The gap and the hardest break
    /// carry on.
    mutating func startRack() {
        cutUsedThisRack = false
    }

    /// Whether `m`, found on the shot just noted, may freeze. A yes uses the moment up (it sets the rack's cut, the
    /// hardest break and the gap), so ask only when the freeze can really play: the same warning HighlightOffer carries.
    /// - computerShot: the computer played this shot in a match or table game.
    /// - freePlay: free play is on the table (no match, no authored mode, no drill), so the first-break rule applies.
    /// - freePlayBreaks: free-play breaks struck this session, this one included.
    mutating func shouldPlay(_ m: BulletMoment, computerShot: Bool, freePlay: Bool, freePlayBreaks: Int) -> Bool {
        if computerShot && !m.kind.isRare { return false }
        switch m.kind {
        case .jumpHit, .curveHit, .kiss:
            break
        case .hardBreak:
            if freePlay && freePlayBreaks < 2 { return false }
            if let hardest = hardestBreak, m.incomingSpeed < hardest + Self.breakBeatBy { return false }
            hardestBreak = m.incomingSpeed
        case .bigCut:
            if cutUsedThisRack { return false }
            if let last = lastFreezeShot, shotsNoted - last < Self.cutGap { return false }
            cutUsedThisRack = true
        }
        lastFreezeShot = shotsNoted
        return true
    }
}
