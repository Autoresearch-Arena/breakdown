// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// PURPOSE: How often the "worth watching" card may appear in free play (plans/22-Nov-2026-v074-glow-up-plan.md, stream
//          watch-invite, G3). Pure bookkeeping, no views and no model: ShowpieceModel keeps one HighlightOffer, tells it
//          each shot (noteShot) and each fresh rack or mode (startRack), and asks it whether a judged highlight may be
//          offered (shouldOffer) and whether its card may carry "Try the trick shot" (mayLinkTrick, noteTrickLinked).
//          The rules, which BreakdownTests/HighlightOfferTests.swift pins:
//            - a rare kind (HighlightKind.isRare: jump, curve, throw, combination, kick) is offered every time;
//            - a common kind is offered at most once per rack, never on two shots in a row, and at least
//              commonGap shots after the last common card (the break counts as common, so it comes once per rack);
//            - startRack forgets the rack (which common kinds were offered and when the last common card was);
//            - the trick link is offered once per kind per session (the model lives for the run of the app), and never
//              for a trick shot the player has already made, nor for a kind no trick shot teaches.
// SRP/DRY check: Pass - checked ShotHighlight.swift (kinds, rarity and trick ids live there and are read, not copied),
//          MatchMode (a match keeps its own once-per-match set; the free-play frequency here does not apply to it) and
//          TrickShotMode (doneIDs is the one record of made trick shots, passed in, never stored here).
import Foundation

struct HighlightOffer: Equatable {
    /// The smallest gap, in shots, between two common cards: a common card on shot n allows the next one on shot
    /// n + commonGap at the earliest, so two of them can never be on consecutive shots and the table stays calm.
    static let commonGap = 3

    /// Shots noted so far (free play only). Counts across racks; only differences between two counts are used.
    private(set) var shotsNoted = 0
    /// The common kinds already offered on this rack.
    private var offeredThisRack: Set<HighlightKind> = []
    /// The shot count when the last common card was offered on this rack; nil when none has been.
    private var lastCommonShot: Int?
    /// The kinds whose trick shot the player has been sent to from a card this session.
    private var linkedKinds: Set<HighlightKind> = []

    /// A fresh rack, a new table or a mode starting: the per-rack memory goes. The session's trick links stay.
    mutating func startRack() {
        offeredThisRack = []
        lastCommonShot = nil
    }

    /// A free-play shot was struck and recorded (whether or not it turns out remarkable).
    mutating func noteShot() {
        shotsNoted += 1
    }

    /// Whether a highlight of `kind`, judged on the shot just noted, may be offered. Saying yes to a common kind uses
    /// up that kind for the rack and starts the gap, so ask only when the card can really be shown.
    mutating func shouldOffer(_ kind: HighlightKind) -> Bool {
        if kind.isRare { return true }
        guard !offeredThisRack.contains(kind) else { return false }
        if let last = lastCommonShot, shotsNoted - last < Self.commonGap { return false }
        offeredThisRack.insert(kind)
        lastCommonShot = shotsNoted
        return true
    }

    /// Whether the card may carry "Try the trick shot" for `kind`: a trick shot teaches it, the player has not made
    /// that trick shot yet (`done` is TrickShotMode.doneIDs), and no card has sent them to it this session.
    func mayLinkTrick(_ kind: HighlightKind, done: Set<String>) -> Bool {
        guard let id = kind.trickID else { return false }
        return !done.contains(id) && !linkedKinds.contains(kind)
    }

    /// The player took the card's "Try the trick shot" for `kind`.
    mutating func noteTrickLinked(_ kind: HighlightKind) {
        linkedKinds.insert(kind)
    }
}
