// Author: Claude Opus 5.5 High
// Date: 22-November-2026
// PURPOSE: The gentle close-up on a held signature moment of a guided Lens replay (plans/22-Nov-2026-v074-glow-up-
//          plan.md, F7 and stream lens-drawing): eases the hand zoom toward the contact or event being held and back
//          when the hold ends, never during Ride and never over a zoom the player chose. FOUNDATION stub: TableStage
//          calls step once per frame before the camera updates; the lens-drawing stream fills the body.
// SRP/DRY check: Pass - checked TableZoom (owns the hand zoom; this only asks it to move) and ShotCamera (Ride, which
//          this stays out of).
import SwiftUI

@MainActor
enum SignatureCloseUp {
    /// Called once per frame before the camera updates: eases the hand zoom toward the moment of a held signature beat
    /// and back when the hold ends.
    static func step(model: ShowpieceModel, table: TableScene) {}
}
