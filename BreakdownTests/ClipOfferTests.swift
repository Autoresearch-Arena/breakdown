// Author: Claude Opus 5.5 High
// Date: 23-November-2026
// PURPOSE: Checks for when the game offers a Lens clip (ClipOffer, App/Clips/ClipSource.swift, 0.7.7), on the real
//          model: nothing during the first launch's opening (the calm first minute); a free-play shot at rest offers
//          one, and its source carries the model's own captions for that recording; nothing behind the menu; and
//          nothing while a clip is being made.
//          The device's opening-seen setting is kept and put back, as the other model tests do.
// SRP/DRY check: Pass - checks only; every action goes through the model's own methods.
@testable import Breakdown
import BreakdownLensModel
import BreakdownPhysics
import BreakdownTimeline
import Foundation
import XCTest

@MainActor
final class ClipOfferTests: XCTestCase {
    /// A model past the opening with the menu closed, in free play.
    private func freshModel() -> ShowpieceModel {
        let m = ShowpieceModel()
        for _ in 0..<3 where m.openingStage != .none { m.skipOpening() }
        m.closeMenu()
        return m
    }

    /// Waits for the model's background solve to land, then lets the shot play out (the balls at rest).
    private func settle(_ m: ShowpieceModel) async {
        var waited = 0
        while m.isSolving && waited < 1000 { try? await Task.sleep(for: .milliseconds(10)); waited += 1 }
        m.scrub(to: m.duration)
    }

    /// The Ride demo's straight pot as a free-play layout and aim.
    private func straightPotLayout() -> (start: [Vec2], aim: Double) {
        let input = RideDemo.straightPot()
        let d = input.strike.direction
        return (input.positions, atan2(d.y, d.x) * 180 / Double.pi)
    }

    func testNothingDuringTheOpening() {
        let key = GameSettings.seenOpeningKey
        let before = UserDefaults.standard.object(forKey: key)
        UserDefaults.standard.set(false, forKey: key)
        defer { UserDefaults.standard.set(before, forKey: key) }
        let m = ShowpieceModel()
        if m.openingStage != .none {
            XCTAssertFalse(ClipOffer.available(m), "a clip was offered in the first minute")
        }
    }

    func testAShotAtRestOffersAClipWithTheModelsCaptions() async throws {
        let m = freshModel()
        let pot = straightPotLayout()
        m.loadTrickLayout(pot.start, aim: pot.aim, power: 2.5, tipUp: 0, tipSide: 0)
        m.shootNow()
        XCTAssertFalse(ClipOffer.available(m), "offered while the shot was being solved")
        await settle(m)
        XCTAssertTrue(ClipOffer.available(m), "a free-play shot at rest should offer a clip")
        let source = try XCTUnwrap(ClipOffer.source(m))
        XCTAssertEqual(source.captions, m.captions, "the clip rebuilt captions the model already had")
        m.openMenu()
        XCTAssertFalse(ClipOffer.available(m), "offered behind the menu")
        m.closeMenu()
        XCTAssertTrue(ClipOffer.available(m))
    }

    func testNothingWhileAClipIsBeingMade() async throws {
        let m = freshModel()
        let pot = straightPotLayout()
        m.loadTrickLayout(pot.start, aim: pot.aim, power: 2.5, tipUp: 0, tipSide: 0)
        m.shootNow()
        await settle(m)
        let maker = ClipMaker.shared
        defer { maker.cancel() }
        ClipOffer.start(m)
        XCTAssertTrue(maker.isMaking, "the tap did not start a clip")
        XCTAssertFalse(ClipOffer.available(m), "a second clip was offered while one is being made")
        maker.cancel()
        XCTAssertTrue(maker.isIdle)
        XCTAssertTrue(ClipOffer.available(m))
    }
}
