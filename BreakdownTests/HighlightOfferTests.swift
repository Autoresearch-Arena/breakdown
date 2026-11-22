// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// PURPOSE: HighlightOffer (App/HighlightOffer.swift), the pure rule for how often free play's "worth watching" card
//          appears (plans/22-Nov-2026-v074-glow-up-plan.md, stream watch-invite). Checks each rule the file states: rare
//          kinds every time; a common kind once per rack and never on two shots in a row; at least commonGap shots
//          between two common cards; startRack forgetting the rack; the trick link once per kind per session and never
//          for a made trick shot or a kind no trick shot teaches. Also a match's own rule (MatchMode.highlightShow) and
//          that every kind has words on its card.
// SRP/DRY check: Pass - checks only; the gap is read from HighlightOffer.commonGap and the kinds' rarity and trick ids
//          from ShotHighlight.swift, never retyped.
@testable import Breakdown
import XCTest

final class HighlightOfferTests: XCTestCase {
    private let rare = HighlightKind.allCases.filter(\.isRare)
    private let common = HighlightKind.allCases.filter { !$0.isRare }

    /// Note a shot and ask about `kind` on it, as the model does.
    private func shot(_ offer: inout HighlightOffer, _ kind: HighlightKind) -> Bool {
        offer.noteShot()
        return offer.shouldOffer(kind)
    }

    func testRareKindsAreOfferedEveryTime() {
        XCTAssertFalse(rare.isEmpty)
        var offer = HighlightOffer()
        for kind in rare {
            // Back to back, many times over, on one rack.
            for _ in 0..<5 { XCTAssertTrue(shot(&offer, kind), "\(kind) is rare and must be offered every time") }
        }
    }

    func testACommonKindIsOfferedOncePerRack() {
        for kind in common {
            var offer = HighlightOffer()
            XCTAssertTrue(shot(&offer, kind), "\(kind): the first one on a rack is offered")
            // However long the rack runs, the same common kind is not offered again on it.
            for _ in 0..<(HighlightOffer.commonGap * 4) { XCTAssertFalse(shot(&offer, kind), "\(kind) twice on one rack") }
        }
    }

    func testCommonCardsAreNeverOnTwoShotsInARow() {
        var offer = HighlightOffer()
        XCTAssertTrue(shot(&offer, .bank))
        // A different common kind on the very next shot is held back.
        XCTAssertFalse(shot(&offer, .drawBack))
    }

    func testAtLeastTheGapSeparatesTwoCommonCards() {
        var offer = HighlightOffer()
        XCTAssertTrue(shot(&offer, .bank))
        // Every shot inside the gap offers a different common kind, and every one is held back...
        let others: [HighlightKind] = [.drawBack, .stopDead, .multiPot, .rimSkip, .breakShot]
        for k in 1..<HighlightOffer.commonGap {
            XCTAssertFalse(shot(&offer, others[k % others.count]), "a common card \(k) shots after the last one")
        }
        // ...and the first shot at the gap may have one.
        XCTAssertTrue(shot(&offer, .stopDead))
    }

    func testRareCardsDoNotHoldBackOrUseUpCommonOnes() {
        var offer = HighlightOffer()
        XCTAssertTrue(shot(&offer, .jump))
        // A rare card is not a common card: the next shot's common kind is still offered.
        XCTAssertTrue(shot(&offer, .bank))
        XCTAssertTrue(shot(&offer, .curve))
    }

    func testStartRackForgetsTheRack() {
        var offer = HighlightOffer()
        XCTAssertTrue(shot(&offer, .breakShot))
        XCTAssertFalse(shot(&offer, .breakShot))
        offer.startRack()
        // A new rack: the break card comes again, at once, even inside the old gap.
        XCTAssertTrue(shot(&offer, .breakShot))
        offer.startRack()
        XCTAssertTrue(shot(&offer, .bank))
    }

    func testTheTrickLinkIsOfferedOncePerKindPerSession() {
        var offer = HighlightOffer()
        let taught = HighlightKind.allCases.filter { $0.trickID != nil }
        XCTAssertFalse(taught.isEmpty)
        for kind in taught {
            XCTAssertTrue(offer.mayLinkTrick(kind, done: []), "\(kind): its trick shot may be offered")
            offer.noteTrickLinked(kind)
            XCTAssertFalse(offer.mayLinkTrick(kind, done: []), "\(kind): offered a second time")
        }
        // A new rack does not bring the links back: they are once per session.
        offer.startRack()
        for kind in taught { XCTAssertFalse(offer.mayLinkTrick(kind, done: [])) }
    }

    func testTheTrickLinkIsNeverOfferedForADoneTrickOrAnUntaughtKind() {
        let offer = HighlightOffer()
        for kind in HighlightKind.allCases {
            if let id = kind.trickID {
                XCTAssertFalse(offer.mayLinkTrick(kind, done: [id]), "\(kind): its trick shot is already made")
            } else {
                XCTAssertFalse(offer.mayLinkTrick(kind, done: []), "\(kind): no trick shot teaches it")
            }
        }
    }

    /// A match's rule (MatchMode.highlightShow): rare kinds every time, a common kind once per game, never a ball too
    /// fast for the pocket; an offered shot turns a routine banner into the card; the break keeps its own way.
    @MainActor
    func testMatchOffersRareEveryTimeCommonOnceAndTheBreakAsItWas() {
        for kind in rare {
            XCTAssertEqual(MatchMode.highlightShow(kind, offered: Set(HighlightKind.allCases), current: .banner), .card,
                           "\(kind) is rare: offered every time, as the card")
        }
        for kind in common where kind != .breakShot && kind != .rimSkip {
            XCTAssertEqual(MatchMode.highlightShow(kind, offered: [], current: .banner), .card, "\(kind) the first time")
            XCTAssertNil(MatchMode.highlightShow(kind, offered: [kind], current: .banner), "\(kind) twice in a game")
        }
        XCTAssertNil(MatchMode.highlightShow(.rimSkip, offered: [], current: .banner))
        XCTAssertEqual(MatchMode.highlightShow(.breakShot, offered: [], current: .banner), .banner)
        XCTAssertEqual(MatchMode.highlightShow(.breakShot, offered: [], current: .card), .card)
    }

    func testEveryKindHasATitleAndALine() {
        for kind in HighlightKind.allCases {
            XCTAssertFalse(HighlightWords.title(kind).isEmpty, "\(kind) has no title")
            XCTAssertFalse(HighlightWords.line(kind).isEmpty, "\(kind) has no line")
        }
    }
}
